# @version 0.3.7
"""
@title CLendCompoundV3.vy
@license Unlicensed
@notice This contract can be used by Invoker to interact with Compound V3
"""

from vyper.interfaces import ERC20

interface Comet:
    def supplyFrom(from_: address, dst: address, asset: address, amount: uint256): nonpayable
    def withdrawFrom(from_: address, dst: address, asset: address, amount: uint256): nonpayable
    def supplyTo(dst: address, asset: address, amount: uint256): nonpayable
    def withdrawTo(to: address, asset: address, amount: uint256): nonpayable
    def transferAsset(dst: address, asset: address, amount: uint256): nonpayable
    def transferAssetFrom(src: address, dst: address, asset: address, amount: uint256): nonpayable

@internal
def _approve_token(token: address, spender: address, amount: uint256):
    if ERC20(token).allowance(self, spender) > 0:
       ERC20(token).approve(spender, 0, default_return_value=True)
    ERC20(token).approve(spender, amount, default_return_value=True)

@external
@payable
def transfer_asset_in(comet: address, asset: address, amount: uint256):
    """
    @notice Supply a collateral asset into the Invoker
    @dev CompoundV3 collateral assets do not have a corresponding ERC20 token.
        User must have previously performed comet.allow(invoker, True)
    @param comet The address of the comet instance
    @param asset The address of the asset to transfer
    @param amount The amount of the asset to transfer
    """
    Comet(comet).transferAssetFrom(msg.sender, self, asset, amount)

@external
@payable
def transfer_asset_out(comet: address, asset: address, amount: uint256, receiver: address):
    """
    @notice Remove a collateral asset from the Invoker
    @dev CompoundV3 collateral assets do not have a corresponding ERC20 token.
    @param comet The address of the comet instance
    @param asset The address of the asset to transfer
    @param amount The amount of the asset to transfer
    @param receiver The address which will receive the asset
    """
    Comet(comet).transferAsset(receiver, asset, amount)

@external
@payable
def supply_user(comet: address, asset: address, amount: uint256, receiver: address):
    """
    @notice Supply/repay an asset to the comet where the asset is currently in the users wallet.
    @dev User must have previously performed comet.allow(invoker, True)
    @param comet The address of the comet instance
    @param asset The address of the asset to deposit
    @param amount The amount of the asset to deposit
    @param receiver The address which will be credited with the deposit
    """
    Comet(comet).supplyFrom(msg.sender, receiver, asset, amount)

@external
@payable
def supply_invoker(comet: address, asset: address, amount: uint256, receiver: address):
    """
    @notice Supply/repay an asset to the comet where the asset is currently in the Invoker.
    @dev This function should be used when composing a deposit with other interactions.
    @param comet The address of the comet instance
    @param asset The address of the asset to deposit
    @param amount The amount of the asset to deposit
    @param receiver The address which will be credited with the deposit
    """
    self._approve_token(asset, comet, amount)
    Comet(comet).supplyTo(receiver, asset, amount)

@external
@payable
def withdraw_user(comet: address, asset: address, amount: uint256, receiver: address):
    """
    @notice Withdraw/borrow an asset from the comet where the asset is currently in the users wallet.
    @dev User must have previously performed comet.allow(invoker, True)
    @param comet The address of the comet instance
    @param asset The address of the asset to withdraw
    @param amount The amount of the asset to withdraw
    @param receiver The address which will receive the asset
    """
    Comet(comet).withdrawFrom(msg.sender, receiver, asset, amount)

@external
@payable
def withdraw_invoker(comet: address, asset: address, amount: uint256, receiver: address):
    """
    @notice Withdraw/borrowy an asset to the comet where the asset is currently in the Invoker.
    @param comet The address of the comet instance
    @param asset The address of the asset to withdraw
    @param amount The amount of the asset to withdraw
    @param receiver The address which will receive the asset
    """
    Comet(comet).withdrawTo(receiver, asset, amount)