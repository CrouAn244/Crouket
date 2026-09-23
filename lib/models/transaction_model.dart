enum TransactionType { expense, income }

class TransactionModel {
  final String id;
  final String? photoPath; // Local path or image asset/URL
  final String caption;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime createdAt;
  final String userId;
  final String userName;
  final String userAvatar;
  final bool isPrivate;
  final Map<String, int> reactions; // emoji -> count
  final Set<String> userReactedEmojis; // emojis this user reacted with

  const TransactionModel({
    required this.id,
    this.photoPath,
    required this.caption,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.createdAt,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.isPrivate = false,
    this.reactions = const {},
    this.userReactedEmojis = const {},
  });

  TransactionModel copyWith({
    String? id,
    String? photoPath,
    String? caption,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? createdAt,
    String? userId,
    String? userName,
    String? userAvatar,
    bool? isPrivate,
    Map<String, int>? reactions,
    Set<String>? userReactedEmojis,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      photoPath: photoPath ?? this.photoPath,
      caption: caption ?? this.caption,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      isPrivate: isPrivate ?? this.isPrivate,
      reactions: reactions ?? this.reactions,
      userReactedEmojis: userReactedEmojis ?? this.userReactedEmojis,
    );
  }
}
