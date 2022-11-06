# @version ^0.2.16


struct PaymasterDeposit:
  amount: uint256                # amount of stake deposited
  stake_lock_duration: uint256 # time in seconds for which the stake is locked   
  stake_withdrawal_time: uint256 # time when the stake can be withdrawn


min_paymaster_stake_lock_time: public(uint256)                 # minimum time (in seconds) a paymaster stake must be locked
paymaster_deposits: public(HashMap[address, PaymasterDeposit]) # paymaster address => paymaster deposit


event UserOperationEventSucceeded:
  request_id: indexed(bytes32)
  sender: indexed(address)
  paymaster_address: indexed(address)
  nonce: uint256
  actual_gas_cost: uint256
  actual_gas_price: uint256
  status: uint256


event UserOperationEventFailed:
  request_id: indexed(bytes32)
  sender: indexed(address)
  nonce: uint256
  reason: String[32]


event StakeDepositToEvent:
  amount: uint256
  stake_lock_duration: uint256
  account_to_stake_to: indexed(address)


@external
@payable
def stake_deposit_to(_account_to_stake_to: address, _stake_lock_duration: uint256) -> address:
  log StakeDepositToEvent(msg.value, _stake_lock_duration, _account_to_stake_to)
  return msg.sender


@external
def __init__(_min_paymaster_stake_lock_time: uint256):
  self.min_paymaster_stake_lock_time = _min_paymaster_stake_lock_time