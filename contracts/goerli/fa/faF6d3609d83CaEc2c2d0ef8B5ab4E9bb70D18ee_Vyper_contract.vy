# @version 0.3.7

"""
@title Voting Adapter
@author Lido Finance
@license MIT
@notice Used to allow voting with tokens under vesting
"""

from vyper.interfaces import ERC20


interface IDelegation:
    def setDelegate(
        _id: bytes32,
        _delegate: address,
    ): nonpayable


interface IVoting:
    def vote(
        _voteId: uint256,
        _supports: bool,
        _executesIfDecided_deprecated: bool,
    ): nonpayable


event ERC20Recovered:
    token: address
    amount: uint256


event ETHRecovered:
    amount: uint256


event OwnerChanged:
    owner: address


ZERO_BYTES32: constant(
    bytes32
) = 0x0000000000000000000000000000000000000000000000000000000000000000

VOTING_CONTRACT_ADDR: immutable(address)
SNAPSHOT_DELEGATE_CONTRACT_ADDR: immutable(address)
DELEGATION_CONTRACT_ADDR: immutable(address)

owner: public(address)


@external
def __init__(
    voting_addr: address,
    snapshot_delegate_addr: address,
    delegation_addr: address,
    owner: address,
):
    """
    @notice Initialize source contract implementation.
    @param voting_addr Address of the Voting contract
    @param snapshot_delegate_addr Address of the Shapshot Delegate contract
    @param delegation_addr Address of the voting power delegation contract
    @param owner Address to recover tokens and ether to
    """
    assert owner != empty(address), "zero owner"
    self.owner = owner
    VOTING_CONTRACT_ADDR = voting_addr
    SNAPSHOT_DELEGATE_CONTRACT_ADDR = snapshot_delegate_addr
    DELEGATION_CONTRACT_ADDR = delegation_addr


@external
@view
def encode_aragon_vote_calldata(voteId: uint256, supports: bool) -> Bytes[1000]:
    """
    @notice Encode calldata for use in VestingEscrow
    @param voteId Id of the vote
    @param supports Support flag true - yea, false - nay
    """
    return _abi_encode(voteId, supports)


@external
def aragon_vote(abi_encoded_params: Bytes[1000]):
    """
    @notice Cast vote on Aragon voting
    @param abi_encoded_params Abi encoded data for call. Can be obtained from encode_aragon_vote_calldata
    """
    vote_id: uint256 = empty(uint256)
    supports: bool = empty(bool)
    vote_id, supports = _abi_decode (abi_encoded_params, (uint256, bool))
    IVoting(VOTING_CONTRACT_ADDR).vote(
        vote_id, supports, False
    )  # dev: third arg is deprecated


@external
@view
def encode_snapshot_set_delegate_calldata(delegate: address) -> Bytes[1000]:
    """
    @notice Encode calldata for use in VestingEscrow
    @param delegate Address of the delegate
    """
    return _abi_encode(delegate)


@external
def snapshot_set_delegate(abi_encoded_params: Bytes[1000]):
    """
    @notice Delegate Snapshot voting power of all available tokens
    @param abi_encoded_params Abi encoded data for call. Can be obtained from encode_snapshot_set_delegate_calldata
    """
    delegate: address = empty(address)
    delegate = _abi_decode (abi_encoded_params, (address))
    IDelegation(SNAPSHOT_DELEGATE_CONTRACT_ADDR).setDelegate(
        ZERO_BYTES32, delegate
    )  # dev: null id allows voting at any snapshot space


@external
@view
def encode_delegate_calldata(delegate: address) -> Bytes[1000]:
    """
    @notice Encode calldata for use in VestingEscrow
    @param delegate Address of the delegate
    """
    return _abi_encode(delegate)


@external
def delegate(abi_encoded_params: Bytes[1000]):
    """
    @notice Delegate voting power of all available tokens
    @param abi_encoded_params Abi encoded data for call. Can be obtained from encode_delegate_calldata
    """
    assert False, "not implemented"


@external
@view
def voting_contract_addr() -> address:
    return VOTING_CONTRACT_ADDR


@external
@view
def snapshot_delegate_contract_addr() -> address:
    return SNAPSHOT_DELEGATE_CONTRACT_ADDR


@external
@view
def delegation_contract_addr() -> address:
    return DELEGATION_CONTRACT_ADDR


@external
def change_owner(owner: address):
    """
    @notice Change contract owner.
    @param owner Address of the new owner. Must be non-zero.
    """
    self._check_sender_is_owner()
    assert owner != empty(address), "zero owner address"

    self.owner = owner
    log OwnerChanged(owner)


@external
def recover_erc20(token: address, amount: uint256):
    """
    @notice Recover ERC20 tokens to owner
    @param token Address of the ERC20 token to be recovered
    """
    if amount != 0:
        assert ERC20(token).transfer(
            self.owner, amount, default_return_value=True
        ), "transfer failed!"
        log ERC20Recovered(token, amount)


@external
def recover_ether():
    """
    @notice Recover Ether to owner
    """
    amount: uint256 = self.balance
    self._safe_send_ether(self.owner, amount)
    log ETHRecovered(amount)


@internal
def _check_sender_is_owner():
    assert msg.sender == self.owner, "msg.sender not owner"


@internal
def _safe_send_ether(_to: address, _value: uint256):
    """
    @notice Overcome 2300 gas limit on simple send
    """
    _response: Bytes[32] = raw_call(
        _to, empty(bytes32), value=_value, max_outsize=32
    )
    if len(_response) > 0:
        assert convert(_response, bool), "ETH transfer failed!"