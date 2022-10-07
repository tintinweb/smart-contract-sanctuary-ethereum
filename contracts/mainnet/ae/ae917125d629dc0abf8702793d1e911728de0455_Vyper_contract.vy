# @version 0.3.7
"""
@title Curve CryptoSwap Registry
@license MIT
@author Curve.Fi
"""

MAX_COINS: constant(int128) = 8
CALC_INPUT_SIZE: constant(int128) = 100


struct CoinInfo:
    index: uint256
    register_count: uint256
    swap_count: uint256
    swap_for: address[max_value(int128)]


struct PoolArray:
    location: uint256
    base_pool: address
    n_coins: uint256
    name: String[64]
    has_positive_rebasing_tokens: bool


interface AddressProvider:
    def admin() -> address: view
    def get_address(_id: uint256) -> address: view
    def get_registry() -> address: view

interface ERC20:
    def balanceOf(_addr: address) -> uint256: view
    def decimals() -> uint256: view
    def totalSupply() -> uint256: view

interface CurvePool:
    def token() -> address: view
    def coins(i: uint256) -> address: view
    def A() -> uint256: view
    def gamma() -> uint256: view
    def fee() -> uint256: view
    def get_virtual_price() -> uint256: view
    def mid_fee() -> uint256: view
    def out_fee() -> uint256: view
    def admin_fee() -> uint256: view
    def balances(i: uint256) -> uint256: view
    def D() -> uint256: view
    def xcp_profit() -> uint256: view
    def xcp_profit_a() -> uint256: view

interface StableSwapLegacy:
    def coins(i: int128) -> address: view
    def underlying_coins(i: int128) -> address: view
    def balances(i: int128) -> uint256: view

interface LiquidityGauge:
    def lp_token() -> address: view
    def is_killed() -> bool: view

interface GaugeController:
    def gauge_types(gauge: address) -> int128: view

interface BasePoolRegistry:
    def get_base_pool_for_lp_token(_lp_token: address) ->  address: view
    def get_n_coins(_pool: address) -> uint256: view
    def get_coins(_pool: address) -> address[MAX_COINS]: view
    def get_lp_token(_pool: address) -> address: view
    def is_legacy(_pool: address) -> bool: view


event PoolAdded:
    pool: indexed(address)

event BasePoolAdded:
    basepool: indexed(address)

event PoolRemoved:
    pool: indexed(address)


GAUGE_CONTROLLER: constant(address) = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB

address_provider: public(AddressProvider)
base_pool_registry: public(BasePoolRegistry)
pool_list: public(address[65536])   # master list of pools
pool_count: public(uint256)         # actual length of pool_list
base_pool_count: public(uint256)

pool_data: HashMap[address, PoolArray]

# lp token -> pool
get_pool_from_lp_token: public(HashMap[address, address])

# pool -> lp token
get_lp_token: public(HashMap[address, address])

# mapping of coins -> pools for trading
# a mapping key is generated for each pair of addresses via
# `bitwise_xor(convert(a, uint256), convert(b, uint256))`
markets: HashMap[uint256, address[65536]]
market_counts: HashMap[uint256, uint256]

liquidity_gauges: HashMap[address, address[10]]

# mapping of pool -> deposit/exchange zap
get_zap: public(HashMap[address, address])

last_updated: public(uint256)


@external
def __init__(_address_provider: address, _base_pool_registry: address):
    self.address_provider = AddressProvider(_address_provider)
    self.base_pool_registry = BasePoolRegistry(_base_pool_registry)


# internal functionality for getters

@internal
@view
def _get_coins(_pool: address) -> address[MAX_COINS]:
    _coins: address[MAX_COINS] = empty(address[MAX_COINS])
    for i in range(MAX_COINS):
        if i == convert(self.pool_data[_pool].n_coins, int128):
            break
        _coins[i] = CurvePool(_pool).coins(convert(i, uint256))
    return _coins


@view
@internal
def _get_decimals(_coins: address[MAX_COINS]) -> uint256[MAX_COINS]:
    decimals: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    value: uint256 = 0
    for i in range(MAX_COINS):
        if _coins[i] == empty(address):
            break
        coin: address = _coins[i]
        if coin == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
            value = 18
        else:
            value = ERC20(coin).decimals()
            assert value < 256  # dev: decimal overflow

        decimals[i] = value

    return decimals


