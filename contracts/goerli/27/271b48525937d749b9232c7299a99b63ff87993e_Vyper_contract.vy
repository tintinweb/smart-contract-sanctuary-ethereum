# @version ^0.2.0

owner : public(address)
ipfsHash : String[1000]

@external
def __init__():
    self.owner = msg.sender
    self.ipfsHash = 'NoHashStoredYet'

@external
@nonpayable
def change_hash(new_hash : String[1000]):
    assert msg.sender == self.owner , "Only Onwer can change Hash !"
    self.ipfsHash = new_hash

@external
@view
def fetch_hash() -> String[1000]:
    return self.ipfsHash