# @version ^0.3.0

# @external
# @pure
# def wut(_ethSignedHash: bytes32, _signature: bytes32) -> address:
#     r: uint256 = convert(slice(_signature, 0, 32), uint256)
#     s: uint256 = convert(slice(_signature, 32, 32), uint256)
#     v: uint256 = convert(slice(_signature, 64, 1), uint256)
#     return ecrecover(_ethSignedHash, v, r, s)

@external
@pure
def getHash(_str: String[100]) -> bytes32:
    return keccak256(_str)

@external
@pure
def getEthSignedHash(_hash: bytes32) -> bytes32:
    return keccak256(
        concat(
            b'\x19Ethereum Signed Message:\n32',
            _hash
        )
    )

@external
@pure
def verify(_ethSignedHash: bytes32, _sig: Bytes[65]) -> address:
    r: uint256 = convert(slice(_sig, 0, 32), uint256)
    s: uint256 = convert(slice(_sig, 32, 32), uint256)
    v: uint256 = convert(slice(_sig, 64, 1), uint256)
    return ecrecover(_ethSignedHash, v, r, s)

@external
@view
def verify_message(_hashedMessage: bytes32,
                    _r: bytes32,
                    _s: bytes32,
                    _v: uint256) -> address:
    prefix: Bytes[28] = b'\x19Ethereum Signed Message:\n32'
    prefixedHashedMessage: bytes32 = keccak256(concat(prefix, _hashedMessage))
    return ecrecover(prefixedHashedMessage,
                     _v,
                     convert(_r, uint256),
                     convert(_s, uint256))