@view
@internal
def _get_underlying_coins_for_metapool(_pool: address) -> address[MAX_COINS]:

    base_pool_coins: address[MAX_COINS] = self.base_pool_registry.get_coins(self.pool_data[_pool].base_pool)
    _underlying_coins: address[MAX_COINS] = empty(address[MAX_COINS])
    base_coin_offset: int128 = convert(self.pool_data[_pool].n_coins - 1, int128)
    _coins: address[MAX_COINS] = self._get_coins(_pool)

    for i in range(MAX_COINS):
        if i < base_coin_offset:
            _underlying_coins[i] = _coins[i]
        else:
            _underlying_coins[i] = base_pool_coins[i - base_coin_offset]

    assert _underlying_coins[0] != empty(address)

    return _underlying_coins


@view
@internal
def _get_balances(_pool: address) -> uint256[MAX_COINS]:
    balances: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    _coins: address[MAX_COINS] = self._get_coins(_pool)
    for i in range(MAX_COINS):
        if _coins[i] == empty(address):
            assert i != 0
            break

        balances[i] = CurvePool(_pool).balances(convert(i, uint256))

    return balances


@view
@internal
def _get_meta_underlying_balances(_pool: address) -> uint256[MAX_COINS]:
    base_coin_idx: uint256 = self.pool_data[_pool].n_coins - 1
    base_pool: address = self.pool_data[_pool].base_pool
    base_total_supply: uint256 = ERC20(self.base_pool_registry.get_lp_token(base_pool)).totalSupply()

    underlying_balances: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    ul_balance: uint256 = 0
    underlying_pct: uint256 = 0
    if base_total_supply > 0:
        underlying_pct = CurvePool(_pool).balances(base_coin_idx) * 10**36 / base_total_supply

    ul_coins: address[MAX_COINS] = self._get_underlying_coins_for_metapool(_pool)
    for i in range(MAX_COINS):

        if ul_coins[i] == empty(address):
            break

        if i < convert(base_coin_idx, int128):
            ul_balance = CurvePool(_pool).balances(convert(i, uint256))

        else:

            if self.base_pool_registry.is_legacy(base_pool):
                ul_balance = StableSwapLegacy(base_pool).balances(i - convert(base_coin_idx, int128))
            else:
                ul_balance = CurvePool(base_pool).balances(convert(i, uint256) - base_coin_idx)
            ul_balance = ul_balance * underlying_pct / 10**36
        underlying_balances[i] = ul_balance

    return underlying_balances


@view
@internal
def _is_meta(_pool: address) -> bool:
    return self.pool_data[_pool].base_pool != empty(address)


@view
@internal
def _get_coin_indices(
    _pool: address,
    _from: address,
    _to: address
) -> uint256[3]:
    # the return value is stored as `uint256[3]` to reduce gas costs
    # from index, to index, is the market underlying?
    result: uint256[3] = empty(uint256[3])
    _coins: address[MAX_COINS] = self._get_coins(_pool)
    found_market: bool = False

    # check coin markets
    for x in range(MAX_COINS):
        coin: address = _coins[x]
        if coin == empty(address):
            # if we reach the end of the coins, reset `found_market` and try again
            # with the underlying coins
            found_market = False
            break
        if coin == _from:
            result[0] = convert(x, uint256)
        elif coin == _to:
            result[1] = convert(x, uint256)
        else:
            continue

        if found_market:
            # the second time we find a match, break out of the loop
            break
        # the first time we find a match, set `found_market` to True
        found_market = True

    if not found_market and self._is_meta(_pool):
        # check underlying coin markets
        underlying_coins: address[MAX_COINS] = self._get_underlying_coins_for_metapool(_pool)
        for x in range(MAX_COINS):
            coin: address = underlying_coins[x]
            if coin == empty(address):
                raise "No available market"
            if coin == _from:
                result[0] = convert(x, uint256)
            elif coin == _to:
                result[1] = convert(x, uint256)
            else:
                continue

            if found_market:
                result[2] = 1
                break
            found_market = True

    return result


@internal
@view
def _get_gauge_type(_gauge: address) -> int128:

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

    if success and not LiquidityGauge(_gauge).is_killed():
        return convert(response, int128)

    return 0


