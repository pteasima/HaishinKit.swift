import Foundation

protocol HTTPRequestCompatible: BytesConvertible, CustomStringConvertible {
    var uri:String { get set }
    var method:String { get set }
    var version:String { get set }
    var headerFields:[String: String] { get set }
    var body:Data? { get set }
}

extension HTTPRequestCompatible {

    public var description:String {
        return Mirror(reflecting: self).description
    }

    var bytes:[UInt8] {
        get {
            var lines:[String] = ["\(method) \(uri) \(version)"]
            for (field, value) in headerFields {
                lines.append("\(field): \(value)")
            }
            lines.append("\r\n")
            return [UInt8](lines.joined(separator: "\r\n").utf8)
        }
        set {
            var lines:[String] = []
            let bytes:[ArraySlice<UInt8>] = newValue.split(separator: HTTPRequest.separator)
            for i in 0..<bytes.count {
                guard let line:String = String(bytes: Array<UInt8>(bytes[i]), encoding: .utf8) else {
                    continue
                }
                let newLine:String = line.trimmingCharacters(in: .newlines)
                if newLine == "" {
                    body = Data(bytes[i+1..<bytes.count].joined(separator: [HTTPRequest.separator]))
                    break
                }
                lines.append(newLine)
            }

            guard let first:[String] = lines.first?.components(separatedBy: " "), first.count >= 3 else {
                return
            }
            
            method = first[0]
            uri = first[1]
            version = first[2]
            for i in 1..<lines.count {
                if (lines[i].isEmpty) {
                    continue
                }
                let pairs:[String] = lines[i].components(separatedBy: ": ")
                headerFields[pairs[0]] = pairs[1]
            }
        }
    }
}

// MARK: -
public struct HTTPRequest: HTTPRequestCompatible {
    public static let separator:UInt8 = 0x0a

    public var uri:String = "/"
    public var method:String = ""
    public var version:String = HTTPVersion.version11.description
    public var headerFields:[String: String] = [:]
    public var body:Data?

    init?(bytes:[UInt8]) {
        self.bytes = bytes
    }
}
