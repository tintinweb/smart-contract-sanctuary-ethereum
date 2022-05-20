# @version 0.3.3

@external
@pure
def encode(payload: Bytes[64]) -> Bytes[64]:
    return concat(slice(payload, 0, 32), convert(100, bytes32))