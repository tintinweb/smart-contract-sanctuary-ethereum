# @version ^0.2.16

struct UserOperation:
  sender: address                   # The wallet making the operation
  calldata: bytes32                # The data to pass to the sender during the main execution call
  nonce: uint256                    # Anti-replay parameter; also used as the salt for first-time wallet creation
  max_fee_per_gas: uint256          # Maximum fee per gas (similar to EIP-1559 max_fee_per_gas)
  max_priority_fee_per_gas: uint256 # Maximum priority fee per gas (similar to EIP-1559 max_priority_fee_per_gas)
  signature: bytes32                # Data passed into the wallet along with the nonce during the verification step

  init_code: bytes32                # The initCode of the wallet (needed if and only if the wallet is not yet on-chain and needs to be created)
  call_gas_limit: uint256           # The amount of gas to allocate the main execution call
  verification_gas_limit: uint256   # The amount of gas to allocate for the verification step
  per_verification_gas: uint256     # The amount of gas to pay for to compensate the bundler for pre-verification execution and calldata
  paymaster_and_data: bytes32       # Address of paymaster sponsoring the transaction, followed by extra data to send to the paymaster (empty for self-sponsored transaction)


struct PaymasterDeposit:
  amount: uint256                   # amount of stake deposited
  stake_lock_duration: uint256      # time in seconds for which the stake is locked   
  stake_withdrawal_time: uint256    # time when the stake can be withdrawn


min_paymaster_stake_lock_time: public(uint256)                 # minimum time (in seconds) a paymaster stake must be locked
paymaster_deposits: public(HashMap[address, PaymasterDeposit]) # paymaster address => paymaster deposit

@external
def get_user_op_encoding(
    _sender: address, 
    _calldata: bytes32, 
    _nonce: uint256, 
    _max_fee_per_gas: uint256, 
    _max_priority_fee_per_gas: uint256, 
    _signature: bytes32, 
    _init_code: bytes32, 
    _call_gas_limit: uint256, 
    _verification_gas_limit: uint256, 
    _per_verification_gas: uint256, 
    _paymaster_and_data: bytes32
  ) -> Bytes[356]:
  return _abi_encode(
    _sender, 
    _calldata, 
    _nonce, 
    _max_fee_per_gas, 
    _max_priority_fee_per_gas, 
    _signature, 
    _init_code, 
    _call_gas_limit, 
    _verification_gas_limit, 
    _per_verification_gas, 
    _paymaster_and_data,
    ensure_tuple=True,
    method_id=method_id("get_user_op_encoding()")
  )


@external
def __init__(_min_paymaster_stake_lock_time: uint256):
  self.min_paymaster_stake_lock_time = _min_paymaster_stake_lock_time