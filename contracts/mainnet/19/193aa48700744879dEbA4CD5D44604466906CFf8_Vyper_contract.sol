# @version 0.3.1
"""
@title Curve Polygon Bridge Wrapper
"""
from vyper.interfaces import ERC20


interface BridgeManager:
    def depositFor(_user: address, _root_token: address, _deposit_data: Bytes[32]): nonpayable


CRV20: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
POLYGON_BRIDGE_MANAGER: constant(address) = 0xA0c68C638235ee32657e8f720a23ceC1bFc77C77
POLYGON_BRIDGE_RECEIVER: constant(address) = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf


# token -> is approval given to bridge
is_approved: public(HashMap[address, bool])


@external
def __init__():
    assert ERC20(CRV20).approve(POLYGON_BRIDGE_RECEIVER, MAX_UINT256)
    self.is_approved[CRV20] = True


@external
def bridge(_token: address, _to: address, _amount: uint256):
    """
    @notice Bridge a token to Polygon mainnet
    @param _token The token to bridge
    @param _to The address to deposit the token to on polygon
    @param _amount The amount of the token to bridge
    """
    assert ERC20(_token).transferFrom(msg.sender, self, _amount)

    if _token != CRV20 and not self.is_approved[_token]:
        assert ERC20(_token).approve(POLYGON_BRIDGE_RECEIVER, MAX_UINT256)
        self.is_approved[_token] = True

    BridgeManager(POLYGON_BRIDGE_MANAGER).depositFor(_to, _token, _abi_encode(_amount))


@pure
@external
def cost() -> uint256:
    """
    @notice Cost in ETH to bridge
    """
    return 0


@pure
@external
def check(_account: address) -> bool:
    """
    @notice Check if `_account` is allowed to bridge
    @param _account The account to check
    """
    return True