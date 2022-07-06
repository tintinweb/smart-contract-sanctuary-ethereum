# @version 0.3.1
"""
@title Guild
@author Versailles heroes
@license MIT
@notice Used for measuring owner and members rewards
"""

from vyper.interfaces import ERC20

interface VRH20:
    def future_epoch_time_write() -> uint256: nonpayable
    def rate() -> uint256: view

interface GuildController:
    def guild_relative_weight(addr: address, time: uint256) -> uint256: view
    def get_guild_weight(addr: address) -> uint256: view
    def add_member(guild_addr: address, user_addr: address): nonpayable
    def remove_member(user_addr: address): nonpayable
    def voting_escrow() -> address: view
    def gas_type_escrow(token: address) -> address: view
    def checkpoint_guild(addr: address): nonpayable
    def refresh_guild_votes(user_addr: address, guild_addr: address): nonpayable
    def belongs_to_guild(user_addr: address, guild_addr: address) -> bool: view

interface Minter:
    def minted(user: address, guild: address) -> uint256: view
    def controller() -> address: view
    def token() -> address: view
    def vestingEscrow() -> address: view

interface VotingEscrow:
    def user_point_epoch(addr: address) -> uint256: view
    def user_point_history__ts(addr: address, epoch: uint256) -> uint256: view

interface GasEscrow:
    def user_point_epoch(addr: address) -> uint256: view
    def user_point_history__ts(addr: address, epoch: uint256) -> uint256: view

interface RewardVestingEscrow:
    def claimable_tokens(addr: address) -> uint256: view


DECIMALS: constant(uint256) = 10 ** 18

TOKENLESS_PRODUCTION: constant(uint256) = 40
BOOST_WARMUP: constant(uint256) = 2 * 7 * 86400

minter: public(address)
vrh_token: public(address)
controller: public(address)
voting_escrow: public(address)
gas_escrow: public(address)
future_epoch_time: public(uint256)

working_balances: public(HashMap[address, uint256])
working_supply: public(uint256)
period_timestamp: public(uint256[100000000000000000000000000000])
period: public(int128)

last_change_rate: public(uint256)

# 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
integrate_inv_supply: public(uint256[100000000000000000000000000000])  # bump epoch when rate() changes

# 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
integrate_inv_supply_of: public(HashMap[address, uint256])
integrate_checkpoint_of: public(HashMap[address, uint256])

# ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
# Units: rate * t = already number of coins per address to issue
integrate_fraction: public(HashMap[address, uint256])

inflation_rate: public(uint256)
is_paused: public(bool)
WEEK: constant(uint256) = 604800
DAY: constant(uint256) = 86400

# guild variables
owner: public(address) # guild owner address

# Proportion of what the guild owner gets
commission_rate: public(HashMap[uint256, uint256])  # time -> commission_rate
total_owner_bonus: public(HashMap[address, uint256]) # owner address -> owner bonus

event UpdateLiquidityLimit:
    user: address
    original_balance: uint256
    original_supply: uint256
    working_balance: uint256
    working_supply: uint256

event TriggerPause:
    guild: address
    pause: bool

event SetCommissionRate:
    commission_rate: uint256
    effective_time: uint256

@external
def __init__():
    self.owner = msg.sender


@external
@nonreentrant('lock')
def initialize(_owner: address, _commission_rate: uint256, _token: address, _gas_escrow: address, _minter: address) -> bool:

    #@notice Initialize the contract to create a guild
    assert self.owner == ZERO_ADDRESS  # dev: can only initialize once

    self.is_paused = False
    self.owner = _owner
    self.period_timestamp[0] = block.timestamp

    assert _minter != ZERO_ADDRESS
    self.minter = _minter

    self.vrh_token = _token
    _controller: address = Minter(_minter).controller()
    self.controller = _controller
    self.voting_escrow = GuildController(_controller).voting_escrow()

    assert _gas_escrow != ZERO_ADDRESS
    self.gas_escrow = _gas_escrow

    assert _commission_rate >= 0 and _commission_rate <= 20, 'Rate has to be minimally 0% and maximum 20%'
    next_time: uint256 = (block.timestamp + WEEK) / WEEK * WEEK
    self.commission_rate[next_time] = _commission_rate
    self.last_change_rate = next_time # Record last updated commission rate
    self.inflation_rate = VRH20(self.vrh_token).rate()
    self.future_epoch_time = VRH20(self.vrh_token).future_epoch_time_write()

    return True


@internal
def _get_commission_rate():
    """
    @notice Fill historic commission rate week-over-week for missed checkins
            and return the commission rate for the future week
    """
    t: uint256 = self.last_change_rate
    if t > 0:
        w: uint256 = self.commission_rate[t]
        for i in range(500):
            if t > block.timestamp:
                break
            t += WEEK
            self.commission_rate[t] = w


