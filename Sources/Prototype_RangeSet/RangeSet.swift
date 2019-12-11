/// A set of values of any comparable value, represented by ranges.
public struct RangeSet<Bound: Comparable> {
    internal var _ranges: [Range<Bound>] = []

    /// Creates an empty range set.
    public init() {}

    /// Creates a range set containing the values in the given range.
    ///
    /// - Parameter range: The range to use for the new range set.
    public init(_ range: Range<Bound>) {
        if !range.isEmpty {
            self._ranges = [range]
        }
    }
    
    /// Creates a range set containing the values in the given ranges.
    ///
    /// Any ranges that overlap or adjoin are merged together in the range set.
    /// Empty ranges are ignored. For example:
    ///
    ///     let allowedValues = RangeSet(0.0..<0.0, 0.25..<0.5, 0.5..<1.0, 2.0..<5.0, 4.0..<6.0)
    ///     // allowedValues == RangeSet(0.25..<1.0, 2.0..<6.0)
    ///
    /// - Parameter ranges: The ranges of values to include in the new range
    ///   set.
    public init<S: Sequence>(_ ranges: S) where S.Element == Range<Bound> {
        for range in ranges {
            insert(contentsOf: range)
        }
    }
    
    /// Checks the invariants of `_ranges`.
    ///
    /// The ranges stored by a range set are never empty, never overlap,
    /// and are always stored in ascending order when comparing their lower
    /// or upper bounds. In addition to not overlapping, no two consecutive
    /// ranges share an upper and lower bound — `[0..<5, 5..<10]` is ill-formed,
    /// and would instead be represented as `[0..<10]`.
    internal func _checkInvariants() {
        for (a, b) in zip(ranges, ranges.dropFirst()) {
            precondition(!a.isEmpty && !b.isEmpty, "Empty range in range set")
            precondition(
                a.upperBound < b.lowerBound,
                "Out of order/overlapping ranges in range set")
        }
    }
    
    /// Creates a new range set from `_ranges`, which satisfies the range set
    /// invariants.
    internal init(_ranges: [Range<Bound>]) {
        self._ranges = _ranges
        _checkInvariants()
    }
    
    /// A Boolean value indicating whether the range set is empty.
    public var isEmpty: Bool {
        _ranges.isEmpty
    }
    
    /// Returns a Boolean value indicating whether the given value is
    /// contained by the ranges in the range set.
    ///
    /// - Parameter value: The value to look for in the range set.
    /// - Return: `true` if `value` is contained by a range in the range set;
    ///   otherwise, `false`.
    ///
    /// - Complexity: O(log *n*), where *n* is the number of ranges in the
    ///   range set.
    public func contains(_ value: Bound) -> Bool {
        let i = _ranges._partitioningIndex { $0.upperBound > value }
        return i == _ranges.endIndex
            ? false
            : _ranges[i].lowerBound <= value
    }
    
    /// Returns a range indicating the existing ranges that `range` overlaps
    /// with.
    ///
    /// For example, if `self` is `[0..<5, 10..<15, 20..<25, 30..<35]`, then:
    ///
    /// - `_indicesOfRange(12..<14) == 1..<2`
    /// - `_indicesOfRange(12..<19) == 1..<2`
    /// - `_indicesOfRange(17..<19) == 2..<2`
    /// - `_indicesOfRange(12..<22) == 1..<3`
    func _indicesOfRange(_ range: Range<Bound>) -> Range<Int> {
        precondition(!range.isEmpty)
        precondition(!_ranges.isEmpty)
        precondition(range.lowerBound <= _ranges.last!.upperBound)
        precondition(range.upperBound >= _ranges.first!.lowerBound)
        
        // The beginning index for the position of `range` is the first range
        // with an upper bound larger than `range`'s lower bound. The range
        // at this position may or may not overlap `range`.
        let beginningIndex = _ranges
            ._partitioningIndex { $0.upperBound >= range.lowerBound }
        
        // The ending index for `range` is the first range with a lower bound
        // greater than `range`'s upper bound. If this is the same as
        // `beginningIndex`, than `range` doesn't overlap any of the existing
        // ranges. If this is `ranges.endIndex`, then `range` overlaps the
        // rest of the ranges. Otherwise, `range` overlaps one or
        // more ranges in the set.
        let endingIndex = _ranges[beginningIndex...]
            ._partitioningIndex { $0.lowerBound > range.upperBound }

        return beginningIndex ..< endingIndex
    }
    
    /// Inserts a range that is known to be greater than all the elements in
    /// the set so far.
    ///
    /// - Precondition: The range set must be empty, or else
    ///   `ranges.last!.upperBound <= range.lowerBound`.
    internal mutating func _append(_ range: Range<Bound>) {
        precondition(_ranges.isEmpty || _ranges.last!.upperBound <= range.lowerBound)
        if _ranges.isEmpty { 
            _ranges.append(range)
        } else if _ranges.last!.upperBound == range.lowerBound {
            _ranges[_ranges.count - 1] = 
                _ranges[_ranges.count - 1].lowerBound ..< range.upperBound
        } else {
            _ranges.append(range)
        }
    }
    
