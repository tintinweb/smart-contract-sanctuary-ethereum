# @version 0.3.3

"""
@title EntryPoint Contract
@license MIT
@author Candide Wallet Team
@notice EntryPoint comtract

"""

struct UserOperation:
    sender: address
    nonce: uint256
    initCode: Bytes[25000]
    callData: Bytes[25000]
    callGas: uint256
    verificationGas: uint256
    preVerificationGas: uint256
    maxFeePerGas: uint256
    maxPriorityFeePerGas: uint256
    paymaster: address
    paymasterData: Bytes[25000]
    signature: Bytes[25000]

struct UserOperations:
    userOperations: UserOperation[10]

@external
def handleOps(ops: UserOperations, redeemer: address) :
    pass