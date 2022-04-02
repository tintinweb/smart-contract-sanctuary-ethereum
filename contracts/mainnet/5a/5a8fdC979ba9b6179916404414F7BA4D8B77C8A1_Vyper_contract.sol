# @version 0.3.1
"""
@title Curve CryptoSwap Owner Proxy
@author Curve Finance
@license MIT
@notice Allows DAO ownership of `Factory` and it's deployed pools
"""

interface Curve:
    def ramp_A_gamma(future_A: uint256, future_gamma: uint256, future_time: uint256): nonpayable
    def stop_ramp_A_gamma(): nonpayable
    def commit_new_parameters(
        _new_mid_fee: uint256,
        _new_out_fee: uint256,
        _new_admin_fee: uint256,
        _new_fee_gamma: uint256,
        _new_allowed_extra_profit: uint256,
        _new_adjustment_step: uint256,
        _new_ma_half_time: uint256,
    ): nonpayable
    def apply_new_parameters(): nonpayable
    def revert_new_parameters(): nonpayable

interface Gauge:
    def set_killed(_is_killed: bool): nonpayable
    def add_reward(_reward_token: address, _distributor: address): nonpayable
    def set_reward_distributor(_reward_token: address, _distributor: address): nonpayable

interface Factory:
    def set_fee_receiver(_fee_receiver: address): nonpayable
    def set_pool_implementation(_pool_implementation: address): nonpayable
    def set_token_implementation(_token_implementation: address): nonpayable
    def set_gauge_implementation(_gauge_implementation: address): nonpayable
    def commit_transfer_ownership(addr: address): nonpayable
    def accept_transfer_ownership(): nonpayable


event CommitAdmins:
    ownership_admin: address
    parameter_admin: address
    emergency_admin: address

event ApplyAdmins:
    ownership_admin: address
    parameter_admin: address
    emergency_admin: address

ownership_admin: public(address)
parameter_admin: public(address)
emergency_admin: public(address)

future_ownership_admin: public(address)
future_parameter_admin: public(address)
future_emergency_admin: public(address)

gauge_manager: public(address)


@external
def __init__(
    _ownership_admin: address,
    _parameter_admin: address,
    _emergency_admin: address,
    _gauge_manager: address
):
    self.ownership_admin = _ownership_admin
    self.parameter_admin = _parameter_admin
    self.emergency_admin = _emergency_admin
    self.gauge_manager = _gauge_manager


@external
def commit_set_admins(_o_admin: address, _p_admin: address, _e_admin: address):
    """
    @notice Set ownership admin to `_o_admin`, parameter admin to `_p_admin` and emergency admin to `_e_admin`
    @param _o_admin Ownership admin
    @param _p_admin Parameter admin
    @param _e_admin Emergency admin
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    self.future_ownership_admin = _o_admin
    self.future_parameter_admin = _p_admin
    self.future_emergency_admin = _e_admin

    log CommitAdmins(_o_admin, _p_admin, _e_admin)


@external
def apply_set_admins():
    """
    @notice Apply the effects of `commit_set_admins`
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    _o_admin: address = self.future_ownership_admin
    _p_admin: address = self.future_parameter_admin
    _e_admin: address = self.future_emergency_admin
    self.ownership_admin = _o_admin
    self.parameter_admin = _p_admin
    self.emergency_admin = _e_admin

    log ApplyAdmins(_o_admin, _p_admin, _e_admin)


@external
@nonreentrant('lock')
def ramp_A_gamma(_pool: address, _future_A: uint256,  _future_gamma: uint256, _future_time: uint256):
    assert msg.sender == self.parameter_admin, "Access denied"
    Curve(_pool).ramp_A_gamma(_future_A, _future_gamma, _future_time)


@external
@nonreentrant('lock')
def stop_ramp_A_gamma(_pool: address):
    assert msg.sender in [self.parameter_admin, self.emergency_admin], "Access denied"
    Curve(_pool).stop_ramp_A_gamma()


@external
@nonreentrant('lock')
def commit_new_parameters(
    _pool: address,
    _new_mid_fee: uint256,
    _new_out_fee: uint256,
    _new_admin_fee: uint256,
    _new_fee_gamma: uint256,
    _new_allowed_extra_profit: uint256,
    _new_adjustment_step: uint256,
    _new_ma_half_time: uint256,
):
    assert msg.sender == self.parameter_admin, "Access denied"
    assert _new_mid_fee != 0  # dev: prevent reinitialization
    Curve(_pool).commit_new_parameters(
        _new_mid_fee,
        _new_out_fee,
        _new_admin_fee,
        _new_fee_gamma,
        _new_allowed_extra_profit,
        _new_adjustment_step,
        _new_ma_half_time,
    )


@external
@nonreentrant('lock')
def apply_new_parameters(_pool: address):
    assert msg.sender == self.parameter_admin, "Access denied"
    Curve(_pool).apply_new_parameters()


@external
@nonreentrant('lock')
def revert_new_parameters(_pool: address):
    assert msg.sender in [self.parameter_admin, self.emergency_admin], "Access denied"
    Curve(_pool).revert_new_parameters()


@external
@nonreentrant('lock')
def set_fee_receiver(_target: address, _fee_receiver: address):
    assert msg.sender == self.ownership_admin, "Access denied"
    Factory(_target).set_fee_receiver(_fee_receiver)


@external
@nonreentrant('lock')
def set_pool_implementation(_target: address, _pool_implementation: address):
    assert msg.sender == self.ownership_admin, "Access denied"
    Factory(_target).set_pool_implementation(_pool_implementation)


@external
@nonreentrant('lock')
def set_token_implementation(_target: address, _token_implementation: address):
    assert msg.sender == self.ownership_admin, "Access denied"
    Factory(_target).set_token_implementation(_token_implementation)


@external
@nonreentrant('lock')
def set_gauge_implementation(_target: address, _gauge_implementation: address):
    assert msg.sender == self.ownership_admin, "Access denied"
    Factory(_target).set_gauge_implementation(_gauge_implementation)


@external
@nonreentrant('lock')
def set_gauge_manager(_manager: address):
    """
    @notice Set the manager
    @dev Callable by the admin or existing manager
    @param _manager Manager address
    """
    assert msg.sender in [self.ownership_admin, self.emergency_admin, self.gauge_manager], "Access denied"

    self.gauge_manager = _manager


@external
def commit_transfer_ownership(_target: address, _new_admin: address):
    """
    @notice Transfer ownership of `_target` to `_new_admin`
    @param _target `Factory` deployment address
    @param _new_admin New admin address
    """
    assert msg.sender == self.ownership_admin  # dev: admin only

    Factory(_target).commit_transfer_ownership(_new_admin)


@external
def accept_transfer_ownership(_target: address):
    """
    @notice Accept a pending ownership transfer
    @param _target `Factory` deployment address
    """
    Factory(_target).accept_transfer_ownership()


@external
def set_killed(_gauge: address, _is_killed: bool):
    assert msg.sender in [self.ownership_admin, self.emergency_admin]
    Gauge(_gauge).set_killed(_is_killed)


@external
def add_reward(_gauge: address, _reward_token: address, _distributor: address):
    assert msg.sender in [self.ownership_admin, self.gauge_manager]
    Gauge(_gauge).add_reward(_reward_token, _distributor)


@external
def set_reward_distributor(_gauge: address, _reward_token: address, _distributor: address):
    assert msg.sender in [self.ownership_admin, self.gauge_manager]
    Gauge(_gauge).set_reward_distributor(_reward_token, _distributor)