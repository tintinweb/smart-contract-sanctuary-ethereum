# @version ^0.3.7

interface RplInterface:
  def balanceOf(_who: address) -> uint256: view
  def transfer(_to: address, _wad: uint256) -> bool: nonpayable

interface RocketStorageInterface:
  def getAddress(_key: bytes32) -> address: view
  def confirmWithdrawalAddress(_nodeAddress: address): nonpayable
  def setWithdrawalAddress(_nodeAddress: address, _newWithdrawalAddress: address, _confirm: bool): nonpayable

rocketTokenRPLKey: constant(bytes32) = keccak256("contract.addressrocketTokenRPL")
rocketStorage: immutable(RocketStorageInterface)
rplToken: immutable(RplInterface)

owner: public(address)
pendingOwner: public(address)

beneficiary1: public(address)
beneficiary2: public(address)

nodeAddress: public(address)
payoutNumerator: public(uint256)
payoutDenominator: public(uint256)

@external
def __init__(_rocketStorageAddress: address):
  rocketStorage = RocketStorageInterface(_rocketStorageAddress)
  rplToken = RplInterface(rocketStorage.getAddress(rocketTokenRPLKey))
  self.owner = msg.sender

@external
@payable
def __default__():
  pass

@external
def changeOwner(_newOwner: address):
  assert msg.sender == self.owner, "only owner can change owner"
  self.pendingOwner = _newOwner

@external
def confirmChangeOwner():
  assert msg.sender == self.pendingOwner, "incorrect address"
  self.owner = self.pendingOwner

@external
def changeBeneficiaries(_beneficiary1: address, _beneficiary2: address):
  assert msg.sender == self.owner, "only owner can change beneficiaries"
  self.beneficiary1 = _beneficiary1
  self.beneficiary2 = _beneficiary2

@external
def changePayout(_numerator: uint256, _denominator: uint256):
  assert msg.sender == self.owner, "only owner can change payout"
  self.payoutNumerator = _numerator
  self.payoutDenominator = _denominator

@external
def withdrawRpl(_amount: uint256):
  assert msg.sender == self.owner, "only owner can withdrawRpl"
  assert _amount <= rplToken.balanceOf(self), "amount exceeds balance"
  payout: uint256 = _amount * self.payoutNumerator / self.payoutDenominator
  assert rplToken.transfer(self.beneficiary1, payout), "payout transfer to 1 failed"
  assert rplToken.transfer(self.beneficiary2, payout), "payout transfer to 2 failed"
  assert rplToken.transfer(self.owner, _amount - payout - payout), "rewards transfer failed"

@external
def withdrawEth(_amount: uint256):
  assert msg.sender == self.owner, "only owner can withdrawEth"
  assert self.balance <= _amount, "amount exceeds balance"
  send(self.owner, _amount)

@external
def rpConfirmWithdrawalAddress():
  rocketStorage.confirmWithdrawalAddress(self.nodeAddress)

@external
def changeNodeAddress(_newNodeAddress: address):
  assert msg.sender == self.owner, "only owner can changeNodeAddress"
  self.nodeAddress = _newNodeAddress

@external
def changeWithdrawalAddress(_newWithdrawalAddress: address):
  assert msg.sender == self.owner, "only owner can changeWithdrawalAddress"
  rocketStorage.setWithdrawalAddress(self.nodeAddress, _newWithdrawalAddress, False)