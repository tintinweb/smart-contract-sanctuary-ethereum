# @version 0.3.1
"""
@notice Curve Multichain EOA Bridge Wrapper
"""
from vyper.interfaces import ERC20


# address of anyswap cross chain call proxy
ANYCALL: immutable(address)
# EOA bridge address
ANYSWAP_BRIDGE: immutable(address)


@external
def __init__(_anycall: address, _anyswap_bridge: address):
    ANYCALL = _anycall
    ANYSWAP_BRIDGE = _anyswap_bridge


@external
def bridge(_token: address, _to: address, _amount: uint256):
    # FTM bridge is an EOA bridge, and transfers tokens by checking
    # `Transfer` events. Using transferFrom to transfer tokens from
    # `msg.sender` -> bridge, has the same effect as if the `msg.sender`
    # called transfer on the token itself
    ERC20(_token).transferFrom(msg.sender, ANYSWAP_BRIDGE, _amount)


@view
@external
def cost() -> uint256:
    return 0


@view
@external
def check(_transmit_caller: address) -> bool:
    # anyswap bridge cannot handle multiple transfers in one call, so we
    # block smart contracts that could checkpoint multiple gauges at once
    # therefore the caller of `transmit_emissions` on the factory has to
    # either be tx originator, or anycall
    return _transmit_caller in [tx.origin, ANYCALL]


@pure
@external
def anycall() -> address:
    return ANYCALL


@pure
@external
def anyswap_bridge() -> address:
    return ANYSWAP_BRIDGE