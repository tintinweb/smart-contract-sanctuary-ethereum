# @version 0.3.7
"""
@title Curve BasePool Registry
@license MIT
@author Curve.Fi
"""
MAX_COINS: constant(uint256) = 8


struct BasePool:
    location: uint256
    lp_token: address
    n_coins: uint256
    is_v2: bool
    is_legacy: bool
    is_lending: bool


interface AddressProvider:
    def admin() -> address: view


interface ERC20:
    def decimals() -> uint256: view


interface CurvePoolLegacy:
    def coins(i: int128) -> address: view


interface CurvePool:
    def coins(i: uint256) -> address: view


event BasePoolAdded:
    basepool: indexed(address)


event BasePoolRemoved:
    basepool: indexed(address)


ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383
base_pool: HashMap[address, BasePool]
base_pool_list: public(address[100])
get_base_pool_for_lp_token: public(HashMap[address, address])
base_pool_count: public(uint256)
last_updated: public(uint256)


@internal
@view
def _get_basepool_coins(_pool: address) -> address[MAX_COINS]:
    _n_coins: uint256 = self.base_pool[_pool].n_coins
    _is_legacy: bool = self.base_pool[_pool].is_legacy
    _coins: address[MAX_COINS] = empty(address[MAX_COINS])
    for i in range(MAX_COINS):
        if i == _n_coins:
            break

        if _is_legacy:
            _coins[i] = CurvePoolLegacy(_pool).coins(convert(i, int128))
        else:
            _coins[i] = CurvePool(_pool).coins(i)

    return _coins



@internal
@view
def _get_basepools_for_coin(_coin: address) -> DynArray[address, 1000]:
    """
    @notice Gets the base pool for a coin
    @dev Some coins can be in multiple base pools, this function returns
         the base pool for a coin at a specific index
    @param _coin Address of the coin
    @return basepool addresses
    """
    _base_pools: DynArray[address, 1000] = empty(DynArray[address, 1000])
    for _pool in self.base_pool_list:
        _coins: address[MAX_COINS] = self._get_basepool_coins(_pool)
        if _coin in _coins:
            _base_pools.append(_pool)

    return _base_pools


@external
@view
def get_coins(_pool: address) -> address[MAX_COINS]:
    """
    @notice Gets coins in a base pool
    @param _pool Address of the base pool
    @return address[MAX_COINS] with coin addresses
    """
    return self._get_basepool_coins(_pool)


@external
@view
def get_basepool_for_coin(_coin: address, _idx: uint256 = 0) -> address:
    """
    @notice Gets the base pool for a coin
    @dev Some coins can be in multiple base pools, this function returns
         the base pool for a coin at a specific index
    @param _coin Address of the coin
    @param _idx Index of base pool that holds the coin
    @return basepool address
    """
    return self._get_basepools_for_coin(_coin)[_idx]


@external
@view
def get_basepools_for_coin(_coin: address) -> DynArray[address, 1000]:
    """
    @notice Gets the base pool for a coin
    @dev Some coins can be in multiple base pools, this function returns
         the base pool for a coin at a specific index
    @param _coin Address of the coin
    @return basepool addresses
    """
    return self._get_basepools_for_coin(_coin)


