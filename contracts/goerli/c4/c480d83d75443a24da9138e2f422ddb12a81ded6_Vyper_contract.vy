# @version ^0.3.7

interface RplInterface:
  def balanceOf(_who: address) -> uint256: view
  def transfer(_to: address, _wad: uint256) -> bool: nonpayable

interface RocketStorageInterface:
  def getAddress(_key: bytes32) -> address: view
  def confirmWithdrawalAddress(_nodeAddress: address): nonpayable
  def setWithdrawalAddress(_nodeAddress: address, _newWithdrawalAddress: address, _confirm: bool): nonpayable

interface RocketNodeStakingInterface:
  def getNodeRPLStake(_nodeAddress: address) -> uint256: view

rocketNodeStakingKey: constant(bytes32) = keccak256("contract.addressrocketNodeStaking")
rocketStorageAddress: constant(address) = 0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46
rplTokenAddress: constant(address) = 0xD33526068D116cE69F19A9ee46F0bd304F21A51f
rocketStorage: immutable(RocketStorageInterface)
rplToken: immutable(RplInterface)

ownerEth: public(address)
ownerRpl: public(address)
nodeAddress: public(address)
pendingNodeAddress: public(address)
pendingWithdrawalAddress: public(address)

rplPrincipal: public(uint256)
rplFeeNumerator: public(uint256)
rplFeeDenominator: public(uint256)
pendingRplFeeNumerator: public(uint256)
pendingRplFeeDenominator: public(uint256)

@external
def __init__(_ownerRpl: address):
  rocketStorage = RocketStorageInterface(rocketStorageAddress)
  rplToken = RplInterface(rplTokenAddress)
  self.ownerEth = msg.sender
  self.ownerRpl = _ownerRpl

@external
@payable
def __default__():
  pass

@external
def setOwnerEth(_newOwnerEth: address):
  assert msg.sender == self.ownerEth, "only ownerEth can set ownerEth"
  self.ownerEth = _newOwnerEth

@external
def setOwnerRpl(_newOwnerRpl: address):
  assert msg.sender == self.ownerRpl, "only ownerRpl can set ownerRpl"
  self.ownerRpl = _newOwnerRpl

@internal
def _getNodeRPLStake() -> uint256:
  rocketNodeStakingAddress: address = rocketStorage.getAddress(rocketNodeStakingKey)
  rocketNodeStaking: RocketNodeStakingInterface = RocketNodeStakingInterface(rocketNodeStakingAddress)
  return rocketNodeStaking.getNodeRPLStake(self.nodeAddress)

@external
def setRplFee(_numerator: uint256, _denominator: uint256):
  assert msg.sender == self.ownerEth, "only ownerEth can initiate fee change"
  self.pendingRplFeeNumerator = _numerator
  self.pendingRplFeeDenominator = _denominator

@external
def confirmRplFee(_numerator: uint256, _denominator: uint256):
  assert msg.sender == self.ownerRpl, "only ownerRpl can confirm fee change"
  assert _numerator == self.pendingRplFeeNumerator, "incorrect numerator"
  assert _denominator == self.pendingRplFeeDenominator, "incorrect denominator"
  self.rplFeeNumerator = _numerator
  self.rplFeeDenominator = _denominator

@external
def updateRplPrincipal(_expectedAmount: uint256):
  assert msg.sender == self.ownerRpl, "only ownerRpl can set principal"
  assert _expectedAmount == self._getNodeRPLStake(), "incorrect RPL stake amount"
  self.rplPrincipal = _expectedAmount

@external
def withdrawRplPrincipal(_amount: uint256):
  assert msg.sender == self.ownerRpl, "only ownerRpl can withdrawRplPrincipal"
  assert _amount <= self.rplPrincipal, "amount exceeds principal"
  assert _amount <= rplToken.balanceOf(self), "amount exceeds balance"
  assert rplToken.transfer(self.ownerRpl, _amount), "rpl principal transfer failed"
  self.rplPrincipal -= _amount

@external
def withdrawRewards(_amount: uint256):
  assert msg.sender == self.ownerRpl, "only ownerRpl can withdrawRewards"
  assert _amount <= rplToken.balanceOf(self), "amount exceeds balance"
  fee: uint256 = _amount * self.rplFeeNumerator / self.rplFeeDenominator
  assert rplToken.transfer(self.ownerEth, fee), "fee transfer failed"
  assert rplToken.transfer(self.ownerRpl, _amount - fee), "rpl rewards transfer failed"
  send(self.ownerEth, self.balance)

@external
def withdrawEth():
  assert msg.sender == self.ownerEth, "only ownerEth can withdrawEth"
  assert self._getNodeRPLStake() == 0, "unstake RPL before withdrawing ETH"
  send(self.ownerEth, self.balance)

@external
def rpConfirmWithdrawalAddress():
  rocketStorage.confirmWithdrawalAddress(self.nodeAddress)

@external
def changeNodeAddress(_newNodeAddress: address):
  assert msg.sender == self.ownerEth, "only ownerEth can changeNodeAddress"
  self.pendingNodeAddress = _newNodeAddress

@external
def confirmChangeNodeAddress(_newNodeAddress: address):
  assert msg.sender == self.ownerRpl, "only ownerRpl can confirmChangeNodeAddress"
  assert _newNodeAddress == self.pendingNodeAddress, "incorrect address"
  self.nodeAddress = _newNodeAddress

@external
def changeWithdrawalAddress(_newWithdrawalAddress: address):
  assert msg.sender == self.ownerEth, "only ownerEth can changeWithdrawalAddress"
  self.pendingWithdrawalAddress = _newWithdrawalAddress

@external
def confirmChangeWithdrawalAddress(_newWithdrawalAddress: address):
  assert msg.sender == self.ownerRpl, "only ownerRpl can confirmChangeWithdrawalAddress"
  assert _newWithdrawalAddress == self.pendingWithdrawalAddress, "incorrect address"
  rocketStorage.setWithdrawalAddress(self.nodeAddress, _newWithdrawalAddress, False)