# @version 0.3.1
"""
@title Guild Controller
@author Versailles heroes
@license MIT
@notice Controls guilds and the issuance of coins through the guilds
"""

# 7 * 86400 seconds - all future times are rounded by week
WEEK: constant(uint256) = 604800

# Cannot change weight votes more often than once in 10 days
WEIGHT_VOTE_DELAY: constant(uint256) = 10 * 86400
REQUIRED_CRITERIA: constant(uint256) = 100000

struct Point:
    bias: uint256
    slope: uint256

struct VotedSlope:
    slope: uint256
    end: uint256


interface VotingEscrow:
    def balanceOf(addr: address, _t: uint256 = block.timestamp) -> uint256: view   
    def get_last_user_slope(addr: address) -> int128: view
    def locked__end(addr: address) -> uint256: view

interface Guild:
    def initialize(_admin: address, _commission_rate: uint256, _token: address, _game_token: address, _minter: address) -> bool: nonpayable
    def transfer_ownership(new_owner: address): nonpayable
    def toggle_pause(): nonpayable

interface GasEscrow:
    def initialize(_admin: address, _token: address, _name: String[64], _symbol: String[32]) -> bool: nonpayable

interface Minter:
    def mint_from_controller(guild_addr: address, _for: address): nonpayable

event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address

event CommitCreateGuildOwnership:
    create_guild_admin: address

event ApplyCreateGuildOwnership:
    create_guild_admin: address

event AddType:
    name: String[64]
    type_id: int128
    gas_addr: address
    weight: uint256
    gas_escrow: address

event NewTypeWeight:
    type_id: int128
    time: uint256
    weight: uint256
    total_weight: uint256

event NewGuildWeight:
    guild_address: address
    time: uint256
    weight: uint256
    total_weight: uint256

event VoteForGuild:
    time: uint256
    user: address
    guild_addr: address
    vote: bool
    voting_weight: uint256

event NewGuild:
    addr: address
    user_voting_power: uint256
    rate: uint256

event AddMember:
    guild_addr: indexed(address)
    member_addr: indexed(address)

event RemoveMember:
    guild_addr: indexed(address)
    member_addr: indexed(address)

event SetMinter:
    minter: address

event TransferGuildOwnership:
    guild: address
    from_addr: address
    to_addr: address

event ChangeGuildContract:
    old_addr: address
    new_addr: address

event ChangeGasEscrowContract:
    old_addr: address
    new_addr: address

MULTIPLIER: constant(uint256) = 10 ** 18
    
admin: public(address)  # Can and will be a smart contract
future_admin: public(address)  # Can and will be a smart contract

create_guild_admin: public(address)  # Can and will be a smart contract
future_create_guild_admin: public(address)  # Can and will be a smart contract

token: public(address) # VRH token
voting_escrow: public(address)  # Voting escrow
guild: public(address) # guild contract address
gas_escrow: public(address)  # Gas escrow
gas_type_escrow: public(HashMap[int128, address])
gas_addr_escrow: public(HashMap[address, address])
minter: public(address)

guild_owner_list: public(HashMap[address, address]) # guild owner -> guild addr
global_member_list: public(HashMap[address, address]) # member_addr -> guild_addr

# Guild parameters
# All numbers are "fixed point" on the basis of 1e18
n_guild_types: public(int128)
n_guilds: public(int128)
guild_type_names: public(HashMap[int128, String[64]])

# Needed for enumeration
guilds: public(address[1000000000])

# we increment values by 1 prior to storing them here so we can rely on a value
# of zero as meaning the guild has not been set
guild_types_: HashMap[address, int128]

vote_user_slopes: public(HashMap[address, HashMap[address, VotedSlope]])  # user -> guild_addr -> VotedSlope
last_user_join: public(HashMap[address, HashMap[address, uint256]])  # Last user join's timestamp for each guild address

