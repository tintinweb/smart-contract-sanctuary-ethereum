# @version 0.3.7
"""
@title call_me
@license MIT
@author Long J'hat
@notice
    One function call to distribute Fixed Forex rewards.
    -- It works, until it doesn't.
"""

from vyper.interfaces import ERC20


interface controller:
    def profit(): nonpayable


interface ib_burner:
    def update_snx(): nonpayable
    def exchange_all(): nonpayable
    def distribute(): nonpayable


MSIG: constant(address) = 0x0D5Dc686d0a2ABBfDaFDFb4D0533E886517d4E83
CONTROLLER: immutable(controller)
BURNER: immutable(ib_burner)


@external
def __init__(control: controller, burn: ib_burner):
    CONTROLLER = control
    BURNER = burn


@external
def distribute(update: bool):
    CONTROLLER.profit()
    if update:
        BURNER.update_snx()
    BURNER.exchange_all()
    BURNER.distribute()


@payable
@external
def __default__():
    pass


@external
def collect_eth():
    assert msg.sender == MSIG # !msig
    send(msg.sender, self.balance)


@external
def collect_dust(token: ERC20):
    assert msg.sender == MSIG # !msig
    assert token.transfer(msg.sender, token.balanceOf(self), default_return_value=True)