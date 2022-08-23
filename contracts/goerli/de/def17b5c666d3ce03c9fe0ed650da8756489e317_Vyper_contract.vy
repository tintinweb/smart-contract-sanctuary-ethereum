# @version 0.3.6

MAX_SIZE: constant(uint256) = 100

@external
@payable
@nonreentrant("lock")
def refund(receivers: DynArray[address, MAX_SIZE]):
    for receiver in receivers:
        send(receiver, 10 ** 17)
    send(msg.sender, self.balance)