# @version 0.3.4
"""
@title Zap for Curve Factory
@license MIT
@author Curve.Fi
@notice Zap for StableSwap Factory metapools created via CryptoSwap Factory.
        Coins are set as [[meta0, base0, base1, ...], [meta1, ...]],
        where meta is coin that is used in CryptoSwap(LP token for base pools) and
        base is base pool coins or ZERO_ADDRESS when there is no such coins.
@dev Does not work if 2 ETH used in pools, e.g. (ETH, Plain2ETH)
"""


interface ERC20:  # Custom ERC20 which works for USDT, WETH, WBTC and Curve LP Tokens
    def transfer(_receiver: address, _amount: uint256): nonpayable
    def transferFrom(_sender: address, _receiver: address, _amount: uint256): nonpayable
    def approve(_spender: address, _amount: uint256): nonpayable
    def balanceOf(_owner: address) -> uint256: view


interface wETH:
    def deposit(): payable
    def withdraw(_amount: uint256): nonpayable


# CurveCryptoSwap2ETH from Crypto Factory
interface CurveMeta:
    def coins(i: uint256) -> address: view
    def token() -> address: view
    def price_oracle() -> uint256: view
    def price_scale() -> uint256: view
    def lp_price() -> uint256: view
    def get_dy(i: uint256, j: uint256, dx: uint256) -> uint256: view
    def calc_token_amount(amounts: uint256[META_N_COINS]) -> uint256: view
    def calc_withdraw_one_coin(token_amount: uint256, i: uint256) -> uint256: view
    def exchange(i: uint256, j: uint256, dx: uint256, min_dy: uint256, use_eth: bool = False, receiver: address = msg.sender) -> uint256: payable
    def add_liquidity(amounts: uint256[META_N_COINS], min_mint_amount: uint256, use_eth: bool = False, receiver: address = msg.sender) -> uint256: payable
    def remove_liquidity(_amount: uint256, min_amounts: uint256[META_N_COINS], use_eth: bool = False, receiver: address = msg.sender): nonpayable
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256, use_eth: bool = False, receiver: address = msg.sender) -> uint256: nonpayable


interface Factory:
    def get_coins(_pool: address) -> address[BASE_MAX_N_COINS]: view
    def get_n_coins(_pool: address) -> (uint256): view


# Plain2* from StableSwap Factory
interface CurveBase:
    def get_virtual_price() -> uint256: view
    def coins(i: uint256) -> address: view
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view
    def calc_withdraw_one_coin(_burn_amount: uint256, i: int128) -> uint256: view
    def exchange(i: int128, j: int128, _dx: uint256, _min_dy: uint256, _receiver: address = msg.sender) -> uint256: payable
    def remove_liquidity_one_coin(_burn_amount: uint256, i: int128, _min_received: uint256, _receiver: address = msg.sender) -> uint256: nonpayable


interface CurveBase2:
    def add_liquidity(_amounts: uint256[2], _min_mint_amount: uint256, _receiver: address = msg.sender) -> uint256: payable
    def remove_liquidity(_burn_amount: uint256, _min_amounts: uint256[2], _receiver: address = msg.sender) -> uint256[2]: nonpayable
    def calc_token_amount(_amounts: uint256[2], _is_deposit: bool) -> uint256: view


interface CurveBase3:
    def add_liquidity(_amounts: uint256[3], _min_mint_amount: uint256, _receiver: address = msg.sender) -> uint256: payable
    def remove_liquidity(_burn_amount: uint256, _min_amounts: uint256[3], _receiver: address = msg.sender) -> uint256[3]: nonpayable
    def calc_token_amount(_amounts: uint256[3], _is_deposit: bool) -> uint256: view


interface CurveBase4:
    def add_liquidity(_amounts: uint256[4], _min_mint_amount: uint256, _receiver: address = msg.sender) -> uint256: payable
    def remove_liquidity(_burn_amount: uint256, _min_amounts: uint256[4], _receiver: address = msg.sender) -> uint256[4]: nonpayable
    def calc_token_amount(_amounts: uint256[4], _is_deposit: bool) -> uint256: view


