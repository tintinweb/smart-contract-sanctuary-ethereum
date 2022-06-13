# @version 0.3.3
"""
@title YFI Buyer
@license MIT
@author banteg
@notice
    Buy YFI for DAI at the current Chainlink price.

    New in v0.2.0
    - Accept and release a LlamaPay stream on buy
"""
from vyper.interfaces import ERC20

YFI: constant(address) = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e
DAI: constant(address) = 0x6B175474E89094C44Da98b954EedeAC495271d0F
YFI_USD: constant(address) = 0xA027702dbb89fbd58938e4324ac03B58d812b0E1
LLAMAPAY: constant(address) = 0x60c7B0c5B3a4Dc8C690b074727a17fF7aA287Ff2

STALE_AFTER: constant(uint256) = 3600

admin: public(address)
treasury: public(address)
rate: public(uint216)

struct ChainlinkRound:
    roundId: uint80
    answer: int256
    startedAt: uint256
    updatedAt: uint256
    answeredInRound: uint80

interface Chainlink:
    def latestRoundData() -> ChainlinkRound: view

struct Withdrawable:
    amount: uint256
    last_update: uint256
    owed: uint256

interface LlamaPay:
    def withdraw(source: address, target: address, rate: uint216): nonpayable
    def withdrawable(source: address, target: address, rate: uint216) -> Withdrawable: view

event Buyback:
    buyer: indexed(address)
    yfi: uint256
    dai: uint256

event UpdateAdmin:
    admin: indexed(address)

event UpdateTreasury:
    treasury: indexed(address)

event UpdateRate:
    rate: indexed(uint216)


@external
def __init__():
    self.admin = msg.sender
    self.treasury = msg.sender
    
    log UpdateAdmin(msg.sender)
    log UpdateTreasury(msg.sender)


@view
@internal
def withdrawable() -> uint256:
    if self.rate != 0:
        return LlamaPay(LLAMAPAY).withdrawable(self.admin, self, self.rate).amount
    return 0


@external
def buy_dai(yfi_amount: uint256):
    oracle: ChainlinkRound = Chainlink(YFI_USD).latestRoundData()
    assert oracle.updatedAt + STALE_AFTER > block.timestamp  # dev: stale oracle

    if self.rate != 0:
        LlamaPay(LLAMAPAY).withdraw(self.admin, self, self.rate)

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
def total_dai() -> uint256:
    return ERC20(DAI).balanceOf(self) + self.withdrawable()


@view
@external
def max_amount() -> uint256:
    oracle: ChainlinkRound = Chainlink(YFI_USD).latestRoundData()
    amount: uint256 = ERC20(DAI).balanceOf(self) + self.withdrawable()
    return amount / convert(oracle.answer, uint256) * 10 ** 8


@external
def sweep(token: address, amount: uint256 = MAX_UINT256):
    assert msg.sender == self.admin
    value: uint256 = amount
    if value == MAX_UINT256:
        value = ERC20(token).balanceOf(self)
    
    assert ERC20(token).transfer(self.admin, value)


@external
def set_admin(proposed_admin: address):
    assert msg.sender == self.admin
    self.admin = proposed_admin

    log UpdateAdmin(proposed_admin)


@external
def set_treasury(new_treasury: address):
    assert msg.sender == self.admin
    self.treasury = new_treasury

    log UpdateTreasury(new_treasury)


@external
def set_rate(new_rate: uint216):
    assert msg.sender == self.admin
    self.rate = new_rate

    log UpdateRate(new_rate)