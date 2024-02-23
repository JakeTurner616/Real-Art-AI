class Post {
  late final String imageBase64;

  Post({
    required this.imageBase64,
  });

  factory Post.fromJson(String imageBase64) {
    return Post(imageBase64: imageBase64);
  }

  get id => null;
}
