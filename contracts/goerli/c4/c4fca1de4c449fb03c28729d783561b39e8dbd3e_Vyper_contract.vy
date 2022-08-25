# @version ^0.3.6
# @title    Relay
# @author   Maka

ops: address
MAX: constant(uint256) = 1024

@external
def __init__():
  self.ops = msg.sender

@external
@payable
def fn_relay(_dest: address, _data: Bytes[MAX]) -> Bytes[128]:
  assert msg.sender == self.ops
  success: bool = False
  response: Bytes[128] = b''
  success, response = raw_call(
    _dest,
    _data, 
    value=msg.value, 
    max_outsize=128, 
    revert_on_failure=False
  )
  assert success
  return response

 # 1 love