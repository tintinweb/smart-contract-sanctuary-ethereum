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
def __init__(_factory: address, _manager: address):
    FACTORY = _factory
    OWNER_PROXY = Factory(_factory).admin()

    self.manager = _manager
    log SetManager(_manager)


@external
def add_reward(_gauge: address, _reward_token: address, _distributor: address):
    """
    @notice Add a reward to a gauge
    @param _gauge The gauge the reward will be added to
    @param _reward_token The token to be added as a reward (should be ERC20-compliant)
    @param _distributor The account which will top-up, and distribute the rewards.
    """
    assert msg.sender in [self.gauge_manager[_gauge], self.manager]

    OwnerProxy(OWNER_PROXY).add_reward(_gauge, _reward_token, _distributor)


@external
def set_reward_distributor(_gauge: address, _reward_token: address, _distributor: address):
    """
    @notice Set the reward distributor for a gauge
    @param _gauge The gauge to update
    @param _reward_token The reward token for which the distributor will be changed
    @param _distributor The new distributor for the reward token.
    """
    assert msg.sender in [self.gauge_manager[_gauge], self.manager]

    OwnerProxy(OWNER_PROXY).set_reward_distributor(_gauge, _reward_token, _distributor)


@external
def deploy_gauge(_pool: address, _gauge_manager: address = msg.sender) -> address:
    """
    @notice Deploy a gauge, and set _gauge_manager as the manager
    @param _pool The pool to deploy a gauge for
    @param _gauge_manager The account to which will manage rewards for the gauge
    """
    gauge: address = Factory(FACTORY).deploy_gauge(_pool)

    self.gauge_manager[gauge] = _gauge_manager
    log SetGaugeManager(gauge, _gauge_manager)
    return gauge


@external
def set_gauge_manager(_gauge: address, _gauge_manager: address):
    """
    @notice Change the gauge manager for a gauge
    @dev The manager of this contract, or the ownership admin can outright modify gauge
        managership. A gauge manager can also transfer managership to a new manager via this
        method, but only for the gauge which they are the manager of.
    @param _gauge The gauge to change the managership of
    @param _gauge_manager The account to set as the new manager of the gauge.
    """
    if msg.sender not in [self.manager, OwnerProxy(OWNER_PROXY).ownership_admin()]:
        assert msg.sender == self.gauge_manager[_gauge]

    self.gauge_manager[_gauge] = _gauge_manager
    log SetGaugeManager(_gauge, _gauge_manager)


@external
def set_manager(_manager: address):
    """
    @notice Set the manager of this contract
    @param _manager The account to set as the manager
    """
    assert msg.sender in [self.manager, OwnerProxy(OWNER_PROXY).ownership_admin()]

    self.manager = _manager
    log SetManager(_manager)


@pure
@external
def factory() -> address:
    return FACTORY


@pure
@external
def owner_proxy() -> address:
    return OWNER_PROXY