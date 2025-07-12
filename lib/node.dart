class Node<T> {
  final String key;
  final T value;
  Node(this.key, this.value);
  toJson() => {'key': key, 'value': value};
}