@internal
def _checkpoint(addr: address):
    """
    @notice Checkpoint for a user
    @param addr User address
    """
    _token: address = self.vrh_token
    _controller: address = self.controller
    _period: int128 = self.period
    _period_time: uint256 = self.period_timestamp[_period]
    _integrate_inv_supply: uint256 = self.integrate_inv_supply[_period]
    _owner_bonus: uint256 = 0

    rate: uint256 = self.inflation_rate
    new_rate: uint256 = rate
    prev_future_epoch: uint256 = self.future_epoch_time
    if prev_future_epoch >= _period_time:
        self.future_epoch_time = VRH20(_token).future_epoch_time_write()
        new_rate = VRH20(_token).rate()
        self.inflation_rate = new_rate

    GuildController(_controller).checkpoint_guild(self)

    _working_balance: uint256 = self.working_balances[addr]
    _working_supply: uint256 = self.working_supply
    
    if self.is_paused:
        rate = 0  # Stop distributing inflation as soon as paused

    # Update integral of 1/supply
    if block.timestamp > _period_time:
        prev_week_time: uint256 = _period_time
        week_time: uint256 = min((_period_time + WEEK) / WEEK * WEEK, block.timestamp)

        # Fill missing check-in for commission rate
        self._get_commission_rate()

        for i in range(500):
            dt: uint256 = week_time - prev_week_time
            w: uint256 = GuildController(_controller).guild_relative_weight(self, prev_week_time / WEEK * WEEK)
            commission_rate: uint256 = self.commission_rate[prev_week_time / WEEK * WEEK]

            if _working_supply > 0:
                if prev_future_epoch >= prev_week_time and prev_future_epoch < week_time:
                    # If we went across one or multiple epochs, apply the rate
                    # of the first epoch until it ends, and then the rate of
                    # the last epoch.
                    # If more than one epoch is crossed - the gauge gets less,
                    # but that'd meen it wasn't called for more than 1 year
                    _integrate_inv_supply += rate * w * (prev_future_epoch - prev_week_time) / _working_supply * (100 - commission_rate) / 100
                    _owner_bonus += rate * w * (prev_future_epoch - prev_week_time) * commission_rate / 100
                    
                    rate = new_rate
                    _integrate_inv_supply += rate * w * (week_time - prev_future_epoch) / _working_supply * (100 - commission_rate) / 100
                    _owner_bonus += rate * w * (week_time - prev_future_epoch) * commission_rate / 100
                else:
                    _integrate_inv_supply += rate * w * dt / _working_supply * (100 - commission_rate) / 100
                    _owner_bonus += rate * w * dt * commission_rate / 100
                    
                # On precisions of the calculation
                # rate ~= 10e18
                # last_weight > 0.01 * 1e18 = 1e16 (if pool weight is 1%)
                # _working_supply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                # The largest loss is at dt = 1
                # Loss is 1e-9 - acceptable

            if week_time == block.timestamp:
                break
            prev_week_time = week_time
            week_time = min(week_time + WEEK, block.timestamp)

    _period += 1
    self.period = _period
    self.period_timestamp[_period] = block.timestamp
    self.integrate_inv_supply[_period] = _integrate_inv_supply

    # Update user-specific integrals
    # calculate owner bonus
    if _owner_bonus > 0:
        self.integrate_fraction[self.owner] += _owner_bonus / 10 ** 18
        self.total_owner_bonus[self.owner] += _owner_bonus / 10 ** 18

    # calculate for all members (including owner)
    self.integrate_fraction[addr] += _working_balance * (_integrate_inv_supply - self.integrate_inv_supply_of[addr]) / 10 ** 18
    self.integrate_inv_supply_of[addr] = _integrate_inv_supply
    self.integrate_checkpoint_of[addr] = block.timestamp


@external
def set_commission_rate(increase: bool):
    assert self.owner == msg.sender,'Only guild owner can change commission rate'
    assert block.timestamp >= self.last_change_rate, "Can only change commission rate once every week"
    
    next_time: uint256 = (block.timestamp + WEEK) / WEEK * WEEK
    commission_rate: uint256 = self.commission_rate[self.last_change_rate]

    # 0 == decrease, 1 equals increase
    if increase == True :
        commission_rate += 1
        assert commission_rate <= 20, 'Maximum is 20'
    else:
        commission_rate -= 1
        assert commission_rate >= 0, 'Minimum is 0'
    
    self.commission_rate[next_time] = commission_rate
    self.last_change_rate = next_time
    log SetCommissionRate(commission_rate, next_time)


@internal
def _update_liquidity_limit(addr: address, bu: uint256, S: uint256):
    """
    @notice Calculate limits which depend on the amount of VRH token per-user.
            Effectively it calculates working balances to apply amplification
            of veVRH production by gas
    @param addr User address
    @param bu User's amount of veVRH
    @param S Total amount of veVRH in a guild
    """
    # To be called after totalSupply is updated
    _gas_escrow: address = self.gas_escrow
    wi: uint256 = ERC20(_gas_escrow).balanceOf(addr) # gas balance of a user
    W: uint256 = ERC20(_gas_escrow).totalSupply() # gas total of all users

    lim: uint256 = bu * TOKENLESS_PRODUCTION / 100 # 0.4bu

    # Boost portion below : game tokens (gas)
    if (S > 0) and (block.timestamp > self.period_timestamp[0] + BOOST_WARMUP) and wi > 0:
        lim += S * wi / W * (100 - TOKENLESS_PRODUCTION) / 100

    lim = min(bu, lim)
    old_bal: uint256 = self.working_balances[addr]
    self.working_balances[addr] = lim
    _working_supply: uint256 = self.working_supply + lim - old_bal
    self.working_supply = _working_supply

    log UpdateLiquidityLimit(addr, bu, S, lim, _working_supply)


