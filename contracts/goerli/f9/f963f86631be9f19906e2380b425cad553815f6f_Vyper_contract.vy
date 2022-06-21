# @version 0.3.3

@external
@pure
def uint2str(_value: uint256) -> String[78]:
    if _value == 0:
        return "0"
    value: uint256 = _value
    buffer: Bytes[78] = empty(Bytes[78])
    digits: uint256 = 78

    for i in range(78):
        if value == 0:
            digits = i
            break
        value /= 10
    value = _value
    for i in range(78):
        if value == 0:
            break
        digits -= 1
        char: Bytes[1] = slice(convert(value % 10 + 48, bytes32), 31, 1)
        buffer = slice(concat(char, buffer), 0, 78)
        value /= 10
    return convert(slice(buffer, 0, digits), String[78])