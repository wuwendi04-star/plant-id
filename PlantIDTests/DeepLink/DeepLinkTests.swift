import Testing
import Foundation
@testable import PlantID

@Suite("Deep Link URL Parsing Tests")
struct DeepLinkTests {

    @Test("plantid://plant/{UUID} scheme is recognized")
    func testPlantSchemeRecognized() {
        let uuid = UUID()
        let url = URL(string: "plantid://plant/\(uuid.uuidString)")!
        #expect(url.scheme == "plantid")
        #expect(url.host == "plant")
    }

    @Test("plantid://plant/{UUID} last path component parses to UUID")
    func testPlantUUIDParsed() {
        let uuid = UUID()
        let url = URL(string: "plantid://plant/\(uuid.uuidString)")!
        #expect(UUID(uuidString: url.lastPathComponent) == uuid)
    }

    @Test("plantid://nfc/{tagId} scheme is recognized")
    func testNfcSchemeRecognized() {
        let url = URL(string: "plantid://nfc/ABCDEF12")!
        #expect(url.scheme == "plantid")
        #expect(url.host == "nfc")
        #expect(url.lastPathComponent == "ABCDEF12")
    }

    @Test("Malformed UUID yields nil when parsed")
    func testMalformedUUIDIsNil() {
        let url = URL(string: "plantid://plant/not-a-valid-uuid")!
        #expect(UUID(uuidString: url.lastPathComponent) == nil)
    }

    @Test("Valid hex tag ID passes regex validation")
    func testValidHexTagId() {
        let valid = "ABCDEF12"
        let result = valid.range(of: "^[0-9A-Fa-f]{8,32}$", options: .regularExpression)
        #expect(result != nil)
    }

    @Test("Short hex tag ID (less than 8 chars) fails regex")
    func testShortHexTagIdFails() {
        let tooShort = "ABCD"
        let result = tooShort.range(of: "^[0-9A-Fa-f]{8,32}$", options: .regularExpression)
        #expect(result == nil)
    }

    @Test("Non-hex tag ID fails regex validation")
    func testNonHexTagIdFails() {
        let invalid = "ZZ../etc/passwd"
        let result = invalid.range(of: "^[0-9A-Fa-f]{8,32}$", options: .regularExpression)
        #expect(result == nil)
    }

    @Test("plantid://plant URL round-trips correctly")
    func testPlantURLRoundTrip() {
        let uuid = UUID()
        let urlString = "plantid://plant/\(uuid.uuidString)"
        let url = URL(string: urlString)!
        let parsed = UUID(uuidString: url.lastPathComponent)
        #expect(parsed == uuid)
    }

    @Test("Unknown host is ignored gracefully")
    func testUnknownHostReturnsNoMatch() {
        let url = URL(string: "plantid://unknown/somevalue")!
        let isPlant = url.host == "plant"
        let isNfc = url.host == "nfc"
        #expect(!isPlant)
        #expect(!isNfc)
    }
}
