# @version 0.3.4
"""
@title Curve Registry Handler for v2 Factory
@license MIT
"""

# ---- interfaces ---- #
interface BaseRegistry:
    def find_pool_for_coins(_from: address, _to: address, i: uint256 = 0) -> address: view
    def get_balances(_pool: address) -> uint256[MAX_COINS]: view
    def get_coins(_pool: address) -> address[MAX_COINS]: view
    def get_decimals(_pool: address) -> uint256[MAX_COINS]: view
    def get_gauge(_pool: address) -> address: view
    def get_n_coins(_pool: address) -> uint256: view
    def get_token(_pool: address) -> address: view
    def pool_count() -> uint256: view
    def pool_list(pool_id: uint256) -> address: view


interface BasePoolRegistry:
    def get_base_pool_for_lp_token(_lp_token: address) -> address: view
    def get_n_coins(_pool: address) -> uint256: view
    def get_coins(_pool: address) -> address[MAX_METAREGISTRY_COINS]: view
    def get_lp_token(_pool: address) -> address: view
    def is_legacy(_pool: address) -> bool: view
    def base_pool_list(i: uint256) -> address: view
    def get_basepools_for_coin(_coin: address) -> DynArray[address, 1000]: view


interface CurvePool:
    def adjustment_step() -> uint256: view
    def admin_fee() -> uint256: view
    def allowed_extra_profit() -> uint256: view
    def A() -> uint256: view
    def balances(i: uint256) -> uint256: view
    def D() -> uint256: view
    def fee() -> uint256: view
    def fee_gamma() -> uint256: view
    def gamma() -> uint256: view
    def get_virtual_price() -> uint256: view
    def ma_half_time() -> uint256: view
    def mid_fee() -> uint256: view
    def out_fee() -> uint256: view
    def virtual_price() -> uint256: view
    def xcp_profit() -> uint256: view
    def xcp_profit_a() -> uint256: view


interface StableSwapLegacy:
    def coins(i: int128) -> address: view
    def underlying_coins(i: int128) -> address: view
    def balances(i: int128) -> uint256: view


interface ERC20:
    def name() -> String[64]: view
    def balanceOf(_addr: address) -> uint256: view
    def totalSupply() -> uint256: view
    def decimals() -> uint256: view


interface GaugeController:
    def gauge_types(gauge: address) -> int128: view
    def gauges(i: uint256) -> address: view


interface Gauge:
    def is_killed() -> bool: view


interface MetaRegistry:
    def registry_length() -> uint256: view


# ---- constants ---- #
GAUGE_CONTROLLER: constant(address) = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB
MAX_COINS: constant(uint256) = 2
MAX_METAREGISTRY_COINS: constant(uint256) = 8
MAX_POOLS: constant(uint256) = 65536
N_COINS: constant(uint256) = 2


# ---- storage variables ---- #
base_registry: public(BaseRegistry)
base_pool_registry: BasePoolRegistry


# ---- constructor ---- #
@external
def __init__(_registry_address: address, _base_pool_registry: address):
    self.base_registry = BaseRegistry(_registry_address)
    self.base_pool_registry = BasePoolRegistry(_base_pool_registry)


# ---- internal methods ---- #
@internal
@view
def _pad_uint_array(_array: uint256[MAX_COINS]) -> uint256[MAX_METAREGISTRY_COINS]:
    _padded_array: uint256[MAX_METAREGISTRY_COINS] = empty(uint256[MAX_METAREGISTRY_COINS])
    for i in range(MAX_COINS):
        _padded_array[i] = _array[i]
    return _padded_array


@internal
@view
def _get_balances(_pool: address) -> uint256[MAX_METAREGISTRY_COINS]:
    return self._pad_uint_array(self.base_registry.get_balances(_pool))


@internal
@view
def _get_coins(_pool: address) -> address[MAX_METAREGISTRY_COINS]:
    _coins: address[MAX_COINS] = self.base_registry.get_coins(_pool)
    _padded_coins: address[MAX_METAREGISTRY_COINS] = empty(address[MAX_METAREGISTRY_COINS])
    for i in range(MAX_COINS):
        _padded_coins[i] = _coins[i]
    return _padded_coins


