# @version 0.3.1
"""
@title Token Minter
@author Versailles heroes
@license MIT
"""

interface Guild:
    # Presumably, other gauges will provide the same interfaces
    def integrate_fraction(addr: address) -> uint256: view
    def update_working_balance(addr: address) -> bool: nonpayable
    def user_checkpoint(addr: address) -> bool: nonpayable

interface MERC20:
    def mint(_to: address, _value: uint256) -> bool: nonpayable

interface GuildController:
    def set_minter(_minter: address): nonpayable
    def global_member_list(addr: address) -> address: view

interface RewardVestingEscrow:
    def balanceOf(_addr: address) -> uint256: view
    def vesting(_recipient: address, _amount: uint256) -> uint256: nonpayable
    def claim(addr: address) -> uint256: nonpayable

event Minted:
    recipient: indexed(address)
    guild: address
    vesting_locked: uint256
    minted: uint256

token: public(address)
controller: public(address)
rewardVestingEscrow: public(address)

# user -> guild -> value
minted: public(HashMap[address, HashMap[address, uint256]])

# minter -> user -> can mint?
allowed_to_mint_for: public(HashMap[address, HashMap[address, bool]])

@external
def __init__(_token: address, _controller: address, _rewardVestingEscrow: address):
    self.token = _token
    self.controller = _controller
    self.rewardVestingEscrow = _rewardVestingEscrow

@internal
def _mint_for(guild_addr: address, _for: address, leave_guild: bool):
    vested_claimable: uint256 = RewardVestingEscrow(self.rewardVestingEscrow).claim(_for) # claimable amount from existing vesting
    to_mint: uint256 = vested_claimable
    new_vested_locked: uint256 = 0

    if guild_addr != ZERO_ADDRESS: # user is in a guild
        if leave_guild:
            # update user's integrate_fraction to the latest without refreshing guild votes
            Guild(guild_addr).update_working_balance(_for)
        else:
            # update user's integrate_fraction to the latest and refresh guild votes
            Guild(guild_addr).user_checkpoint(_for)

        total_mint: uint256 = Guild(guild_addr).integrate_fraction(_for)
        mintable: uint256 = total_mint - self.minted[_for][guild_addr]

        if mintable > 0:
            new_vested_locked = RewardVestingEscrow(self.rewardVestingEscrow).vesting(_for, mintable) # new 70% locked amount
            immediate_release: uint256 = mintable - new_vested_locked # new 30% vested amount
            to_mint += immediate_release # inclusive of previous vested_claimable
            self.minted[_for][guild_addr] = total_mint
    
    if to_mint > 0:
        MERC20(self.token).mint(_for, to_mint)
        log Minted(_for, guild_addr, new_vested_locked, to_mint)


@external
@nonreentrant('lock')
def mint():
    """
    @notice Mint everything which belongs to `msg.sender` and send to them
    """
    guild_addr: address = GuildController(self.controller).global_member_list(msg.sender)
    self._mint_for(guild_addr, msg.sender, False)


@external
@nonreentrant('lock')
def mint_for(guild_addr: address, _for: address):
    """
    @notice Mint tokens for `_for`
    @dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
    @param guild_addr `Guild` address to get mintable amount from
    @param _for Address to mint to
    """
    
    # allowing GuildController to trigger mint via leave_guild function
    if msg.sender == self.controller or self.allowed_to_mint_for[msg.sender][_for]:
        self._mint_for(guild_addr, _for, False)


@external
@nonreentrant('lock')
def mint_from_controller(guild_addr: address, _for: address):
    """
    @notice Mint tokens from controller for `_for`
    @param guild_addr `Guild` address to get mintable amount from
    @param _for Address to mint to
    """
    
    assert msg.sender == self.controller # dev: GuildController only
    self._mint_for(guild_addr, _for, True)


@external
def toggle_approve_mint(minting_user: address):
    """
    @notice allow `minting_user` to mint for `msg.sender`
    @param minting_user Address to toggle permission for
    """
    
    self.allowed_to_mint_for[minting_user][msg.sender] = not self.allowed_to_mint_for[minting_user][msg.sender]