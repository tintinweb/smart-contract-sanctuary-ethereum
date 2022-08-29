storedData: public(uint256)

@external
def __init__(_x: uint256):
  self.storedData = _x
  
@external
def storeDataHere(_x: uint256):
  self.storedData = _x
  
@external
@view
def returnStoredData(_y: uint256) -> uint256:
	if _y == 1:
		return 999
	else:
		return self.storedData