@internal
@view
def _get_decimals(_pool: address) -> uint256[MAX_METAREGISTRY_COINS]:
    return self._pad_uint_array(self.base_registry.get_decimals(_pool))


@internal
@view
def _get_lp_token(_pool: address) -> address:
    return self.base_registry.get_token(_pool)


@internal
@view
def _get_n_coins(_pool: address) -> uint256:

    if (self.base_registry.get_coins(_pool)[0] != empty(address)):
        return N_COINS
    return 0


@internal
@view
def _get_base_pool(_pool: address) -> address:
    _coins: address[2] = self.base_registry.get_coins(_pool)
    _base_pool: address = empty(address)
    for coin in _coins:
        _base_pool = self.base_pool_registry.get_base_pool_for_lp_token(coin)
        if _base_pool != empty(address):
            return _base_pool
    return empty(address)


@view
@internal
def _get_underlying_coins_for_metapool(_pool: address) -> address[MAX_METAREGISTRY_COINS]:

    base_pool: address = self._get_base_pool(_pool)
    assert base_pool != empty(address)

    base_pool_coins: address[MAX_METAREGISTRY_COINS] = self.base_pool_registry.get_coins(base_pool)
    _underlying_coins: address[MAX_METAREGISTRY_COINS] = empty(address[MAX_METAREGISTRY_COINS])
    base_coin_offset: uint256 = self._get_n_coins(_pool) - 1

    for i in range(MAX_METAREGISTRY_COINS):
        if i < base_coin_offset:
            _underlying_coins[i] = self._get_coins(_pool)[i]
        else:
            _underlying_coins[i] = base_pool_coins[i - base_coin_offset]

    return _underlying_coins


@view
@internal
def _is_meta(_pool: address) -> bool:
    return self._get_base_pool(_pool) != empty(address)


@view
@internal
def _get_meta_underlying_balances(_pool: address) -> uint256[MAX_METAREGISTRY_COINS]:
    base_coin_idx: uint256 = self._get_n_coins(_pool) - 1
    base_pool: address = self._get_base_pool(_pool)
    base_total_supply: uint256 = ERC20(self.base_pool_registry.get_lp_token(base_pool)).totalSupply()

    ul_balance: uint256 = 0
    underlying_pct: uint256 = 0
    if base_total_supply > 0:
        underlying_pct = CurvePool(_pool).balances(base_coin_idx) * 10**36 / base_total_supply

    underlying_balances: uint256[MAX_METAREGISTRY_COINS] = empty(uint256[MAX_METAREGISTRY_COINS])
    ul_coins: address[MAX_METAREGISTRY_COINS] = self._get_underlying_coins_for_metapool(_pool)
    for i in range(MAX_METAREGISTRY_COINS):

        if ul_coins[i] == empty(address):
            break

        if i < base_coin_idx:
            ul_balance = CurvePool(_pool).balances(i)

        else:

            if self.base_pool_registry.is_legacy(base_pool):
                ul_balance = StableSwapLegacy(base_pool).balances(convert(i - base_coin_idx, int128))
            else:
                ul_balance = CurvePool(base_pool).balances(i - base_coin_idx)
            ul_balance = ul_balance * underlying_pct / 10**36
        underlying_balances[i] = ul_balance

    return underlying_balances


@internal
@view
def _get_pool_from_lp_token(_lp_token: address) -> address:
    max_pools: uint256 = self.base_registry.pool_count()
    for i in range(MAX_POOLS):
        if i == max_pools:
            break
        pool: address = self.base_registry.pool_list(i)
        token: address = self._get_lp_token(pool)
        if token == _lp_token:
            return pool
    return empty(address)


