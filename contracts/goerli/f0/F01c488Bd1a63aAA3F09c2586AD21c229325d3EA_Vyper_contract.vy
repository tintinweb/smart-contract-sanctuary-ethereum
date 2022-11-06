# @version ^0.2.16

"""
@title A contract that agree to pay the gas fees associated with the operation
@license MIT
@author Peaze Inc
@notice Typically, this contract would be reimbursed somehow (perhaps with an ERC20 token), 
but the system does not specify or enforce any particular incentive.  They must stake some funds 
beforehand as an anti-sybil mechanism. They must also prepay for the operations that they will fund.
"""

entry_point: public(address)
deployer_address: public(address)


@external
@payable
def add_stake(_unstake_delay_sec: uint256) -> Bytes[32]:
  assert msg.sender == self.deployer_address
  response: Bytes[32] = raw_call(self.entry_point, _abi_encode(msg.sender, _unstake_delay_sec, method_id("stake_deposit_to(address,uint256)")), max_outsize=32, value=msg.value)
  return response


@external
def __init__(_entry_point: address):
  self.entry_point = _entry_point
  self.deployer_address = msg.sender