    /// Adds the values represented by the given range to the range set.
    ///
    /// If `range` overlaps or adjoins any existing ranges in the set, the
    /// ranges are merged together. Empty ranges are ignored.
    ///
    ///     var set = RangeSet(0.0..<0.5, 1.0..<1.5)
    ///     set.insert(contentsOf: 0.25..<0.75)
    ///     // set == (0.0..<0.75, 1.0..<1.5)
    ///     set.insert(contentsOf: 2.0..<2.0)
    ///     // set == (0.0..<0.75, 1.0..<1.5)
    ///
    /// - Parameter range: The range to add to the set.
    ///
    /// - Complexity: O(*n*), where *n* is the number of ranges in the range
    ///   set.
    public mutating func insert(contentsOf range: Range<Bound>) {
        // Shortcuts for the (literal) edge cases
        if range.isEmpty { return }
        guard !_ranges.isEmpty else {
            _ranges.append(range)
            return
        }
        guard range.lowerBound < _ranges.last!.upperBound else {
            _append(range)
            return
        }
        guard range.upperBound >= _ranges.first!.lowerBound else {
            _ranges.insert(range, at: 0)
            return
        }
        
        let indices = _indicesOfRange(range)
        
        // Non-overlapping is a simple insertion.
        guard !indices.isEmpty else {
            _ranges.insert(range, at: indices.lowerBound)
            return
        }
        
        // Find the lower and upper bounds of the overlapping ranges.
        let newLowerBound = Swift.min(
            _ranges[indices.lowerBound].lowerBound,
            range.lowerBound)
        let newUpperBound = Swift.max(
            _ranges[indices.upperBound - 1].upperBound,
            range.upperBound)
        _ranges.replaceSubrange(
            indices,
            with: CollectionOfOne(newLowerBound..<newUpperBound))
    }
    
    /// Removes the given range of values from the range set.
    ///
    /// The values represented by `range` are removed from this set. This may
    /// result in one or more ranges being truncated or removed, depending on
    /// the overlap between `range` and the set's existing ranges.
    ///
    ///     var set = RangeSet(0.0..<0.5, 1.0..<1.5)
    ///     set.remove(contentsOf: 0.25..<1.25)
    ///     // set == (0.0..<0.25, 1.25..<1.5)
    ///
    /// Passing an empty range as `range` has no effect.
    ///
    ///     set.remove(contentsOf: 0.125..<0.125)
    ///     // set == (0.0..<0.25, 1.25..<1.5)
    ///
    /// - Parameter range: The range to remove from the set.
    ///
    /// - Complexity: O(*n*), where *n* is the number of ranges in the range
    ///   set.
    public mutating func remove(contentsOf range: Range<Bound>) {
        // Shortcuts for the (literal) edge cases
        if range.isEmpty
            || _ranges.isEmpty
            || range.lowerBound >= _ranges.last!.upperBound
            || range.upperBound < _ranges.first!.lowerBound
        { return }

        let indices = _indicesOfRange(range)
        
        // No actual overlap, nothing to remove.
        if indices.isEmpty { return }
        
        let overlapsLowerBound =
          range.lowerBound > _ranges[indices.lowerBound].lowerBound
        let overlapsUpperBound =
          range.upperBound < _ranges[indices.upperBound - 1].upperBound
        
        switch (overlapsLowerBound, overlapsUpperBound) {
        case (false, false):
            _ranges.removeSubrange(indices)
        case (false, true):
            let newRange =
              range.upperBound..<_ranges[indices.upperBound - 1].upperBound
            _ranges.replaceSubrange(indices, with: CollectionOfOne(newRange))
        case (true, false):
            let newRange =
              _ranges[indices.lowerBound].lowerBound..<range.lowerBound
            _ranges.replaceSubrange(indices, with: CollectionOfOne(newRange))
        case (true, true):
            _ranges.replaceSubrange(indices, with: Pair(
                _ranges[indices.lowerBound].lowerBound..<range.lowerBound,
                range.upperBound..<_ranges[indices.upperBound - 1].upperBound
            ))
        }
    }
}

extension RangeSet: Equatable {}

extension RangeSet: Hashable where Bound: Hashable {}

// MARK: - Range Collection

extension RangeSet {
    /// The ranges that make up a `RangeSet`.
    public struct Ranges: RandomAccessCollection {
        var _ranges: [Range<Bound>]
    
        public var startIndex: Int { _ranges.startIndex }
        public var endIndex: Int { _ranges.endIndex }
        
        public subscript(i: Int) -> Range<Bound> {
            _ranges[i]
        }
    }
    
    /// A collection of the ranges that make up the range set.
    public var ranges: Ranges {
        Ranges(_ranges: _ranges)
    }
}

// MARK: - Gaps

