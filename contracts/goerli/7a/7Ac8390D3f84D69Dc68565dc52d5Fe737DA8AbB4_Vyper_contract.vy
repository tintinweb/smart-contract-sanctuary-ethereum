# @version ^0.3.0

@external
@view
def verify_message(_hashedMessage: bytes32,
                   _signature: Bytes[65]) -> address:

    # Arguments:
    # _hashedMessage is the hashed message signed by the user
    # _signature is the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    # The required prefix for ethereum signed messages.
    # The `32` is the number of bytes in the hashed message.
    prefix: Bytes[28] = b'\x19Ethereum Signed Message:\n32'

    # Concatenate them together since the prefix is required.
    prefixedHashedMessage: bytes32 = keccak256(concat(prefix, _hashedMessage))

    # Split the signature into the r, s, and v components
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    # Return if the signer's address matches the caller's address
    # https://vyper.readthedocs.io/en/stable/built-in-functions.html#ecrecover
    # return ecrecover(prefixedHashedMessage, v, r, s) == msg.sender
    return ecrecover(prefixedHashedMessage, v, r, s)

@external
@view
def verify_message2(_hashedMessage: bytes32,
                   _signature: Bytes[65]) -> address:

    # Arguments:
    # _hashedMessage is the hashed message signed by the user
    # _signature is the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    # Concatenate them together since the prefix is required.
    prefixedHashedMessage: bytes32 = keccak256(_hashedMessage)

    # Split the signature into the r, s, and v components
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    # Return if the signer's address matches the caller's address
    # https://vyper.readthedocs.io/en/stable/built-in-functions.html#ecrecover
    return ecrecover(prefixedHashedMessage, v, r, s)

@external
@view
def verify_message3(_hashedMessage: bytes32,
                   _signature: Bytes[65]) -> address:

    # Arguments:
    # _hashedMessage is the hashed message signed by the user
    # _signature is the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    # Split the signature into the r, s, and v components
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    # Return if the signer's address matches the caller's address
    # https://vyper.readthedocs.io/en/stable/built-in-functions.html#ecrecover
    return ecrecover(_hashedMessage, v, r, s)