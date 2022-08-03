# @version 0.3.3

# A map of {operatorPublicKey:beneficiaryWallet}
operators: HashMap[address, address]


# Fire whenever we have a good operator to add
event OperatorAdded:
    operatorPublicKey: indexed(address)
    beneficiaryWallet: indexed(address)


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
@nonpayable
def add_operator(operatorPublicKey: address,
                 operatorSignedMessage: bytes32,
                 operatorSignature: Bytes[65]) -> (bool, address):

    result: bool = self.verify_message(operatorSignedMessage, operatorSignature) == operatorPublicKey
    if result:
        # Revert the transaction if someone has already added the operator.
        # assert operatorPublicKey not in self.operators, "Operator previously added. Please remove using "
        # "the original beneficiary wallet."

        # self.operators[operatorPublicKey] = msg.sender
        log OperatorAdded(msg.sender, operatorPublicKey)
    return result, self.operators[operatorPublicKey]