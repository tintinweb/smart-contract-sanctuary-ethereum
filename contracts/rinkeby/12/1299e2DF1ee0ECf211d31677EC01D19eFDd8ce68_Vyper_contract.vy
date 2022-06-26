## TODO: 20000 is an arbitrary constant throughout

## Structs ##
struct Proposal:
    _hash: bytes32

## Events ##
event Proposed:
    proposer: indexed(address)
    proposalId: indexed(uint256)

event Executed:
    executor: indexed(address)
    proposalId: indexed(uint256)

## State Variables ##
owners: public(DynArray[address, 69])
minimum: public(uint256)

## Map from proposal ID  
proposals: public(HashMap[uint256, Proposal])
approvals: public(HashMap[uint256, uint256])
approved: HashMap[uint256,DynArray[address, 69]]

@external
@payable
def __init__(_owners: DynArray[address, 69], _minimum: uint256):
    self.owners = _owners
    self.minimum = _minimum

@external
def propose(id: uint256, _hash: bytes32):
    ## TODO: tFigure out how to do a zero comparison for this in vyper, 
    ## there is probably a way better way to check this
    if self.proposals[id]._hash != 0x0000000000000000000000000000000000000000000000000000000000000000:
        raise "Proposal already exists"

    self.proposals[id] = Proposal({_hash: _hash})
    log Proposed(msg.sender, id)

@external
def approve(id: uint256):
    is_owner: bool = False
    for owner in self.owners:
        if owner == msg.sender:
            is_owner = True
            break
    if is_owner == False:
        raise "Only owners can approve proposals"

    ## Check that someone can't approve twice
    previous_approvals: DynArray[address, 69] = self.approved[id]
    for approval in previous_approvals:
        if approval == msg.sender:
            raise "You have already approved this proposal"
    
    self.approvals[id] = self.approvals[id] + 1
    self.approved[id].append(msg.sender)

@external
def execute(id: uint256, target: address, calldata: Bytes[2000], _value: uint256):
    ## TODO: tFigure out how to do a zero comparison for this in vyper, 
    ## there is probably a way better way to check this
    if self.proposals[id]._hash == 0x0000000000000000000000000000000000000000000000000000000000000000:
        raise "Proposal does not exist"
    
    ## Check that the proposal has been approved by the minimum number of owners
    if self.approvals[id] < self.minimum:
        raise "Proposal has not been approved by the minimum number of owners"
    
    _constructed_hash: bytes32 = keccak256(_abi_encode(target, calldata, _value))
    if self.proposals[id]._hash != _constructed_hash:
        raise "Proposal hash does not provided data"
        
    ## Execute the proposal
    ## TODO: Actually test that this return stuff works
    proposal: Proposal = self.proposals[id]

    ## Neutralize proposal before executing 
    self.proposals[id] = Proposal({_hash: 0x0000000000000000000000000000000000000000000000000000000000000000})
    self.approvals[id] = 0
    self.approved[id] = [0x0000000000000000000000000000000000000000]

    ## Execute
    ret: Bytes[20000] = raw_call(target, calldata, value=_value, max_outsize=20000)
    log Executed(msg.sender, id)

@external
def revoke_approval(id: uint256):
    prior_approvals: DynArray[address, 69] = self.approved[id]
    for index in range(69):
        if prior_approvals[index] == msg.sender:
            prior_approvals[index] = 0x0000000000000000000000000000000000000000
            self.approved[id] = prior_approvals
            self.approvals[id] = self.approvals[id] - 1
            return
    raise "No approval to revoke"


@external
@payable
def __default__():
    pass