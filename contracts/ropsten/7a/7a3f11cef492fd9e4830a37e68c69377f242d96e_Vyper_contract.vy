# @version ^0.2.16
#Timestamps SVB KDE uploads on IPFS
struct MultiHash:
    code: int128
    length: int128
    value: bytes32
KDEs: public(HashMap[uint256, MultiHash])
PPs: public(HashMap[int128, MultiHash])
PPnonce: public(HashMap[int128, int128])
svb: public(address)

@external
def __init__(_svb: address):
    self.svb = _svb

@external
def logKDEs(_code: int128, _length: int128, _value: bytes32):
    assert msg.sender == self.svb, "Only SVB can log KDEs."
    self.KDEs[block.number] = MultiHash({code: _code, length: _length, value: _value})

@external
def logCreditAction(_code: int128, _length: int128, _value: bytes32, _id: int128):
    assert msg.sender == self.svb, "Only SVB can log Credit Actions."
    self.PPs[_id + self.PPnonce[_id]] = MultiHash({code: _code, length: _length, value: _value})
    self.PPnonce[_id] = self.PPnonce[_id] + 1