# @version 0.3.4
"""
@title Zap for Curve Factory
@license MIT
@author Curve.Fi
@notice Zap for fraxbp metapools created via crypto factory
"""


interface ERC20:  # Custom ERC20 which works for Curve LP Tokens
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
    def lp_price() -> uint256: view
    def price_scale() -> uint256: view
    def price_oracle() -> uint256: view
    def virtual_price() -> uint256: view
    def get_dy(i: uint256, j: uint256, dx: uint256) -> uint256: view
    def calc_token_amount(amounts: uint256[N_COINS]) -> uint256: view
    def calc_withdraw_one_coin(token_amount: uint256, i: uint256) -> uint256: view
    def exchange(i: uint256, j: uint256, dx: uint256, min_dy: uint256, use_eth: bool = False, receiver: address = msg.sender) -> uint256: payable
    def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256, use_eth: bool = False, receiver: address = msg.sender) -> uint256: payable
    def remove_liquidity(_amount: uint256, min_amounts: uint256[2], use_eth: bool = False, receiver: address = msg.sender): nonpayable
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256, use_eth: bool = False, receiver: address = msg.sender) -> uint256: nonpayable


# FraxBP
interface CurveBase:
    def coins(i: uint256) -> address: view
    def lp_token() -> address: view
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view
    def calc_token_amount(amounts: uint256[BASE_N_COINS], is_deposit: bool) -> uint256: view
    def calc_withdraw_one_coin(token_amount: uint256, i: int128) -> uint256: view
    def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256): nonpayable
    def add_liquidity(amounts: uint256[BASE_N_COINS], min_mint_amount: uint256): nonpayable
    def remove_liquidity_one_coin(token_amount: uint256, i: int128, min_amount: uint256): nonpayable
    def remove_liquidity(amount: uint256, min_amounts: uint256[BASE_N_COINS]): nonpayable
    def get_virtual_price() -> uint256: view


N_COINS: constant(uint256) = 2
MAX_COIN: constant(uint256) = N_COINS - 1
BASE_N_COINS: constant(uint256) = 2
N_ALL_COINS: constant(uint256) = N_COINS + BASE_N_COINS - 1

WETH: immutable(wETH)

BASE_POOL: immutable(CurveBase)
BASE_LP_TOKEN: immutable(address)
BASE_COINS: immutable(address[BASE_N_COINS])
# coin -> pool -> is approved to transfer?
is_approved: HashMap[address, HashMap[address, bool]]


@external
def __init__(_base_pool: address, _weth: address):
    """
    @notice Contract constructor
    """
    BASE_POOL = CurveBase(_base_pool)
    BASE_LP_TOKEN = BASE_POOL.lp_token()
    base_coins: address[BASE_N_COINS] = empty(address[BASE_N_COINS])
    for i in range(BASE_N_COINS):
        base_coins[i] = BASE_POOL.coins(i)
    BASE_COINS = base_coins
    WETH = wETH(_weth)

    for coin in base_coins:
        ERC20(coin).approve(_base_pool, max_value(uint256))
        self.is_approved[coin][_base_pool] = True


@payable
@external
def __default__():
    assert msg.sender.is_contract  # dev: receive only from pools and WETH


@pure
@external
def base_pool() -> address:
    return BASE_POOL.address


@pure
@external
def base_token() -> address:
    return BASE_LP_TOKEN


@external
@view
def price_oracle(_pool: address) -> uint256:
    usd_tkn: uint256 = CurveMeta(_pool).price_oracle()
    vprice: uint256 = BASE_POOL.get_virtual_price()
    return vprice * 10**18 / usd_tkn


@external
@view
def price_scale(_pool: address) -> uint256:
    usd_tkn: uint256 = CurveMeta(_pool).price_scale()
    vprice: uint256 = BASE_POOL.get_virtual_price()
    return vprice * 10**18 / usd_tkn


@external
@view
def lp_price(_pool: address) -> uint256:
    p: uint256 = CurveMeta(_pool).lp_price()  # price in tkn
    usd_tkn: uint256 = CurveMeta(_pool).price_oracle()
    vprice: uint256 = BASE_POOL.get_virtual_price()
    return p * vprice / usd_tkn


