# @version 0.3.7

"""
@title Vesting Escrow
@author Curve Finance, Yearn Finance, Lido Finance
@license GPL-3.0
@notice Vests ERC20 tokens for a single address
@dev Intended to be deployed many times via `VotingEscrowFactory`
"""

from vyper.interfaces import ERC20


interface IVestingEscrowFactory:
    def voting_adapter() -> address: nonpayable
    def owner() -> address: nonpayable
    def manager() -> address: nonpayable


event VestingEscrowInitialized:
    factory: indexed(address)
    recipient: indexed(address)
    token: indexed(address)
    amount: uint256
    start_time: uint256
    end_time: uint256
    cliff_length: uint256
    is_fully_revokable: bool


event Claim:
    beneficiary: indexed(address)
    claimed: uint256


event UnvestedTokensRevoked:
    recoverer: indexed(address)
    revoked: uint256


event VestingFullyRevoked:
    recoverer: indexed(address)
    revoked: uint256


event ERC20Recovered:
    token: address
    amount: uint256


event ETHRecovered:
    amount: uint256


recipient: public(address)
token: public(ERC20)
start_time: public(uint256)
end_time: public(uint256)
cliff_length: public(uint256)
factory: public(IVestingEscrowFactory)
total_locked: public(uint256)
is_fully_revokable: public(bool)

total_claimed: public(uint256)
disabled_at: public(uint256)
initialized: public(bool)
is_fully_revoked: public(bool)


@external
def __init__():
    """
    @notice Initialize source contract implementation.
    """
    # ensure that the original contract cannot be initialized
    self.initialized = True


@external
def initialize(
    token: address,
    amount: uint256,
    recipient: address,
    start_time: uint256,
    end_time: uint256,
    cliff_length: uint256,
    is_fully_revokable: bool,
    factory: address,
) -> bool:
    """
    @notice Initialize the contract.
    @dev This function is separate from `__init__` because of the factory pattern
         used in `VestingEscrowFactory.deploy_vesting_contract`. It may be called
         once per deployment.
    @param token Address of the ERC20 token being distributed
    @param amount Amount of the ERC20 token to be controleed by escrow
    @param recipient Address to vest tokens for
    @param start_time Epoch time at which token distribution starts
    @param end_time Time until everything should be vested
    @param cliff_length Duration after which the first portion vests
    @param factory Address of the parent factory
    """
    assert not self.initialized, "can only initialize once"
    self.initialized = True

    self.token = ERC20(token)
    self.is_fully_revokable = is_fully_revokable
    self.start_time = start_time
    self.end_time = end_time
    self.cliff_length = cliff_length

    assert ERC20(token).balanceOf(self) >= amount, "insufficient balance"

    self.total_locked = amount
    self.recipient = recipient
    self.disabled_at = end_time  # Set to maximum time
    self.factory = IVestingEscrowFactory(factory)
    log VestingEscrowInitialized(
        factory,
        recipient,
        token,
        amount,
        start_time,
        end_time,
        cliff_length,
        is_fully_revokable,
    )

    return True


@internal
@view
def _total_vested_at(time: uint256) -> uint256:
    start: uint256 = self.start_time
    end: uint256 = self.end_time
    locked: uint256 = self.total_locked
    if time < start + self.cliff_length:
        return 0
    return min(locked * (time - start) / (end - start), locked)


@internal
@view
def _unclaimed() -> uint256:
    if self.is_fully_revoked:
        return 0
    claim_time: uint256 = min(block.timestamp, self.disabled_at)
    return self._total_vested_at(claim_time) - self.total_claimed


@external
@view
def unclaimed() -> uint256:
    """
    @notice Get the number of unclaimed, vested tokens for recipient
    """
    return self._unclaimed()


@internal
@view
def _locked() -> uint256:
    if block.timestamp >= self.disabled_at:
        return 0
    return self.total_locked - self._total_vested_at(block.timestamp)


@external
@view
def locked() -> uint256:
    """
    @notice Get the number of locked tokens for recipient
    """
    return self._locked()


@external
def claim(
    beneficiary: address = msg.sender, amount: uint256 = max_value(uint256)
) -> uint256:
    """
    @notice Claim tokens which have vested
    @param beneficiary Address to transfer claimed tokens to
    @param amount Amount of tokens to claim
    """
    self._check_sender_is_recipient()

    claimable: uint256 = min(self._unclaimed(), amount)
    self.total_claimed += claimable

    assert self.token.transfer(
        beneficiary, claimable, default_return_value=True
    ), "transfer failed"

    log Claim(beneficiary, claimable)

    return claimable


