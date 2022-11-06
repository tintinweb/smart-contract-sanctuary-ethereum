# @version ^0.2.16

@external
@nonpayable
def delegate_wave(_wave_portal_address: address):
  result: Bytes[32] = raw_call(_wave_portal_address, _abi_encode(method_id("wave()")), max_outsize=32)

@external
def __init__():
  pass