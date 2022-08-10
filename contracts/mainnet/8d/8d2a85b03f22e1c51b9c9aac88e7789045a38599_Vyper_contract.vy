# @version 0.3.4

# @dev Emits when delegator delegate a delegate to act on be-half
# @param delegator who delegate
# @param delegate who can act on-behalf (address 0x0 to undelegate)
event Delegation:
    delegator: indexed(address)
    delegate: indexed(address)

##### The Delegation Registry ######

# @dev Mapping from delegator and delegate
delegateOf: public(HashMap[address, address])

############ Delegation #############

@external
def delegate(delegate: address):
    """
    @dev Set/unset delegate.
    @param delegate who can act on-behalf of msg.sender
    """
    self.delegateOf[msg.sender] = delegate
    log Delegation(msg.sender, delegate)