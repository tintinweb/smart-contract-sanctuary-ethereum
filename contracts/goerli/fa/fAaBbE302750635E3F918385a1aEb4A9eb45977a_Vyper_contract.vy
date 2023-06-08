# @version 0.3.8

MAX_LIDO_REQUESTS: constant(uint8) = 80 # maximum requestIds within a withdrawal request
MAX_LIDO_WITHDRAWAL: constant(uint256) = 1000 * (10 ** 18) # maximum size of a requestId

MAX_REQUESTS: constant(uint8) = 32 # maximum number of stETH withdrawals a caller of finaliseWithdrawal can process at a time
STAKING_EMISSION: constant(uint256) = 1 # amount of LIDONT emitted per staked rETH per block
MINIPOOL_REWARD: constant(uint256) = 2100000 * (10 ** 18) # amount of atto-LIDONT emitted per minipool claim

interface ERC20:
  def name() -> String[64]: view
  def symbol() -> String[8]: view
  def decimals() -> uint8: view
  def totalSupply() -> uint256: view
  def balanceOf(_owner: address) -> uint256: view
  def transfer(_to: address, _value: uint256) -> bool: nonpayable
  def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
  def approve(_spender: address, _value: uint256) -> bool: nonpayable
  def allowance(_owner: address, _spender: address) -> uint256: view

event Transfer:
  _from: indexed(address)
  _to: indexed(address)
  _value: uint256

event Approval:
  _owner: indexed(address)
  _spender: indexed(address)
  _value: uint256

interface RocketStorage:
  def getAddress(_key: bytes32) -> address: view
  def getNodeWithdrawalAddress(_nodeAddress: address) -> address: view

interface RocketMinipoolManager:
  def getMinipoolCount() -> uint256: view
  def getMinipoolAt(_index: uint256) -> address: view
  def getNodeMinipoolAt(_nodeAddress: address, _index: uint256) -> address: view

interface RocketDepositPool:
  def deposit(): payable

interface RocketEther:
  def getRethValue(_ethAmount: uint256) -> uint256: view

interface UnstETH:
  def requestWithdrawals(_amounts: DynArray[uint256, MAX_LIDO_REQUESTS], _owner: address) -> DynArray[uint256, MAX_LIDO_REQUESTS]: nonpayable
  def claimWithdrawals(_requestIds: DynArray[uint256, MAX_REQUESTS], _hints: DynArray[uint256, MAX_REQUESTS]): nonpayable

interface Minipool:
  def getStatus() -> uint8: view
Staking: constant(uint8) = 2
Withdrawable: constant(uint8) = 3

rocketStorage: immutable(RocketStorage)
rocketDepositPoolKey: constant(bytes32) = keccak256("contract.addressrocketDepositPool")
rocketMinipoolManagerKey: constant(bytes32) = keccak256("contract.addressrocketMinipoolManager")
rocketEtherKey: constant(bytes32) = keccak256("contract.addressrocketTokenRETH")
rocketEther: immutable(ERC20)
stakedEther: immutable(ERC20)
unstETH: immutable(UnstETH)

# ERC20 functions
name: public(constant(String[64])) = "Lidont Staked to Rocket Ether Ratchet"
symbol: public(constant(String[8])) = "LIDONT"
decimals: public(constant(uint8)) = 18
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

# Staked rETH accounting
struct StakeDetails:
  stake: uint256 # amount of atto-rETH staked
  rewardDebt: uint256 # amount of atto-LIDONT rewards owed
  lastClaimBlock: uint256 # block for which rewardDebt is current

stakedReth: public(HashMap[address, StakeDetails])

# easy balance viewer (stakedReth(who)[0] is equivalent)
@external
@view
def getStake(who: address) -> uint256:
  return self.stakedReth[who].stake

# Minipool rewards accounting
rewardMinipoolsFromIndex: public(immutable(uint256))
minipoolClaimed: public(HashMap[address, bool])

@external
def __init__(rocketStorageAddress: address, stETHAddress: address, unstETHAddress: address):
  rocketStorage = RocketStorage(rocketStorageAddress)
  rocketEther = ERC20(rocketStorage.getAddress(rocketEtherKey))
  stakedEther = ERC20(stETHAddress)
  unstETH = UnstETH(unstETHAddress)
  rewardMinipoolsFromIndex = RocketMinipoolManager(rocketStorage.getAddress(rocketMinipoolManagerKey)).getMinipoolCount()
  self.minipoolClaimed[empty(address)] = True

# ERC20 functions

@internal
def _transfer(_from: address, _to: address, _amount: uint256) -> bool:
  balanceFrom: uint256 = self.balanceOf[_from]
  if balanceFrom < _amount:
    return False
  self.balanceOf[_from] = unsafe_sub(balanceFrom, _amount)
  self.balanceOf[_to] = self.balanceOf[_to] + _amount
  log Transfer(_from, _to, _amount)
  return True

@external
def transfer(_to: address, _value: uint256) -> bool:
  return self._transfer(msg.sender, _to, _value)

@external
def approve(_spender: address, _value: uint256) -> bool:
  self.allowance[msg.sender][_spender] = _value
  log Approval(msg.sender, _spender, _value)
  return True

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
  allowanceFrom: uint256 = self.allowance[_from][_to]
  if allowanceFrom < _value:
    return False
  transferred: bool = self._transfer(_from, _to, _value)
  if transferred:
    self.allowance[_from][_to] = unsafe_sub(allowanceFrom, _value)
  return transferred

# internal functions for minting LIDONT, and staking and unstaking rETH