points_weight: public(HashMap[address, HashMap[uint256, Point]])  # guild_addr -> time -> Point
changes_weight: HashMap[address, HashMap[uint256, uint256]]  # guild_addr -> time -> slope
time_weight: public(HashMap[address, uint256])  # guild_addr -> last scheduled time (next week)

points_sum: public(HashMap[int128, HashMap[uint256, Point]])  # type_id -> time -> Point
changes_sum: HashMap[int128, HashMap[uint256, uint256]]  # type_id -> time -> slope
time_sum: public(uint256[1000000000])  # type_id -> last scheduled time (next week)

points_total: public(HashMap[uint256, uint256])  # time -> total weight
time_total: public(uint256)  # last scheduled time

points_type_weight: public(HashMap[int128, HashMap[uint256, uint256]])  # type_id -> time -> type weight
time_type_weight: public(uint256[1000000000])  # type_id -> last scheduled time (next week)


@external
def __init__(_token: address, _voting_escrow: address, _guild: address, _gas_escrow: address):
    """
    @notice Contract constructor
    @param _token `ERC20VRH` contract address
    @param _voting_escrow `VotingEscrow` contract address
    @param _guild `Guild` contract address
    @param _gas_escrow `GasEscrow` contract address
    """
    assert _token != ZERO_ADDRESS
    assert _voting_escrow != ZERO_ADDRESS
    assert _guild != ZERO_ADDRESS
    assert _gas_escrow != ZERO_ADDRESS

    self.admin = msg.sender
    self.create_guild_admin = msg.sender
    self.token = _token
    self.voting_escrow = _voting_escrow
    self.guild = _guild
    self.gas_escrow = _gas_escrow
    self.time_total = block.timestamp / WEEK * WEEK


@external
def set_minter(_minter: address):
    assert msg.sender == self.admin
    assert self.minter == ZERO_ADDRESS
    self.minter = _minter
    log SetMinter(_minter)


@external
def commit_transfer_ownership(addr: address):
    """
    @notice Transfer ownership of GuildController to `addr`
    @param addr Address to have ownership transferred to
    """
    assert msg.sender == self.admin  # dev: admin only
    self.future_admin = addr
    log CommitOwnership(addr)


@external
def apply_transfer_ownership():
    """
    @notice Apply pending ownership transfer
    """
    assert msg.sender == self.admin  # dev: admin only
    _admin: address = self.future_admin
    assert _admin != ZERO_ADDRESS  # dev: admin not set
    self.admin = _admin
    log ApplyOwnership(_admin)


@external
def commit_transfer_create_guild_ownership(addr: address):
    """
    @notice Transfer ownership of GuildController to `addr`
    @param addr Address to have ownership transferred to
    """
    assert msg.sender == self.admin  # dev: admin only
    self.future_create_guild_admin = addr
    log CommitCreateGuildOwnership(addr)


@external
def apply_transfer_create_guild_ownership():
    """
    @notice Apply pending ownership transfer
    """
    assert msg.sender == self.admin  # dev: admin only
    _create_guild_admin: address = self.future_create_guild_admin
    assert _create_guild_admin != ZERO_ADDRESS  # dev: create guild admin not set
    self.create_guild_admin = _create_guild_admin
    log ApplyCreateGuildOwnership(_create_guild_admin)


@external
@view
def guild_types(_addr: address) -> int128:
    """
    @notice Get guild type for address
    @param _addr Guild address
    @return Guild type id
    """
    guild_type: int128 = self.guild_types_[_addr]
    assert guild_type != 0

    return guild_type - 1


@internal
def _get_type_weight(guild_type: int128) -> uint256:
    """
    @notice Fill historic type weights week-over-week for missed checkins
            and return the type weight for the future week
    @param guild_type Guild type id
    @return Type weight
    """
    t: uint256 = self.time_type_weight[guild_type]
    if t > 0:
        w: uint256 = self.points_type_weight[guild_type][t]
        for i in range(500):
            if t > block.timestamp:
                break
            t += WEEK
            self.points_type_weight[guild_type][t] = w
            if t > block.timestamp:
                self.time_type_weight[guild_type] = t
        return w
    else:
        return 0


