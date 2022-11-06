# @version ^0.2.16

struct UserOperation:
  sender: address                   # The wallet making the operation
  call_data: bytes32                # The data to pass to the sender during the main execution call
  nonce: uint256                    # Anti-replay parameter; also used as the salt for first-time wallet creation
  max_fee_per_gas: uint256          # Maximum fee per gas (similar to EIP-1559 max_fee_per_gas)
  max_priority_fee_per_gas: uint256 # Maximum priority fee per gas (similar to EIP-1559 max_priority_fee_per_gas)
  signature: bytes32                # Data passed into the wallet along with the nonce during the verification step

  init_code: bytes32                # The initCode of the wallet (needed if and only if the wallet is not yet on-chain and needs to be created)
  call_gas_limit: uint256           # The amount of gas to allocate the main execution call
  verification_gas_limit: uint256   # The amount of gas to allocate for the verification step
  per_verification_gas: uint256     # The amount of gas to pay for to compensate the bundler for pre-verification execution and calldata
  paymaster_and_data: bytes32       # Address of paymaster sponsoring the transaction, followed by extra data to send to the paymaster (empty for self-sponsored transaction)

struct Deposit:
  amount: uint256
  is_staked: bool
  stake_amount: uint256
  unstake_delay_sec: uint256
  withdraw_time: uint256

unstake_delay_sec: public(uint256)
# minimum required locked stake for a paymaster
min_paymaster_stake: public(uint256)
paymaster_deposits: public(HashMap[address, Deposit])

@internal
@payable
def compensate(_account: address, _amount: uint256):
  assert _amount > 0
  assert _account != ZERO_ADDRESS
  assert _amount <= msg.value
  result: Bytes[32] = raw_call(_account, b"\x01", max_outsize=32, value=_amount)


@external
@payable
def handle_op(_user_op: UserOperation, _sponsor: address):
  # handle validations

  # handle executions

  # handle compensation
  self.compensate(_sponsor, msg.value)


@external
@payable
def deposit_to(_account: address):
  assert _account != ZERO_ADDRESS
  assert msg.value > 0

  deposit_info: Deposit = self.paymaster_deposits[_account]
  updated_deposit_amount: uint256 = deposit_info.amount + msg.value
  self.paymaster_deposits[_account] = Deposit({
    amount: updated_deposit_amount,
    is_staked: deposit_info.is_staked,
    stake_amount: deposit_info.stake_amount,
    unstake_delay_sec: deposit_info.unstake_delay_sec,
    withdraw_time: deposit_info.withdraw_time
  })



@external
def __init__(_min_paymaster_stake: uint256, _unstake_delay_sec: uint256):
  assert _unstake_delay_sec > 0
  self.unstake_delay_sec   = _unstake_delay_sec
  self.min_paymaster_stake = _min_paymaster_stake