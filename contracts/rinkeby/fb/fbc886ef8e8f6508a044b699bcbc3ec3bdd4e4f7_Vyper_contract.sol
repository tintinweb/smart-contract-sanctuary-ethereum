struct Proposal:
   name: String[40]

   amt: uint256

   dest: address

   votesFor: int128

   totalVotes: int128

   closed: bool


struct Voter:

   voted: bool


struct Proposal_with_Address:

   Ind: int128

   addr: address


ProposalMap: public(HashMap[int128, Proposal])

PropVoters: public(HashMap[bytes32, Voter])

PropInd: int128

VoterList: address[3]


@external

def __init__():

   self.VoterList = [0xcEA4e535D03086DBAa04c71675129654E92CC055, 0x8F6ef8D0466DEC9Ac7028931fbeb225717Cd89c4, 0x5232333151CC6D8b3699D0ADc5D009aB2c6621c6]

   self.PropInd = 0


@external

def CreateProposal(_name: String[40], _amt: uint256, _dest: address):

   assert msg.sender in self.VoterList

   self.PropInd += 1

   self.ProposalMap[self.PropInd] = Proposal({name: _name, amt: _amt, dest: _dest, votesFor: 0, totalVotes: 0, closed: False})


@external

def Vote(_propInd: int128, _inFavor: bool):

   assert msg.sender in self.VoterList

   assert not self.PropVoters[keccak256(concat(convert(msg.sender, bytes32), convert(_propInd, bytes32)))].voted == True

   if _inFavor == True:

       self.ProposalMap[_propInd].votesFor += 1

   self.ProposalMap[_propInd].totalVotes += 1

   self.PropVoters[(keccak256(concat(convert(msg.sender, bytes32), convert(_propInd, bytes32))))].voted = True


@external

def closeProposal(_propInd: int128):

   assert self.ProposalMap[_propInd].totalVotes == 3 or self.ProposalMap[_propInd].votesFor >= 2

   assert not self.ProposalMap[_propInd].closed == True

   if self.ProposalMap[_propInd].votesFor >= 2:

       send(self.ProposalMap[_propInd].dest, self.ProposalMap[_propInd].amt)

   self.ProposalMap[_propInd].closed = True


@payable

@external

def addFunds():

   pass