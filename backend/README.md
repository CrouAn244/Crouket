# Crouket Backend: Kiến Trúc 2 Database & Hệ Thống Tối Ưu Ảnh Toàn Diện

Hệ thống Backend chuẩn công nghiệp cho ứng dụng quản lý chi tiêu phong cách Locket **Crouket**, thiết kế theo tiêu chuẩn:
1. **Kiến trúc 2 Database độc lập**:
   - **DB 1 (Metadata & User DB)**: Lưu thông tin người dùng, mật khẩu đã mã hóa bcrypt, giao dịch, danh mục, liên kết bạn bè, lượt thả emoji. **Tuyệt đối không lưu chuỗi nhị phân ảnh hoặc Base64** vào DB 1 (chỉ lưu metadata cực nhẹ như SHA-256, BlurHash, dimensions).
   - **DB 2 (Dedicated Media Storage Engine)**: Lưu trữ ảnh nhị phân đã nén tối ưu (WebP) theo cơ chế Content-Addressed, phân mảnh thư mục (sharding) chống nghẽn I/O.
2. **Heavy Lifting on Backend (Tối ưu triệt để ở Backend)**:
   - Frontend chỉ gửi 1 multipart request duy nhất chứa ảnh thô từ camera.
   - Toàn bộ việc nặng (xoá EXIF nhạy cảm, nén WebP bằng C-core `libvips`/`sharp`, tạo 3 biến thể kích thước, sinh chuỗi **BlurHash** làm placeholder mượt mà, chống trùng lặp SHA-256) được thực hiện 100% tại Backend.

---

## 1. So Sánh Hiệu Quả Tối Ưu Hoá

| Tiêu chí | Lưu trực tiếp vào DB 1 (Cách cũ) | Kiến Trúc Crouket 2-DB + Sharp WebP |
| :--- | :--- | :--- |
| **Kích thước ảnh** | 4MB – 10MB (JPEG gốc / Base64 phình 133%) | **~40KB – 60KB (WebP Quality 82 - Giảm ~92%)** |
| **Tải bộ nhớ RAM DB 1** | Tắc nghẽn Buffer Pool khi SELECT danh sách | **Cực nhẹ (mỗi record chỉ tốn ~120 bytes metadata)** |
| **Tốc độ hiển thị Feed** | Chờ tải xong mới thấy ảnh (đen màn hình) | **Hiển thị ngay nền mờ BlurHash trong 1ms** |
| **Ảnh trùng lặp (Deduplication)** | Nhân đôi dung lượng mỗi lần đăng | **Phát hiện mã băm SHA-256 -> Tốn 0 byte lưu trữ** |
| **Dung lượng 10.000 bài đăng** | ~50 GB – 100 GB (gây sập DB) | **~0.4 GB (lưu ở DB 2, DB 1 chỉ tốn ~1.5 MB)** |

---

## 2. Các Biến Thể Ảnh Được Tự Động Sinh Ra (DB 2)

Mỗi lần tải ảnh lên, Backend tự động sinh 3 phiên bản:
1. **`thumb` (150x150, ~5-8 KB)**: Dùng cho thumbnail lịch sử chi tiêu, widget thống kê.
2. **`feed` (800x800, ~40-60 KB)**: Khung vuông 1:1 Retina sắc nét cho Locket Feed.
3. **`full` (max 1200px, ~80-120 KB)**: Dùng khi người dùng bấm phóng to xem chi tiết hoá đơn.

Tất cả các file được phục vụ qua HTTP Header:
```http
Content-Type: image/webp
Cache-Control: public, max-age=31536000, immutable
ETag: "hash-variant"
```

---

## 3. Khởi Chạy Nhanh (Quick Start)

### Yêu cầu
- Node.js v20+ (Máy hiện tại đã có sẵn **Node v24.18.0**)

### Các bước chạy

```bash
# 1. Di chuyển vào thư mục backend
cd backend

# 2. Cài đặt thư viện (nếu chưa)
npm install

# 3. Chạy môi trường phát triển (tự reload khi sửa code)
npm run dev

# 4. Chạy bộ kiểm thử tự động
npm test
```

Server sẽ lắng nghe tại: `http://localhost:3000`

---

## 4. Chạy Bằng Docker Compose (Tuỳ chọn Production)

```bash
cd backend
docker compose up -d
```
Lệnh này sẽ khởi chạy:
- Container Backend tại cổng `3000`
- Container MinIO S3 Object Store tại cổng `9000` và Console UI tại cổng `9001` (user: `minioadmin` / pass: `minioadminpassword`)

---

## 5. Danh Sách API Endpoints

### Xác Thực (Authentication)
- `POST /api/auth/register`: Đăng ký tài khoản (Tự động khởi tạo 8 danh mục chi tiêu chuẩn).
- `POST /api/auth/login`: Đăng nhập lấy JWT Token.
- `POST /api/auth/forgot-password`: Gửi hướng dẫn đặt lại mật khẩu.
- `GET /api/auth/me`: Lấy thông tin tài khoản hiện tại (Yêu cầu `Bearer <token>`).

### Xử Lý & Lưu Trữ Media (DB 2)
- `POST /api/media/upload`: Tải ảnh lên (`multipart/form-data`, trường `image`).
  - *Response*: Trả về `mediaId`, `sha256`, `blurhash`, tỷ lệ nén `% reduction`, và các URLs `thumb`, `feed`, `full`.
- `GET /api/media/:variant/:hash`: Truy xuất ảnh WebP với cache vĩnh viễn (`variant`: `thumb`, `feed`, hoặc `full`).
- `GET /api/media/stats`: Xem báo cáo thống kê dung lượng và số MB đã tiết kiệm được giữa DB 1 và DB 2.

### Giao Dịch Chi Tiêu (Transactions)
- `GET /api/transactions/feed`: Lấy dòng thời gian bài đăng của bạn bè (kèm thông tin ảnh, blurhash, emoji reaction).
- `POST /api/transactions`: Đăng giao dịch chi tiêu/thu nhập mới (kèm `mediaId`, `amount`, `categoryId`, `caption`).
- `POST /api/transactions/:id/react`: Thả hoặc gỡ emoji reaction (`💸`, `🔥`, `👏`, `🤤`, `😱`).

### Thống Kê (Analytics)
- `GET /api/stats?period=week|month|year`: Lấy tổng thu chi, tỷ lệ phân bổ theo danh mục và biểu đồ cột 7 ngày.

### Danh Mục & Bạn Bè (Categories & Friends)
- `GET /api/categories`: Danh sách danh mục và tiến độ ngân sách tháng.
- `POST /api/categories`: Tạo danh mục mới (tên, emoji, màu, ngân sách).
- `GET /api/friends`: Danh sách bạn bè.
- `POST /api/friends/add`: Kết bạn bằng mã Crouket ID (ví dụ `@duc_huy`).