META_N_COINS: constant(uint256) = 2
BASE_MAX_N_COINS: constant(uint256) = 4
POOL_N_COINS: constant(uint256) = 1 + BASE_MAX_N_COINS

ETH_ADDRESS: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: immutable(wETH)
STABLE_FACTORY: immutable(Factory)

# coin -> pool -> is approved to transfer?
is_approved: HashMap[address, HashMap[address, bool]]


@external
def __init__(_weth: address, _stable_factory: address):
    """
    @notice Contract constructor
    """
    WETH = wETH(_weth)
    STABLE_FACTORY = Factory(_stable_factory)


@external
@payable
def __default__():
    assert msg.sender.is_contract  # dev: receive only from pools and WETH


# ------------ View methods ------------


@external
@view
def get_coins(_pool: address) -> address[POOL_N_COINS][META_N_COINS]:
    """
    @notice Get coins of the pool in current zap representation
    @param _pool Address of the pool
    @return Addresses of coins used in zap
    """
    coins: address[POOL_N_COINS][META_N_COINS] = empty(address[POOL_N_COINS][META_N_COINS])

    for i in range(META_N_COINS):
        # Set i-th meta coin
        coins[i][0] = CurveMeta(_pool).coins(i)

        # Set base coins
        # If meta coin is not LP Token, `get_coins()` will return [ZERO_ADDRESS] * 4
        base_coins: address[BASE_MAX_N_COINS] = STABLE_FACTORY.get_coins(coins[i][0])
        for j in range(BASE_MAX_N_COINS):
            coins[i][1 + j] = base_coins[j]

    return coins


@external
@view
def coins(_pool: address, _i: uint256) -> address:
    """
    @notice Get coins of the pool in current zap representation
    @param _pool Address of the pool
    @param _i Index of the coin
    @return Address of `_i` coin used in zap
    """
    i_pool: uint256 = _i / POOL_N_COINS
    coin: address = CurveMeta(_pool).coins(i_pool)

    # If coin is in base pool
    if _i % POOL_N_COINS > 0:
        adjusted_i: uint256 = _i % POOL_N_COINS - 1
        coin = CurveBase(coin).coins(adjusted_i)

    return coin


@internal
@view
def _calc_price(_pool: address, _0_in_1: bool, _meta_price: uint256) -> uint256:
    """
    @notice Calculate price from base token to another base token
    @param _pool Address of base pool
    @param _0_in_1 If True, calculate price of `0` coin in `1` coin, inverse otherwise
    @param _meta_price Price of `meta1` in terms of `meta0`
    @return Price with base = 10 ** 18
    """
    vprices: uint256[META_N_COINS] = [10 ** 18, 10 ** 18]
    for i in range(META_N_COINS):
        coin: address = CurveMeta(_pool).coins(i)
        n_coins: uint256 = STABLE_FACTORY.get_n_coins(coin)
        # n_coins = 0 for not LP Tokens
        if n_coins > 0:
            vprices[i] = CurveBase(coin).get_virtual_price()

    # base0 <--vp[0]-- meta0 <--_meta_price-- meta1 --vp[1]--> base1
    if _0_in_1:
        return (vprices[1] * 10 ** 18 / vprices[0]) * 10 ** 18 / _meta_price
    else:
        return vprices[0] * _meta_price / vprices[1]


@external
@view
def price_oracle(_pool: address, _0_in_1: bool = True) -> uint256:
    """
    @notice Oracle price for underlying assets
    @param _pool Address of the pool
    @param _0_in_1 If True, calculate price of `0` coin in `1` coin, inverse otherwise
    @return Price with base = 10 ** 18
    """
    price: uint256 = CurveMeta(_pool).price_oracle()
    return self._calc_price(_pool, _0_in_1, price)


