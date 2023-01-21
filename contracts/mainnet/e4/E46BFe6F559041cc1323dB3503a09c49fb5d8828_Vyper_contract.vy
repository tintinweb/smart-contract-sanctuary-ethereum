# @version ^0.3.7

MAX_DATA: constant(uint256) = 2**13

interface RocketStorageInterface:
  def getAddress(_key: bytes32) -> address: view

interface RocketDepositPoolInterface:
  def deposit(): payable

interface WethInterface:
  def approve(_spender: address, _amount: uint256) -> bool: nonpayable
  def balanceOf(_who: address) -> uint256: view
  def deposit(): payable
  def withdraw(_wad: uint256): nonpayable

interface ERC20:
  def approve(_spender: address, _amount: uint256) -> bool: nonpayable
  def balanceOf(_who: address) -> uint256: view
  def transfer(_to: address, _wad: uint256) -> bool: nonpayable

event Arbitrage:
  who: indexed(address)
  deposit: indexed(uint256)
  profit: uint256

DEPOSIT_VALUE: constant(uint256) = 32_000_000_000_000_000_000
rocketStorage: immutable(RocketStorageInterface)
rethToken: immutable(ERC20)
wethToken: immutable(WethInterface)
swapRouter: immutable(address)
owner: public(address)
funder: public(address)

@external
def __init__(rocketStorageAddress: address, swapRouterAddress: address, wethAddress: address):
  self.owner = msg.sender
  rocketStorage = RocketStorageInterface(rocketStorageAddress)
  rethAddress: address = rocketStorage.getAddress(keccak256("contract.addressrocketTokenRETH"))
  rethToken = ERC20(rethAddress)
  wethToken = WethInterface(wethAddress)
  swapRouter = swapRouterAddress
  assert rethToken.approve(swapRouter, max_value(uint256))

@external
def setOwner(newOwner: address):
  assert msg.sender == self.owner, "only owner can set owner"
  self.owner = newOwner

@external
@payable
def __default__():
  assert msg.sender == wethToken.address, "only WETH can send ETH"

@external
@payable
def fund():
  assert msg.value == DEPOSIT_VALUE, "incorrect deposit value"
  assert self.funder == empty(address), "deposit exists already"
  self.funder = msg.sender

@external
def defund():
	bal: uint256 = self.balance
	prev_funder: address = self.funder
	assert prev_funder != empty(address)
	assert msg.sender == prev_funder, "only funder can call"
	self.funder = empty(address)
	send(prev_funder, bal)

@external
def sweep(token:ERC20):
	assert msg.sender == self.owner
	token.transfer(self.owner, token.balanceOf(self))

@external
def arb(ethAmount: uint256, minProfit: uint256, swapData: Bytes[MAX_DATA]):
  rocketDepositPool: RocketDepositPoolInterface = RocketDepositPoolInterface(
    rocketStorage.getAddress(keccak256("contract.addressrocketDepositPool")))

  rocketDepositPool.deposit(value = ethAmount)
  raw_call(swapRouter, swapData)
  assert rethToken.balanceOf(self) == 0, "rETH left over after swap"
  total: uint256 = wethToken.balanceOf(self)
  assert total >= ethAmount, "not enough to cover lent amount"
  profit: uint256 = total - ethAmount
  assert profit >= minProfit, "not enough profit"
  wethToken.withdraw(total)
  send(msg.sender, profit)
  log Arbitrage(msg.sender, ethAmount, profit)