@internal
def _get_sum(guild_type: int128) -> uint256:
    """
    @notice Fill sum of guild weights for the same type week-over-week for
            missed checkins and return the sum for the future week
    @param type Guild type id
    @return Sum of weights
    """
    t: uint256 = self.time_sum[guild_type]
    if t > 0:
        pt: Point = self.points_sum[guild_type][t]
        for i in range(500):
            if t > block.timestamp:
                break
            t += WEEK
            d_bias: uint256 = pt.slope * WEEK
            if pt.bias > d_bias:
                pt.bias -= d_bias
                d_slope: uint256 = self.changes_sum[guild_type][t]
                pt.slope -= d_slope
            else:
                pt.bias = 0
                pt.slope = 0
            self.points_sum[guild_type][t] = pt
            if t > block.timestamp:
                self.time_sum[guild_type] = t
        return pt.bias
    else:
        return 0


@internal
def _get_total() -> uint256:
    """
    @notice Fill historic total weights week-over-week for missed checkins
            and return the total for the future week
    @return Total weight
    """
    t: uint256 = self.time_total
    _n_guild_types: int128 = self.n_guild_types
    if t > block.timestamp:
        # If we have already checkpointed - still need to change the value
        t -= WEEK
    pt: uint256 = self.points_total[t]

    for guild_type in range(100):
        if guild_type == _n_guild_types:
            break
        self._get_sum(guild_type)
        self._get_type_weight(guild_type)

    for i in range(500):
        if t > block.timestamp:
            break
        t += WEEK
        pt = 0
        # Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
        for guild_type in range(100):
            if guild_type == _n_guild_types:
                break
            type_sum: uint256 = self.points_sum[guild_type][t].bias
            type_weight: uint256 = self.points_type_weight[guild_type][t]
            pt += type_sum * type_weight
        self.points_total[t] = pt

        if t > block.timestamp:
            self.time_total = t
    return pt


@internal
def _get_weight(guild_addr: address) -> uint256:
    """
    @notice Fill historic guild weights week-over-week for missed checkins
            and return the total for the future week
    @param guild_addr Address of the guild
    @return Guild weight
    """
    t: uint256 = self.time_weight[guild_addr]
    if t > 0:
        pt: Point = self.points_weight[guild_addr][t]
        for i in range(500):
            if t > block.timestamp:
                break
            t += WEEK
            d_bias: uint256 = pt.slope * WEEK
            if pt.bias > d_bias:
                pt.bias -= d_bias
                d_slope: uint256 = self.changes_weight[guild_addr][t]
                pt.slope -= d_slope
            else:
                pt.bias = 0
                pt.slope = 0
            self.points_weight[guild_addr][t] = pt
            if t > block.timestamp:
                self.time_weight[guild_addr] = t
        return pt.bias
    else:
        return 0


