# @version 0.3.1
"""
@notice Simple Root veCRV Oracle
"""
from vyper.interfaces import ERC20


interface CallProxy:
    def anyCall(
        _to: address, _data: Bytes[1024], _fallback: address, _to_chain_id: uint256
    ): nonpayable


event UpdateCallProxy:
    _old_call_proxy: address
    _new_call_proxy: address

event TransferOwnership:
    _old_owner: address
    _new_owner: address


interface Factory:
    def get_bridger(_chain_id: uint256) -> address: view

interface VotingEscrow:
    def epoch() -> uint256: view
    def point_history(_idx: uint256) -> Point: view
    def user_point_epoch(_user: address) -> uint256: view
    def user_point_history(_user: address, _idx: uint256) -> Point: view


struct Point:
    bias: int128
    slope: int128
    ts: uint256


FACTORY: immutable(address)
VE: immutable(address)


call_proxy: public(address)
owner: public(address)
future_owner: public(address)


@external
def __init__(_factory: address, _ve: address, _call_proxy: address):
    FACTORY = _factory
    VE = _ve

    self.call_proxy = _call_proxy
    log UpdateCallProxy(ZERO_ADDRESS, _call_proxy)

    self.owner = msg.sender
    log TransferOwnership(ZERO_ADDRESS, msg.sender)


@external
def push(_chain_id: uint256, _user: address = msg.sender):
    """
    @notice Push veCRV data to a child chain
    """
    assert Factory(FACTORY).get_bridger(_chain_id) != ZERO_ADDRESS  # dev: invalid chain

    ve: address = VE
    assert ERC20(ve).balanceOf(_user) != 0

    user_point: Point = VotingEscrow(ve).user_point_history(
        _user, VotingEscrow(ve).user_point_epoch(_user)
    )
    global_point: Point = VotingEscrow(ve).point_history(VotingEscrow(ve).epoch())

    CallProxy(self.call_proxy).anyCall(
        self,
        _abi_encode(
            user_point,
            global_point,
            _user,
            method_id=method_id("receive((int128,int128,uint256),(int128,int128,uint256),address)")
        ),
        ZERO_ADDRESS,
        _chain_id
    )


@external
def set_call_proxy(_new_call_proxy: address):
    """
    @notice Set the address of the call proxy used
    @dev _new_call_proxy should adhere to the same interface as defined
    @param _new_call_proxy Address of the cross chain call proxy
    """
    assert msg.sender == self.owner

    log UpdateCallProxy(self.call_proxy, _new_call_proxy)
    self.call_proxy = _new_call_proxy


@external
def commit_transfer_ownership(_future_owner: address):
    """
    @notice Transfer ownership to `_future_owner`
    @param _future_owner The account to commit as the future owner
    """
    assert msg.sender == self.owner  # dev: only owner

    self.future_owner = _future_owner


@external
def accept_transfer_ownership():
    """
    @notice Accept the transfer of ownership
    @dev Only the committed future owner can call this function
    """
    assert msg.sender == self.future_owner  # dev: only future owner

    log TransferOwnership(self.owner, msg.sender)
    self.owner = msg.sender