extension RangeSet {
    /// Returns a range set that represents the ranges of values within the
    /// given bounds that aren't represented by this range set.
    func _gaps(boundedBy bounds: Range<Bound>) -> RangeSet {
        guard let start = _ranges.firstIndex(where: { $0.lowerBound >= bounds.lowerBound })
            else { return RangeSet() }
        guard let end = _ranges.lastIndex(where: { $0.upperBound <= bounds.upperBound })
            else { return RangeSet() }
        
        var result = RangeSet()
        var low = bounds.lowerBound
        for range in _ranges[start...end] {
            result.insert(contentsOf: low..<range.lowerBound)
            low = range.upperBound
        }
        result.insert(contentsOf: low..<bounds.upperBound)
        return result
    }
}

// MARK: - SetAlgebra

// These methods only depend on the ranges that comprise the range set, so
// we can provide them even though we can't provide `SetAlgebra` conformance.
extension RangeSet {
    public mutating func formUnion(_ other: __owned RangeSet<Bound>) {
        for range in other._ranges {
            insert(contentsOf: range)
        }
    }

    public mutating func formIntersection(_ other: RangeSet<Bound>) {
        self = self.intersection(other)
    }

    public mutating func formSymmetricDifference(_ other: __owned RangeSet<Bound>) {
        self = self.symmetricDifference(other)
    }
    
    public mutating func subtract(_ other: RangeSet<Bound>) {
        for range in other._ranges {
            remove(contentsOf: range)
        }
    }

    public __consuming func union(_ other: __owned RangeSet<Bound>) -> RangeSet<Bound> {
        var result = self
        result.formUnion(other)
        return result
    }

    public __consuming func intersection(_ other: RangeSet<Bound>) -> RangeSet<Bound> {
        var otherRangeIndex = 0
        var result: [Range<Bound>] = []
        
        // Considering these two range sets:
        //
        //     self = [0..<5, 9..<14]
        //     other = [1..<3, 4..<6, 8..<12]
        //
        // `self.intersection(other)` looks like this, where x's cover the
        // ranges in `self`, y's cover the ranges in `other`, and z's cover the
        // resulting ranges:
        //
        //   0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
        //   xxxxxxxxxxxxxxxxxxx__               xxxxxxxxxxxxxxxxxxx__
        //       yyyyyyy__   yyyyyyy__       yyyyyyyyyyyyyyy__
        //       zzzzzzz__   zzz__               zzzzzzzzzzz__
        //
        // The same, but for `other.intersection(self)`:
        //
        //   0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
        //       xxxxxxx__   xxxxxxx__       xxxxxxxxxxxxxxx__
        //   yyyyyyyyyyyyyyyyyyy__               yyyyyyyyyyyyyyyyyyy__
        //       zzzzzzz__   zzz__               zzzzzzzzzzz__

        for currentRange in _ranges {
            // Search forward in `other` until finding either an overlapping
            // range or one that is strictly higher than this range.
            while otherRangeIndex < other._ranges.endIndex &&
                other._ranges[otherRangeIndex].upperBound <= currentRange.lowerBound
            {
                otherRangeIndex += 1
            }
            
            // For each range in `other` that overlaps with the current range
            // in `self`, append the intersection to the result.
            while otherRangeIndex < other._ranges.endIndex &&
                other._ranges[otherRangeIndex].lowerBound < currentRange.upperBound
            {
                result.append(
                    Swift.max(other._ranges[otherRangeIndex].lowerBound,
                          currentRange.lowerBound)
                        ..<
                    Swift.min(other._ranges[otherRangeIndex].upperBound, currentRange.upperBound)
                )
                
                // If the range in `other` continues past the current range in
                // `self`, it could overlap the next range in `self`, so break
                // out of examining the current range.
                guard currentRange.upperBound >
                        other._ranges[otherRangeIndex].upperBound else {
                    break
                }
                otherRangeIndex += 1
            }
        }
        
        return RangeSet(_ranges: result)
    }

    public __consuming func symmetricDifference(_ other: __owned RangeSet<Bound>) -> RangeSet<Bound> {
        return union(other).subtracting(intersection(other))
    }

    public func subtracting(_ other: RangeSet<Bound>) -> RangeSet<Bound> {
        var result = self
        result.subtract(other)
        return result
    }
    
    public func isSubset(of other: RangeSet<Bound>) -> Bool {
        self.intersection(other) == self
    }
    
    public func isSuperset(of other: RangeSet<Bound>) -> Bool {
        other.isSubset(of: self)
    }
    
    public func isStrictSubset(of other: RangeSet<Bound>) -> Bool {
        self != other && isSubset(of: other)
    }
    
    public func isStrictSuperset(of other: RangeSet<Bound>) -> Bool {
        other.isStrictSubset(of: self)
    }
}

extension RangeSet: CustomStringConvertible {
    public var description: String {
        let rangesDescription = _ranges
            .map { r in "\(r.lowerBound)..<\(r.upperBound)" }
            .joined(separator: ", ")
        return "RangeSet(\(rangesDescription))"
    }
}