@external
@view
def price_scale(_pool: address, _0_in_1: bool = True) -> uint256:
    """
    @notice Price scale for underlying assets
    @param _pool Address of the pool
    @param _0_in_1 If True, calculate price of `0` coin in `1` coin, inverse otherwise
    @return Price with base = 10 ** 18
    """
    price: uint256 = CurveMeta(_pool).price_scale()
    return self._calc_price(_pool, _0_in_1, price)


@external
@view
def lp_price(_pool: address, _i: uint256 = 0) -> uint256:
    """
    @notice Price of LP token calculated in `_i` underlying asset
    @param _pool Address of the pool
    @param _i Index of asset to calculate the price in (0 or 1)
    @return LP Token price with base = 10 ** 18
    """
    p: uint256 = CurveMeta(_pool).lp_price()  # Price in `0`
    coin: address = CurveMeta(_pool).coins(_i)
    n_coins: uint256 = STABLE_FACTORY.get_n_coins(coin)
    vprice: uint256 = 10 ** 18
    if n_coins > 0:
        vprice = CurveBase(coin).get_virtual_price()

    # lp --p--> meta0
    if _i == 0:
        # --vp--> base0
        return p * vprice / 10 ** 18
    else:
        # <--price-- meta1 --vp--> base1
        price: uint256 = CurveMeta(_pool).price_oracle()
        return p * vprice / price


# --------------- Helpers --------------


