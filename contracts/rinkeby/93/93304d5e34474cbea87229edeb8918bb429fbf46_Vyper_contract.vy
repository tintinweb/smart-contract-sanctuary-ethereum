# @version 0.3.3
 
SMALL_NUMBER: immutable(uint256)
 
@external
def __init__(_number: uint256):
	SMALL_NUMBER = _number
 
@view
@external
def get_number() -> uint256:
	return SMALL_NUMBER