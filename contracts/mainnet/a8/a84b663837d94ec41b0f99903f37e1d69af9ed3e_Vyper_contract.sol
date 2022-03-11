# @version 0.3.1
"""
@title HarvestForwarder
@author mitche50
@notice Forwards tokens to BadgerTree with accompanying Harvest event
"""

from vyper.interfaces import ERC20


event TreeDistribution:
    token: indexed(address)
    amount: uint256
    block_number: indexed(uint256)
    block_timestamp: uint256
    beneficiary: address

event TreeUpdate:
    old_tree: address
    new_tree: address

event OwnerUpdate:
    old_owner: address
    new_owner: address

event Sweep:
    _token: address
    balance_before: uint256


owner: public(address)
badger_tree: public(address)


@external
def __init__(
    _owner: address,
    _tree: address,
):
    """
    @notice Contract constructor
    @param _owner Contract owner address
    @param _tree Address of the BadgerTree
    """
    assert _owner != ZERO_ADDRESS, "Owner must be defined"
    assert _tree != ZERO_ADDRESS, "Tree must be defined"

    self.owner = _owner
    self.badger_tree = _tree


@nonreentrant('distribute')
@external
def distribute(
    _token: address,
    _amount: uint256,
    _beneficiary: address
):
    """
    @notice Distribute token of certain amount to beneficiary vault as a harvest
    @param _token Token to be distributed
    @param _amount Amount to be distributed
    @param _beneficiary Vault address to distribute to
    """
    ERC20(_token).transferFrom(msg.sender, self.badger_tree, _amount)

    log TreeDistribution(_token, _amount, block.number, block.timestamp, _beneficiary)


### Admin functions ###
@external
def set_tree(_address: address):
    """
    @notice Update the badger tree
    @param _address Address of new badger tree
    """
    assert msg.sender == self.owner, '!owner' # dev: only owner

    current_tree: address = self.badger_tree
    self.badger_tree = _address

    log TreeUpdate(current_tree, self.badger_tree)


@external
def set_owner(_address: address):
    """
    @notice Update the owner of the contract
    @param _address Address of the new owner
    """
    assert msg.sender == self.owner, "!owner" # def: only owner

    current_owner: address = self.owner
    self.owner = _address

    log OwnerUpdate(current_owner, self.owner)


@nonreentrant('sweep')
@external
def sweep(_token: address):
    """
    @notice Sweep funds to owner address as nothing should be in contract
    @param _token Token to sweep
    """
    assert msg.sender == self.owner, '!owner' #dev: only owner

    # Sweep the entire balance of the token to the owner address
    balance_before: uint256 = ERC20(_token).balanceOf(self)
    assert balance_before > 0, 'No Token Balance'

    ERC20(_token).transfer(self.owner, balance_before)

    log Sweep(_token, balance_before)