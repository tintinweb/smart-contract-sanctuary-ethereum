storedData: public(uint256)

@external
def __init__(_x: uint256):
  self.storedData = _x
  
@external
def storeDataHere(_x: uint256):
  self.storedData = _x
  
@external
def returnStoredData() -> uint256:
    return self.storedData