@external
@nonreentrant('lock')
def create_guild(owner: address, guild_type: int128, commission_rate: uint256) -> address:
    """
    @notice Add guild with type `guild_type` and guild owner commission rate `rate`
    @param owner Owner address
    @param guild_type Guild type
    @param commission_rate Guild owner commission rate
    """
    assert msg.sender == self.create_guild_admin
    assert (guild_type >= 0) and (guild_type < self.n_guild_types), "Guild type not supported"
    assert self.global_member_list[owner] == ZERO_ADDRESS, "Already in a guild"
    assert self.guild_owner_list[owner] == ZERO_ADDRESS, "Only can create one guild"

    # Check if game token is supported
    gas_escrow: address = self.gas_type_escrow[guild_type]
    assert gas_escrow != ZERO_ADDRESS, "Guild type is not supported"
    
    # Retrieve guild owner voting power
    weight: uint256 = VotingEscrow(self.voting_escrow).balanceOf(owner)
    assert weight >= REQUIRED_CRITERIA * MULTIPLIER, "Does not meet requirement to create guild"

    # Check if user has created a guild before or not
    guild_address: address = create_forwarder_to(self.guild)
    _isSuccess: bool = Guild(guild_address).initialize(owner, commission_rate, self.token, gas_escrow, self.minter)

    next_time: uint256 = (block.timestamp + WEEK) / WEEK * WEEK
    if self.time_sum[guild_type] == 0:
        self.time_sum[guild_type] = next_time
    self.time_weight[guild_address] = next_time

    if _isSuccess:
        n: int128 = self.n_guilds
        self.n_guilds = n + 1
        self.guilds[n] = guild_address

        self.guild_types_[guild_address] = guild_type + 1
        self.guild_owner_list[owner] = guild_address
        self.global_member_list[owner] = guild_address
        self.last_user_join[owner][guild_address] = block.timestamp
        log NewGuild(guild_address, weight, commission_rate)
        return guild_address

    return ZERO_ADDRESS


@external
def checkpoint():
    """
    @notice Checkpoint to fill data common for all guilds
    """
    self._get_total()


@external
def checkpoint_guild(addr: address):
    """
    @notice Checkpoint to fill data for both a specific guild and common for all guilds
    @param addr Guild address
    """
    self._get_weight(addr)
    self._get_total()


@internal
@view
def _guild_relative_weight(addr: address, time: uint256) -> uint256:
    """
    @notice Get Guild relative weight (not more than 1.0) normalized to 1e18
            (e.g. 1.0 == 1e18). Inflation which will be received by it is
            inflation_rate * relative_weight / 1e18
    @param addr Guild address
    @param time Relative weight at the specified timestamp in the past or present
    @return Value of relative weight normalized to 1e18
    """
    t: uint256 = time / WEEK * WEEK
    _total_weight: uint256 = self.points_total[t]

    if _total_weight > 0:
        guild_type: int128 = self.guild_types_[addr] - 1
        _type_weight: uint256 = self.points_type_weight[guild_type][t]
        _guild_weight: uint256 = self.points_weight[addr][t].bias
        return MULTIPLIER * _type_weight * _guild_weight / _total_weight

    else:
        return 0


@external
@view
def guild_relative_weight(addr: address, time: uint256 = block.timestamp) -> uint256:
    """
    @notice Get Guild relative weight (not more than 1.0) normalized to 1e18
            (e.g. 1.0 == 1e18). Inflation which will be received by it is
            inflation_rate * relative_weight / 1e18
    @param addr Guild address
    @param time Relative weight at the specified timestamp in the past or present
    @return Value of relative weight normalized to 1e18
    """
    return self._guild_relative_weight(addr, time)


@external
@view
def guild_effective_weight(addr: address, time: uint256 = block.timestamp) -> uint256:
    """
    @notice Get Guild effective weight in current epoch
    @param addr Guild address
    @param time Effective weight at the specified timestamp in the past or present
    @return Value of effective weight normalized to 1e18
    """
    t: uint256 = time / WEEK * WEEK
    _guild_weight: uint256 = self.points_weight[addr][t].bias

    return _guild_weight


@external
def guild_relative_weight_write(addr: address, time: uint256 = block.timestamp) -> uint256:
    """
    @notice Get guild weight normalized to 1e18 and also fill all the unfilled
            values for type and guild records
    @dev Any address can call, however nothing is recorded if the values are filled already
    @param addr Guild address
    @param time Relative weight at the specified timestamp in the past or present
    @return Value of relative weight normalized to 1e18
    """
    self._get_weight(addr)
    self._get_total()  # Also calculates get_sum
    return self._guild_relative_weight(addr, time)




