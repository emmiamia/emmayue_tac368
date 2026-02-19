

class Coords {
  int c; // column
  int r; // row

  Coords(this.c, this.r);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coords &&
          runtimeType == other.runtimeType &&
          c == other.c &&
          r == other.r;

  @override
  int get hashCode => c.hashCode ^ r.hashCode;

  @override
  String toString() => "($c,$r)";
}
