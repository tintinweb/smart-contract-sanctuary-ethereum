# @version 0.2.7
"""
@title Curve Fee Estimate
@author Ocean Protocol
@license MIT
"""

from vyper.interfaces import ERC20


interface VotingEscrow:
    def user_point_epoch(addr: address) -> uint256: view
    def epoch() -> uint256: view
    def user_point_history(addr: address, loc: uint256) -> Point: view
    def point_history(loc: uint256) -> Point: view
    def checkpoint(): nonpayable

interface FeeDistributor:
    def last_token_time() -> uint256: view
    def start_time() -> uint256: view
    def time_cursor() -> uint256: view
    def time_cursor_of(addr: address) -> uint256: view
    def user_epoch_of(addr: address) -> uint256: view
    def tokens_per_week(week: uint256) -> uint256: view
    def ve_supply(week: uint256) -> uint256: view
    def TOKEN_CHECKPOINT_DEADLINE() -> uint256: view

struct Point:
    bias: int128
    slope: int128  # - dweight / dt
    ts: uint256
    blk: uint256  # block


WEEK: constant(uint256) = 7 * 86400
TOKEN_CHECKPOINT_DEADLINE: constant(uint256) = 86400

voting_escrow: public(address)
fee_distributor: public(address)



@external
def __init__(
    _voting_escrow: address,
    _fee_distributor: address,
):
    """
    @notice Contract constructor
    @param _voting_escrow VotingEscrow contract address
    @param _fee_distributor FeeDistributor contract address
    """
    self.voting_escrow = _voting_escrow
    self.fee_distributor = _fee_distributor

@internal
def _find_timestamp_epoch(ve: address, _timestamp: uint256) -> uint256:
    _min: uint256 = 0
    _max: uint256 = VotingEscrow(ve).epoch()
    for i in range(128):
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 2) / 2
        pt: Point = VotingEscrow(ve).point_history(_mid)
        if pt.ts <= _timestamp:
            _min = _mid
        else:
            _max = _mid - 1
    return _min

@view
@internal
def _find_timestamp_user_epoch(ve: address, user: address, _timestamp: uint256, max_user_epoch: uint256) -> uint256:
    _min: uint256 = 0
    _max: uint256 = max_user_epoch
    for i in range(128):
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 2) / 2
        pt: Point = VotingEscrow(ve).user_point_history(user, _mid)
        if pt.ts <= _timestamp:
            _min = _mid
        else:
            _max = _mid - 1
    return _min



@external
@view
def estimateClaim(addr: address) -> uint256:
    # Minimal user_epoch is 0 (if user had no point)
    user_epoch: uint256 = 0
    to_distribute: uint256 = 0
    _last_token_time: uint256 = FeeDistributor(self.fee_distributor).last_token_time()
    max_user_epoch: uint256 = VotingEscrow(self.voting_escrow).user_point_epoch(addr)
    _start_time: uint256 = FeeDistributor(self.fee_distributor).start_time()
    
    # if checkpoints are missing, them we cannot have an accurate estimate
    # veFeeDistributor can do the checks, but requires tx and not just some call functions
    if block.timestamp >= FeeDistributor(self.fee_distributor).time_cursor():
        raise("Call checkpoint function")
    if block.timestamp > _last_token_time + TOKEN_CHECKPOINT_DEADLINE:
        raise("Call checkpoint function")

    # Round down to weeks
    _last_token_time = _last_token_time / WEEK * WEEK
    
    if max_user_epoch == 0:
        # No lock = no fees
        return 0

    week_cursor: uint256 = FeeDistributor(self.fee_distributor).time_cursor_of(addr)
    if week_cursor == 0:
        # Need to do the initial binary search
        user_epoch = self._find_timestamp_user_epoch(self.voting_escrow, addr, _start_time, max_user_epoch)
    else:
        user_epoch = FeeDistributor(self.fee_distributor).user_epoch_of(addr)

    if user_epoch == 0:
        user_epoch = 1

    user_point: Point = VotingEscrow(self.voting_escrow).user_point_history(addr, user_epoch)

    if week_cursor == 0:
        week_cursor = (user_point.ts + WEEK - 1) / WEEK * WEEK

    if week_cursor >= _last_token_time:
        return 0

    if week_cursor < _start_time:
        week_cursor = _start_time
    old_user_point: Point = empty(Point)

    # Iterate over weeks
    for i in range(50):
        if week_cursor >= _last_token_time:
            break

        if week_cursor >= user_point.ts and user_epoch <= max_user_epoch:
            user_epoch += 1
            old_user_point = user_point
            if user_epoch > max_user_epoch:
                user_point = empty(Point)
            else:
                user_point = VotingEscrow(self.voting_escrow).user_point_history(addr, user_epoch)

        else:
            # Calc
            # + i * 2 is for rounding errors
            dt: int128 = convert(week_cursor - old_user_point.ts, int128)
            balance_of: uint256 = convert(max(old_user_point.bias - dt * old_user_point.slope, 0), uint256)
            if balance_of == 0 and user_epoch > max_user_epoch:
                break
            if balance_of > 0:
                tokens_per_week: uint256 = FeeDistributor(self.fee_distributor).tokens_per_week(week_cursor)
                ve_supply: uint256 = FeeDistributor(self.fee_distributor).ve_supply(week_cursor)
                if ve_supply !=0 and tokens_per_week !=0:
                   to_distribute += balance_of *  tokens_per_week/ ve_supply

            week_cursor += WEEK


    return to_distribute