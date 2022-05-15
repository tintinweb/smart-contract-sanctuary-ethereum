struct Candidate:
    name: String[40]
    vote_count: int128

struct Voter:
    voted: bool
    vote: address
    weight: int128


candidates: public(HashMap[address, Candidate])
voters: public(HashMap[address, Voter])
owner: public(address)

@external
def __init__():
    self.owner = msg.sender


@external
def add_candidate(_address: address, _name: String[40]):
    assert msg.sender == self.owner
    self.candidates[_address] = Candidate({name: _name, vote_count: 0})

@external
def register_voter(_address: address):
    assert msg.sender == self.owner
    self.voters[_address] = Voter({voted: False, vote: ZERO_ADDRESS, weight: 1})

@external
def vote(_candidate: address):
    assert self.voters[msg.sender].voted == False
    assert self.voters[msg.sender].weight != 0
    assert msg.sender != self.owner
    self.candidates[_candidate].vote_count += 1
    self.voters[msg.sender].voted = True
    self.voters[msg.sender].vote = _candidate