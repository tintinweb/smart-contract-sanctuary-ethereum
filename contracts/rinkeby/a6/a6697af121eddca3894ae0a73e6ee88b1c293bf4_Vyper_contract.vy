# @version ^0.3.3

start_time: public(uint256)
deadline: public(uint256)

@external
def __init__():
    self.start_time = 1659744000
    self.deadline = self.start_time + 3600