@internal
def _change_type_weight(type_id: int128, weight: uint256):
    """
    @notice Change type weight
    @param type_id Type id
    @param weight New type weight
    """
    old_weight: uint256 = self._get_type_weight(type_id)
    old_sum: uint256 = self._get_sum(type_id)
    _total_weight: uint256 = self._get_total()
    next_time: uint256 = (block.timestamp + WEEK) / WEEK * WEEK

    _total_weight = _total_weight + old_sum * weight - old_sum * old_weight
    self.points_total[next_time] = _total_weight
    self.points_type_weight[type_id][next_time] = weight
    self.time_total = next_time
    self.time_type_weight[type_id] = next_time

    log NewTypeWeight(type_id, next_time, weight, _total_weight)


@external
def add_type(_name: String[64], _symbol: String[32], gas_addr: address, weight: uint256 = 0):
    """
    @notice Add guild type with name `_name` and weight `weight`
    @param _name Name of guild type
    @param gas_addr Address of the gas token
    @param weight Weight of guild type
    """
    assert msg.sender == self.admin
    assert self.gas_addr_escrow[gas_addr] == ZERO_ADDRESS, "Already has gas escrow" # one gas token can only have one gas escrow

    escrow_addr: address = create_forwarder_to(self.gas_escrow)
    _isSuccess: bool = GasEscrow(escrow_addr).initialize(self.admin, gas_addr, _name, _symbol)

    if _isSuccess:
        type_id: int128 = self.n_guild_types
        self.guild_type_names[type_id] = _name
        self.n_guild_types = type_id + 1
        if weight != 0:
            self._change_type_weight(type_id, weight)
            self.gas_type_escrow[type_id] = escrow_addr
            self.gas_addr_escrow[gas_addr] = escrow_addr
            log AddType(_name, type_id, gas_addr, weight, escrow_addr)


@external
def change_type_weight(type_id: int128, weight: uint256):
    """
    @notice Change guild type `type_id` weight to `weight`
    @param type_id Guild type id
    @param weight New Guild weight
    """
    assert msg.sender == self.admin
    self._change_type_weight(type_id, weight)


@internal
def _change_guild_weight(addr: address, weight: uint256):
    # Change guild weight
    # Only needed when testing in reality
    guild_type: int128 = self.guild_types_[addr] - 1
    old_guild_weight: uint256 = self._get_weight(addr)
    type_weight: uint256 = self._get_type_weight(guild_type)
    old_sum: uint256 = self._get_sum(guild_type)
    _total_weight: uint256 = self._get_total()
    next_time: uint256 = (block.timestamp + WEEK) / WEEK * WEEK

    self.points_weight[addr][next_time].bias = weight
    self.time_weight[addr] = next_time

    new_sum: uint256 = old_sum + weight - old_guild_weight
    self.points_sum[guild_type][next_time].bias = new_sum
    self.time_sum[guild_type] = next_time

    _total_weight = _total_weight + new_sum * type_weight - old_sum * type_weight
    self.points_total[next_time] = _total_weight
    self.time_total = next_time

    log NewGuildWeight(addr, block.timestamp, weight, _total_weight)


@external
def change_guild_weight(addr: address, weight: uint256):
    """
    @notice Change weight of guild `addr` to `weight`
    @param addr `GuildController` contract address
    @param weight New Guild weight
    """
    assert msg.sender == self.admin
    self._change_guild_weight(addr, weight)


