# @version 0.2.13
"""
@title Mirrored Voting Escrow
@author Hundred Finance
@license MIT
"""

interface VotingEscrow:
    def user_point_epoch(_user: address) -> uint256: view
    def get_last_user_slope(_addr: address) -> int128: view
    def user_point_history__ts(_addr: address, _idx: uint256) -> uint256: view
    def locked__end(_addr: address) -> uint256: view
    def totalSupply(_t: uint256) -> uint256: view
    def balanceOf(_addr: address, _t: uint256) -> uint256: view
    def decimals() -> uint256: view

struct Point:
    bias: int128
    slope: int128  # - dweight / dt
    ts: uint256
    blk: uint256  # block

struct LockedBalance:
    amount: int128
    end: uint256


admin: public(address)

voting_escrow: public(address)

whitelisted_mirrors: public(HashMap[address, bool])

mirrored_locks: public(HashMap[address, HashMap[uint256, LockedBalance]])

mirrored_chains_count: public(uint256)
mirrored_chains: public(uint256[500])

mirrored_user_point_history: public(HashMap[address, HashMap[uint256, Point[1000000000]]])  # user -> chain -> Point[user_epoch]
mirrored_user_point_epoch: public(HashMap[address, HashMap[uint256, uint256]])

mirrored_epoch: public(uint256)
mirrored_point_history: public(Point[100000000000000000000000000000])  # epoch -> unsigned point
mirrored_slope_changes: public(HashMap[uint256, int128])  # time -> signed slope change

name: public(String[64])
symbol: public(String[32])
version: public(String[32])
decimals: public(uint256)

WEEK: constant(uint256) = 7 * 86400  # all future times are rounded by week
MAXTIME: constant(uint256) = 4 * 365 * 86400  # 4 years
MULTIPLIER: constant(uint256) = 10 ** 18

@external
def __init__(_admin: address, _voting_escrow: address, _name: String[64], _symbol: String[32], _version: String[32]):
    self.admin = _admin

    self.name = _name
    self.symbol = _symbol
    self.version = _version
    self.decimals = VotingEscrow(_voting_escrow).decimals()

    self.voting_escrow = _voting_escrow


