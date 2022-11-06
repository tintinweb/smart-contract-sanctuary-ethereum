# @version ^0.2.16

waves: public(uint256)

event Wave:
  sender: indexed(address)
  received_timestamp: indexed(uint256)

@external
@nonpayable
def wave():
  self.waves += 1
  log Wave(msg.sender, block.timestamp)


@external
def __init__():
  self.waves = 0