@internal
def _vote_for_guild(user_addr: address, guild_addr: address, vote: bool):
    """
    @notice Allocate voting power to guilds
    @param user_addr User's address
    @param guild_addr Guild which `user_addr` votes for
    @param vote Indicates whether to vote for the guild (True) or remove all votes (False)
    """
    escrow: address = self.voting_escrow
    slope: uint256 = convert(VotingEscrow(escrow).get_last_user_slope(user_addr), uint256)
    lock_end: uint256 = VotingEscrow(escrow).locked__end(user_addr)
    _n_guilds: int128 = self.n_guilds
    next_time: uint256 = (block.timestamp + WEEK) / WEEK * WEEK
    assert lock_end > next_time, "Your token lock expires too soon"
    
    guild_type: int128 = self.guild_types_[guild_addr] - 1
    assert guild_type >= 0, "Guild not added"
    # Prepare slopes and biases in memory
    old_slope: VotedSlope = self.vote_user_slopes[user_addr][guild_addr]
    old_dt: uint256 = 0
    if old_slope.end > next_time:
        old_dt = old_slope.end - next_time
    old_bias: uint256 = old_slope.slope * old_dt # previous user's remaining vote weight
    _user_weight: uint256 = convert(vote, uint256)
    new_slope: VotedSlope = VotedSlope({
        slope: slope * _user_weight,
        end: lock_end
    })
    new_dt: uint256 = lock_end - next_time
    new_bias: uint256 = new_slope.slope * new_dt

    ## Remove old and schedule new slope changes
    # Remove slope changes for old slopes
    # Schedule recording of initial slope for next_time
    old_weight_bias: uint256 = self._get_weight(guild_addr)
    old_weight_slope: uint256 = self.points_weight[guild_addr][next_time].slope
    old_sum_bias: uint256 = self._get_sum(guild_type)
    old_sum_slope: uint256 = self.points_sum[guild_type][next_time].slope

    self.points_weight[guild_addr][next_time].bias = max(old_weight_bias + new_bias, old_bias) - old_bias
    self.points_sum[guild_type][next_time].bias = max(old_sum_bias + new_bias, old_bias) - old_bias
    if old_slope.end > next_time:
        self.points_weight[guild_addr][next_time].slope = max(old_weight_slope + new_slope.slope, old_slope.slope) - old_slope.slope
        self.points_sum[guild_type][next_time].slope = max(old_sum_slope + new_slope.slope, old_slope.slope) - old_slope.slope
    else:
        self.points_weight[guild_addr][next_time].slope += new_slope.slope
        self.points_sum[guild_type][next_time].slope += new_slope.slope
    if old_slope.end > block.timestamp:
        # Cancel old slope changes if they still didn't happen
        self.changes_weight[guild_addr][old_slope.end] -= old_slope.slope
        self.changes_sum[guild_type][old_slope.end] -= old_slope.slope
    # Add slope changes
    self.changes_weight[guild_addr][new_slope.end] += new_slope.slope
    self.changes_sum[guild_type][new_slope.end] += new_slope.slope

    self._get_total()

    self.vote_user_slopes[user_addr][guild_addr] = new_slope

    log VoteForGuild(block.timestamp, user_addr, guild_addr, vote, new_bias)


@external
@view
def get_guild_weight(addr: address) -> uint256:
    """
    @notice Get current guild weight
    @param addr Guild address
    @return Guild weight
    """
    return self.points_weight[addr][self.time_weight[addr]].bias


@external
@view
def get_type_weight(type_id: int128) -> uint256:
    """
    @notice Get current type weight
    @param type_id Type id
    @return Type weight
    """
    return self.points_type_weight[type_id][self.time_type_weight[type_id]]


@external
@view
def get_total_weight() -> uint256:
    """
    @notice Get current total (type-weighted) weight
    @return Total weight
    """
    return self.points_total[self.time_total]


@external
@view
def get_weights_sum_per_type(type_id: int128) -> uint256:
    """
    @notice Get sum of guild weights per type
    @param type_id Type id
    @return Sum of guild weights
    """
    return self.points_sum[type_id][self.time_sum[type_id]].bias
    

@external 
def refresh_guild_votes(user_addr: address, guild_addr: address):
    assert msg.sender == guild_addr # dev: guild access only
    _guild_addr: address = self.global_member_list[user_addr]
    assert _guild_addr != ZERO_ADDRESS and _guild_addr == guild_addr, "User not in guild"
    self._vote_for_guild(user_addr, guild_addr, True)


@external
@view
def belongs_to_guild(user_addr: address, guild_addr: address) -> bool:
    return self.global_member_list[user_addr] == guild_addr


