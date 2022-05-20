# @version 0.3.3

@external
@pure
def encode(payload: Bytes[64]) -> Bytes[64]:
    return slice(concat(payload, convert(100, bytes32)), 0, 64)