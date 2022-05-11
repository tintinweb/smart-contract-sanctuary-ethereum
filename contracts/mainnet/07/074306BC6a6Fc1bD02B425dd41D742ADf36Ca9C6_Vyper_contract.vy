# @version 0.2.15
"""
@title DistributorProxy
@author This version was modified starting from Curve Finance's DAO contracts
@license MIT
"""

interface LiquidityGauge:
    # Presumably, other gauges will provide the same interfaces
    def integrate_fraction(addr: address) -> uint256: view
    def user_checkpoint(addr: address) -> bool: nonpayable

interface Distributor:
    def distribute(_to: address, _value: uint256) -> bool: nonpayable

interface GaugeController:
    def gauge_types(addr: address) -> int128: view


event Distributed:
    recipient: indexed(address)
    gauge: address
    distributed: uint256


distributor: public(address)
controller: public(address)

# user -> gauge -> value
distributed: public(HashMap[address, HashMap[address, uint256]])

# distributor -> user -> can distribute?
allowed_to_distribute_for: public(HashMap[address, HashMap[address, bool]])


@external
def __init__(_distributor: address, _controller: address):
    self.distributor = _distributor
    self.controller = _controller


@internal
def _distribute_for(gauge_addr: address, _for: address):
    assert GaugeController(self.controller).gauge_types(gauge_addr) >= 0  # dev: gauge is not added

    LiquidityGauge(gauge_addr).user_checkpoint(_for)
    total_distribute: uint256 = LiquidityGauge(gauge_addr).integrate_fraction(_for)
    to_distribute: uint256 = total_distribute - self.distributed[_for][gauge_addr]

    if to_distribute != 0:
        Distributor(self.distributor).distribute(_for, to_distribute)
        self.distributed[_for][gauge_addr] = total_distribute

        log Distributed(_for, gauge_addr, total_distribute)


@external
@nonreentrant('lock')
def distribute(gauge_addr: address):
    """
    @notice Distribute everything which belongs to `msg.sender`
    @param gauge_addr `LiquidityGauge` address to get distributable amount from
    """
    self._distribute_for(gauge_addr, msg.sender)


@external
@nonreentrant('lock')
def distribute_many(gauge_addrs: address[8]):
    """
    @notice Distribute everything which belongs to `msg.sender` across multiple gauges
    @param gauge_addrs List of `LiquidityGauge` addresses
    """
    for i in range(8):
        if gauge_addrs[i] == ZERO_ADDRESS:
            break
        self._distribute_for(gauge_addrs[i], msg.sender)


@external
@nonreentrant('lock')
def distribute_for(gauge_addr: address, _for: address):
    """
    @notice Distribute tokens for `_for`
    @dev Only possible when `msg.sender` has been approved via `toggle_approve_distribute`
    @param gauge_addr `LiquidityGauge` address to get distributable amount from
    @param _for Address to distribute to
    """
    if self.allowed_to_distribute_for[msg.sender][_for]:
        self._distribute_for(gauge_addr, _for)


@external
def toggle_approve_distribute(distributing_user: address):
    """
    @notice allow `distributing_user` to distribute for `msg.sender`
    @param distributing_user Address to toggle permission for
    """
    self.allowed_to_distribute_for[distributing_user][msg.sender] = not self.allowed_to_distribute_for[distributing_user][msg.sender]