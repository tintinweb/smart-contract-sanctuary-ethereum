# @version ^0.3.7

# Events
event NewMemo:
    sender: indexed(address)
    time: uint256
    name: String[100]
    message: String[100]

event Payment:
    sender: indexed(address)
    amount: uint256

# Structs
struct Memo:
    sender: address
    time: uint256
    name: String[100]
    message: String[100]
    tip: uint256

# Storage variables
owner: public(address)
memos: public(HashMap[uint256, Memo])
last_memo_index: public(uint256)

@external
def __init__():
    """
    @notice Contract constructor
    """
    self.owner = msg.sender
    self.last_memo_index = 0

@payable    
@external
def __default__():
    """
    @notice Function called when contract receives eth with no or unknown function call
    """
    log Payment(msg.sender, msg.value)

@view
@external
def get_memos(_memo_index: uint256) -> Memo:
    """
    @notice Find a specific memo
    @param _memo_index index of the memo
    @return memo struct
    """
    return self.memos[_memo_index]

@payable
@external
def buy_coffee(_name: String[100], _message: String[100]):
    
    # Must accept more than 0 ETH for a coffee.
    assert msg.value > 0, "Can't buy coffee for free!"

    # Add the memo to storage
    self.memos[self.last_memo_index] = Memo({
        sender: msg.sender,
        time: block.timestamp,
        name: _name,
        message: _message,
        tip: msg.value
    })
    self.last_memo_index += 1

    # Log the event
    log NewMemo(msg.sender, block.timestamp, _name, _message)

@external
def withdraw_tips():
    """
    @notice Withdraw the contract's balance to an address
    """
    assert self.balance > 0, "Empty balance"
    send(self.owner, self.balance)