@internal
@payable
def _receive(_coin: address, _amount: uint256, _use_eth: bool, _eth: bool) -> uint256:
    """
    @notice Transfer coin to zap
    @param _coin Address of the coin
    @param _amount Amount of coin
    @param _from Sender of the coin
    @param _eth_value Eth value sent
    @param _use_eth Use raw ETH
    @param _eth Pool uses ETH_ADDRESS for ETH
    @return Received ETH amount
    """
    coin: address = _coin
    if coin == ETH_ADDRESS:
        coin = WETH.address  # Receive weth if not _use_eth

    if _use_eth and coin == WETH.address:
        assert msg.value == _amount  # dev: incorrect ETH amount
        if _eth and _coin == WETH.address and _amount > 0:
            WETH.deposit(value=_amount)
        else:
            return _amount
    elif _amount > 0:
        response: Bytes[32] = raw_call(
            coin,
            _abi_encode(
                msg.sender,
                self,
                _amount,
                method_id=method_id("transferFrom(address,address,uint256)"),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)  # dev: failed transfer

        if _coin == ETH_ADDRESS:
            WETH.withdraw(_amount)
            return _amount
    return 0


@internal
def _send(_coin: address, _to: address, _use_eth: bool) -> uint256:
    """
    @notice Send coin from zap
    @dev Sends all available amount
    @param _coin Address of the coin
    @param _to Sender of the coin
    @param _use_eth Use raw ETH
    @return Amount of coin sent
    """
    coin: address = _coin
    if coin == ETH_ADDRESS:
        coin = WETH.address  # Send weth if not _use_eth

    amount: uint256 = 0
    if _use_eth and coin == WETH.address:
        amount = ERC20(coin).balanceOf(self)
        if amount > 0:
            WETH.withdraw(amount)

        amount = self.balance
        if amount > 0:
            raw_call(_to, b"", value=amount)
    else:
        if coin == WETH.address and self.balance > 0:
            WETH.deposit(value=self.balance)

        amount = ERC20(coin).balanceOf(self)
        if amount > 0:
            response: Bytes[32] = raw_call(
                coin,
                _abi_encode(_to, amount, method_id=method_id("transfer(address,uint256)")),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)  # dev: failed transfer
    return amount


@internal
def _approve(_coin: address, _pool: address):
    if _coin != ETH_ADDRESS and not self.is_approved[_coin][_pool]:
        ERC20(_coin).approve(_pool, max_value(uint256))
        self.is_approved[_coin][_pool] = True


@internal
@pure
def _need_to_handle_eth(_use_eth: bool, _coin: address) -> bool:
    """
    @notice Handle _use_eth feature for StableSwaps
    """
    return (not _use_eth and _coin == ETH_ADDRESS) or (_use_eth and _coin == WETH.address)


# -------------- Exchange --------------


@internal
def _add_to_base_one(_pool: address, _amount: uint256, _min_lp: uint256, _i: uint256,
                     _receiver: address, _eth_amount: uint256) -> uint256:
    """
    @notice Provide one token to base pool
    @param _pool Address of base pool
    @param _amount Amount of token to provide
    @param _min_lp Minimum LP amount to receive
    @param _i Adjusted index of coin to provide
    @param _receiver Receiver of the coin
    @param _eth_amount Raw ETH amount to provide
    @return LP Token amount received
    """
    n_coins: uint256 = STABLE_FACTORY.get_n_coins(_pool)

    if n_coins == 2:
        amounts: uint256[2] = empty(uint256[2])
        amounts[_i] = _amount
        return CurveBase2(_pool).add_liquidity(amounts, _min_lp, _receiver, value=_eth_amount)
    elif n_coins == 3:
        amounts: uint256[3] = empty(uint256[3])
        amounts[_i] = _amount
        return CurveBase3(_pool).add_liquidity(amounts, _min_lp, _receiver, value=_eth_amount)
    elif n_coins == 4:
        amounts: uint256[4] = empty(uint256[4])
        amounts[_i] = _amount
        return CurveBase4(_pool).add_liquidity(amounts, _min_lp, _receiver, value=_eth_amount)
    else:
        raise "Incorrect indexes"


@external
@payable
def exchange(_pool: address, i: uint256, j: uint256, _dx: uint256, _min_dy: uint256, _use_eth: bool = False, _receiver: address = msg.sender) -> uint256:
    """
    @notice Exchange using wETH by default. Indexing = [[0, 1, ...], [5, ..., 9]]
    @dev Index values can be found via the `coins` public getter method
    @param _pool Address of the pool for the exchange
    @param i Index value for the coin to send
    @param j Index value of the coin to receive
    @param _dx Amount of `i` being exchanged
    @param _min_dy Minimum amount of `j` to receive
    @param _use_eth Use raw ETH
    @param _receiver Address that will receive `j`
    @return Actual amount of `j` received
    """
    assert i != j  # dev: indexes are similar
    if not _use_eth:
        assert msg.value == 0  # dev: nonzero ETH amount

    i_pool: uint256 = i / POOL_N_COINS
    j_pool: uint256 = j / POOL_N_COINS

    pool: address = CurveMeta(_pool).coins(i_pool)
    adjusted_i: uint256 = i % POOL_N_COINS
    coin: address = pool
    if adjusted_i > 0:
        adjusted_i -= 1
        coin = CurveBase(pool).coins(adjusted_i)
        self._approve(coin, pool)

    eth_amount: uint256 = self._receive(coin, _dx, _use_eth, coin != pool)
    if _use_eth and coin not in [ETH_ADDRESS, WETH.address]:
        assert msg.value == 0, "Invalid ETH amount"

    receiver: address = self
    min_dy: uint256 = 0
    amount: uint256 = _dx

    if coin != pool:  # Deposit coin to the pool
        if i_pool == j_pool:
            if j % POOL_N_COINS > 0:  # Exchange in Base
                adjusted_j: uint256 = j % POOL_N_COINS - 1
                coin = CurveBase(pool).coins(adjusted_j)
                if not self._need_to_handle_eth(_use_eth, coin):
                    receiver = _receiver

                amount = CurveBase(pool).exchange(
                    convert(adjusted_i, int128), convert(adjusted_j, int128), amount, _min_dy, receiver,
                    value=eth_amount,
                )
                if receiver == self:
                    amount = self._send(coin, _receiver, _use_eth)
                return amount
            else:  # `j` is lp token of `i`
                receiver = _receiver
                min_dy = _min_dy
        amount = self._add_to_base_one(pool, amount, min_dy, adjusted_i, receiver, eth_amount)
        eth_amount = 0
        coin = pool

    if i_pool != j_pool:  # Exchange in Meta
        self._approve(coin, _pool)

        if j % POOL_N_COINS == 0:  # `j` is meta coin
            receiver = _receiver
            min_dy = _min_dy
        amount = CurveMeta(_pool).exchange(i_pool, j_pool, amount, min_dy, _use_eth, receiver, value=eth_amount)

        coin = CurveMeta(_pool).coins(j_pool)

    if j % POOL_N_COINS > 0:  # Remove 1 coin
        pool = coin
        adjusted_j: uint256 = j % POOL_N_COINS - 1
        coin = CurveBase(pool).coins(adjusted_j)
        self._approve(coin, pool)
        if not self._need_to_handle_eth(_use_eth, coin):
            receiver = _receiver
        amount = CurveBase(pool).remove_liquidity_one_coin(amount, convert(adjusted_j, int128), _min_dy, receiver)

    if receiver == _receiver:
        return amount
    return self._send(coin, _receiver, _use_eth)


@internal
@view
def _calc_in_base_one(_pool: address, _amount: uint256, _i: int128) -> uint256:
    """
    @notice Calculate base LP token received for providing 1 token
    @param _pool Address of the base pool
    @param _amount Amount of token to provide
    @param _i Adjusted index to provide
    @return LP Token amount to receive
    """
    n_coins: uint256 = STABLE_FACTORY.get_n_coins(_pool)

    if n_coins == 2:
        amounts: uint256[2] = empty(uint256[2])
        amounts[_i] = _amount
        return CurveBase2(_pool).calc_token_amount(amounts, True)
    elif n_coins == 3:
        amounts: uint256[3] = empty(uint256[3])
        amounts[_i] = _amount
        return CurveBase3(_pool).calc_token_amount(amounts, True)
    elif n_coins == 4:
        amounts: uint256[4] = empty(uint256[4])
        amounts[_i] = _amount
        return CurveBase4(_pool).calc_token_amount(amounts, True)
    else:
        raise "Invalid indexes"


@external
@view
def get_dy(_pool: address, i: uint256, j: uint256, _dx: uint256) -> uint256:
    """
    @notice Calculate the amount received in exchange. Indexing = [[0, 1, ...], [5, ..., 9]]
    @dev Index values can be found via the `coins` public getter method
    @param _pool Address of the pool for the exchange
    @param i Index value for the coin to send
    @param j Index value of the coin to receive
    @param _dx Amount of `i` being exchanged
    @return Expected amount of `j` to receive
    """
    assert i != j  # dev: indexes are similar

    i_pool: uint256 = i / POOL_N_COINS
    j_pool: uint256 = j / POOL_N_COINS

    if i_pool == j_pool:  # Coins are in the same pool
        pool: address = CurveMeta(_pool).coins(i_pool)
        if i % POOL_N_COINS > 0:
            adjusted_i: int128 = convert(i % POOL_N_COINS - 1, int128)
            if j % POOL_N_COINS > 0:  # Exchange in Base
                return CurveBase(pool).get_dy(adjusted_i, convert(j % POOL_N_COINS - 1, int128), _dx)
            else:  # Add 1 coin (j == lp token)
                return self._calc_in_base_one(pool, _dx, adjusted_i)

        # Exchange LP token to one of the underlying coins = Remove 1 coin
        return CurveBase(pool).calc_withdraw_one_coin(_dx, convert(j % POOL_N_COINS - 1, int128))

    # Coins are from different pools

    amount: uint256 = _dx
    if i % POOL_N_COINS > 0:  # Deposit coin to the pool
        pool: address = CurveMeta(_pool).coins(i_pool)
        amount = self._calc_in_base_one(pool, _dx, convert(i % POOL_N_COINS - 1, int128))

    # Exchange in Meta
    amount = CurveMeta(_pool).get_dy(i_pool, j_pool, amount)

    if j % POOL_N_COINS > 0:  # Remove 1 coin
        pool: address = CurveMeta(_pool).coins(j_pool)
        return CurveBase(pool).calc_withdraw_one_coin(amount, convert(j % POOL_N_COINS - 1, int128))

    return amount


# ------------ Add Liquidity -----------


@internal
def _add_to_base(_pool: address, _amounts: uint256[POOL_N_COINS], _use_eth: bool) -> uint256:
    """
    @notice Deposit tokens to base pool
    @param _pool Address of the basepool to deposit into
    @param _amounts List of amounts of coins to deposit. If only one coin per base pool given, lp token will be used.
    @param _use_eth Use raw ETH
    @return Amount of LP tokens received by depositing
    """
    base_coins: address[BASE_MAX_N_COINS] = STABLE_FACTORY.get_coins(_pool)
    eth_amount: uint256 = 0
    n_coins: uint256 = BASE_MAX_N_COINS
    for i in range(BASE_MAX_N_COINS):
        coin: address = base_coins[i]
        if coin == empty(address):
            n_coins = i
            break
        eth_amount += self._receive(coin, _amounts[1 + i], _use_eth, True)
        self._approve(coin, _pool)

    if n_coins == 2:
        amounts: uint256[2] = [_amounts[1], _amounts[2]]
        return CurveBase2(_pool).add_liquidity(amounts, 0, self, value=eth_amount)
    elif n_coins == 3:
        amounts: uint256[3] = [_amounts[1], _amounts[2], _amounts[3]]
        return CurveBase3(_pool).add_liquidity(amounts, 0, self, value=eth_amount)
    elif n_coins == 4:
        amounts: uint256[4] = [_amounts[1], _amounts[2], _amounts[3], _amounts[4]]
        return CurveBase4(_pool).add_liquidity(amounts, 0, self, value=eth_amount)
    else:
        raise "Incorrect amounts"


@external
@payable
def add_liquidity(
    _pool: address,
    _deposit_amounts: uint256[POOL_N_COINS][META_N_COINS],
    _min_mint_amount: uint256,
    _use_eth: bool = False,
    _receiver: address = msg.sender,
) -> uint256:
    """
    @notice Deposit tokens to base and meta pools
    @dev Providing ETH with _use_eth=True and no ETH actually used will result in ETH remained in zap.
         It can be recovered via removing liquidity.
    @param _pool Address of the metapool to deposit into
    @param _deposit_amounts List of amounts of underlying coins to deposit
    @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
    @param _use_eth Use raw ETH
    @param _receiver Address that receives the LP tokens
    @return Amount of LP tokens received by depositing
    """
    if not _use_eth:
        assert msg.value == 0  # dev: nonzero ETH amount
    eth_amount: uint256 = 0
    meta_amounts: uint256[META_N_COINS] = empty(uint256[META_N_COINS])
    for i in range(META_N_COINS):
        meta_amounts[i] = _deposit_amounts[i][0]
        coin: address = CurveMeta(_pool).coins(i)
        eth_amount += self._receive(coin, meta_amounts[i], _use_eth, False)
        self._approve(coin, _pool)

        for j in range(1, POOL_N_COINS):
            if _deposit_amounts[i][j] > 0:
                meta_amounts[i] += self._add_to_base(coin, _deposit_amounts[i], _use_eth)
                break

    return CurveMeta(_pool).add_liquidity(meta_amounts, _min_mint_amount, _use_eth, _receiver, value=eth_amount)


@internal
@view
def _calc_in_base(_pool: address, _amounts: uint256[POOL_N_COINS]) -> uint256:
    """
    @notice Calculate base pool LP received after providing `_amounts`
    @param _pool Address of the base pool
    @param _amounts Amounts to add
    @return LP Token amount to receive
    """
    n_coins: uint256 = STABLE_FACTORY.get_n_coins(_pool)

    if n_coins == 2:
        amounts: uint256[2] = [_amounts[1], _amounts[2]]
        return CurveBase2(_pool).calc_token_amount(amounts, True)
    elif n_coins == 3:
        amounts: uint256[3] = [_amounts[1], _amounts[2], _amounts[3]]
        return CurveBase3(_pool).calc_token_amount(amounts, True)
    elif n_coins == 4:
        amounts: uint256[4] = [_amounts[1], _amounts[2], _amounts[3], _amounts[4]]
        return CurveBase4(_pool).calc_token_amount(amounts, True)
    else:
        raise "Incorrect amounts"


@external
@view
def calc_token_amount(_pool: address, _amounts: uint256[POOL_N_COINS][META_N_COINS]) -> uint256:
    """
    @notice Calculate addition in token supply from a deposit
    @dev This calculation accounts for slippage, but not fees.
         Needed to prevent front-running, not for precise calculations!
    @param _pool Address of the pool to deposit into
    @param _amounts Amount of each underlying coin being deposited
    @return Expected amount of LP tokens received
    """
    meta_amounts: uint256[META_N_COINS] = empty(uint256[META_N_COINS])
    for i in range(META_N_COINS):
        meta_amounts[i] = _amounts[i][0]
        for j in range(1, POOL_N_COINS):
            if _amounts[i][j] > 0:
                meta_amounts[i] += self._calc_in_base(CurveMeta(_pool).coins(i), _amounts[i])
                break

    return CurveMeta(_pool).calc_token_amount(meta_amounts)


# ---------- Remove Liquidity ----------


@internal
def _remove_from_base(_pool: address, _min_amounts: uint256[POOL_N_COINS], _use_eth: bool, _receiver: address) -> uint256[POOL_N_COINS]:
    """
    @notice Remove tokens from base pool
    @param _pool Address of base pool
    @param _min_amounts Minimum amounts to receive
    @param _use_eth Use raw ETH
    @param _receiver Receiver of coins
    @return Received amounts
    """
    receiver: address = _receiver
    base_coins: address[BASE_MAX_N_COINS] = STABLE_FACTORY.get_coins(_pool)
    n_coins: uint256 = BASE_MAX_N_COINS
    for i in range(BASE_MAX_N_COINS):
        if base_coins[i] == empty(address):
            n_coins = i
            break
        if self._need_to_handle_eth(_use_eth, base_coins[i]):  # Need to wrap ETH
            receiver = self

    burn_amount: uint256 = ERC20(_pool).balanceOf(self)
    returned: uint256[POOL_N_COINS] = empty(uint256[POOL_N_COINS])
    if n_coins == 2:
        min_amounts: uint256[2] = [_min_amounts[1], _min_amounts[2]]
        amounts: uint256[2] = CurveBase2(_pool).remove_liquidity(burn_amount, min_amounts, receiver)
        for i in range(2):
            returned[1 + i] = amounts[i]
    elif n_coins == 3:
        min_amounts: uint256[3] = [_min_amounts[1], _min_amounts[2], _min_amounts[3]]
        amounts: uint256[3] = CurveBase3(_pool).remove_liquidity(burn_amount, min_amounts, receiver)
        for i in range(3):
            returned[1 + i] = amounts[i]
    elif n_coins == 4:
        min_amounts: uint256[4] = [_min_amounts[1], _min_amounts[2], _min_amounts[3], _min_amounts[4]]
        amounts: uint256[4] = CurveBase4(_pool).remove_liquidity(burn_amount, min_amounts, receiver)
        for i in range(4):
            returned[1 + i] = amounts[i]
    else:
        raise "Invalid min_amounts"

    if receiver == self:
        for coin in base_coins:
            if coin == empty(address):
                break
            self._send(coin, _receiver, _use_eth)
    return returned


@external
def remove_liquidity(
    _pool: address,
    _burn_amount: uint256,
    _min_amounts: uint256[POOL_N_COINS][META_N_COINS],
    _use_eth: bool = False,
    _receiver: address = msg.sender,
) -> uint256[POOL_N_COINS][META_N_COINS]:
    """
    @notice Withdraw and unwrap coins from the pool.
    @dev Withdrawal amounts are based on current deposit ratios
    @param _pool Address of the pool to withdraw from
    @param _burn_amount Quantity of LP tokens to burn in the withdrawal
    @param _min_amounts Minimum amounts of underlying coins to receive.
                        Amounts for meta coins will be ignored if base amounts provided.
    @param _use_eth Use raw ETH
    @param _receiver Address that receives the LP tokens
    @return List of amounts of underlying coins that were withdrawn
    """
    token: address = CurveMeta(_pool).token()
    ERC20(token).transferFrom(msg.sender, self, _burn_amount)
    CurveMeta(_pool).remove_liquidity(_burn_amount, [_min_amounts[0][0], _min_amounts[1][0]], _use_eth)

    returned: uint256[POOL_N_COINS][META_N_COINS] = empty(uint256[POOL_N_COINS][META_N_COINS])
    for i in range(META_N_COINS):
        removed_from_base: bool = False
        pool: address = CurveMeta(_pool).coins(i)
        for j in range(1, POOL_N_COINS):
            if _min_amounts[i][j] > 0:
                returned[i] = self._remove_from_base(pool, _min_amounts[i], _use_eth, _receiver)
                removed_from_base = True
                break
        if not removed_from_base:
            returned[i][0] = self._send(pool, _receiver, _use_eth)
    return returned


@external
def remove_liquidity_one_coin(
    _pool: address,
    _burn_amount: uint256,
    i: uint256,
    _min_amount: uint256,
    _use_eth: bool = False,
    _receiver: address = msg.sender,
) -> uint256:
    """
    @notice Withdraw and unwrap a single coin from the pool
    @param _pool Address of the pool to withdraw from
    @param _burn_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @param _min_amount Minimum amount of underlying coin to receive
    @param _use_eth Use raw ETH
    @param _receiver Address that receives the LP tokens
    @return Amount of underlying coin received
    """
    token: address = CurveMeta(_pool).token()
    ERC20(token).transferFrom(msg.sender, self, _burn_amount)

    pool_i: uint256 = i / POOL_N_COINS

    if i % POOL_N_COINS == 0:
        return CurveMeta(_pool).remove_liquidity_one_coin(_burn_amount, pool_i, _min_amount, _use_eth, _receiver)
    amount: uint256 = CurveMeta(_pool).remove_liquidity_one_coin(_burn_amount, pool_i, 0, _use_eth)

    pool: address = CurveMeta(_pool).coins(pool_i)
    adjusted_i: uint256 = i % POOL_N_COINS - 1

    coin: address = CurveBase(pool).coins(adjusted_i)
    if not self._need_to_handle_eth(_use_eth, coin):
        return CurveBase(pool).remove_liquidity_one_coin(amount, convert(adjusted_i, int128), _min_amount, _receiver)
    CurveBase(pool).remove_liquidity_one_coin(amount, convert(adjusted_i, int128), _min_amount)
    return self._send(WETH.address, _receiver, _use_eth)


@external
@view
def calc_withdraw_one_coin(_pool: address, _token_amount: uint256, i: uint256) -> uint256:
    """
    @notice Calculate the amount received when withdrawing and unwrapping a single coin
    @param _pool Address of the pool to withdraw from
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the underlying coin to withdraw
    @return Amount of coin to receive
    """
    pool_i: uint256 = i / POOL_N_COINS
    amount: uint256 = CurveMeta(_pool).calc_withdraw_one_coin(_token_amount, pool_i)
    if i % POOL_N_COINS > 0:
        pool: address = CurveMeta(_pool).coins(pool_i)
        adjusted_i: int128 = convert(i % POOL_N_COINS - 1, int128)
        return CurveBase(pool).calc_withdraw_one_coin(amount, adjusted_i)
    return amount