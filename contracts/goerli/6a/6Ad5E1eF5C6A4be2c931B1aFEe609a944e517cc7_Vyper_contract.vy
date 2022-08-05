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
    initCode: bytes32
    callData: bytes32
    callGas: uint256
    verificationGas: uint256
    preVerificationGas: uint256
    maxFeePerGas: uint256
    maxPriorityFeePerGas: uint256
    paymaster: address
    paymasterData: bytes32
    signature: bytes32


@external
def handleOps(ops: UserOperation[10], redeemer: address) :
    pass