@external
@view
def get_decimals(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Gets decimals of coins in a base pool
    @param _pool Address of the base pool
    @return uint256[MAX_COINS] containing coin decimals
    """
    _coins: address[MAX_COINS] = self._get_basepool_coins(_pool)
    _decimals: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if _coins[i] == empty(address):
            break
        if _coins[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
            _decimals[i] = 18
        else:
            _decimals[i] = ERC20(_coins[i]).decimals()

    return _decimals


@external
@view
def get_lp_token(_pool: address) -> address:
    """
    @notice Gets the LP token of a base pool
    @param _pool Address of the base pool
    @return address of the LP token
    """
    return self.base_pool[_pool].lp_token


@external
@view
def get_n_coins(_pool: address) -> uint256:
    """
    @notice Gets the number of coins in a base pool
    @param _pool Address of the base pool
    @return uint256 number of coins
    """
    return self.base_pool[_pool].n_coins


@external
@view
def get_location(_pool: address) -> uint256:
    """
    @notice Gets the index where a base pool's
            data is stored in the registry
    @param _pool Address of the base pool
    @return uint256 index of the base pool
    """
    return self.base_pool[_pool].location


@external
@view
def is_legacy(_pool: address) -> bool:
    """
    @notice Checks if a base pool uses Curve's legacy abi
    @dev Legacy abi includes int128 indices whereas the newer
         abi uses uint256 indices
    @param _pool Address of the base pool
    @return bool True if legacy abi is used
    """
    return self.base_pool[_pool].is_legacy


@external
@view
def is_v2(_pool: address) -> bool:
    """
    @notice Checks if a base pool is a Curve CryptoSwap pool
    @param _pool Address of the base pool
    @return bool True if the pool is a Curve CryptoSwap pool
    """
    return self.base_pool[_pool].is_v2


@external
@view
def is_lending(_pool: address) -> bool:
    """
    @notice Checks if a base pool is a Curve Lending pool
    @param _pool Address of the base pool
    @return bool True if the pool is a Curve Lending pool
    """
    return self.base_pool[_pool].is_lending


@external
def add_base_pool(_pool: address, _lp_token: address, _n_coins: uint256, _is_legacy: bool, _is_lending: bool, _is_v2: bool):
    """
    @notice Add a base pool to the registry
    @param _pool Address of the base pool
    @param _lp_token Address of the LP token
    @param _n_coins Number of coins in the base pool
    @param _is_legacy True if the base pool uses legacy abi
    @param _is_lending True if the base pool is a Curve Lending pool
    @param _is_v2 True if the base pool is a Curve CryptoSwap pool
    """
    assert msg.sender == AddressProvider(ADDRESS_PROVIDER).admin()  # dev: admin-only function
    assert self.base_pool[_pool].lp_token == empty(address)  # dev: pool exists

    # add pool to base_pool_list
    base_pool_count: uint256 = self.base_pool_count
    self.base_pool[_pool].location = base_pool_count
    self.base_pool[_pool].lp_token = _lp_token
    self.base_pool[_pool].n_coins = _n_coins
    self.base_pool[_pool].is_v2 = _is_v2
    self.base_pool[_pool].is_legacy = _is_legacy
    self.base_pool[_pool].is_lending = _is_lending

    # for reverse lookup:
    self.get_base_pool_for_lp_token[_lp_token] = _pool

    self.last_updated = block.timestamp
    self.base_pool_list[base_pool_count] = _pool
    self.base_pool_count = base_pool_count + 1
    log BasePoolAdded(_pool)


@external
def remove_base_pool(_pool: address):
    """
    @notice Remove a base pool from the registry
    @param _pool Address of the base pool
    """
    assert msg.sender == AddressProvider(ADDRESS_PROVIDER).admin()  # dev: admin-only function
    assert _pool != empty(address)
    assert self.base_pool[_pool].lp_token != empty(address)  # dev: pool doesn't exist

    # reset pool <> lp_token mappings
    self.get_base_pool_for_lp_token[self.base_pool[_pool].lp_token] = empty(address)
    self.base_pool[_pool].lp_token = empty(address)
    self.base_pool[_pool].n_coins = 0

    # remove base_pool from base_pool_list
    location: uint256 = self.base_pool[_pool].location
    length: uint256 = self.base_pool_count - 1
    assert location < length

    # because self.base_pool_list is a static array,
    # we can replace the last index with empty(address)
    # and replace the first index with the base pool
    # that was previously in the last index.
    # we skip this step if location == last index
    if location < length:
        # replace _pool with final value in pool_list
        addr: address = self.base_pool_list[length]
        assert addr != empty(address)
        self.base_pool_list[location] = addr
        self.base_pool[addr].location = location

    # delete final pool_list value
    self.base_pool_list[length] = empty(address)
    self.base_pool_count = length

    self.last_updated = block.timestamp
    log BasePoolRemoved(_pool)