@internal
@view
def _get_gauge_type(_gauge: address) -> int128:

    # try to get gauge type registered in gauge controller
    success: bool = False
    response: Bytes[32] = b""
    success, response = raw_call(
        GAUGE_CONTROLLER,
        concat(
            method_id("gauge_type(address)"),
            convert(_gauge, bytes32),
        ),
        max_outsize=32,
        revert_on_failure=False,
        is_static_call=True
    )

    if success and not Gauge(_gauge).is_killed():
        return convert(response, int128)

    # if we are here, the call to get gauge_type failed.
    # in such a case, return a default value.
    # ethereum: mainnet crypto pools have gauge type 5
    return 5


# ---- view methods (API) of the contract ---- #
@external
@view
def find_pool_for_coins(_from: address, _to: address, i: uint256 = 0) -> address:
    """
    @notice checks if either of the two coins are in a base pool and then checks
            if the basepool lp token and the other coin have a pool.
            This is done because the factory does not have `underlying` methods in
            pools that have a basepool lp token in them
    @param _from Address of the _from coin
    @param _to Address of the _to coin
    @param i Index of the pool to return
    @return Address of the pool
    """
    _pool: address = self.base_registry.find_pool_for_coins(_from, _to, i)

    if _pool != empty(address):
        return _pool

    # could not find a pool for the coins for `i`. check if they are in a base pool:
    _pools: address[1000] = empty(address[1000])
    _num_metapool_pairs: uint256 = 0

    for coin in [_from, _to]:

        # we need to loop over several base pools because a coin can exist in multiple base pools
        base_pools: DynArray[address, 1000] = self.base_pool_registry.get_basepools_for_coin(coin)

        if len(base_pools) == 0:
            continue

        for _base_pool in base_pools:

            # found a base pool, but is it the right one?
            if _base_pool != empty(address):

                base_pool_lp_token: address = self.base_pool_registry.get_lp_token(_base_pool)

                for k in range(100):

                    if coin == _from:

                        # check if the basepool containing the _from coin has a pair with the _to coin:
                        _pool = self.base_registry.find_pool_for_coins(base_pool_lp_token, _to, k)

                        if _pool == empty(address):
                            break

                        # only append if a pool is found:
                        _pools[_num_metapool_pairs] = _pool
                        _num_metapool_pairs += 1

                    elif coin == _to:

                        # check if the basepool containing the _to coin has a pair with the _from coin:
                        _pool = self.base_registry.find_pool_for_coins(_from, base_pool_lp_token, k)

                        if _pool == empty(address):
                            break

                        # only append if a pool is found:
                        _pools[_num_metapool_pairs] = _pool
                        _num_metapool_pairs += 1

    # say we found a pair for _from and _to in the base registry without a basepool combination already
    # then that pool will be returned when i == 0. But if that same pair exists in a base pool then
    # i == 1 will return empty(address) in the base_registry query, but i = 0 for _pools will return
    # the metapool pair. But if we keep i == 1 for _pools, it would return empty(address) (unless there
    # is another metapool pair of course). So, we first check how many direct pairs exist:

    num_pairs: uint256 = 0
    for k in range(20):
        _pool = self.base_registry.find_pool_for_coins(_from, _to, k)
        if _pool == empty(address):
            break
        num_pairs += 1

    # now we check if the queried pair index `i` is higher than num_pairs. e.g. if num_pairs == 1 and i == 1,
    # and _num_metapool_pairs == 1, then i >= num_pairs, and we return _pools[1 - num_pairs]. If there are
    # no metapool pairs, then it will automatically return empty(address):
    if i >= num_pairs:
        return _pools[i - num_pairs]
    else:
        return _pools[i]


