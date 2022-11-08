# @version 0.3.1
"""
@title Root Liquidity Gauge Implementation
@license MIT
@author Curve Finance
"""


interface Bridger:
    def cost() -> uint256: view
    def bridge(_token: address, _destination: address, _amount: uint256): payable

interface ERC20:
    def balanceOf(_account: address) -> uint256: view
    def approve(_account: address, _value: uint256): nonpayable
    def transfer(_to: address, _amount: uint256): nonpayable

interface GaugeController:
    def checkpoint_gauge(addr: address): nonpayable
    def gauge_relative_weight(addr: address, time: uint256) -> uint256: view

interface Factory:
    def get_bridger(_chain_id: uint256) -> address: view
    def owner() -> address: view

interface Minter:
    def mint(_gauge: address): nonpayable
    def rate() -> uint256: view
    def committed_rate() -> uint256: view
    def future_epoch_time_write() -> uint256: view


struct InflationParams:
    rate: uint256
    finish_time: uint256


WEEK: constant(uint256) = 604800
YEAR: constant(uint256) = 86400 * 365
RATE_REDUCTION_TIME: constant(uint256) = WEEK * 2

SDL: immutable(address)
GAUGE_CONTROLLER: immutable(address)
MINTER: immutable(address)


chain_id: public(uint256)
bridger: public(address)
factory: public(address)
name: public(String[64])
inflation_params: public(InflationParams)

last_period: public(uint256)
total_emissions: public(uint256)

is_killed: public(bool)


@external
def __init__(_sdl_token: address, _gauge_controller: address, _minter: address):
    # set factory to non-zero value in the logic contract
    self.factory = 0x000000000000000000000000000000000000dEaD

    # assign immutable variables
    SDL = _sdl_token
    GAUGE_CONTROLLER = _gauge_controller
    MINTER = _minter



@payable
@external
def __default__():
    pass


@external
def transmit_emissions():
    """
    @notice Mint any new emissions and transmit across to child gauge
    """
    assert msg.sender == self.factory  # dev: call via factory

    Minter(MINTER).mint(self)
    minted: uint256 = ERC20(SDL).balanceOf(self)

    assert minted != 0  # dev: nothing minted
    bridger: address = self.bridger

    Bridger(bridger).bridge(SDL, self, minted, value=Bridger(bridger).cost())


@view
@external
def integrate_fraction(_user: address) -> uint256:
    """
    @notice Query the total emissions `_user` is entitled to
    @dev Any value of `_user` other than the gauge address will return 0
    """
    if _user == self:
        return self.total_emissions
    return 0


@external
def user_checkpoint(_user: address) -> bool:
    """
    @notice Checkpoint the gauge updating total emissions
    @param _user Vestigal parameter with no impact on the function
    """
    # the last period we calculated emissions up to (but not including)
    last_period: uint256 = self.last_period
    # our current period (which we will calculate emissions up to)
    current_period: uint256 = block.timestamp / WEEK

    # only checkpoint if the current period is greater than the last period
    # last period is always less than or equal to current period and we only calculate
    # emissions up to current period (not including it)
    if last_period != current_period:
        # checkpoint the gauge filling in any missing weight data
        GaugeController(GAUGE_CONTROLLER).checkpoint_gauge(self)

        rate: uint256 = Minter(MINTER).rate()
        self.inflation_params.rate = rate

        params: InflationParams = self.inflation_params
        emissions: uint256 = 0

        # only calculate emissions for at most 256 periods since the last checkpoint
        for i in range(last_period, last_period + 256):
            if i == current_period:
                # don't calculate emissions for the current period
                break
            period_time: uint256 = i * WEEK
            weight: uint256 = GaugeController(GAUGE_CONTROLLER).gauge_relative_weight(self, period_time)

            if period_time <= params.finish_time and params.finish_time < period_time + WEEK:
                # calculate with old rate
                emissions += weight * params.rate * (params.finish_time - period_time) / 10 ** 18
                # update rate
                params.rate = Minter(MINTER).committed_rate()
                if (params.rate == MAX_UINT256):
                    params.rate = rate
                # calculate with new rate
                emissions += weight * params.rate * (period_time + WEEK - params.finish_time) / 10 ** 18
                # update finish time
                params.finish_time += RATE_REDUCTION_TIME
                # update storage
                self.inflation_params = params
            else:
                emissions += weight * params.rate * WEEK / 10 ** 18

        self.last_period = current_period
        self.total_emissions += emissions

    return True


@external
def set_killed(_is_killed: bool):
    """
    @notice Set the gauge kill status
    @dev Inflation params are modified accordingly to disable/enable emissions
    """
    assert msg.sender == Factory(self.factory).owner()

    if _is_killed:
        self.inflation_params.rate = 0
    else:
        self.inflation_params = InflationParams({
            rate: Minter(MINTER).rate(),
            finish_time: Minter(MINTER).future_epoch_time_write()
        })
        self.last_period = block.timestamp / WEEK
    self.is_killed = _is_killed


@external
def update_bridger():
    """
    @notice Update the bridger used by this contract
    @dev Bridger contracts should prevent briding if ever updated
    """
    # reset approval
    bridger: address = Factory(self.factory).get_bridger(self.chain_id)
    ERC20(SDL).approve(self.bridger, 0)
    ERC20(SDL).approve(bridger, MAX_UINT256)
    self.bridger = bridger


@external
def initialize(_bridger: address, _chain_id: uint256, _name: String[32]):
    """
    @notice Proxy initialization method
    """
    assert self.factory == ZERO_ADDRESS, "already initialized"

    self.chain_id = _chain_id
    self.bridger = _bridger
    name: String[64] = concat("Saddle ", _name, " Root Gauge")
    self.name = name
    self.factory = msg.sender

    inflation_params: InflationParams = InflationParams({
        rate: Minter(MINTER).rate(),
        finish_time: Minter(MINTER).future_epoch_time_write()
    })
    assert inflation_params.rate != 0, "inflation rate is 0"

    self.inflation_params = inflation_params
    self.last_period = block.timestamp / WEEK

    ERC20(SDL).approve(_bridger, MAX_UINT256)