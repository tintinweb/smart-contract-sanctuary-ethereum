"""
@title Ark Network
@license MIT
@author charmful0x
@notice this contract is only for testing purpose
@dev link an EVM address to an Arweave address. The
     contract is deterministic, but as part of Ark Network,
     it becomes non-deterministic where the result
     depends on the other SmartWeave contracts states.
"""

# Contract's events
event LinkIdentity:
    evmAddress: indexed(address)
    arweaveAddress: indexed(String[43])
    arAddress: String[43]

event LaunchContract:
    network: String[25]

event PauseState:
    isPaused: bool

# Contract State
network: public(String[25]) # Ark Network's metadata to identify the contract's network
owner: public(address) # the contract admin
pausedContract: public(bool) # contract's pausing state

@external
def __init__(_network: String[25], _pausedContract: bool):
    """
    @dev contract's initialization
    @param _network network's name. This contract is EVMs compatible
    @param _pausedContract initial contract's pause state. Assigned to False
    """
    assert len(_network) > 0

    self.owner = msg.sender # set the contract admin
    self.network = _network
    self.pausedContract = _pausedContract

    log LaunchContract(_network)


@external
def reversePauseState(_pause: bool):
    """
    @dev admin function to pause/unpause the contract
    @param _pause True to pause the contract & vice-versa
    """

    assert msg.sender == self.owner
    assert _pause != self.pausedContract

    self.pausedContract = _pause

    log PauseState(_pause)

@external
def linkIdentity(_arweave_address: String[43]):
    """
    @dev link an Arweave address to the caller's address (msg.sender)
    @param _arweave_address base64url 43 char string
    """
    assert len(_arweave_address) == 43
    assert self.pausedContract == False

    log LinkIdentity(msg.sender, _arweave_address, _arweave_address)