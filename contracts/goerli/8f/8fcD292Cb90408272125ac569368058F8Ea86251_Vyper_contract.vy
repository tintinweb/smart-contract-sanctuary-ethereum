# @version 0.3.7

"""
@title Vesting Escrow Factory
@author Curve Finance, Yearn Finance, Lido Finance
@license MIT
@notice Stores and distributes ERC20 tokens by deploying `VestingEscrow` contracts
"""

from vyper.interfaces import ERC20


interface IVestingEscrow:
    def initialize(
        token: address,
        amount: uint256,
        recipient: address,
        start_time: uint256,
        end_time: uint256,
        cliff_length: uint256,
        is_fully_revokable: bool,
        voting_adapter_addr: address,
    ) -> bool: nonpayable


event VestingEscrowCreated:
    creator: indexed(address)
    escrow: address


event ERC20Recovered:
    token: address
    amount: uint256


event ETHRecovered:
    amount: uint256


event VotingAdapterUpgraded:
    voting_adapter: address


event OwnerChanged:
    owner: address


event ManagerChanged:
    manager: address


target: public(address)
token: public(address)
voting_adapter: public(address)
owner: public(address)
manager: public(address)


@external
def __init__(
    target: address,
    token: address,
    owner: address,
    manager: address,
    voting_adapter: address,
):
    """
    @notice Contract constructor
    @dev Prior to deployment you must deploy one copy of `VestingEscrow` which
         is used as a library for vesting contracts deployed by this factory
    @param target `VestingEscrow` contract address
    @param token Address of the ERC20 token being distributed using escrows
    @param owner Address of the owner of the deployed escrows
    @param manager Address of the manager of the deployed escrows
    @param voting_adapter Address of the Lido Voting Adapter
    """
    assert target != empty(address), "zero target_simple"
    assert owner != empty(address), "zero owner"
    assert token != empty(address), "zero token"
    self.target = target
    self.token = token
    self.owner = owner
    self.manager = manager
    self.voting_adapter = voting_adapter


@external
def deploy_vesting_contract(
    amount: uint256,
    recipient: address,
    vesting_duration: uint256,
    vesting_start: uint256 = block.timestamp,
    cliff_length: uint256 = 0,
    is_fully_revokable: bool = False,  # use ordinary escrow by default
) -> address:
    """
    @notice Deploy and fund a new vesting contract
    @param amount Amount of the tokens to be vested after fundings
    @param recipient Address to vest tokens for
    @param vesting_duration Time period over which tokens are released
    @param vesting_start Epoch time when tokens begin to vest
    @param cliff_length Duration after which the first portion vests
    @param is_fully_revokable Fully revockable flag
    """
    assert vesting_duration > 0, "incorrect vesting duration"
    assert cliff_length <= vesting_duration, "incorrect vesting cliff"
    escrow: address = create_minimal_proxy_to(self.target)

    assert ERC20(self.token).transferFrom(
        msg.sender, self, amount, default_return_value=True
    ), "transferFrom deployer failed"
    assert ERC20(self.token).approve(
        escrow, amount, default_return_value=True
    ), "approve to escrow failed"

    IVestingEscrow(escrow).initialize(
        self.token,
        amount,
        recipient,
        vesting_start,
        vesting_start + vesting_duration,
        cliff_length,
        is_fully_revokable,
        self,
    )
    log VestingEscrowCreated(
        msg.sender,
        escrow,
    )
    return escrow


@external
def recover_erc20(token: address, amount: uint256):
    """
    @notice Recover ERC20 tokens to owner
    @param token Address of the ERC20 token to be recovered
    """
    if amount != 0:
        assert ERC20(token).transfer(
            self.owner, amount, default_return_value=True
        ), "transfer failed"
        log ERC20Recovered(token, amount)


@external
def recover_ether():
    """
    @notice Recover Ether to owner
    """
    amount: uint256 = self.balance
    if amount != 0:
        self._safe_send_ether(self.owner, amount)
        log ETHRecovered(amount)


@external
def update_voting_adapter(voting_adapter: address):
    """
    @notice Update voting_adapter to be used by vestings
    @param voting_adapter Address of the new VotingAdapter implementation
    """
    self._check_sender_is_owner()
    self.voting_adapter = voting_adapter
    log VotingAdapterUpgraded(voting_adapter)


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
def change_manager(manager: address):
    """
    @notice Set contract manager.
            Can update manager if it is already set.
            Can be called only by the owner.
    @param manager Address of the new manager
    """
    self._check_sender_is_owner()

    self.manager = manager
    log ManagerChanged(manager)


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