@external
def revoke_unvested():
    """
    @notice Disable further flow of tokens and revoke the unvested part to owner
    """
    self._check_sender_is_owner_or_manager()

    revokable: uint256 = self._locked()
    assert revokable > 0, "nothing to revoke"
    self.disabled_at = block.timestamp

    assert self.token.transfer(
        self._owner(), revokable, default_return_value=True
    ), "transfer failed"

    log UnvestedTokensRevoked(msg.sender, revokable)


@external
def revoke_all():
    """
    @notice Disable further flow of tokens and revoke all tokens to owner
    """
    self._check_sender_is_owner()
    assert self.is_fully_revokable, "not allowed for ordinary vesting"
    assert not self.is_fully_revoked, "already fully revoked"

    # NOTE: do not revoke extra tokens
    revokable: uint256 = self._locked() + self._unclaimed()
    assert revokable > 0, "nothing to revoke"

    self.is_fully_revoked = True
    self.disabled_at = block.timestamp

    assert self.token.transfer(
        self._owner(), revokable, default_return_value=True
    ), "transfer failed"

    log VestingFullyRevoked(msg.sender, revokable)


@external
def recover_erc20(token: address, amount: uint256):
    """
    @notice Recover ERC20 tokens to recipient
    @param token Address of the ERC20 token to be recovered
    @param amount Amount of the ERC20 token to be recovered
    """
    recoverable: uint256 = amount
    if token == self.token.address:
        available: uint256 = ERC20(token).balanceOf(self) - (
            self._locked() + self._unclaimed()
        )
        recoverable = min(recoverable, available)
    if recoverable > 0:
        assert ERC20(token).transfer(
            self.recipient, recoverable, default_return_value=True
        ), "transfer failed"
        log ERC20Recovered(token, recoverable)


@external
def recover_ether():
    """
    @notice Recover Ether to recipient
    """
    amount: uint256 = self.balance
    if amount != 0:
        self._safe_send_ether(self.recipient, amount)
        log ETHRecovered(amount)


@external
def aragon_vote(abi_encoded_params: Bytes[1000]):
    """
    @notice Participate Aragon vote using all available tokens on the contract's balance
    @param abi_encoded_params Abi encoded data for call. Can be obtained from VotingAdapter.encode_aragon_vote_calldata
    """
    self._check_sender_is_recipient()
    self._check_voting_adapter_is_set()
    raw_call(
        self.factory.voting_adapter(),
        _abi_encode(
            abi_encoded_params,
            method_id=method_id("aragon_vote(bytes)"),
        ),
        is_delegate_call=True,
    )


@external
def snapshot_set_delegate(abi_encoded_params: Bytes[1000]):
    """
    @notice Delegate Snapshot voting power of all available tokens on the contract's balance
    @param abi_encoded_params Abi encoded data for call. Can be obtained from VotingAdapter.encode_snapshot_set_delegate_calldata
    """
    self._check_sender_is_recipient()
    self._check_voting_adapter_is_set()
    raw_call(
        self.factory.voting_adapter(),
        _abi_encode(
            abi_encoded_params,
            method_id=method_id("snapshot_set_delegate(bytes)"),
        ),
        is_delegate_call=True,
    )


@external
def delegate(abi_encoded_params: Bytes[1000]):
    """
    @notice Delegate voting power of all available tokens on the contract's balance
    @param abi_encoded_params Abi encoded data for call. Can be obtained from VotingAdapter.encode_delegate_calldata
    """
    self._check_sender_is_recipient()
    self._check_voting_adapter_is_set()
    raw_call(
        self.factory.voting_adapter(),
        _abi_encode(
            abi_encoded_params,
            method_id=method_id("delegate(bytes)"),
        ),
        is_delegate_call=True,
    )


@internal
def _owner() -> address:
    return self.factory.owner()


@internal
def _manager() -> address:
    return self.factory.manager()


@internal
def _check_sender_is_owner_or_manager():
    assert (
        msg.sender == self._owner() or msg.sender == self._manager()
    ), "msg.sender not owner or manager"


@internal
def _check_sender_is_owner():
    assert msg.sender == self._owner(), "msg.sender not owner"


@internal
def _check_sender_is_recipient():
    assert msg.sender == self.recipient, "msg.sender not recipient"


@internal
def _check_voting_adapter_is_set():
    assert self.factory.voting_adapter() != empty(
        address
    ), "voting adapter not set"


@internal
def _safe_send_ether(_to: address, _value: uint256):
    """
    @notice Overcome 2300 gas limit on simple send
    """
    _response: Bytes[32] = raw_call(
        _to, empty(bytes32), value=_value, max_outsize=32
    )
    if len(_response) > 0:
        assert convert(_response, bool), "ETH transfer failed"