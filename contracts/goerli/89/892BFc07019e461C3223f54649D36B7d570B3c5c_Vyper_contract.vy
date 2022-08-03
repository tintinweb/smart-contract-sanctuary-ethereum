# @version 0.3.3

event ValidatorAdded:
    addingWallet: indexed(address)
    value: address


@internal
@view
def verify_message(_prefixedHashedMessage: bytes32,
                   _signature: Bytes[65]) -> address:

    # Arguments:
    # _prefixedHashedMessage: the hashed message signed by the user, which includes the prefix
    # _signature: the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    # Split the signature into the r, s, and v components
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    # Return if the signer's address matches the caller's address
    # https://vyper.readthedocs.io/en/stable/built-in-functions.html#ecrecover
    # return ecrecover(prefixedHashedMessage, v, r, s) == msg.sender
    return ecrecover(_prefixedHashedMessage, v, r, s)


@external
@view
def derp(_validatorKey: address,
         _prefixedHashedMessage: bytes32,
         _signature: Bytes[65]) -> bool:

    result: bool = self.verify_message(_prefixedHashedMessage, _signature) == _validatorKey
    if result:
        log ValidatorAdded(msg.sender, _validatorKey)
    return result