# targetted external getters, optimized for on-chain calls


@view
@external
def find_pool_for_coins(_from: address, _to: address, i: uint256 = 0) -> address:
    """
    @notice Find an available pool for exchanging two coins
    @param _from Address of coin to be sent
    @param _to Address of coin to be received
    @param i Index value. When multiple pools are available
            this value is used to return the n'th address.
    @return Pool address
    """
    key: uint256 = convert(_from, uint256) ^ convert(_to, uint256)
    return self.markets[key][i]


@view
@external
def get_n_coins(_pool: address) -> uint256:
    """
    @notice Get the number of coins in a pool
    @dev For non-metapools, both returned values are identical
         even when the pool does not use wrapping/lending
    @param _pool Pool address
    @return uint256 Number of wrapped coins, number of underlying coins
    """
    return self.pool_data[_pool].n_coins


@external
@view
def get_n_underlying_coins(_pool: address) -> uint256:
    """
    @notice Get the number of underlying coins in a pool
    @param _pool Pool address
    @return uint256 Number of underlying coins
    """
    if not self._is_meta(_pool):
        return self.pool_data[_pool].n_coins

    base_pool: address = self.pool_data[_pool].base_pool
    return self.pool_data[_pool].n_coins + self.base_pool_registry.get_n_coins(base_pool) - 1


@view
@external
def get_coins(_pool: address) -> address[MAX_COINS]:
    """
    @notice Get the coins within a pool
    @dev For pools using lending, these are the wrapped coin addresses
    @param _pool Pool address
    @return address[MAX_COINS] List of coin addresses
    """
    return self._get_coins(_pool)


@view
@external
def get_underlying_coins(_pool: address) -> address[MAX_COINS]:
    """
    @notice Get the underlying coins within a pool
    @dev For pools that do not lend, returns the same value as `get_coins`
    @param _pool Pool address
    @return address[MAX_COINS] of coin addresses
    """
    if self._is_meta(_pool):
        return self._get_underlying_coins_for_metapool(_pool)
    return self._get_coins(_pool)


