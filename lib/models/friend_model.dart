class FriendModel {
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final bool isMutual;

  const FriendModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    this.isMutual = true,
  });

  static List<FriendModel> defaultFriends = [
    const FriendModel(
      id: 'friend_1',
      username: 'hoangnam',
      displayName: 'Hoàng Nam',
      avatarUrl:
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    ),
    const FriendModel(
      id: 'friend_2',
      username: 'lananh_chi',
      displayName: 'Lan Anh',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    ),
    const FriendModel(
      id: 'friend_3',
      username: 'duy_minh',
      displayName: 'Duy Minh',
      avatarUrl:
          'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
    ),
    const FriendModel(
      id: 'friend_4',
      username: 'khanh_vy',
      displayName: 'Khánh Vy',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    ),
  ];
}
