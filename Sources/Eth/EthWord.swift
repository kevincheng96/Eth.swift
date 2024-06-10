import BigInt
import Foundation

/// A 256-bit word used in Ethereum operations, represented by 32 bytes of data.
public struct EthWord: Codable, Equatable, Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
    let data: Data

    /// Initializes an `EthWord` with a 32-byte data.
    /// - Parameter data: The data to initialize the `EthWord` with.
    /// - Returns: An optional `EthWord` instance, or `nil` if the data is not 32 bytes long.
    public init?(_ data: Data) {
        guard data.count == 32 else {
            return nil
        }
        self.data = data
    }

    /// Initializes an `EthWord` with a hexadecimal string.
    /// - Parameter hex: The hexadecimal string to initialize the `EthWord` with.
    /// - Returns: An optional `EthWord` instance, or `nil` if the string cannot be parsed or is not 32 bytes long.
    public init?(hex: String) {
        guard let data = Hex.parseHex(hex) else {
            return nil
        }
        self.init(data)
    }

    /// Initializes an `EthWord` by extending data with padding to 32 bytes.
    /// - Parameters:
    ///   - data: The data to extend.
    ///   - paddingValue: The value to pad the data with (default is 0).
    /// - Returns: An optional `EthWord` instance, or `nil` if the data is longer than 32 bytes.
    public init?(dataExtending data: Data, withPadding paddingValue: UInt8 = 0) {
        let paddingSize = 32 - data.count
        guard paddingSize >= 0 else {
            return nil
        }
        let padding = Data(repeating: paddingValue, count: paddingSize)
        self.init(padding + data)
    }

    /// Initializes an `EthWord` by extending a hexadecimal string with padding to 32 bytes.
    /// - Parameter hex: The hexadecimal string to extend.
    /// - Returns: An optional `EthWord` instance, or `nil` if the string cannot be parsed or the resulting data is longer than 32 bytes.
    public init?(hexExtending hex: String) {
        guard let data = Hex.parseHex(hex) else {
            return nil
        }
        self.init(dataExtending: data)
    }

    /// Initializes an `EthWord` from a `BigUInt` value.
    /// - Parameter value: The `BigUInt` value to convert.
    /// - Returns: An optional `EthWord` instance, or `nil` if the conversion fails.
    public init?(fromBigUInt value: BigUInt) {
        self.init(dataExtending: value.serialize())
    }

    /// Initializes an `EthWord` from a `BigInt` value.
    /// - Parameter value: The `BigInt` value to convert.
    /// - Returns: An optional `EthWord` instance, or `nil` if the conversion fails.
    public init?(fromBigInt value: BigInt) {
        var data: Data

        if value.sign == .plus {
            data = value.serialize().dropFirst(1)
            if data.count == 32, let msb = data.first, msb & 0x80 != 0 {
                // Positive signed value overflow
                return nil
            }
        } else {
            // Calculate the two's complement for negative values
            var serialized = (-(value + 1)).serialize().dropFirst(1)
            serialized = Data(serialized.map { ~$0 })
            data = serialized
        }

        self.init(dataExtending: data, withPadding: value.sign == .plus ? 0x00 : 0xFF)
    }

    /// Initializes an `EthWord` from an `Int` value.
    /// - Parameter value: The `Int` value to convert.
    /// - Returns: An optional `EthWord` instance, or `nil` if the conversion fails.
    public init?(fromInt value: Int) {
        self.init(fromBigInt: BigInt(value))
    }

    /// Initializes an `EthWord` from a `UInt` value.
    /// - Parameter value: The `UInt` value to convert.
    /// - Returns: An optional `EthWord` instance, or `nil` if the conversion fails.
    public init?(fromUInt value: UInt) {
        self.init(fromBigInt: BigInt(value))
    }

    /// Initializes an `EthWord` from a `UInt8` value.
    /// - Parameter value: The `UInt8` value to convert.
    /// - Returns: An optional `EthWord` instance, or `nil` if the conversion fails.
    public init?(fromUInt8 value: UInt8) {
        self.init(fromBigInt: BigInt(value))
    }

    /// Initializes an `EthWord` from a string literal.
    /// - Parameter value: The string literal to convert.
    /// - Returns: An `EthWord` instance, or triggers a runtime error if the string is invalid.
    public init(stringLiteral value: StringLiteralType) {
        guard let data = Hex.parseHex(value), data.count == 32 else {
            fatalError("Invalid Ethereum Word: \(value)")
        }
        self.data = data
    }

    /// A string representation of the `EthWord`.
    public var description: String {
        "EthWord[\(Hex.toShortHex(data))]"
    }

    /// Converts the `EthWord` to a `BigUInt`.
    /// - Returns: A `BigUInt` representing the `EthWord`.
    public func toBigUInt() -> BigUInt {
        return BigUInt(data)
    }

    private static let maxInt256 = BigInt(1) << 256

    private func bitwise(_ fn: (UInt8) -> UInt8) -> Data {
        var result = Data(count: 32)
        for i in 0 ..< 32 {
            result[i] = fn(data[i])
        }
        return result
    }

    /// Converts the `EthWord` to a `BigInt`.
    /// - Returns: A `BigInt` representing the `EthWord`.
    public func toBigInt() -> BigInt {
        // Convert EthWord number to a BigInt
        // As EthWords are stored as two's complement, we will
        // need to convert this to a form that BigInt recognizes,
        // which is [sign_byte, ...bytes]
        if data[0] & 0x80 != 0 {
            // Negative number handling
            // Create an inverted copy of the data
            var invertedData = Data(count: 32)
            for i in 0 ..< 32 {
                invertedData[i] = ~data[i]
            }

            // Convert the inverted data to a BigInt and add 1 to get the positive equivalent
            var positiveValue = BigInt(Data([0]) + invertedData) + 1

            // Negate the value to get the original negative number
            positiveValue = -positiveValue

            return positiveValue
        } else {
            return BigInt(Data([0x00]) + data)
        }
    }

    /// Converts the `EthWord` to an `Int`, if possible.
    /// - Returns: An optional `Int` representing the `EthWord`, or `nil` if the value exceeds `Int.max`.
    public func toInt() -> Int? {
        let bigInt = toBigUInt()
        if bigInt <= BigUInt(Int.max) {
            return Int(bigInt)
        } else {
            return nil
        }
    }
}
