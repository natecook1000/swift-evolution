import XCTest
import Prototype_RangeSet
import TestHelpers

let letterString = "ABCdefGHIjklMNOpqrStUvWxyz"
let lowercaseLetters = letterString.filter { $0.isLowercase }
let uppercaseLetters = letterString.filter { $0.isUppercase }

extension Collection {
    func every(_ n: Int) -> [Element] {
        sequence(first: startIndex) { i in
            self.index(i, offsetBy: n, limitedBy: self.endIndex)
        }.map { self[$0] }
    }
}

final class CollectionExtensionsTests: XCTestCase {
    func testIndicesWhere() {
        let a = [1, 2, 3, 4, 3, 3, 4, 5, 3, 4, 3, 3, 3]
        let indices = a.ranges(of: 3)
        XCTAssertEqual(indices, RangeSet([2..<3, 4..<6, 8..<9, 10..<13]))
        
        let allTheThrees = a[indices]
        XCTAssertEqual(allTheThrees.count, 7)
        XCTAssertTrue(allTheThrees.allSatisfy { $0 == 3 })
        XCTAssertEqual(Array(allTheThrees), Array(repeating: 3, count: 7))
        
        let lowerIndices = letterString.ranges(where: { $0.isLowercase })
        let lowerOnly = letterString[lowerIndices]
        XCTAssertEqual(lowerOnly, lowercaseLetters)
        XCTAssertEqual(lowerOnly.reversed(), lowercaseLetters.reversed())
        
        let upperOnly = letterString.removingAll(at: lowerIndices)
        XCTAssertEqual(upperOnly, uppercaseLetters)
        XCTAssertEqual(upperOnly.reversed(), uppercaseLetters.reversed())
    }
    
    func testRemoveAllRangeSet() {
        var a = [1, 2, 3, 4, 3, 3, 4, 5, 3, 4, 3, 3, 3]
        let indices = a.ranges(of: 3)
        a.removeAll(at: indices)
        XCTAssertEqual(a, [1, 2, 4, 4, 5, 4])

        var numbers = Array(1...20)
        numbers.removeAll(at: RangeSet([2..<5, 10..<15, 18..<20]))
        XCTAssertEqual(numbers, [1, 2, 6, 7, 8, 9, 10, 16, 17, 18])
        
        var str = letterString
        let lowerIndices = str.ranges(where: { $0.isLowercase })
        
        let upperOnly = str.removingAll(at: lowerIndices)
        XCTAssertEqual(upperOnly, uppercaseLetters)

        str.removeAll(at: lowerIndices)
        XCTAssertEqual(str, uppercaseLetters)
    }
    
    func testGatherRangeSet() {
        // Move before
        var numbers = Array(1...20)
        let range1 = numbers.gather(RangeSet([10..<15, 18..<20]), at: 4)
        XCTAssertEqual(range1, 4..<11)
        XCTAssertEqual(numbers, [
            1, 2, 3, 4,
            11, 12, 13, 14, 15,
            19, 20,
            5, 6, 7, 8, 9, 10, 16, 17, 18])
        
        // Move to start
        numbers = Array(1...20)
        let range2 = numbers.gather(RangeSet([10..<15, 18..<20]), at: 0)
        XCTAssertEqual(range2, 0..<7)
        XCTAssertEqual(numbers, [
            11, 12, 13, 14, 15,
            19, 20,
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 16, 17, 18])
        
        // Move to end
        numbers = Array(1...20)
        let range3 = numbers.gather(RangeSet([10..<15, 18..<20]), at: 20)
        XCTAssertEqual(range3, 13..<20)
        XCTAssertEqual(numbers, [
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 16, 17, 18,
            11, 12, 13, 14, 15,
            19, 20,
        ])
        
        // Move to middle of selected elements
        numbers = Array(1...20)
        let range4 = numbers.gather(RangeSet([10..<15, 18..<20]), at: 14)
        XCTAssertEqual(range4, 10..<17)
        XCTAssertEqual(numbers, [
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
            11, 12, 13, 14, 15,
            19, 20,
            16, 17, 18])

        // Move none
        numbers = Array(1...20)
        let range5 = numbers.gather(RangeSet(), at: 10)
        XCTAssertEqual(range5, 10..<10)
        XCTAssertEqual(numbers, Array(1...20))
    }
    
    func testGatherPredicate() {
        for length in 0..<11 {
            let initial = Array(0..<length)
            
            for destination in 0..<length {
                for modulus in 1...5 {
                    let f: (Int) -> Bool = { $0.isMultiple(of: modulus) }
                    let notf = { !f($0) }
                    
                    var array = initial
                    var range = array.gather(at: destination, where: f)
                    XCTAssertEqual(array[range], initial.filter(f))
                    XCTAssertEqual(
                        array[..<range.lowerBound] + array[range.upperBound...],
                        initial.filter(notf))

                    array = initial
                    range = array.gather(at: destination, where: notf)
                    XCTAssertEqual(array[range], initial.filter(notf))
                    XCTAssertEqual(
                        array[..<range.lowerBound] + array[range.upperBound...],
                        initial.filter(f))
                }
            }
        }
    }
    
    func testDiscontiguousSliceSlicing() {
        let initial = 1...100
        
        // Build an array of ranges that include alternating groups of 5 elements
        // e.g. 1...5, 11...15, etc
        let rangeStarts = initial.indices.every(10)
        let rangeEnds = rangeStarts.compactMap {
            initial.index($0, offsetBy: 5, limitedBy: initial.endIndex)
        }
        let ranges = zip(rangeStarts, rangeEnds).map(Range.init)
        
        // Create a collection of the elements represented by `ranges` without
        // using `RangeSet`
        let chosenElements = ranges.map { initial[$0] }.joined()
        
        let set = RangeSet(ranges)
        let discontiguousSlice = initial[set]
        XCTAssertEqual(discontiguousSlice, chosenElements)
        
        for (chosenIdx, disIdx) in zip(chosenElements.indices, discontiguousSlice.indices) {
            XCTAssertEqual(chosenElements[chosenIdx...], discontiguousSlice[disIdx...])
            XCTAssertEqual(chosenElements[..<chosenIdx], discontiguousSlice[..<disIdx])
            for (chosenUpper, disUpper) in
                zip(chosenElements.indices[chosenIdx...], discontiguousSlice.indices[disIdx...])
            {
                XCTAssertEqual(
                    chosenElements[chosenIdx..<chosenUpper],
                    discontiguousSlice[disIdx..<disUpper])
                XCTAssert(chosenElements[chosenIdx..<chosenUpper]
                    .elementsEqual(discontiguousSlice[disIdx..<disUpper]))
            }
        }
    }
    
    func testNoCopyOnWrite() {
        var numbers = COWLoggingArray(1...20)
        let copyCount = COWLoggingArray_CopyCount
        
        _ = numbers.gather(RangeSet([10..<15, 18..<20]), at: 4)
        XCTAssertEqual(copyCount, COWLoggingArray_CopyCount)

        numbers.removeAll(at: RangeSet([2..<5, 10..<15, 18..<20]))
        XCTAssertEqual(copyCount, COWLoggingArray_CopyCount)
    }
}
