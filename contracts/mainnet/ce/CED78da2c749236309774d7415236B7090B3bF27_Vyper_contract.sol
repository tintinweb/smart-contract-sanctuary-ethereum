# @version 0.3.1
"""
@title Fundraising Gauge
@license MIT
@author veFunder
@notice Custom gauge directing emissions entirely to a specific address up to a maximum
"""


interface CRV20:
    def rate() -> uint256: view
    def future_epoch_time_write() -> uint256: nonpayable

interface GaugeController:
    def checkpoint_gauge(_gauge: address): nonpayable
    def gauge_relative_weight(_gauge: address, _time: uint256) -> uint256: view

interface Minter:
    def minted(_user: address, _gauge: address) -> uint256: view


event Checkpoint:
    _timestamp: uint256
    _new_emissions: uint256


ADMIN: immutable(address)


CRV: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
GAUGE_CONTROLLER: constant(address) = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB
MINTER: constant(address) = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0

WEEK: constant(uint256) = 604800
YEAR: constant(uint256) = 86400 * 365

# taken from CRV20 to allow calculating locally
RATE_DENOMINATOR: constant(uint256) = 10 ** 18
RATE_REDUCTION_COEFFICIENT: constant(uint256) = 1189207115002721024  # 2 ** (1/4) * 1e18
RATE_REDUCTION_TIME: constant(uint256) = YEAR

# [uint216 inflation_rate][uint40 future_epoch_time]
inflation_params: uint256
_is_killed: bool

# _user => accumulated CRV
integrate_fraction: public(HashMap[address, uint256])
last_checkpoint: public(uint256)

receiver: public(address)
max_emissions: public(uint256)


@external
def __init__(_admin: address):
    ADMIN = _admin

    # prevent initialization of the implementation contract
    self.last_checkpoint = MAX_UINT256


@internal
def _user_checkpoint(_user: address) -> bool:
    # timestamp of the last checkpoint and start point for calculating new emissions
    prev_week_time: uint256 = self.last_checkpoint

    # if time has not advanced since the last checkpoint
    if block.timestamp == prev_week_time:
        return True

    # load the receiver
    receiver: address = self.receiver
    max_emissions: uint256 = self.max_emissions

    # initialize emission tracking variables
    receiver_emissions: uint256 = self.integrate_fraction[receiver]

    # if the maximum emissions has already been reached return early
    if receiver_emissions == max_emissions:
        return True

    # cache the receiver emissions var
    cached_receiver_emissions: uint256 = receiver_emissions

    # load and unpack inflation params
    inflation_params: uint256 = self.inflation_params
    rate: uint256 = shift(inflation_params, -40)
    future_epoch_time: uint256 = bitwise_and(inflation_params, 2 ** 40 - 1)

    # checkpoint the gauge filling in any missing gauge data across weeks
    GaugeController(GAUGE_CONTROLLER).checkpoint_gauge(self)

    # either the start of the next week or the current timestamp
    week_time: uint256 = min((prev_week_time + WEEK) / WEEK * WEEK, block.timestamp)

    # iterate 512 times at maximum
    for i in range(512):
        dt: uint256 = week_time - prev_week_time
        w: uint256 = GaugeController(GAUGE_CONTROLLER).gauge_relative_weight(self, prev_week_time / WEEK * WEEK)

        period_emissions: uint256 = 0

        # if we cross over an inflation epoch, calculate the emissions using old and new rate
        if prev_week_time <= future_epoch_time and future_epoch_time < week_time:
            # calculate up to the epoch using the old rate
            period_emissions = rate * w * (future_epoch_time - prev_week_time) / 10 ** 18
            # update the rate in memory
            rate = rate * RATE_DENOMINATOR / RATE_REDUCTION_COEFFICIENT
            # calculate using the new rate for the rest of the time period
            period_emissions += rate * w * (week_time - future_epoch_time) / 10 ** 18
            # update the new future epoch time
            future_epoch_time += RATE_REDUCTION_TIME
            # update storage
            self.inflation_params = shift(rate, 40) + future_epoch_time
        else:
            period_emissions = rate * w * dt / 10 ** 18

        # if adding period emissions is still below max emissions add to receiver
        if receiver_emissions + period_emissions <= max_emissions:
            receiver_emissions += period_emissions
        # else set received emissions at max and break
        else:
            receiver_emissions = max_emissions
            break

        if week_time == block.timestamp:
            break

        # update timestamps for tracking timedelta
        prev_week_time = week_time
        week_time = min(week_time + WEEK, block.timestamp)

    # this will only be the case if receiver got emissions
    if receiver_emissions != cached_receiver_emissions:
        self.integrate_fraction[receiver] = receiver_emissions

    self.last_checkpoint = block.timestamp

    log Checkpoint(block.timestamp, (receiver_emissions - cached_receiver_emissions))
    return True


@external
def user_checkpoint(_user: address) -> bool:
    """
    @notice Checkpoint the gauge updating total emissions
    @param _user The user to checkpoint and update accumulated emissions for
    """
    return self._user_checkpoint(_user)


@external
def claimable_tokens_write(_user: address) -> uint256:
    """
    @notice Get the number of claimable tokens per user
    @dev This function should be manually changed to "view" in the ABI
    @param _user The user to check claimable emissions of
    @return uint256 number of claimable tokens per user
    """
    self._user_checkpoint(_user)
    return self.integrate_fraction[_user] - Minter(MINTER).minted(_user, self)


@external
def set_killed(_is_killed: bool):
    """
    @notice Set the gauge status
    @dev Inflation params are modified accordingly to disable/enable emissions
    """
    assert msg.sender == ADMIN

    if _is_killed:
        self._is_killed = True
        self.inflation_params = 0
    else:
        self._is_killed = False
        self.inflation_params = shift(CRV20(CRV).rate(), 40) + CRV20(CRV).future_epoch_time_write()


@view
@external
def is_killed() -> bool:
    """
    @notice Get whether this gauge is killed and not receiving anymore emissions
    @dev This will return True if the max emissions has been reached or if set to killed by
        the ADMIN.
    """
    return self.integrate_fraction[self.receiver] == self.max_emissions or self._is_killed


@view
@external
def inflation_rate() -> uint256:
    """
    @notice Get the locally stored inflation rate
    """
    return shift(self.inflation_params, -40)


@view
@external
def future_epoch_time() -> uint256:
    """
    @notice Get the locally stored timestamp of the inflation rate epoch end
    """
    return bitwise_and(self.inflation_params, 2 ** 40 - 1)


@pure
@external
def admin() -> address:
    """
    @notice Get the address of the admin which can kill this gauge
    """
    return ADMIN


@external
def initialize(_receiver: address, _max_emissions: uint256):
    """
    @notice Proxy initializer method
    @dev Placed last in the source file to save some gas, this fn is called only once.
        Additional checks should be made by the DAO before voting in this gauge, specifically
        to make sure that `_fund_recipient` is capable of collecting emissions.
    @param _receiver The address which will receive CRV emissions
    @param _max_emissions The maximum amount of emissions which `_receiver` will
        receive
    """
    assert self.last_checkpoint == 0  # dev: already initialized

    self.receiver = _receiver
    self.max_emissions = _max_emissions

    self.last_checkpoint = block.timestamp
    self.inflation_params = shift(CRV20(CRV).rate(), 40) + CRV20(CRV).future_epoch_time_write()