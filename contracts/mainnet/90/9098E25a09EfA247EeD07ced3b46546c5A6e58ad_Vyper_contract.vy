# @version 0.3.1
"""
@title Gauge Factory
@license MIT
@author Aladdin DAO
"""

interface LiquidityGauge:
    def initialize(_lp_token: address): nonpayable

event LiquidityGaugeDeployed:
    token: address
    gauge: address

event UpdateGaugeImplementation:
    _old_gauge_implementation: address
    _new_gauge_implementation: address

event TransferOwnership:
    _old_owner: address
    _new_owner: address


admin: public(address)
future_admin: public(address)

gauge_implementation: public(address)


@external
def __init__(_gauge_implementation: address):
    self.gauge_implementation = _gauge_implementation

    self.admin = msg.sender

    log UpdateGaugeImplementation(ZERO_ADDRESS, _gauge_implementation)
    log TransferOwnership(ZERO_ADDRESS, msg.sender)


@external
def deploy_gauge(_token: address) -> address:
    """
    @notice Deploy a liquidity gauge for a LP token
    @param _token LP token address to deploy a gauge for
    @return Address of the deployed gauge
    """

    gauge: address = create_forwarder_to(self.gauge_implementation)
    LiquidityGauge(gauge).initialize(_token)

    log LiquidityGaugeDeployed(_token, gauge)
    return gauge


@external
def set_gauge_implementation(_gauge_implementation: address):
    """
    @notice Set gauge implementation
    @dev Set to ZERO_ADDRESS to prevent deployment of new gauges
    @param _gauge_implementation Address of the new token implementation
    """
    assert msg.sender == self.admin  # dev: admin-only function

    log UpdateGaugeImplementation(self.gauge_implementation, _gauge_implementation)
    self.gauge_implementation = _gauge_implementation


@external
def commit_transfer_ownership(_addr: address):
    """
    @notice Transfer ownership of this contract to `addr`
    @param _addr Address of the new owner
    """
    assert msg.sender == self.admin  # dev: admin only

    self.future_admin = _addr


@external
def accept_transfer_ownership():
    """
    @notice Accept a pending ownership transfer
    @dev Only callable by the new owner
    """
    assert msg.sender == self.future_admin  # dev: future admin only

    log TransferOwnership(self.admin, msg.sender)
    self.admin = msg.sender