@internal
def forceSend(_to: address, _amount: uint256) -> bool:
  # gas=0 should prevent any action on receipt, and hence any chance of reentrancy
  return raw_call(_to, b"", value=_amount, gas=0, revert_on_failure=False)

event Mint:
  amount: indexed(uint256)

event Stake:
  who: indexed(address)
  amount: indexed(uint256)

event Unstake:
  who: indexed(address)
  amount: indexed(uint256)

@internal
def _mint(amount: uint256):
  self.totalSupply += amount
  self.balanceOf[empty(address)] += amount
  log Mint(amount)

@internal
def _addRewardDebt(who: address):
  blocks: uint256 = block.number - self.stakedReth[who].lastClaimBlock
  amount: uint256 = blocks * self.stakedReth[who].stake * STAKING_EMISSION
  self._mint(amount)
  self.stakedReth[who].rewardDebt += amount
  self.stakedReth[who].lastClaimBlock = block.number

@internal
def _stake(who: address, amount: uint256):
  self._addRewardDebt(who)
  self.stakedReth[who].stake += amount
  log Stake(who, amount)

@internal
def _unstake(who: address, amount: uint256):
  self._addRewardDebt(who)
  self.stakedReth[who].stake -= amount
  log Unstake(who, amount)

# Main mechanisms:
# - swap stETH for staked rETH
# - deposit (stake) rETH for staked rETH
# - withdraw (unstake) staked rETH
# - claim LIDONT rewards for staked rETH
# - claim LIDONT for a minipool

event Swap:
  who: indexed(address)
  stakedEther: indexed(uint256)
  rocketEther: indexed(uint256)

event ClaimMinipool:
  who: indexed(address)
  node: indexed(address)
  minipool: indexed(address)

event ClaimEmission:
  who: indexed(address)
  lidont: indexed(uint256)

@external
def swap(stETHAmount: uint256, stake: bool):
  rETHAmount: uint256 = RocketEther(rocketEther.address).getRethValue(stETHAmount)
  assert stakedEther.transferFrom(msg.sender, self, stETHAmount), "stETH transfer failed"
  log Swap(msg.sender, stETHAmount, rETHAmount)
  if stake:
    self._stake(msg.sender, rETHAmount)
  else:
    assert rocketEther.transfer(msg.sender, rETHAmount), "rETH transfer failed"

@external
def stake(rETHAmount: uint256):
  assert rocketEther.transferFrom(msg.sender, self, rETHAmount), "rETH transfer failed"
  self._stake(msg.sender, rETHAmount)

@external
def unstake(rETHAmount: uint256):
  self._unstake(msg.sender, rETHAmount)
  assert rocketEther.transfer(msg.sender, rETHAmount), "rETH transfer failed"

@external
def claimEmission() -> uint256:
  self._addRewardDebt(msg.sender)
  amount: uint256 = self.stakedReth[msg.sender].rewardDebt
  self._transfer(empty(address), msg.sender, amount)
  self.stakedReth[msg.sender].rewardDebt = 0
  log ClaimEmission(msg.sender, amount)
  return amount

@external
def claimMinipool(nodeAddress: address, nodeIndex: uint256, index: uint256):
  assert (msg.sender == rocketStorage.getNodeWithdrawalAddress(nodeAddress) or
          msg.sender == nodeAddress), "auth"
  rocketMinipoolManager: RocketMinipoolManager = RocketMinipoolManager(rocketStorage.getAddress(rocketMinipoolManagerKey))
  minipool: address = rocketMinipoolManager.getNodeMinipoolAt(nodeAddress, nodeIndex)
  assert rocketMinipoolManager.getMinipoolAt(index) == minipool, "index"
  assert rewardMinipoolsFromIndex <= index, "old"
  minipoolStatus: uint8 = Minipool(minipool).getStatus()
  assert minipoolStatus == Staking or minipoolStatus == Withdrawable, "not staking"
  assert not self.minipoolClaimed[minipool], "claimed"
  self._mint(MINIPOOL_REWARD)
  self._transfer(empty(address), msg.sender, MINIPOOL_REWARD)
  self.minipoolClaimed[minipool] = True
  log ClaimMinipool(msg.sender, nodeAddress, minipool)

# Manage this contract's stETH and rETH balances:
# - withdraw ETH for stETH
# - mint rETH with ETH

event WithdrawalRequest:
  requestIds: DynArray[uint256, MAX_LIDO_REQUESTS]
  amount: indexed(uint256)

@external
def initiateWithdrawal(stETHAmount: uint256) -> DynArray[uint256, MAX_LIDO_REQUESTS]:
  assert stakedEther.approve(unstETH.address, stETHAmount), "stETH approve failed"
  amountLeft: uint256 = stETHAmount
  requestAmounts: DynArray[uint256, MAX_LIDO_REQUESTS] = []
  for _ in range(MAX_LIDO_REQUESTS):
    amount: uint256 = min(amountLeft, MAX_LIDO_WITHDRAWAL)
    requestAmounts.append(amount)
    amountLeft = unsafe_sub(amountLeft, amount)
    if amountLeft == 0: break
  requestIds: DynArray[uint256, MAX_LIDO_REQUESTS] = unstETH.requestWithdrawals(requestAmounts, self)
  log WithdrawalRequest(requestIds, stETHAmount)
  return requestIds

@external
def finaliseWithdrawal(_requestIds: DynArray[uint256, MAX_REQUESTS], _hints: DynArray[uint256, MAX_REQUESTS]):
  unstETH.claimWithdrawals(_requestIds, _hints)

@external
def mintRocketEther(ethAmount: uint256):
  depositPool: RocketDepositPool = RocketDepositPool(rocketStorage.getAddress(rocketDepositPoolKey))
  depositPool.deposit(value = ethAmount)