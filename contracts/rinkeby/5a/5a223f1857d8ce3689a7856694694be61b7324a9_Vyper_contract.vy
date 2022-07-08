result: public(bool)
curr_balance: public(uint256)
active: public(bool)
guesses: public(uint256)
choice: uint256

@external
@payable
def __init__():
    assert msg.value == (10**18)
    self.guesses = self.guesses
    self.active = True
    self.curr_balance = self.curr_balance + msg.value


    
@external
@payable
def play() -> uint256:
    assert msg.value == (10**18)/20
    self.choice = uint256_mulmod(block.difficulty, block.number, 2)
    if self.choice == 1:
        self.result = False
        self.guesses = self.guesses + 1
        return self.choice
    elif self.choice == 0:
        self.result = True
        self.guesses = self.guesses + 1
        send(msg.sender, self.balance/2)
        return self.choice
    else:
        return self.choice