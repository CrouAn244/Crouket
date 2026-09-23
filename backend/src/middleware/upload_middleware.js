import multer from 'multer';
import { config } from '../config.js';

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files (JPEG, PNG, WebP, HEIC, etc.) are allowed!'), false);
  }
};

export const uploadSingleImage = multer({
  storage,
  limits: {
    fileSize: config.imageOptimization.maxUploadSizeBytes,
  },
  fileFilter,
}).single('image');

