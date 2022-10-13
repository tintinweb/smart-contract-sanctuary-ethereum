# @version 0.3.7

MAX_SIZE: constant(uint256) = 256

event Refund:
    final_block: uint256

@external
@payable
@nonreentrant("lock")
def refund(receivers: DynArray[address, MAX_SIZE], amounts: DynArray[uint256, MAX_SIZE], final_block: uint256):
    assert len(receivers) == len(amounts)
    i: uint256 = 0
    for receiver in receivers:
        send(receiver, amounts[i])
        i = unsafe_add(i, 1)
    if self.balance > 0:
        send(msg.sender, self.balance)
    log Refund(final_block)