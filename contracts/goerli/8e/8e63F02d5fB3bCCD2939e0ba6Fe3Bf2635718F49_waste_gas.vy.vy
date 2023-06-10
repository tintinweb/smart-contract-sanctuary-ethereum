# @version ^0.2.16
# @title waste_gas.vy
# @notice waste gas with a callable sig

@external
def waste_gas():
  x: uint256 = convert(0x0ba5ed,uint256)
  for i in range(420):
    x = block.number

# 1 love