@external
@view
def get_admin_balances(_pool: address) -> uint256[MAX_METAREGISTRY_COINS]:
    """
    @notice Returns the balances of the admin tokens of the given pool
    @dev Cryptoswap pools do not store admin fees in the form of
         admin token balances. Instead, the admin fees are computed
         at the time of claim iff sufficient profits have been made.
         These fees are allocated to the admin by minting LP tokens
         (dilution). The logic to calculate fees are derived from
         cryptopool._claim_admin_fees() method.
    @param _pool Address of the pool
    @return uint256[MAX_METAREGISTRY_COINS] Array of admin balances
    """
    xcp_profit: uint256 = CurvePool(_pool).xcp_profit()
    xcp_profit_a: uint256 = CurvePool(_pool).xcp_profit_a()
    admin_fee: uint256 = CurvePool(_pool).admin_fee()
    admin_balances: uint256[MAX_METAREGISTRY_COINS] = empty(uint256[MAX_METAREGISTRY_COINS])

    # admin balances are non zero if pool has made more than allowed profits:
    if xcp_profit > xcp_profit_a:

        # calculate admin fees in lp token amounts:
        fees: uint256 = (xcp_profit - xcp_profit_a) * admin_fee / (2 * 10**10)
        if fees > 0:
            vprice: uint256 = CurvePool(_pool).virtual_price()
            lp_token: address = self._get_lp_token(_pool)
            frac: uint256 = vprice * 10**18 / (vprice - fees) - 10**18

            # the total supply of lp token is current supply + claimable:
            lp_token_total_supply: uint256 = ERC20(lp_token).totalSupply()
            d_supply: uint256 = lp_token_total_supply * frac / 10**18
            lp_token_total_supply += d_supply
            admin_lp_frac: uint256 = d_supply * 10 ** 18 / lp_token_total_supply

            # get admin balances in individual assets:
            reserves: uint256[MAX_METAREGISTRY_COINS] = self._get_balances(_pool)
            for i in range(MAX_METAREGISTRY_COINS):
                admin_balances[i] = admin_lp_frac * reserves[i] / 10 ** 18

    return admin_balances


@external
@view
def get_balances(_pool: address) -> uint256[MAX_METAREGISTRY_COINS]:
    """
    @notice Returns the balances of the tokens of the given pool
    @param _pool Address of the pool
    @return uint256[MAX_METAREGISTRY_COINS] Array of balances
    """
    return self._get_balances(_pool)


@external
@view
def get_base_pool(_pool: address) -> address:
    """
    @notice Returns the base pool of the given pool
    @dev Returns empty(address) if the pool isn't a metapool
    @param _pool Address of the pool
    @return Address of the base pool
    """
    if not self._is_meta(_pool):
        return empty(address)
    return self._get_base_pool(_pool)


@view
@external
def get_coin_indices(_pool: address, _from: address, _to: address) -> (uint256, uint256, bool):
    """
    @notice Convert coin addresses to indices for use with pool methods
    @param _pool Address of the pool
    @param _from Address of the from coin
    @param _to Address of the to coin
    @return (uint256, uint256, bool) Tuple of indices of the coins in the pool,
            and whether the market is an underlying market or not.
    """
    # the return value is stored as `uint256[3]` to reduce gas costs
    # from index, to index, is the market underlying?
    result: uint256[3] = empty(uint256[3])
    _coins: address[MAX_METAREGISTRY_COINS] = self._get_coins(_pool)
    found_market: bool = False

    # check coin markets
    for x in range(MAX_METAREGISTRY_COINS):
        coin: address = _coins[x]
        if coin == empty(address):
            # if we reach the end of the coins, reset `found_market` and try again
            # with the underlying coins
            found_market = False
            break
        if coin == _from:
            result[0] = x
        elif coin == _to:
            result[1] = x
        else:
            continue

        if found_market:
            # the second time we find a match, break out of the loop
            break
        # the first time we find a match, set `found_market` to True
        found_market = True

    if not found_market and self._is_meta(_pool):
        # check underlying coin markets
        underlying_coins: address[MAX_METAREGISTRY_COINS] = self._get_underlying_coins_for_metapool(_pool)
        for x in range(MAX_METAREGISTRY_COINS):
            coin: address = underlying_coins[x]
            if coin == empty(address):
                raise "No available market"
            if coin == _from:
                result[0] = x
            elif coin == _to:
                result[1] = x
            else:
                continue

            if found_market:
                result[2] = 1
                break
            found_market = True

    return result[0], result[1], result[2] > 0


