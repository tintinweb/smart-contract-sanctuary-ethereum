# @version ^0.3.1

names: HashMap[uint256, String[30]]
lenN: uint256

@external
def set(namesadd: String[30]):
    assert namesadd != "", "Don't enter a blank string."
    assert len(namesadd) < 30, "String is too long."

    self.names[self.lenN] = namesadd
    self.lenN = self.lenN + 1

@view
@external
def read(num: uint256) -> String[30]:
    name: String[30] = self.names[num]
    return name