@internal
def _checkpoint(addr: address, _chain: uint256, old_locked: LockedBalance, new_locked: LockedBalance):
    """
    @notice Record global and per-user data to checkpoint
    @param addr User's wallet address. No user checkpoint if 0x0
    @param old_locked Pevious locked amount / end lock time for the user
    @param new_locked New locked amount / end lock time for the user
    """
    u_old: Point = empty(Point)
    u_new: Point = empty(Point)
    old_dslope: int128 = 0
    new_dslope: int128 = 0
    _epoch: uint256 = self.mirrored_epoch

    if addr != ZERO_ADDRESS:
        # Calculate slopes and biases
        # Kept at zero when they have to
        if old_locked.end > block.timestamp and old_locked.amount > 0:
            u_old.slope = old_locked.amount / MAXTIME
            u_old.bias = u_old.slope * convert(old_locked.end - block.timestamp, int128)
        if new_locked.end > block.timestamp and new_locked.amount > 0:
            u_new.slope = new_locked.amount / MAXTIME
            u_new.bias = u_new.slope * convert(new_locked.end - block.timestamp, int128)

        # Read values of scheduled changes in the slope
        # old_locked.end can be in the past and in the future
        # new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
        old_dslope = self.mirrored_slope_changes[old_locked.end]
        if new_locked.end != 0:
            if new_locked.end == old_locked.end:
                new_dslope = old_dslope
            else:
                new_dslope = self.mirrored_slope_changes[new_locked.end]

    last_point: Point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number})
    if _epoch > 0:
        last_point = self.mirrored_point_history[_epoch]
    last_checkpoint: uint256 = last_point.ts
    # initial_last_point is used for extrapolation to calculate block number
    # (approximately, for *At methods) and save them
    # as we cannot figure that out exactly from inside the contract
    initial_last_point: Point = last_point
    block_slope: uint256 = 0  # dblock/dt
    if block.timestamp > last_point.ts:
        block_slope = MULTIPLIER * (block.number - last_point.blk) / (block.timestamp - last_point.ts)
    # If last point is already recorded in this block, slope=0
    # But that's ok b/c we know the block in such case

    # Go over weeks to fill history and calculate what the current point is
    t_i: uint256 = (last_checkpoint / WEEK) * WEEK
    for i in range(255):
        # Hopefully it won't happen that this won't get used in 5 years!
        # If it does, users will be able to withdraw but vote weight will be broken
        t_i += WEEK
        d_slope: int128 = 0
        if t_i > block.timestamp:
            t_i = block.timestamp
        else:
            d_slope = self.mirrored_slope_changes[t_i]
        last_point.bias -= last_point.slope * convert(t_i - last_checkpoint, int128)
        last_point.slope += d_slope
        if last_point.bias < 0:  # This can happen
            last_point.bias = 0
        if last_point.slope < 0:  # This cannot happen - just in case
            last_point.slope = 0
        last_checkpoint = t_i
        last_point.ts = t_i
        last_point.blk = initial_last_point.blk + block_slope * (t_i - initial_last_point.ts) / MULTIPLIER
        _epoch += 1
        if t_i == block.timestamp:
            last_point.blk = block.number
            break
        else:
            self.mirrored_point_history[_epoch] = last_point

    self.mirrored_epoch = _epoch
    # Now point_history is filled until t=now

    if addr != ZERO_ADDRESS:
        # If last point was in this block, the slope change has been applied already
        # But in such case we have 0 slope(s)
        last_point.slope += (u_new.slope - u_old.slope)
        last_point.bias += (u_new.bias - u_old.bias)
        if last_point.slope < 0:
            last_point.slope = 0
        if last_point.bias < 0:
            last_point.bias = 0

    # Record the changed point into history
    self.mirrored_point_history[_epoch] = last_point

    if addr != ZERO_ADDRESS:
        # Schedule the slope changes (slope is going down)
        # We subtract new_user_slope from [new_locked.end]
        # and add old_user_slope to [old_locked.end]
        if old_locked.end > block.timestamp:
            # old_dslope was <something> - u_old.slope, so we cancel that
            old_dslope += u_old.slope
            if new_locked.end == old_locked.end:
                old_dslope -= u_new.slope  # It was a new deposit, not extension
            self.mirrored_slope_changes[old_locked.end] = old_dslope

        if new_locked.end > block.timestamp:
            if new_locked.end > old_locked.end:
                new_dslope -= u_new.slope  # old slope disappeared at this point
                self.mirrored_slope_changes[new_locked.end] = new_dslope
            # else: we recorded it already in old_dslope

        # Now handle user history
        user_epoch: uint256 = self.mirrored_user_point_epoch[addr][_chain] + 1

        self.mirrored_user_point_epoch[addr][_chain] = user_epoch
        u_new.ts = block.timestamp
        u_new.blk = block.number
        self.mirrored_user_point_history[addr][_chain][user_epoch] = u_new


@external
def mirror_lock(_user: address, _chain: uint256, _value: uint256, _unlock_time: uint256):
    assert self.whitelisted_mirrors[msg.sender] == True # dev: only whitelisted address can mirror locks

    old_locked: LockedBalance = self.mirrored_locks[_user][_chain]
    new_locked: LockedBalance = old_locked
    
    new_locked.amount = convert(_value, int128)
    new_locked.end = _unlock_time

    self.mirrored_locks[_user][_chain] = new_locked

    chain_already_mirrored: bool = False
    for i in range(499):
        if i >= self.mirrored_chains_count:
            break

        if self.mirrored_chains[i] == _chain:
            chain_already_mirrored = True
            break
    
    if not chain_already_mirrored:
        self.mirrored_chains[self.mirrored_chains_count] = _chain
        self.mirrored_chains_count += 1
    
    self._checkpoint(_user, _chain, old_locked, new_locked)


@external
@view
def user_point_epoch(_user: address, _chain: uint256 = 0) -> uint256:
    if _chain == 0:
        return VotingEscrow(self.voting_escrow).user_point_epoch(_user)

    return self.mirrored_user_point_epoch[_user][_chain]
    

@external
@view
def user_point_history__ts(_addr: address, _idx: uint256, _chain: uint256 = 0) -> uint256:
    if _chain == 0:
        return VotingEscrow(self.voting_escrow).user_point_history__ts(_addr, _idx)

    return self.mirrored_user_point_history[_addr][_chain][_idx].ts


@external
@view
def user_last_checkpoint_ts(_user: address) -> uint256:
    _epoch: uint256 = VotingEscrow(self.voting_escrow).user_point_epoch(_user)
    _ts: uint256 = VotingEscrow(self.voting_escrow).user_point_history__ts(_user, _epoch)

    for i in range(499):
        if i >= self.mirrored_chains_count:
            break

        _chain: uint256 = self.mirrored_chains[i]
        _chain_epoch: uint256 = self.mirrored_user_point_epoch[_user][_chain]
        _chain_ts: uint256 = self.mirrored_user_point_history[_user][_chain][_chain_epoch].ts

        if _chain_ts < _ts:
            _ts = _chain_ts
    
    return _ts


