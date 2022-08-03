# @version ^0.3.4

interface RollupProcessor:
    def depositPendingFunds(assetId: uint256, amount: uint256, owner: address, proofHash: bytes32): payable

from vyper.interfaces import ERC20

ROLLUP: constant(address) = 0xFF1F2B4ADb9dF6FC8eAFecDcbF96A2B351680455
owner: public(address)

@external 
def __init__(owner: address):
    self.owner = owner

@external
@payable
def __default__():
    assert msg.value > 0
    RollupProcessor(ROLLUP).depositPendingFunds(
        0,
        msg.value,
        msg.sender,
        empty(bytes32),
        value = msg.value
    )

@external
def gib(asset: address):
    assert self.owner == msg.sender, "Not owner"
    tokenBalance: uint256 = ERC20(asset).balanceOf(self)
    ERC20(asset).transfer(msg.sender, tokenBalance, default_return_value=True)