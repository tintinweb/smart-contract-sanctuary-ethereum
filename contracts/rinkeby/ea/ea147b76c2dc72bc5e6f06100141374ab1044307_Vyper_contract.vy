secret_number: uint256
curr_balance: public(uint256)
guesses: public(uint256)
active: public(bool)
blockn: public(uint256)

@external
@payable
def __init__(_secret_number: uint256):
    assert msg.value == (10**18)
    assert (_secret_number >= 0) and (_secret_number <= 100), "Number must be between 0-100"
    self.secret_number = _secret_number
    self.guesses = self.guesses
    self.curr_balance = self.curr_balance + msg.value
    self.active = True
    self.blockn = (block.number) 
    
@external
@payable
def play(_guessed_number: uint256) -> String[100]:
    assert self.active == True, "The contract has already paid out"
    assert msg.value == (10**18)/20
    if _guessed_number == self.secret_number:
        send(msg.sender, self.balance)
        self.curr_balance = 0
        self.active = False
        return "Correct!"
    else:
        self.guesses = self.guesses + 1
        return "Wrong!"