@external
def user_checkpoint(addr: address) -> bool:
    """
    @notice Record a checkpoint for `addr`
    @param addr User address
    @return bool success
    """
    assert (msg.sender == addr) or (msg.sender == self.minter)  # dev: unauthorized

    # check that user truly belongs to guild
    _controller: address = self.controller
    assert GuildController(_controller).belongs_to_guild(addr, self), "Not in guild"
    
    _user_voting_power: uint256 = ERC20(self.voting_escrow).balanceOf(addr)
    if _user_voting_power != 0:
        GuildController(_controller).refresh_guild_votes(addr, self)
    self._checkpoint(addr)
    _guild_voting_power: uint256 = GuildController(_controller).get_guild_weight(self)
    self._update_liquidity_limit(addr, _user_voting_power, _guild_voting_power)
    
    return True


@external
def update_working_balance(addr: address) -> bool:
    """
    @notice Record a checkpoint for `addr`
    @param addr User address
    @return bool success
    """
    assert msg.sender == self.minter  # dev: unauthorized

    _controller: address = self.controller
    assert GuildController(_controller).belongs_to_guild(addr, self), "Not in guild"

    self._checkpoint(addr)
    _user_voting_power: uint256 = ERC20(self.voting_escrow).balanceOf(addr)
    _guild_voting_power: uint256 = GuildController(_controller).get_guild_weight(self)
    self._update_liquidity_limit(addr, _user_voting_power, _guild_voting_power)
    return True


@external
def claimable_tokens(addr: address) -> uint256:
    """
    @notice Get the number of claimable tokens per user
    @dev This function should be manually changed to "view" in the ABI
    @return uint256 number of claimable tokens per user
    """
    self._checkpoint(addr)
    _vestingEscrow: address = Minter(self.minter).vestingEscrow()
    _vesting_claimable: uint256 = RewardVestingEscrow(_vestingEscrow).claimable_tokens(addr)
    return self.integrate_fraction[addr] - Minter(self.minter).minted(addr, self) + _vesting_claimable


@external
def kick(addr: address):
    """
    @notice Kick `addr` for abusing their boost
    @dev Only if either they had abusing gas boost, or their voting escrow lock expired
    @param addr Address to kick
    """

    _voting_escrow: address = self.voting_escrow
    _gas_escrow: address = self.gas_escrow
    t_last: uint256 = self.integrate_checkpoint_of[addr]
    t_gas: uint256 = GasEscrow(_gas_escrow).user_point_history__ts(
        addr, GasEscrow(_gas_escrow).user_point_epoch(addr))
    _balance: uint256 = ERC20(self.voting_escrow).balanceOf(addr)
    _gas_balance: uint256 = ERC20(self.gas_escrow).balanceOf(addr)

    assert (_balance == 0) or (_gas_balance == 0 or t_gas > t_last)  # dev: kick not allowed
    assert self.working_balances[addr] > _balance * 2 * TOKENLESS_PRODUCTION / 100 # dev: kick not needed

    self._checkpoint(addr)
    _user_voting_power: uint256 = _balance
    _guild_voting_power: uint256 = GuildController(self.controller).get_guild_weight(self)
    self._update_liquidity_limit(addr, _user_voting_power, _guild_voting_power)


@external
@nonreentrant('lock')
def join_guild():
    """
    @notice Join into this guild and start mining
    """
    addr: address = msg.sender
    GuildController(self.controller).add_member(self, addr)
    self._checkpoint(addr)
    _user_voting_power: uint256 = ERC20(self.voting_escrow).balanceOf(addr)
    _guild_voting_power: uint256 = GuildController(self.controller).get_guild_weight(self)
    self._update_liquidity_limit(addr, _user_voting_power, _guild_voting_power)


@external
@nonreentrant('lock')
def leave_guild():
    """
    @notice Leave this guild and stop mining
    """
    GuildController(self.controller).remove_member(msg.sender)
    _user_voting_power: uint256 = 0 # set user's working balance to 0 after minting remaining and leave guild
    _guild_voting_power: uint256 = GuildController(self.controller).get_guild_weight(self)
    self._update_liquidity_limit(msg.sender, _user_voting_power, _guild_voting_power)


@external
def transfer_ownership(new_owner: address):
    """
    @notice Transfer ownership of Guild to `new_owner`
    @param new_owner Address to have ownership transferred to
    """
    assert msg.sender == self.controller # only GuildController can access this
    old_owner: address = self.owner
    self._checkpoint(old_owner) # updates current owner integrate fraction and bonus before transferring ownership
    self.owner = new_owner


@external
def toggle_pause():
    assert msg.sender == self.controller # only GuildController can access this
    self.is_paused = not self.is_paused

    log TriggerPause(self, self.is_paused)