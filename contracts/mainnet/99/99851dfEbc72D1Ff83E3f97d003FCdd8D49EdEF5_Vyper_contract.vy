# @version 0.3.1
"""
@title Fundraising Gauge Factory
@license MIT
@author veFunder
@notice Emissions based fundraising factory targeting Curve DAO
"""


interface Gauge:
    def initialize(_receiver: address, _max_emissions: uint256): nonpayable


event NewGauge:
    _instance: indexed(address)
    _receiver: indexed(address)
    _max_emissions: uint256


# maximum number of gauges this factory can create
MAX_GAUGES: constant(uint256) = 1_000_000


# implementation contract used for deploying instances
IMPLEMENTATION: immutable(address)


# storage variables for enumerating through deployed gauges
get_gauge_count: public(uint256)
get_gauge_by_idx: public(address[MAX_GAUGES])


@external
def __init__(_implementation: address):
    IMPLEMENTATION = _implementation


@external
def deploy_gauge(_receiver: address, _max_emissions: uint256) -> address:
    """
    @notice Deploy a new fundraising gauge
    @param _receiver The address which will receiver all emissions
    @param _max_emissions The maximum amount of emissions `_receiver` will receive
    """
    # deploy the proxy pointing at the implementation
    gauge: address = create_forwarder_to(IMPLEMENTATION)

    # update the enumeration storage variables
    idx: uint256 = self.get_gauge_count
    self.get_gauge_by_idx[idx] = gauge
    self.get_gauge_count = idx + 1

    # initialize the proxy
    Gauge(gauge).initialize(_receiver, _max_emissions)

    # log new gauge has been deployed + return gauge address
    log NewGauge(gauge, _receiver, _max_emissions)
    return gauge


@pure
@external
def implementation() -> address:
    """
    @notice Get the implementation address used for created proxies
    """
    return IMPLEMENTATION