@external
@view
def get_coins(_pool: address) -> address[MAX_METAREGISTRY_COINS]:
    """
    @notice Returns the coins of the given pool
    @param _pool Address of the pool
    @return address[MAX_METAREGISTRY_COINS] Array of coins
    """
    return self._get_coins(_pool)


@external
@view
def get_decimals(_pool: address) -> uint256[MAX_METAREGISTRY_COINS]:
    """
    @notice Returns the decimals of the coins in a given pool
    @param _pool Address of the pool
    @return uint256[MAX_METAREGISTRY_COINS] Array of decimals
    """
    return self._get_decimals(_pool)


@external
@view
def get_fees(_pool: address) -> uint256[10]:
    """
    @notice Returns the fees of the given pool
    @param _pool Address of the pool
    @return uint256[10] Array of fees. Fees are arranged as:
            1. swap fee (or `fee`)
            2. admin fee
            3. mid fee (fee when cryptoswap pool is pegged)
            4. out fee (fee when cryptoswap pool depegs)
    """
    fees: uint256[10] = empty(uint256[10])
    pool_fees: uint256[4] = [CurvePool(_pool).fee(), CurvePool(_pool).admin_fee(), CurvePool(_pool).mid_fee(), CurvePool(_pool).out_fee()]
    for i in range(4):
        fees[i] = pool_fees[i]
    return fees


@external
@view
def get_gauges(_pool: address) -> (address[10], int128[10]):
    """
    @notice Returns the gauges of the given pool
    @param _pool Address of the pool
    @return (address[10], int128[10]) Tuple of gauges. Gauges are arranged as:
            1. gauge addresses
            2. gauge types
    """
    gauges: address[10] = empty(address[10])
    types: int128[10] = empty(int128[10])
    gauges[0] = self.base_registry.get_gauge(_pool)
    types[0] = self._get_gauge_type(gauges[0])
    return (gauges, types)


@external
@view
def get_lp_token(_pool: address) -> address:
    """
    @notice Returns the Liquidity Provider token of the given pool
    @param _pool Address of the pool
    @return Address of the Liquidity Provider token
    """
    return self._get_lp_token(_pool)


@external
@view
def get_n_coins(_pool: address) -> uint256:
    """
    @notice Returns the number of coins in the given pool
    @param _pool Address of the pool
    @return uint256 Number of coins
    """
    return self._get_n_coins(_pool)


@external
@view
def get_n_underlying_coins(_pool: address) -> uint256:
    """
    @notice Get the number of underlying coins in a pool
    @param _pool Address of the pool
    @return uint256 Number of underlying coins
    """
    _coins: address[MAX_METAREGISTRY_COINS] = empty(address[MAX_METAREGISTRY_COINS])

    if self._is_meta(_pool):
        _coins = self._get_underlying_coins_for_metapool(_pool)
    else:
        _coins = self._get_coins(_pool)

    for i in range(MAX_METAREGISTRY_COINS):
        if _coins[i] == empty(address):
            return i
    raise


@external
@view
def get_pool_asset_type(_pool: address) -> uint256:
    """
    @notice Returns the asset type of the given pool
    @dev Returns 4: 0 = USD, 1 = ETH, 2 = BTC, 3 = Other
    @param _pool Address of the pool
    @return uint256 Asset type
    """
    return 4


@external
@view
def get_pool_from_lp_token(_lp_token: address) -> address:
    """
    @notice Returns the pool of the given Liquidity Provider token
    @param _lp_token Address of the Liquidity Provider token
    @return Address of the pool
    """
    max_pools: uint256 = self.base_registry.pool_count()
    for i in range(MAX_POOLS):
        if i == max_pools:
            break
        pool: address = self.base_registry.pool_list(i)
        token: address = self._get_lp_token(pool)
        if token == _lp_token:
            return pool
    return empty(address)


