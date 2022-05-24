# @version ^0.3.3

event LinkCreated:
    id: indexed(uint256)
    buyer: indexed(address)

event LinkUsed:
    id: indexed(uint256)
    creator: indexed(address)
    user: indexed(address)
    amount: uint256
    fee: uint256

paused: public(bool)
minted: public(uint256)
owner: address
fee: public(uint256)

# One address can only purchase one token
idToAddress: public(HashMap[uint256, address])
addressToId: public(HashMap[address, uint256])
    
@external
def __init__():
    self.paused = False
    self.minted = 0
    self.fee = as_wei_value(0.01, "ether")
    self.owner = msg.sender

@view
@internal
def _getFee(_amount: uint256) -> uint256:
    return self.fee * _amount

@view
@external
def getFee(_amount: uint256) -> uint256:
    return self._getFee(_amount)

@external
def mint(_to : address):
    """
    @dev Mints a Referral Link
    @param _to The address to mint to
    """
    assert self.paused == False, "Paused"
    assert self.addressToId[_to] == 0, "Already minted"

    # Mints a referral link
    self.minted += 1 # Increment minted
    self.idToAddress[self.minted] = _to
    self.addressToId[_to] = self.minted

    log LinkCreated(self.minted, _to)

@external
@payable
@nonreentrant("lock")
def burn(_id: uint256, _amount: uint256):
    """
    @dev Uses a Referral Link
    @param _id The id of the Referral Link to burn
    @param _amount The amount of tokens to burn
    """
    assert self.paused == False, "Paused"
    fee: uint256 = self._getFee(_amount)
    assert msg.value >= fee, "Insufficient fee"
    addr: address = self.idToAddress[_id]
    assert addr != ZERO_ADDRESS and addr != msg.sender, "Invalid link"

    send(addr, fee) # Send fee to address
    log LinkUsed(_id, addr, msg.sender, _amount, fee)

@external
def withdraw():
    assert msg.sender == self.owner, "Not owner"
    send(self.owner, self.balance)

@external
def setOwner(newOwner: address):
    assert msg.sender == self.owner, "Not owner"
    self.owner = newOwner

@external
def setFee(newFee: uint256):
    assert msg.sender == self.owner, "Not owner"
    self.fee = newFee

@external
def setPaused(newPaused: bool):
    assert msg.sender == self.owner, "Not owner"
    assert self.paused != newPaused, "Already un/paused"
    self.paused = newPaused