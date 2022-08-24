# @version 0.3.6

MAX_SIZE: constant(uint256) = 256

@external
@payable
@nonreentrant("lock")
def refund(receivers: DynArray[address, MAX_SIZE]):
    bal: uint256 = 0
    for receiver in receivers:
        bal = receiver.balance
        if bal < 10 ** 17:
            send(receiver, unsafe_sub(15 * 10 ** 16, bal))
    if self.balance > 0:
        send(msg.sender, self.balance)