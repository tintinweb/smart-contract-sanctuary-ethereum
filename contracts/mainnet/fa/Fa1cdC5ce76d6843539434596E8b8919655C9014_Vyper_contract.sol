# @version 0.3.1
"""
@notice Curve Gnosis (prev Xdai) Omni Bridge Wrapper
"""
from vyper.interfaces import ERC20


interface OmniBridge:
    def relayTokens(_token: address, _receiver: address, _value: uint256): nonpayable


CRV20: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
OMNI_BRIDGE: constant(address) = 0x88ad09518695c6c3712AC10a214bE5109a655671


is_approved: public(HashMap[address, bool])


@external
def __init__():
    assert ERC20(CRV20).approve(OMNI_BRIDGE, MAX_UINT256)
    self.is_approved[CRV20] = True


@external
def bridge(_token: address, _to: address, _amount: uint256):
    """
    @notice Bridge an asset using the Omni Bridge
    @param _token The ERC20 asset to bridge
    @param _to The receiver on Gnosis Chain
    @param _amount The amount of `_token` to bridge
    """
    assert ERC20(_token).transferFrom(msg.sender, self, _amount)

    if _token != CRV20 and not self.is_approved[_token]:
        assert ERC20(_token).approve(OMNI_BRIDGE, MAX_UINT256)
        self.is_approved[_token] = True

    OmniBridge(OMNI_BRIDGE).relayTokens(_token, _to, _amount)


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
    @notice Check if `_account` may bridge via `transmit_emissions`
    @param _account The account to check
    """
    return True