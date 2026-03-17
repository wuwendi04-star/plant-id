import CoreNFC
import Observation

@Observable
final class NfcService: NSObject {
    var lastTagId: String? = nil
    var isScanning: Bool = false
    var error: String? = nil

    var isAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    private var session: NFCNDEFReaderSession?
    private var onTagScanned: ((String) -> Void)?
    private var writeUri: String? = nil

    func startScanning(onTagScanned: @escaping (String) -> Void) {
        guard isAvailable else {
            error = "NFC is not available on this device"
            return
        }
        self.onTagScanned = onTagScanned
        writeUri = nil
        session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near the NFC tag"
        session?.begin()
        isScanning = true
        error = nil
    }

    func startWriting(uri: String, onTagScanned: @escaping (String) -> Void) {
        guard isAvailable else { return }
        self.onTagScanned = onTagScanned
        self.writeUri = uri
        session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the NFC tag to bind it"
        session?.begin()
        isScanning = true
        error = nil
    }

    private func extractTagId(from tag: NFCNDEFTag) -> String? {
        switch tag {
        case let iso15693Tag as NFCISO15693Tag:
            return iso15693Tag.identifier.map { String(format: "%02X", $0) }.joined()
        case let iso7816Tag as NFCISO7816Tag:
            return iso7816Tag.identifier.map { String(format: "%02X", $0) }.joined()
        case let felicaTag as NFCFeliCaTag:
            return felicaTag.currentSystemCode.map { String(format: "%02X", $0) }.joined()
        case let mifareTag as NFCMiFareTag:
            return mifareTag.identifier.map { String(format: "%02X", $0) }.joined()
        default:
            return nil
        }
    }
}

extension NfcService: NFCNDEFReaderSessionDelegate {
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // handled in didDetect tags
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag found")
            return
        }

        session.connect(to: tag) { [weak self] connectError in
            guard let self else { return }
            if let connectError {
                session.invalidate(errorMessage: connectError.localizedDescription)
                return
            }

            guard let tagId = self.extractTagId(from: tag) else {
                session.invalidate(errorMessage: "Could not read tag ID")
                return
            }

            self.lastTagId = tagId

            if let uri = self.writeUri {
                let uriRecord = NFCNDEFPayload.wellKnownTypeURIPayload(
                    url: URL(string: "plantid://nfc/\(tagId)")!
                ) ?? NFCNDEFPayload(
                    format: .nfcWellKnown,
                    type: Data("U".utf8),
                    identifier: Data(),
                    payload: Data([0x00]) + Data(uri.utf8)
                )
                let message = NFCNDEFMessage(records: [uriRecord])
                tag.writeNDEF(message) { writeError in
                    if writeError != nil {
                        session.invalidate(errorMessage: "Failed to write to tag")
                    } else {
                        session.alertMessage = "Tag bound successfully!"
                        session.invalidate()
                        self.onTagScanned?(tagId)
                    }
                }
            } else {
                session.alertMessage = "Tag recognized!"
                session.invalidate()
                self.onTagScanned?(tagId)
            }
            self.isScanning = false
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        isScanning = false
        let nfcError = error as? NFCReaderError
        if nfcError?.code != .readerSessionInvalidationErrorFirstNDEFTagRead &&
           nfcError?.code != .readerSessionInvalidationErrorUserCanceled {
            self.error = error.localizedDescription
        }
    }
}
