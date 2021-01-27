# Rename subranges(where:/of:)

* Proposal: [SE-0000](0000-rename-subranges.md)
* Authors: [Nate Cook](https://github.com/natecook1000)
* Review Manager: TBD
* Status: **Awaiting implementation**

## Introduction

Rename the `subranges(where:)` and `subranges(of:)` collection methods, added as part of [SE-0270][], to be `indices(where:)` and `indices(of:)`.

## Motivation

Though approved and implemented at the beginning of last year, the new APIs in SE-0270 have yet to land in a shipping version of Swift, due to  concerns about naming. In particular, we've had questions about whether `subranges` is the appropriate name for the methods that find all instances of a particular element, or all elements that match a given predicate.

In the interim, we've launched the [Algorithms package][] and continued exploration of searching within collections. This research has pointed out out a distinction between the methods in SE-0270, which return a value that represents all matching indices, and searching algorithms, which, depending on the design, can return the matched subsequences of a collection or the ranges of those matches. That is to say, the *unit* of the returned values differ: the SE-0270 methods return indices, while subsequence searching methods return ranges.

This distinction points to a need for a better name for the existing `subranges(where:)` and `subranges(of:)` methods, to make room for future collection searching operations.

## Proposed solution

The two methods in questions will be renamed to `indices(where:)` and `indices(of:)`. In addition to solving the problem described above, this brings these methods inline with their documentation, which describes the methods as returning the indices of the matching elements.

## Detailed design

The new versions of these two methods are as follows:

```swift
extension Collection {
  /// Returns the indices of all the elements that match the given predicate.
  ///
  /// For example, you can use this method to find all the places that a
  /// vowel occurs in a string.
  ///
  ///     let str = "Fresh cheese in a breeze"
  ///     let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
  ///     let allTheVowels = str.indices(where: { vowels.contains($0) })
  ///     // str[allTheVowels].count == 9
  ///
  /// - Parameter predicate: A closure that takes an element as its argument
  ///   and returns a Boolean value that indicates whether the passed element
  ///   represents a match.
  /// - Returns: A set of the indices of the elements for which `predicate`
  ///   returns `true`.
  ///
  /// - Complexity: O(*n*), where *n* is the length of the collection.
  public func indices(where predicate: (Element) throws -> Bool) rethrows
    -> RangeSet<Index>
}

extension Collection where Element: Equatable {
  /// Returns the indices of all the elements that are equal to the given
  /// element.
  ///
  /// For example, you can use this method to find all the places that a
  /// particular letter occurs in a string.
  ///
  ///     let str = "Fresh cheese in a breeze"
  ///     let allTheEs = str.indices(of: "e")
  ///     // str[allTheEs].count == 7
  ///
  /// - Parameter element: An element to look for in the collection.
  /// - Returns: A set of the indices of the elements that are equal to
  ///   `element`.
  ///
  /// - Complexity: O(*n*), where *n* is the length of the collection.
  public func indices(of element: Element) -> RangeSet<Index>
}
```

## Source compatibility

Because these methods have not shipped in a Swift release, this will have no source compatibility impact for code that relies only on the standard library. The [SE-0270 preview package][] will be updated to include the new names along with deprecated methods with the old names.

## Effect on ABI stability

The existing methods are not yet part of any Swift ABI. Once landed in a release, `indices(where:)` and `indices(of:)` will become part of the ABI.

## Effect on API resilience

The methods with new names will continue to have the same treatment as the rest of SE-0270's additions.

[SE-0270]: https://github.com/apple/swift-evolution/blob/main/proposals/0270-rangeset-and-collection-operations.md
[Algorithms package]: https://github.com/apple/swift-algorithms
[SE-0270 preview package]: https://github.com/apple/swift-se0270-range-set/