@internal
def _receive(_coin: address, _amount: uint256, _from: address,
             _eth_value: uint256, _use_eth: bool, _wrap_eth: bool=False) -> uint256:
    """
    Transfer coin to zap
    @param _coin Address of the coin
    @param _amount Amount of coin
    @param _from Sender of the coin
    @param _eth_value Eth value sent
    @param _use_eth Use raw ETH
    @param _wrap_eth Wrap raw ETH
    @return Received ETH amount
    """
    if _use_eth and _coin == WETH.address:
        assert _eth_value == _amount  # dev: incorrect ETH amount
        if _wrap_eth:
            WETH.deposit(value=_amount)
        else:
            return _amount
    else:
        response: Bytes[32] = raw_call(
            _coin,
            _abi_encode(
                _from,
                self,
                _amount,
                method_id=method_id("transferFrom(address,address,uint256)"),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)  # dev: failed transfer
    return 0


@internal
def _send(_coin: address, _to: address, _use_eth: bool, _withdraw_eth: bool=False) -> uint256:
    """
    Send coin from zap
    @dev Sends all available amount
    @param _coin Address of the coin
    @param _to Sender of the coin
    @param _use_eth Use raw ETH
    @param _withdraw_eth Withdraw raw ETH from wETH
    @return Amount of coin sent
    """
    amount: uint256 = 0
    if _use_eth and _coin == WETH.address:
        if _withdraw_eth:
            amount = ERC20(_coin).balanceOf(self)
            WETH.withdraw(amount)
        amount = self.balance
        raw_call(_to, b"", value=amount)
    else:
        amount = ERC20(_coin).balanceOf(self)
        response: Bytes[32] = raw_call(
            _coin,
            _abi_encode(_to, amount, method_id=method_id("transfer(address,uint256)")),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)  # dev: failed transfer
    return amount


@payable
@external
def exchange(_pool: address, i: uint256, j: uint256, _dx: uint256, _min_dy: uint256,
             _use_eth: bool = False, _receiver: address = msg.sender) -> uint256:
    """
    @notice Exchange using wETH by default
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

    base_coins: address[BASE_N_COINS] = BASE_COINS
    if i < MAX_COIN:  # Swap to LP token and remove from base
        # Receive and swap to LP Token
        coin: address = CurveMeta(_pool).coins(i)
        eth_amount: uint256 = self._receive(coin, _dx, msg.sender, msg.value, _use_eth)
        if not self.is_approved[coin][_pool]:
            ERC20(coin).approve(_pool, max_value(uint256))
            self.is_approved[coin][_pool] = True
        lp_amount: uint256 = CurveMeta(_pool).exchange(i, MAX_COIN, _dx, 0, _use_eth, value=eth_amount)

        # Remove and send to _receiver
        BASE_POOL.remove_liquidity_one_coin(lp_amount, convert(j - MAX_COIN, int128), _min_dy)

        coin = base_coins[j - MAX_COIN]
        return self._send(coin, _receiver, _use_eth, True)

    # Receive coin i
    base_i: int128 = convert(i - MAX_COIN, int128)
    self._receive(base_coins[base_i], _dx, msg.sender, msg.value, _use_eth, True)

    # Add in base and exchange LP token
    if j < MAX_COIN:
        amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
        amounts[base_i] = _dx

        BASE_POOL.add_liquidity(amounts, 0)

        if not self.is_approved[BASE_LP_TOKEN][_pool]:
            ERC20(BASE_LP_TOKEN).approve(_pool, max_value(uint256))
            self.is_approved[BASE_LP_TOKEN][_pool] = True

        lp_amount: uint256 = ERC20(BASE_LP_TOKEN).balanceOf(self)
        return CurveMeta(_pool).exchange(MAX_COIN, j, lp_amount, _min_dy, _use_eth, _receiver)

    base_j: int128 = convert(j - MAX_COIN, int128)

    BASE_POOL.exchange(base_i, base_j, _dx, _min_dy)

    coin: address = base_coins[base_j]
    return self._send(coin, _receiver, _use_eth, True)


@view
@external
def get_dy(_pool: address, i: uint256, j: uint256, _dx: uint256) -> uint256:
    """
    @notice Calculate the amount received in exchange
    @dev Index values can be found via the `coins` public getter method
    @param _pool Address of the pool for the exchange
    @param i Index value for the coin to send
    @param j Index value of the coin to receive
    @param _dx Amount of `i` being exchanged
    @return Expected amount of `j` to receive
    """
    assert i != j  # dev: indexes are similar

    if i < MAX_COIN:  # Swap to LP token and remove from base
        lp_amount: uint256 = CurveMeta(_pool).get_dy(i, MAX_COIN, _dx)

        return BASE_POOL.calc_withdraw_one_coin(lp_amount, convert(j - MAX_COIN, int128))

    # Add in base and exchange LP token
    if j < MAX_COIN:
        amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
        amounts[i - MAX_COIN] = _dx
        lp_amount: uint256 = BASE_POOL.calc_token_amount(amounts, True)

        return CurveMeta(_pool).get_dy(MAX_COIN, j, lp_amount)

    # Exchange in base
    return BASE_POOL.get_dy(convert(i - MAX_COIN, int128), convert(j - MAX_COIN, int128), _dx)


@payable
@external
def add_liquidity(
    _pool: address,
    _deposit_amounts: uint256[N_ALL_COINS],
    _min_mint_amount: uint256,
    _use_eth: bool = False,
    _receiver: address = msg.sender,
) -> uint256:
    """
    @notice Deposit tokens to base and meta pools
    @param _pool Address of the metapool to deposit into
    @param _deposit_amounts List of amounts of underlying coins to deposit
    @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
    @param _use_eth Use raw ETH
    @param _receiver Address that receives the LP tokens
    @return Amount of LP tokens received by depositing
    """
    if not _use_eth:
        assert msg.value == 0  # dev: nonzero ETH amount
    meta_amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    base_amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    deposit_base: bool = False
    base_coins: address[BASE_N_COINS] = BASE_COINS
    eth_amount: uint256 = 0

    if _deposit_amounts[0] != 0:
        coin: address = CurveMeta(_pool).coins(0)
        eth_amount = self._receive(coin, _deposit_amounts[0], msg.sender, msg.value, _use_eth)
        if not self.is_approved[coin][_pool]:
            ERC20(coin).approve(_pool, max_value(uint256))
            self.is_approved[coin][_pool] = True
        meta_amounts[0] = _deposit_amounts[0]

    for i in range(MAX_COIN, N_ALL_COINS):
        amount: uint256 = _deposit_amounts[i]
        if amount == 0:
            continue
        deposit_base = True

        base_idx: uint256 = i - MAX_COIN

        coin: address = base_coins[base_idx]
        self._receive(coin, amount, msg.sender, msg.value, _use_eth, True)
        base_amounts[base_idx] = amount

    # Deposit to the base pool
    if deposit_base:
        BASE_POOL.add_liquidity(base_amounts, 0)
        meta_amounts[MAX_COIN] = ERC20(BASE_LP_TOKEN).balanceOf(self)
        if not self.is_approved[BASE_LP_TOKEN][_pool]:
            ERC20(BASE_LP_TOKEN).approve(_pool, max_value(uint256))
            self.is_approved[BASE_LP_TOKEN][_pool] = True

    # Deposit to the meta pool
    return CurveMeta(_pool).add_liquidity(meta_amounts, _min_mint_amount, _use_eth, _receiver, value=eth_amount)


@view
@external
def calc_token_amount(_pool: address, _amounts: uint256[N_ALL_COINS]) -> uint256:
    """
    @notice Calculate addition in token supply from a deposit or withdrawal
    @dev This calculation accounts for slippage, but not fees.
         Needed to prevent front-running, not for precise calculations!
    @param _pool Address of the pool to deposit into
    @param _amounts Amount of each underlying coin being deposited
    @return Expected amount of LP tokens received
    """
    meta_amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    base_amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    deposit_base: bool = False

    meta_amounts[0] = _amounts[0]
    for i in range(BASE_N_COINS):
        base_amounts[i] = _amounts[i + MAX_COIN]
        if base_amounts[i] > 0:
            deposit_base = True

    if deposit_base:
        base_tokens: uint256 = BASE_POOL.calc_token_amount(base_amounts, True)
        meta_amounts[MAX_COIN] = base_tokens

    return CurveMeta(_pool).calc_token_amount(meta_amounts)


@external
def remove_liquidity(
    _pool: address,
    _burn_amount: uint256,
    _min_amounts: uint256[N_ALL_COINS],
    _use_eth: bool = False,
    _receiver: address = msg.sender,
) -> uint256[N_ALL_COINS]:
    """
    @notice Withdraw and unwrap coins from the pool
    @dev Withdrawal amounts are based on current deposit ratios
    @param _pool Address of the pool to withdraw from
    @param _burn_amount Quantity of LP tokens to burn in the withdrawal
    @param _min_amounts Minimum amounts of underlying coins to receive
    @param _use_eth Use raw ETH
    @param _receiver Address that receives the LP tokens
    @return List of amounts of underlying coins that were withdrawn
    """
    lp_token: address = CurveMeta(_pool).token()
    ERC20(lp_token).transferFrom(msg.sender, self, _burn_amount)

    min_amounts_base: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    amounts: uint256[N_ALL_COINS] = empty(uint256[N_ALL_COINS])

    # Withdraw from meta
    CurveMeta(_pool).remove_liquidity(
        _burn_amount,
        [_min_amounts[0], 0],
        _use_eth,
    )
    lp_amount: uint256 = ERC20(BASE_LP_TOKEN).balanceOf(self)

    # Withdraw from base
    for i in range(BASE_N_COINS):
        min_amounts_base[i] = _min_amounts[MAX_COIN + i]
    BASE_POOL.remove_liquidity(lp_amount, min_amounts_base)

    # Transfer all coins out
    coin: address = CurveMeta(_pool).coins(0)
    amounts[0] = self._send(coin, _receiver, _use_eth)

    base_coins: address[BASE_N_COINS] = BASE_COINS
    for i in range(MAX_COIN, N_ALL_COINS):
        coin = base_coins[i - MAX_COIN]
        amounts[i] = self._send(coin, _receiver, _use_eth, True)

    return amounts


@external
def remove_liquidity_one_coin(
    _pool: address,
    _burn_amount: uint256,
    i: uint256,
    _min_amount: uint256,
    _use_eth: bool = False,
    _receiver: address=msg.sender
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
    lp_token: address = CurveMeta(_pool).token()
    ERC20(lp_token).transferFrom(msg.sender, self, _burn_amount)

    if i < MAX_COIN:
        return CurveMeta(_pool).remove_liquidity_one_coin(_burn_amount, i, _min_amount, _use_eth, _receiver)

    # Withdraw a base pool coin
    coin_amount: uint256 = CurveMeta(_pool).remove_liquidity_one_coin(_burn_amount, MAX_COIN, 0)

    BASE_POOL.remove_liquidity_one_coin(coin_amount, convert(i - MAX_COIN, int128), _min_amount)

    coin: address = BASE_COINS[i - MAX_COIN]
    return self._send(coin, _receiver, _use_eth, True)


@view
@external
def calc_withdraw_one_coin(_pool: address, _token_amount: uint256, i: uint256) -> uint256:
    """
    @notice Calculate the amount received when withdrawing and unwrapping a single coin
    @param _pool Address of the pool to withdraw from
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the underlying coin to withdraw
    @return Amount of coin received
    """
    if i < MAX_COIN:
        return CurveMeta(_pool).calc_withdraw_one_coin(_token_amount, i)

    _base_tokens: uint256 = CurveMeta(_pool).calc_withdraw_one_coin(_token_amount, MAX_COIN)
    return BASE_POOL.calc_withdraw_one_coin(_base_tokens, convert(i - MAX_COIN, int128))