# @version ^0.3.7

MAX_DATA: constant(uint256) = 2**13

interface RocketStorageInterface:
  def getAddress(_key: bytes32) -> address: view

interface RocketDepositPoolInterface:
  def deposit(): payable

interface FlashLoanInterface:
  def flashLoan(receiver: address, token: address, amount: uint256, data: Bytes[MAX_DATA]) -> bool: nonpayable

interface WethInterface:
  def approve(_spender: address, _amount: uint256) -> bool: nonpayable
  def balanceOf(_who: address) -> uint256: view
  def deposit(): payable
  def withdraw(_wad: uint256): nonpayable

interface RethInterface:
  def approve(_spender: address, _amount: uint256) -> bool: nonpayable
  def balanceOf(_who: address) -> uint256: view
  def transfer(_to: address, _wad: uint256) -> bool: nonpayable

interface RocketDepositArbitrageInterface:
  def drain(): nonpayable

rocketStorage: immutable(RocketStorageInterface)
rethToken: immutable(RethInterface)
wethToken: immutable(WethInterface)
flashLender: immutable(FlashLoanInterface)
swapRouter: immutable(address)
owner: public(address)

@external
def __init__(flashLenderAddress: address, rocketStorageAddress: address, swapRouterAddress: address, wethAddress: address):
  self.owner = msg.sender
  rocketStorage = RocketStorageInterface(rocketStorageAddress)
  rethAddress: address = rocketStorage.getAddress(keccak256("contract.addressrocketTokenRETH"))
  rethToken = RethInterface(rethAddress)
  wethToken = WethInterface(wethAddress)
  flashLender = FlashLoanInterface(flashLenderAddress)
  swapRouter = swapRouterAddress

@external
def setOwner(newOwner: address):
  assert msg.sender == self.owner, "only owner can set owner"
  self.owner = newOwner

@external
@payable
def __default__():
  assert msg.sender == wethToken.address, "only WETH can send ETH"

@external
def onFlashLoan(initiator: address, token: address, amount: uint256, fee: uint256, data: Bytes[MAX_DATA]) -> bytes32:
  assert initiator == self, "only I can initiate a flash loan"
  assert token == wethToken.address, "only WETH can be flash loaned"
  assert fee == 0, "no fee allowed"

  wethToken.withdraw(amount)

  rocketDepositPool: RocketDepositPoolInterface = RocketDepositPoolInterface(
    rocketStorage.getAddress(keccak256("contract.addressrocketDepositPool")))
  assert rethToken.balanceOf(self) == 0, "unexpected held rETH"
  rocketDepositPool.deposit(value = amount)

  assert rethToken.approve(swapRouter, rethToken.balanceOf(self)), "rETH approve failed"
  raw_call(swapRouter, data)
  assert wethToken.balanceOf(self) >= amount, "not enough WETH after swap"
  assert rethToken.balanceOf(self) == 0, "rETH left over after swap"

  assert wethToken.approve(msg.sender, amount), "WETH approve failed"
  return keccak256("ERC3156FlashBorrower.onFlashLoan")

@external
def arb(wethAmount: uint256, minProfit: uint256, swapData: Bytes[MAX_DATA]):
  RocketDepositArbitrageInterface(self).drain()
  assert flashLender.flashLoan(self, wethToken.address, wethAmount, swapData), "flash loan failed"
  profit: uint256 = wethToken.balanceOf(self)
  assert profit >= minProfit, "not enough profit"
  wethToken.withdraw(profit)
  send(msg.sender, profit)

@external
def drain():
  rethBalance: uint256 = rethToken.balanceOf(self)
  if 0 < rethBalance:
    rethToken.transfer(self.owner, rethBalance)

  wethBalance: uint256 = wethToken.balanceOf(self)
  if 0 < wethBalance:
    wethToken.withdraw(wethBalance)
  if 0 < self.balance:
    send(self.owner, self.balance)