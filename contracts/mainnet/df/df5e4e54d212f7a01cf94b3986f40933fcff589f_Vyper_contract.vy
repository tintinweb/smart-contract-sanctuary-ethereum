# @version 0.3.3
"""
@title YFI Buyer
@license MIT
@author banteg
@notice
    This contract buys YFI for DAI at the current Chainlink price.
"""
from vyper.interfaces import ERC20

YFI: constant(address) = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e
DAI: constant(address) = 0x6B175474E89094C44Da98b954EedeAC495271d0F
YFI_USD: constant(address) = 0xA027702dbb89fbd58938e4324ac03B58d812b0E1

STALE_AFTER: constant(uint256) = 3600

admin: public(address)
pending_admin: public(address)
treasury: public(address)

struct ChainlinkRound:
    roundId: uint80
    answer: int256
    startedAt: uint256
    updatedAt: uint256
    answeredInRound: uint80

interface Chainlink:
    def latestRoundData() -> ChainlinkRound: view

event Buyback:
    buyer: indexed(address)
    yfi: uint256
    dai: uint256

event ProposeAdmin:
    pending_admin: indexed(address)

event UpdateAdmin:
    admin: indexed(address)

event UpdateTreasury:
    treasury: indexed(address)


@external
def __init__():
    self.admin = msg.sender
    self.treasury = msg.sender
    
    log UpdateAdmin(msg.sender)
    log UpdateTreasury(msg.sender)


@external
def buy_dai(yfi_amount: uint256):
    oracle: ChainlinkRound = Chainlink(YFI_USD).latestRoundData()
    assert oracle.updatedAt + STALE_AFTER > block.timestamp  # dev: stale oracle

    dai_amount: uint256 = convert(oracle.answer, uint256) * yfi_amount / 10 ** 8

    assert ERC20(YFI).transferFrom(msg.sender, self.treasury, yfi_amount)  # dev: no allowance
    assert ERC20(DAI).transfer(msg.sender, dai_amount)  # dev: not enough dai

    log Buyback(msg.sender, yfi_amount, dai_amount)


@view
@external
def price() -> uint256:
    oracle: ChainlinkRound = Chainlink(YFI_USD).latestRoundData()
    return convert(oracle.answer, uint256) * 10 ** 10


@view
@external
def max_amount() -> uint256:
    oracle: ChainlinkRound = Chainlink(YFI_USD).latestRoundData()
    return ERC20(DAI).balanceOf(self) / convert(oracle.answer, uint256) * 10 ** 8


@external
def sweep(token: address, amount: uint256 = MAX_UINT256):
    assert msg.sender == self.admin
    
    value: uint256 = amount
    if value == MAX_UINT256:
        value = ERC20(token).balanceOf(self)
    
    ERC20(token).transfer(self.admin, value)


@external
def propose_admin(proposed_admin: address):
    assert msg.sender == self.admin
    self.pending_admin = proposed_admin

    log ProposeAdmin(proposed_admin)


@external
def accept_admin():
    assert msg.sender == self.pending_admin
    self.admin = msg.sender
    self.pending_admin = ZERO_ADDRESS

    log UpdateAdmin(msg.sender)


@external
def set_treasury(new_treasury: address):
    assert msg.sender == self.admin
    self.treasury = new_treasury

    log UpdateTreasury(new_treasury)