@external
@view
def get_pool_name(_pool: address) -> String[64]:
    """
    @notice Returns the name of the given pool
    @param _pool Address of the pool
    @return String[64] Name of the pool
    """
    token: address = self._get_lp_token(_pool)
    if token != empty(address):
        return ERC20(self.base_registry.get_token(_pool)).name()
    else:
        return ""


@external
@view
def get_pool_params(_pool: address) -> uint256[20]:
    """
    @notice returns pool params given a cryptopool address
    @dev contains all settable parameter that alter the pool's performance
    @dev only applicable for cryptopools
    @param _pool Address of the pool for which data is being queried.
    """

    pool_params: uint256[20] = empty(uint256[20])
    pool_params[0] = CurvePool(_pool).A()
    pool_params[1] = CurvePool(_pool).D()
    pool_params[2] = CurvePool(_pool).gamma()
    pool_params[3] = CurvePool(_pool).allowed_extra_profit()
    pool_params[4] = CurvePool(_pool).fee_gamma()
    pool_params[5] = CurvePool(_pool).adjustment_step()
    pool_params[6] = CurvePool(_pool).ma_half_time()
    return pool_params


@external
@view
def get_underlying_balances(_pool: address) -> uint256[MAX_METAREGISTRY_COINS]:
    """
    @notice Returns the underlying balances of the given pool
    @param _pool Address of the pool
    @return uint256[MAX_METAREGISTRY_COINS] Array of underlying balances
    """
    if self._is_meta(_pool):
        return self._get_meta_underlying_balances(_pool)
    return self._get_balances(_pool)

@external
@view
def get_underlying_coins(_pool: address) -> address[MAX_METAREGISTRY_COINS]:
    """
    @notice Returns the underlying coins of the given pool
    @param _pool Address of the pool
    @return address[MAX_METAREGISTRY_COINS] Array of underlying coins
    """
    if self._is_meta(_pool):
        return self._get_underlying_coins_for_metapool(_pool)
    return self._get_coins(_pool)


@external
@view
def get_underlying_decimals(_pool: address) -> uint256[MAX_METAREGISTRY_COINS]:
    """
    @notice Returns the underlying decimals of the given pool
    @param _pool Address of the pool
    @return uint256[MAX_METAREGISTRY_COINS] Array of underlying decimals
    """
    if self._is_meta(_pool):
        _underlying_coins: address[MAX_METAREGISTRY_COINS] = self._get_underlying_coins_for_metapool(_pool)
        _decimals: uint256[MAX_METAREGISTRY_COINS] = empty(uint256[MAX_METAREGISTRY_COINS])
        for i in range(MAX_METAREGISTRY_COINS):
            if _underlying_coins[i] == empty(address):
                break
            _decimals[i] = ERC20(_underlying_coins[i]).decimals()
        return _decimals
    return self._get_decimals(_pool)


@external
@view
def get_virtual_price_from_lp_token(_token: address) -> uint256:
    """
    @notice Returns the virtual price of the given Liquidity Provider token
    @param _token Address of the Liquidity Provider token
    @return uint256 Virtual price
    """
    return CurvePool(self._get_pool_from_lp_token(_token)).get_virtual_price()


@external
@view
def is_meta(_pool: address) -> bool:
    """
    @notice Returns whether the given pool is a meta pool
    @param _pool Address of the pool
    @return bool Whether the pool is a meta pool
    """
    return self._is_meta(_pool)


@external
@view
def is_registered(_pool: address) -> bool:
    """
    @notice Check if a pool belongs to the registry using get_n_coins
    @param _pool The address of the pool
    @return A bool corresponding to whether the pool belongs or not
    """
    return self._get_n_coins(_pool) > 0


@external
@view
def pool_count() -> uint256:
    """
    @notice Returns the number of pools in the registry
    @return uint256 Number of pools
    """
    return self.base_registry.pool_count()


@external
@view
def pool_list(_index: uint256) -> address:
    """
    @notice Returns the address of the pool at the given index
    @param _index Index of the pool
    @return Address of the pool
    """
    return self.base_registry.pool_list(_index)