@external
def add_member(guild_addr: address, user_addr: address):
    guild_type: int128 = self.guild_types_[guild_addr] - 1
    assert guild_type >= 0, "Not a guild"
    assert msg.sender == guild_addr # dev: guild access only
    assert user_addr != ZERO_ADDRESS, "Not valid address"
    assert self.global_member_list[user_addr] == ZERO_ADDRESS, "Already in a guild"
    assert VotingEscrow(self.voting_escrow).balanceOf(user_addr) > 0, "Insufficient votes"

    self._vote_for_guild(user_addr, guild_addr, True)
    self.last_user_join[user_addr][guild_addr] = block.timestamp
    self.global_member_list[user_addr] = guild_addr
    log AddMember(guild_addr, user_addr)


@external
def remove_member(user_addr: address):
    guild_addr: address = msg.sender # dev: guild access only
    assert self.global_member_list[user_addr] == guild_addr, "Cannot access other guilds"
    assert self.guild_owner_list[user_addr] == ZERO_ADDRESS, "Owner cannot leave guild"
    assert block.timestamp >= self.last_user_join[user_addr][guild_addr] + WEIGHT_VOTE_DELAY, "Leave guild too soon"

    Minter(self.minter).mint_from_controller(guild_addr, user_addr) # to mint before leaving guild
    _balance: uint256 = VotingEscrow(self.voting_escrow).balanceOf(user_addr)

    # if balance is already 0, vote_for_guild is not necessary as 
    # Minter.mint_for will perform checkpoint_guild to decay guild votes
    if _balance != 0:
        self._vote_for_guild(user_addr, guild_addr, False)
    self.global_member_list[user_addr] = ZERO_ADDRESS
    log RemoveMember(guild_addr, user_addr)


@external
def transfer_guild_ownership(new_owner: address):
    """
    @notice Transfer ownership of Guild to `new_owner`, if new_owner is ZERO_ADDRESS, it will give up owner privilege and irreversible
    @param new_owner Address to have ownership transferred to
    """
    old_owner: address = msg.sender
    assert old_owner != new_owner # dev: tx sender cannot transfer to himself
    guild_addr: address = self.guild_owner_list[msg.sender]
    assert guild_addr != ZERO_ADDRESS, "Not an owner"
    if new_owner != ZERO_ADDRESS:
        assert self.guild_owner_list[new_owner] == ZERO_ADDRESS, "New owner cannot be an owner of another guild"
        assert guild_addr == self.global_member_list[new_owner], "New owner is not in the same guild"

        # Check if new owner fulfils create_guild requirements
        weight: uint256 = VotingEscrow(self.voting_escrow).balanceOf(new_owner)
        assert weight >= REQUIRED_CRITERIA * MULTIPLIER, "New owner does not meet requirement to take over guild"

    Guild(guild_addr).transfer_ownership(new_owner)
    self.guild_owner_list[old_owner] = ZERO_ADDRESS
    if new_owner != ZERO_ADDRESS:
        self.guild_owner_list[new_owner] = guild_addr
    log TransferGuildOwnership(guild_addr, old_owner, new_owner)
    

@external
def toggle_pause(guild_addr: address):
    assert msg.sender == self.admin
    Guild(guild_addr).toggle_pause()


@external
def change_guild_contract(new_addr: address):
    assert msg.sender == self.admin # only admin can access
    assert new_addr != ZERO_ADDRESS # new guild address cannot be empty

    old_addr: address = self.guild
    self.guild = new_addr
    log ChangeGuildContract(old_addr, new_addr)


@external
def change_gas_escrow_contract(new_addr: address):
    assert msg.sender == self.admin # only admin can access
    assert new_addr != ZERO_ADDRESS # new gas escrow address cannot be empty

    old_addr: address = self.gas_escrow
    self.gas_escrow = new_addr
    log ChangeGasEscrowContract(old_addr, new_addr)