@internal
@view
def mirrored_supply_at(point: Point, t: uint256) -> uint256:
    """
    @notice Calculate total voting power at some point in the past
    @param point The point (bias/slope) to start search from
    @param t Time to calculate the total voting power at
    @return Total voting power at that time
    """
    last_point: Point = point
    t_i: uint256 = (last_point.ts / WEEK) * WEEK
    for i in range(255):
        t_i += WEEK
        d_slope: int128 = 0
        if t_i > t:
            t_i = t
        else:
            d_slope = self.mirrored_slope_changes[t_i]
        last_point.bias -= last_point.slope * convert(t_i - last_point.ts, int128)
        if t_i == t:
            break
        last_point.slope += d_slope
        last_point.ts = t_i

    if last_point.bias < 0:
        last_point.bias = 0
    return convert(last_point.bias, uint256)


@external
@view
def total_mirrored_supply(t: uint256 = block.timestamp) -> uint256:
    """
    @notice Calculate total voting power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total voting power
    """
    _epoch: uint256 = self.mirrored_epoch
    last_point: Point = self.mirrored_point_history[_epoch]
    return self.mirrored_supply_at(last_point, t)


@external
@view
def totalSupply(_t: uint256 = block.timestamp) -> uint256:
    _local_supply: uint256 = VotingEscrow(self.voting_escrow).totalSupply(_t)

    _epoch: uint256 = self.mirrored_epoch
    _last_point: Point = self.mirrored_point_history[_epoch]
    _mirrored_supply: uint256 = self.mirrored_supply_at(_last_point, _t)

    return _local_supply + _mirrored_supply


@internal
@view
def _mirrored_balance_of(addr: address, _t: uint256) -> uint256:
    _chain_count: uint256 = self.mirrored_chains_count
    _mirrored_balance: uint256 = 0

    for i in range(499):
        if i >= _chain_count:
            break

        _chain: uint256 = self.mirrored_chains[i]

        _chain_epoch: uint256 = self.mirrored_user_point_epoch[addr][_chain]
        if _chain_epoch > 0:
            _last_point: Point = self.mirrored_user_point_history[addr][_chain][_chain_epoch]
            _last_point.bias -= _last_point.slope * convert(_t - _last_point.ts, int128)
            if _last_point.bias < 0:
                _last_point.bias = 0
            _mirrored_balance += convert(_last_point.bias, uint256)

    return _mirrored_balance


@external
@view
def balanceOf(_addr: address, _t: uint256 = block.timestamp) -> uint256:
    _local_balance: uint256 = VotingEscrow(self.voting_escrow).balanceOf(_addr, _t)
    _mirrored_balance: uint256 = self._mirrored_balance_of(_addr, _t)

    return _local_balance + _mirrored_balance


@external
@view
def mirrored_balance_of(addr: address, _t: uint256) -> uint256:
    return self._mirrored_balance_of(addr, _t)


@external
@view
def locked__end(_addr: address, _chain: uint256 = 0) -> uint256:

    if _chain == 0:
        return VotingEscrow(self.voting_escrow).locked__end(_addr)

    return self.mirrored_locks[_addr][_chain].end


@external
@view
def nearest_locked__end(_addr: address) -> uint256:
    _lock_end: uint256 = VotingEscrow(self.voting_escrow).locked__end(_addr)
    _chain_count: uint256 = self.mirrored_chains_count
    for i in range(499):
        if i >= _chain_count:
            break
        
        _chain: uint256 = self.mirrored_chains[i]
        _chain_lock_end: uint256 = self.mirrored_locks[_addr][_chain].end
        if _chain_lock_end < _lock_end or _lock_end == 0:
            _lock_end = _chain_lock_end
    
    return _lock_end

@external
@view
def get_last_user_slope(_addr: address, _chain: uint256 = 0) -> int128:
    if _chain == 0:
        return VotingEscrow(self.voting_escrow).get_last_user_slope(_addr)
    
    _chain_uepoch: uint256 = self.mirrored_user_point_epoch[_addr][_chain]
    return self.mirrored_user_point_history[_addr][_chain][_chain_uepoch].slope


@external
def set_admin(_new_admin: address):
    assert msg.sender == self.admin # dev: only admin

    self.admin = _new_admin

@external
def set_mirror_whitelist(_addr: address, _is_whitelisted: bool):
    assert msg.sender == self.admin # dev: only admin

    self.whitelisted_mirrors[_addr] = _is_whitelisted