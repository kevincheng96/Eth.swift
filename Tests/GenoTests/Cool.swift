import BigInt
import Eth
import Foundation

enum Cool {
    static let creationCode: Hex = "0x608060405234801561001057600080fd5b5060d88061001f6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063cad0899b14602d575b600080fd5b603c60383660046061565b604e565b60405190815260200160405180910390f35b6000605882846082565b90505b92915050565b60008060408385031215607357600080fd5b50508035926020909101359150565b80820180821115605b57634e487b7160e01b600052601160045260246000fdfea264697066735822122009bb58f13fe00f9a4823e324313255ba6da63085111762970486bc5b48658cfe64736f6c63430008180033"
    static let runtimeCode: Hex = "0x6080604052348015600f57600080fd5b506004361060285760003560e01c8063cad0899b14602d575b600080fd5b603c60383660046061565b604e565b60405190815260200160405180910390f35b6000605882846082565b90505b92915050565b60008060408385031215607357600080fd5b50508035926020909101359150565b80820180821115605b57634e487b7160e01b600052601160045260246000fdfea264697066735822122009bb58f13fe00f9a4823e324313255ba6da63085111762970486bc5b48658cfe64736f6c63430008180033"

    static let sumFn = ABI.Function(
        name: "sum",
        inputs: [.uint256, .uint256],
        outputs: [.uint256]
    )

    static let someErrFn = ABI.Function(
        name: "someErr",
        inputs: [.uint256],
        outputs: []
    )

    static let errors: [ABI.Function] = [someErrFn]

    static func sum(x: BigUInt, y: BigUInt) throws -> BigUInt {
        let query = try sumFn.encoded(with: [.uint256(x), .uint256(y)])
        let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors)
        let decoded = try sumFn.decode(output: result)

        switch decoded {
        case let .tuple1(.uint256(var0)):
            return var0
        default:
            throw ABI.DecodeError.mismatchedType(decoded.schema, sumFn.outputTuple)
        }
    }
}