@view
@external
def get_decimals(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get decimal places for each coin within a pool
    @dev For pools using lending, these are the wrapped coin decimal places
    @param _pool Pool address
    @return uint256 list of decimals
    """
    _coins: address[MAX_COINS] = self._get_coins(_pool)
    return self._get_decimals(_coins)


@view
@external
def get_underlying_decimals(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get decimal places for each underlying coin within a pool
    @dev For pools that do not lend, returns the same value as `get_decimals`
    @param _pool Pool address
    @return uint256 list of decimals
    """
    if self._is_meta(_pool):
        _underlying_coins: address[MAX_COINS] = self._get_underlying_coins_for_metapool(_pool)
        _decimals: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
        for i in range(MAX_COINS):
            if _underlying_coins[i] == empty(address):
                break
            _decimals[i] = ERC20(_underlying_coins[i]).decimals()
        return _decimals

    _coins: address[MAX_COINS] = self._get_coins(_pool)
    return self._get_decimals(_coins)


@view
@external
def get_gauges(_pool: address) -> (address[10], int128[10]):
    """
    @notice Get a list of LiquidityGauge contracts associated with a pool
    @param _pool Pool address
    @return address[10] of gauge addresses, int128[10] of gauge types
    """
    liquidity_gauges: address[10] = empty(address[10])
    gauge_types: int128[10] = empty(int128[10])
    for i in range(10):
        gauge: address = self.liquidity_gauges[_pool][i]
        if gauge == empty(address):
            break
        liquidity_gauges[i] = gauge
        gauge_types[i] = GaugeController(GAUGE_CONTROLLER).gauge_types(gauge)

    return liquidity_gauges, gauge_types


@view
@external
def get_balances(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get balances for each coin within a pool
    @dev For pools using lending, these are the wrapped coin balances
    @param _pool Pool address
    @return uint256 list of balances
    """
    return self._get_balances(_pool)


@view
@external
def get_underlying_balances(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get balances for each underlying coin within a pool
    @dev  For pools that do not lend, returns the same value as `get_balances`
    @param _pool Pool address
    @return uint256 list of underlyingbalances
    """
    if not self._is_meta(_pool):
        return self._get_balances(_pool)
    return self._get_meta_underlying_balances(_pool)


@view
@external
def get_virtual_price_from_lp_token(_token: address) -> uint256:
    """
    @notice Get the virtual price of a pool LP token
    @param _token LP token address
    @return uint256 Virtual price
    """
    return CurvePool(self.get_pool_from_lp_token[_token]).get_virtual_price()


@view
@external
def get_A(_pool: address) -> uint256:
    """
    @notice Get a pool's amplification factor
    @param _pool Pool address
    @return uint256 Amplification factor
    """
    return CurvePool(_pool).A()


@view
@external
def get_D(_pool: address) -> uint256:
    """
    @notice Get invariant of a pool's curve
    @param _pool Pool address
    @return uint256 Invariant
    """
    return CurvePool(_pool).D()


@view
@external
def get_gamma(_pool: address) -> uint256:
    """
    @notice Get the pool's gamma parameter
    @param _pool Pool address
    @return uint256 Gamma parameter
    """
    return CurvePool(_pool).gamma()


@view
@external
def get_fees(_pool: address) -> uint256[4]:
    """
    @notice Get the fees for a pool
    @dev Fees are expressed as integers
    @param _pool Pool address
    @return Pool fee as uint256 with 1e10 precision
            Admin fee as 1e10 percentage of pool fee
            Mid fee
            Out fee
    """
    return [CurvePool(_pool).fee(), CurvePool(_pool).admin_fee(), CurvePool(_pool).mid_fee(), CurvePool(_pool).out_fee()]


@external
@view
def get_admin_balances(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get the admin balances for a pool (accrued fees)
    @dev Cryptoswap pools do not store admin fees in the form of
         admin token balances. Instead, the admin fees are computed
         at the time of claim iff sufficient profits have been made.
         These fees are allocated to the admin by minting LP tokens
         (dilution). The logic to calculate fees are derived from
         cryptopool._claim_admin_fees() method.
    @param _pool Pool address
    @return uint256 list of admin balances
    """
    xcp_profit: uint256 = CurvePool(_pool).xcp_profit()
    xcp_profit_a: uint256 = CurvePool(_pool).xcp_profit_a()
    admin_fee: uint256 = CurvePool(_pool).admin_fee()
    admin_balances: uint256[MAX_COINS] = empty(uint256[MAX_COINS])

    # admin balances are non zero if pool has made more than allowed profits:
    if xcp_profit > xcp_profit_a:

        # calculate admin fees in lp token amounts:
        fees: uint256 = (xcp_profit - xcp_profit_a) * admin_fee / (2 * 10**10)
        if fees > 0:
            vprice: uint256 = CurvePool(_pool).get_virtual_price()
            lp_token: address = self.get_lp_token[_pool]
            frac: uint256 = vprice * 10**18 / (vprice - fees) - 10**18

            # the total supply of lp token is current supply + claimable:
            lp_token_total_supply: uint256 = ERC20(lp_token).totalSupply()
            d_supply: uint256 = lp_token_total_supply * frac / 10**18
            lp_token_total_supply += d_supply
            admin_lp_frac: uint256 = d_supply * 10 ** 18 / lp_token_total_supply

            # get admin balances in individual assets:
            reserves: uint256[MAX_COINS] = self._get_balances(_pool)
            for i in range(MAX_COINS):
                admin_balances[i] = admin_lp_frac * reserves[i] / 10 ** 18

    return admin_balances


@view
@external
def get_coin_indices(
    _pool: address,
    _from: address,
    _to: address
) -> (int128, int128, bool):
    """
    @notice Convert coin addresses to indices for use with pool methods
    @param _pool Pool address
    @param _from Coin address to be used as `i` within a pool
    @param _to Coin address to be used as `j` within a pool
    @return int128 `i`, int128 `j`, boolean indicating if `i` and `j` are underlying coins
    """
    result: uint256[3] = self._get_coin_indices(_pool, _from, _to)
    return convert(result[0], int128), convert(result[1], int128), result[2] > 0


@view
@external
def is_meta(_pool: address) -> bool:
    """
    @notice Verify `_pool` is a metapool
    @param _pool Pool address
    @return True if `_pool` is a metapool
    """
    return self.pool_data[_pool].base_pool != empty(address)


@view
@external
def get_base_pool(_pool: address) -> address:
    """
    @notice Get the base pool of a metapool
    @param _pool Pool address
    @return Base pool address
    """
    return self.pool_data[_pool].base_pool


@view
@external
def get_pool_name(_pool: address) -> String[64]:
    """
    @notice Get the given name for a pool
    @param _pool Pool address
    @return The name of a pool
    """
    return self.pool_data[_pool].name


# internal functionality used in admin setters


@internal
def _add_coins_to_market(_pool: address, _coin_list: address[MAX_COINS], _is_underlying: bool = False):

    for i in range(MAX_COINS):

        if _coin_list[i] == empty(address):
            break

        # we dont want underlying <> underlying markets
        # since that should be covered by the base_pool
        # and not _pool: underlying <> underlying swaps
        # happen at the base_pool level, not at the _pool
        # level:
        if _is_underlying and i > 0:
            break

        # add pool to markets
        i2: int128 = i + 1
        for x in range(i2, i2 + MAX_COINS):

            if _coin_list[x] == empty(address):
                break

            key: uint256 = (
                convert(_coin_list[i], uint256) ^ convert(_coin_list[x], uint256)
            )
            length: uint256 = self.market_counts[key]
            self.markets[key][length] = _pool
            self.market_counts[key] = length + 1


@internal
@view
def _market_exists(_pool: address, _coina: address, _coinb: address) -> bool:
    key: uint256 = convert(_coina, uint256) ^ convert(_coinb, uint256)
    if self.market_counts[key] == 0:
        return False
    return True


@internal
def _remove_market(_pool: address, _coina: address, _coinb: address):

    key: uint256 = convert(_coina, uint256) ^ convert(_coinb, uint256)
    length: uint256 = self.market_counts[key] - 1

    for i in range(65536):
        if i > length:
            break
        if self.markets[key][i] == _pool:
            if i < length:
                self.markets[key][i] = self.markets[key][length]
            self.markets[key][length] = empty(address)
            self.market_counts[key] = length
            break


@internal
def _remove_liquidity_gauges(_pool: address):
    for i in range(10):
        if self.liquidity_gauges[_pool][i] != empty(address):
            self.liquidity_gauges[_pool][i] = empty(address)
        else:
            break


# admin functions


@external
def add_pool(
    _pool: address,
    _lp_token: address,
    _gauge: address,
    _zap: address,
    _n_coins: uint256,
    _name: String[64],
    _base_pool: address = empty(address),
    _has_positive_rebasing_tokens: bool = False
):
    """
    @notice Add a pool to the registry
    @dev Only callable by admin
    @param _pool Pool address to add
    @param _lp_token Pool deposit token address
    @param _gauge Gauge address
    @param _zap Zap address
    @param _n_coins Number of coins in the pool
    @param _name The name of the pool
    @param _base_pool Address of base pool
    @param _has_positive_rebasing_tokens pool contains positive rebasing tokens
    """
    assert msg.sender == self.address_provider.admin()  # dev: admin-only function
    assert _lp_token != empty(address)
    assert self.get_pool_from_lp_token[_lp_token] == empty(address)  # dev: pool exists

    # initialise PoolArray struct
    length: uint256 = self.pool_count
    self.pool_list[length] = _pool
    self.pool_count = length + 1
    self.pool_data[_pool].location = length
    self.pool_data[_pool].name = _name
    self.pool_data[_pool].n_coins = _n_coins

    # update public mappings
    if _zap != empty(address):
        self.get_zap[_pool] = _zap

    if _gauge != empty(address):
        self.liquidity_gauges[_pool][0] = _gauge

    self.get_pool_from_lp_token[_lp_token] = _pool
    self.get_lp_token[_pool] = _lp_token

    # add coins mappings:
    _coins: address[MAX_COINS] = empty(address[MAX_COINS])
    for i in range(MAX_COINS):
        if i == convert(_n_coins, int128):
            break
        _coins[i] = CurvePool(_pool).coins(convert(i, uint256))
    self._add_coins_to_market(_pool, _coins)

    # the following does not add basepool_lp_token <> underlying_coin mapping
    # since that is redundant:
    if _base_pool != empty(address):
        assert self.base_pool_registry.get_lp_token(_base_pool) != empty(address)
        self.pool_data[_pool].base_pool = _base_pool

        _underlying_coins: address[MAX_COINS] = self._get_underlying_coins_for_metapool(_pool)
        assert _underlying_coins[0] != empty(address)

        self._add_coins_to_market(_pool, _underlying_coins, True)

    if _has_positive_rebasing_tokens:
        self.pool_data[_pool].has_positive_rebasing_tokens = True

    # log pool added:
    self.last_updated = block.timestamp
    log PoolAdded(_pool)


@external
def remove_pool(_pool: address):
    """
    @notice Remove a pool to the registry
    @dev Only callable by admin
    @param _pool Pool address to remove
    """
    assert msg.sender == self.address_provider.admin()  # dev: admin-only function
    assert self.get_lp_token[_pool] != empty(address)  # dev: pool does not exist

    self.get_pool_from_lp_token[self.get_lp_token[_pool]] = empty(address)
    self.get_lp_token[_pool] = empty(address)

    # remove _pool from pool_list
    location: uint256 = self.pool_data[_pool].location
    length: uint256 = self.pool_count - 1

    # because self.pool_list is a static array,
    # we can replace the last index with empty(address)
    # and replace the first index with the pool
    # that was previously in the last index.
    # we skip this step if location == last index
    if location < length:
        # replace _pool with final value in pool_list
        addr: address = self.pool_list[length]
        self.pool_list[location] = addr
        self.pool_data[addr].location = location

    # delete final pool_list value
    self.pool_list[length] = empty(address)
    self.pool_count = length

    coins: address[MAX_COINS] = self._get_coins(_pool)
    ucoins: address[MAX_COINS] = empty(address[MAX_COINS])
    is_meta: bool = self._is_meta(_pool)
    if is_meta:
        ucoins = self._get_underlying_coins_for_metapool(_pool)

    for i in range(MAX_COINS):

        if coins[i] == empty(address) and ucoins[i] == empty(address):
            break

        for j in range(MAX_COINS):

            if not j > i:
                continue

            if empty(address) not in [coins[i], coins[j]] and self._market_exists(_pool, coins[i], coins[j]):
                self._remove_market(_pool, coins[i], coins[j])

            if empty(address) not in [coins[i], ucoins[j]] and self._market_exists(_pool, coins[i], ucoins[j]):
                self._remove_market(_pool, coins[i], ucoins[j])

    # reset remaining mappings:
    self.pool_data[_pool].base_pool = empty(address)
    self.pool_data[_pool].n_coins = 0
    self.pool_data[_pool].name = ""
    self.get_zap[_pool] = empty(address)
    self._remove_liquidity_gauges(_pool)

    self.last_updated = block.timestamp
    log PoolRemoved(_pool)


@external
def set_liquidity_gauges(_pool: address, _liquidity_gauges: address[10]):
    """
    @notice Set liquidity gauge contracts
    @param _pool Pool address
    @param _liquidity_gauges Liquidity gauge address
    """
    assert msg.sender == self.address_provider.admin()  # dev: admin-only function

    _lp_token: address = self.get_lp_token[_pool]
    for i in range(10):
        _gauge: address = _liquidity_gauges[i]
        if _gauge != empty(address):
            assert LiquidityGauge(_gauge).lp_token() == _lp_token  # dev: wrong token
            self.liquidity_gauges[_pool][i] = _gauge
        elif self.liquidity_gauges[_pool][i] != empty(address):
            self.liquidity_gauges[_pool][i] = empty(address)
        else:
            break
    self.last_updated = block.timestamp


@external
def batch_set_liquidity_gauges(_pools: address[10], _liquidity_gauges: address[10]):
    """
    @notice Set many liquidity gauge contracts
    @param _pools List of pool addresses
    @param _liquidity_gauges List of liquidity gauge addresses
    """
    assert msg.sender == self.address_provider.admin()  # dev: admin-only function

    for i in range(10):
        _pool: address = _pools[i]
        if _pool == empty(address):
            break
        _gauge: address = _liquidity_gauges[i]
        assert LiquidityGauge(_gauge).lp_token() == self.get_lp_token[_pool]  # dev: wrong token
        self.liquidity_gauges[_pool][0] = _gauge

    self.last_updated = block.timestamp