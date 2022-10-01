# @version ^0.3.0

admin: public(address)

event FundsDeposited:
    depositingWallet: indexed(address)
    value: uint256


@external
@nonpayable
def __init__():
    self.admin = msg.sender


@external
@payable
def __default__():
    log FundsDeposited(msg.sender, msg.value)


@external
def destroy_contract():
    assert(msg.sender == self.admin)
    selfdestruct(msg.sender)