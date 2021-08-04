import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(GeoJSONCodableTest.allTests),
    testCase(GeoJSONParserTest.allTests),
  ]
}
#endif
