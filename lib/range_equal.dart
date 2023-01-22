extension RangeEqual on num {
  /// Returns true if this equals to value +/- padding
  bool equalsInRange(num value, num padding) {
    return this - padding <= value && value <= this + padding;
  }
}
