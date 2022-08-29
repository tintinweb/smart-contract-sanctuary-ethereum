# @version 0.3.3
"""
@notice Gauge Manager Proxy
@author CurveFi
"""


interface Factory:
    def admin() -> address: view
    def deploy_gauge(_pool: address) -> address: nonpayable

interface OwnerProxy:
    def add_reward(_gauge: address, _reward_token: address, _distributor: address): nonpayable
    def ownership_admin() -> address: view
    def set_reward_distributor(_gauge: address, _reward_token: address, _distributor: address): nonpayable


event SetManager:
    _manager: indexed(address)

event SetGaugeManager:
    _gauge: indexed(address)
    _gauge_manager: indexed(address)


FACTORY: immutable(address)
OWNER_PROXY: immutable(address)


gauge_manager: public(HashMap[address, address])
manager: public(address)


@external
def __init__(_factory: address):
    FACTORY = _factory
    OWNER_PROXY = Factory(_factory).admin()

    self.manager = msg.sender
    log SetManager(msg.sender)


@external
def add_reward(_gauge: address, _reward_token: address, _distributor: address):
    assert msg.sender == self.gauge_manager[_gauge]

    OwnerProxy(OWNER_PROXY).add_reward(_gauge, _reward_token, _distributor)


@external
def set_reward_distributor(_gauge: address, _reward_token: address, _distributor: address):
    assert msg.sender == self.gauge_manager[_gauge]

    OwnerProxy(OWNER_PROXY).set_reward_distributor(_gauge, _reward_token, _distributor)


@external
def deploy_gauge(_pool: address, _gauge_manager: address = msg.sender) -> address:
    gauge: address = Factory(FACTORY).deploy_gauge(_pool)

    self.gauge_manager[gauge] = _gauge_manager
    log SetGaugeManager(gauge, _gauge_manager)
    return gauge


@external
def set_gauge_manager(_gauge: address, _gauge_manager: address):
    assert msg.sender in [self.manager, OwnerProxy(OWNER_PROXY).ownership_admin()]

    self.gauge_manager[_gauge] = _gauge_manager
    log SetGaugeManager(_gauge, _gauge_manager)


@external
def set_manager(_manager: address):
    assert msg.sender in [self.manager, OwnerProxy(OWNER_PROXY).ownership_admin()]

    self.manager = _manager
    log SetManager(_manager)