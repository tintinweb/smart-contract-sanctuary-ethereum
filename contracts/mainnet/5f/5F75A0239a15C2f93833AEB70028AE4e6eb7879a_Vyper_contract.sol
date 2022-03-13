# @version 0.3.1
"""
@title veFunder Fundraising Gauge Ownership Proxy
@license MIT
@author veFunder
@notice Ownership proxy giving privilege to the Curve DAO to kill gauges
"""

interface Gauge:
    def set_killed(_is_killed: bool): nonpayable


event CommitAdmins:
    ownership_admin: address
    emergency_admin: address

event ApplyAdmins:
    ownership_admin: address
    emergency_admin: address


ownership_admin: public(address)
emergency_admin: public(address)

future_ownership_admin: public(address)
future_emergency_admin: public(address)


@external
def __init__(_ownership_admin: address, _emergency_admin: address):
    self.ownership_admin = _ownership_admin
    self.emergency_admin = _emergency_admin

    log ApplyAdmins(_ownership_admin, _emergency_admin)


@external
@nonreentrant('lock')
def set_killed(_gauge: address, _is_killed: bool):
    """
    @notice Set the killed status for `_gauge`
    @dev When killed, the gauge always yields a rate of 0 and so cannot mint CRV
    @param _gauge Gauge address
    @param _is_killed Killed status to set
    """
    assert msg.sender in [self.ownership_admin, self.emergency_admin], "Access denied"

    Gauge(_gauge).set_killed(_is_killed)


@external
def commit_set_admins(_o_admin: address, _e_admin: address):
    """
    @notice Set ownership admin to `_o_admin` and emergency admin to `_e_admin`
    @param _o_admin Ownership admin
    @param _e_admin Emergency admin
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    self.future_ownership_admin = _o_admin
    self.future_emergency_admin = _e_admin

    log CommitAdmins(_o_admin, _e_admin)


@external
def accept_set_admins():
    """
    @notice Apply the effects of `commit_set_admins`
    @dev Only callable by the new owner admin
    """
    assert msg.sender == self.future_ownership_admin, "Access denied"

    e_admin: address = self.future_emergency_admin
    self.ownership_admin = msg.sender
    self.emergency_admin = e_admin

    log ApplyAdmins(msg.sender, e_admin)