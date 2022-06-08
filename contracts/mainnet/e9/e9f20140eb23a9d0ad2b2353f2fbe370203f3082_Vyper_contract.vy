# @version 0.3.3

# define swap route
struct SwapRoute:
    swap_pool: address # swap pool to use for swap
    j_token: address # out token from the pool
    i: int128 # in token index
    j: int128 # out token index
    is_underlying: bool # true if exchange underlying coins using exchange_underlying()
    is_crypto_pool: bool # true if token index in uint256

# ERC20 events
event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

# Vault events
event Deposit:
    _token: indexed(address)
    _from: indexed(address)
    token_amount: uint256
    vault_balance: uint256

event Withdraw:
    _token: indexed(address)
    _from: indexed(address)
    token_amount: uint256
    vault_balance: uint256

event Updated:
    old_pool: indexed(address)
    new_pool: indexed(address)
    _timestamp: uint256
    from_amount: uint256
    to_amount: uint256

# ERC20 standard interfaces
name: public(String[64])
symbol: public(String[32])

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

paused: public(bool)
main_pool: public(address) # main curve pool address
main_pool_coin_count: public(uint8) # (undelying) coin count
is_crypto_pool: public(bool) # true if main pool coin index type is uint256

# main deposit address for meta pools
# address(0) for base pools
# addresss(1) for lending pools (add_liquidity function has one more argument)
main_deposit: public(address)
main_lp_token: public(address) # Curve LP address of main pool
validators: public(HashMap[address, bool]) # validators who can update pool
admin: public(address) # admin

zap_deposit: public(address) # ZAP deposit pool address that curve provides
MAX_COINS: constant(uint8) = 8 # MAX_COINS of curve pools
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE # Virtual address for ETH coin
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
IS_A_POOL_IN_DEPOSIT: constant(address) = 0x0000000000000000000000000000000000000001 # use address(1) as deposit address for aave pools
INIT_ZAP_DEPOSIT: constant(address) = 0xA79828DF1850E8a3A3064576f380D90aECDD3359 # init ZAP deposit contract address
TRUE_BYTES32: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000000000001 # conversion True into bytes32
MAX_SWAP: constant(uint256) = 4 # MAX count of swap steps

interface CrvPool:
    def remove_liquidity_one_coin(token_amount: uint256, i: int128, min_amount: uint256): nonpayable
    def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256): payable
    def exchange_underlying(i: int128, j: int128, dx: uint256, min_dy: uint256): payable

interface CryptoPool:
    def exchange(i: uint256, j: uint256, dx: uint256, min_dy: uint256): payable
    def exchange_underlying(i: uint256, j: uint256, dx: uint256, min_dy: uint256): payable
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256): nonpayable

interface CrvAPool:
    def remove_liquidity_one_coin(token_amount: uint256, i: int128, min_amount: uint256, use_underlying: bool): nonpayable

interface CryptoAPool:
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256, use_underlying: bool): nonpayable

interface CrvZapDeposit:
    def remove_liquidity_one_coin(_pool: address, token_amount: uint256, i: int128, min_amount: uint256): nonpayable

interface CryptoZapDeposit:
    def remove_liquidity_one_coin(_pool: address, token_amount: uint256, i: uint256, min_amount: uint256): nonpayable

interface CrvDeposit:
    def pool() -> address: view

interface ERC20:
    def balanceOf(_to: address) -> uint256: view

interface WrappedEth:
    def deposit(): payable
    def withdraw(amount: uint256): nonpayable

@external
def __init__(_name: String[64], _symbol: String[32], _main_pool: address, _main_deposit: address, _main_pool_coin_count: uint8, _main_lp_token: address, _is_crypto_pool: bool):
    """
    @notice Contract constructor
    @param _name ERC20 standard name
    @param _symbol ERC20 standard symbol
    @param _main_pool main curve pool
    @param _main_deposit main deposit address
    @param _main_pool_coin_count coin count of main pool
    @param _main_lp_token curve LP token address of the main pool
    @param _is_crypto_pool true if main pool coin index type is uint256
    """
    self.name = _name
    self.symbol = _symbol
    self.admin = msg.sender
    self.validators[msg.sender] = True
    assert _main_pool != ZERO_ADDRESS, "Wrong Pool"
    self.main_pool = _main_pool
    self.main_deposit = _main_deposit
    assert _main_pool_coin_count >= 2 and _main_pool_coin_count <= MAX_COINS, "Wrong Pool Coin Count"
    self.main_pool_coin_count = _main_pool_coin_count
    assert _main_lp_token != ZERO_ADDRESS, "Wrong Pool"
    self.main_lp_token = _main_lp_token
    self.zap_deposit = INIT_ZAP_DEPOSIT
    self.is_crypto_pool = _is_crypto_pool

# ERC20 common functions

@internal
def _mint(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS # dev: zero address
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

@internal
def _burn(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS # dev: zero address
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)

@internal
def safe_approve(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("approve(address,uint256)"),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed approve

@internal
def safe_transfer(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed transfer
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed transfer

@internal
def safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transferFrom(address,address,uint256)"),
            convert(_from, bytes32),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed transfer from
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed transfer from

@external
@pure
def decimals() -> uint8:
    return 18

@external
def transfer(_to : address, _value : uint256) -> bool:
    assert _to != ZERO_ADDRESS # dev: zero address
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    assert _to != ZERO_ADDRESS # dev: zero address
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    assert _value == 0 or self.allowance[msg.sender][_spender] == 0
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@external
def increaseAllowance(_spender: address, _value: uint256) -> bool:
    allowance: uint256 = self.allowance[msg.sender][_spender]
    allowance += _value
    self.allowance[msg.sender][_spender] = allowance
    log Approval(msg.sender, _spender, allowance)
    return True

@external
def decreaseAllowance(_spender: address, _value: uint256) -> bool:
    allowance: uint256 = self.allowance[msg.sender][_spender]
    allowance -= _value
    self.allowance[msg.sender][_spender] = allowance
    log Approval(msg.sender, _spender, allowance)
    return True

@internal
def _deposit(main_pool_: address, _main_deposit: address, _main_pool_coin_count: uint8, i: int128, in_token: address, in_amount: uint256):
    """
    @notice deposit to curve pool using one token only
    @param _main_pool main curve pool to withdraw tokens
    @param _main_deposit
        deposit contract to main pool
        address(0) if we can deposit does not exist
        address(1) if the main pool is lending pool and add_liquidity() function requires boolean argument more
    @param _main_pool_coin_count (underlying) coin count of the main curve pool
    @param i in token index
    @param in_amount token in amount
    """
    _main_pool: address = main_pool_
    payload: Bytes[320] = empty(Bytes[320])
    length: uint256 = len(payload)
    # payload using only one coin
    if i == 0:
        payload = concat(convert(in_amount, bytes32), EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32)
    elif i == 1:
        payload = concat(EMPTY_BYTES32, convert(in_amount, bytes32), EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32)
    elif i == 2:
        payload = concat(EMPTY_BYTES32, EMPTY_BYTES32, convert(in_amount, bytes32), EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32)
    elif i == 3:
        payload = concat(EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, convert(in_amount, bytes32), EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32)
    elif i == 4:
        payload = concat(EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, convert(in_amount, bytes32), EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32)
    elif i == 5:
        payload = concat(EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, convert(in_amount, bytes32), EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32)
    elif i == 6:
        payload = concat(EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, convert(in_amount, bytes32), EMPTY_BYTES32, EMPTY_BYTES32)
    else:
        payload = concat(EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, convert(in_amount, bytes32), EMPTY_BYTES32)

    m_id: Bytes[4] = empty(Bytes[4])
    if _main_deposit == IS_A_POOL_IN_DEPOSIT: # if main_deposit is address(1), mail_pool requires one argument more
        if _main_pool_coin_count == 2:
            m_id = method_id("add_liquidity(uint256[2],uint256,bool)")
            payload = concat(slice(payload, 0, 96), TRUE_BYTES32)
        elif _main_pool_coin_count == 3:
            m_id = method_id("add_liquidity(uint256[3],uint256,bool)")
            payload = concat(slice(payload, 0, 128), TRUE_BYTES32)
        elif _main_pool_coin_count == 4:
            m_id = method_id("add_liquidity(uint256[4],uint256,bool)")
            payload = concat(slice(payload, 0, 160), TRUE_BYTES32)
        elif _main_pool_coin_count == 5:
            m_id = method_id("add_liquidity(uint256[5],uint256,bool)")
            payload = concat(slice(payload, 0, 192), TRUE_BYTES32)
        elif _main_pool_coin_count == 6:
            m_id = method_id("add_liquidity(uint256[6],uint256,bool)")
            payload = concat(slice(payload, 0, 224), TRUE_BYTES32)
        elif _main_pool_coin_count == 7:
            m_id = method_id("add_liquidity(uint256[7],uint256,bool)")
            payload = concat(slice(payload, 0, 256), TRUE_BYTES32)
        else:
            m_id = method_id("add_liquidity(uint256[8],uint256,bool)")
            payload = concat(slice(payload, 0, 288), TRUE_BYTES32)
    elif _main_deposit == self.zap_deposit: # zap deposit has different arguments
        if _main_pool_coin_count == 2:
            m_id = method_id("add_liquidity(address,uint256[2],uint256)")
            payload = concat(convert(_main_pool, bytes32), slice(payload, 0, 96))
        elif _main_pool_coin_count == 3:
            m_id = method_id("add_liquidity(address,uint256[3],uint256)")
            payload = concat(convert(_main_pool, bytes32), slice(payload, 0, 128))
        elif _main_pool_coin_count == 4:
            m_id = method_id("add_liquidity(address,uint256[4],uint256)")
            payload = concat(convert(_main_pool, bytes32), slice(payload, 0, 160))
        elif _main_pool_coin_count == 5:
            m_id = method_id("add_liquidity(address,uint256[5],uint256)")
            payload = concat(convert(_main_pool, bytes32), slice(payload, 0, 192))
        elif _main_pool_coin_count == 6:
            m_id = method_id("add_liquidity(address,uint256[6],uint256)")
            payload = concat(convert(_main_pool, bytes32), slice(payload, 0, 224))
        elif _main_pool_coin_count == 7:
            m_id = method_id("add_liquidity(address,uint256[7],uint256)")
            payload = concat(convert(_main_pool, bytes32), slice(payload, 0, 256))
        else:
            m_id = method_id("add_liquidity(address,uint256[8],uint256)")
            payload = concat(convert(_main_pool, bytes32), slice(payload, 0, 288))
    else: # common pool/deposit add_liquidity function
        if _main_pool_coin_count == 2:
            m_id = method_id("add_liquidity(uint256[2],uint256)")
            payload = slice(payload, 0, 96)
        elif _main_pool_coin_count == 3:
            m_id = method_id("add_liquidity(uint256[3],uint256)")
            payload = slice(payload, 0, 128)
        elif _main_pool_coin_count == 4:
            m_id = method_id("add_liquidity(uint256[4],uint256)")
            payload = slice(payload, 0, 160)
        elif _main_pool_coin_count == 5:
            m_id = method_id("add_liquidity(uint256[5],uint256)")
            payload = slice(payload, 0, 192)
        elif _main_pool_coin_count == 6:
            m_id = method_id("add_liquidity(uint256[6],uint256)")
            payload = slice(payload, 0, 224)
        elif _main_pool_coin_count == 7:
            m_id = method_id("add_liquidity(uint256[7],uint256)")
            payload = slice(payload, 0, 256)
        else:
            m_id = method_id("add_liquidity(uint256[8],uint256)")
            payload = slice(payload, 0, 288)
 
    if _main_deposit != ZERO_ADDRESS and _main_deposit != IS_A_POOL_IN_DEPOSIT:
        _main_pool = _main_deposit
    if in_token == VETH:
        raw_call(
            _main_pool,
            concat(
                m_id,
                payload
            ),
            value=in_amount
        )
    else:
        self.safe_approve(in_token, _main_pool, in_amount)
        raw_call(
            _main_pool,
            concat(
                m_id,
                payload
            )
        )

@internal
def _swap(pool: address, i: int128, j: int128, from_token: address, to_token: address, is_underlying: bool, from_amount: uint256, is_crypto_pool: bool) -> uint256:
    """
    @notice swap function using curve pool
    @param pool swap pool to exchange tokens
    @param i from_token index
    @param j to_token index
    @param from_token token address to put into swap pool
    @param to_token token address to get out from swap pool
    @param is_underlying true for meta pools
    @param from_amount from_token amount
    @param is_crypto_pool true for the pools that use uint256 for indexes
    """
    to_amount: uint256 = 0
    if to_token == VETH: # Wrapping ETH
        if from_token == WETH:
            WrappedEth(WETH).withdraw(from_amount)
            return from_amount
        to_amount = self.balance
    elif from_token == VETH and to_token == WETH: # unwrapping WETH
        WrappedEth(WETH).deposit(value=from_amount)
        return from_amount
    else:
        to_amount = ERC20(to_token).balanceOf(self)
        
    if is_crypto_pool:
        # if the pool requires uint256 type indexes
        if from_token == VETH:
            CryptoPool(pool).exchange(convert(i, uint256), convert(j, uint256), from_amount, 0, value=from_amount)
        else:
            self.safe_approve(from_token, pool, from_amount)
            if is_underlying:
                CryptoPool(pool).exchange_underlying(convert(i, uint256), convert(j, uint256), from_amount, 0)
            else:
                CryptoPool(pool).exchange(convert(i, uint256), convert(j, uint256), from_amount, 0)
    else:
        # if the pool requires int128 type indexes
        if from_token == VETH:
            CrvPool(pool).exchange(i, j, from_amount, 0, value=from_amount)
        else:
            self.safe_approve(from_token, pool, from_amount)
            if is_underlying:
                CrvPool(pool).exchange_underlying(i, j, from_amount, 0)
            else:
                CrvPool(pool).exchange(i, j, from_amount, 0)
    # calculate swapped amount
    if to_token == VETH:
        to_amount = self.balance - to_amount
    else:
        to_amount = ERC20(to_token).balanceOf(self) - to_amount
    return to_amount

@external
@payable
@nonreentrant("lock")
def deposit(token_address: address, amount: uint256, i: int128, swap_route: DynArray[SwapRoute, MAX_SWAP], min_amount: uint256) -> uint256:
    """
    @notice Deposit token
    @param token_address deposit token address
    @param amount deposit token amount
    @param i deposit token index of the main pool (even after swap)
    @param swap_route swap route before deposit
    @param min_amount minimum amount of vault balance after deposit
    @return added balance of vault
    """
    assert not self.paused, "Paused"
    self.safe_transfer_from(token_address, msg.sender, self, amount)
    in_token: address = token_address
    in_amount: uint256 = amount
    for route in swap_route:
        # swap tokens with swap route
        if route.swap_pool != ZERO_ADDRESS:
            in_amount = self._swap(route.swap_pool, route.i, route.j, in_token, route.j_token, route.is_underlying, in_amount, route.is_crypto_pool)
            in_token = route.j_token
    _main_lp_token: address = self.main_lp_token
    old_balance: uint256 = ERC20(_main_lp_token).balanceOf(self)
    self._deposit(self.main_pool, self.main_deposit, self.main_pool_coin_count, i, in_token, in_amount)
    new_balance: uint256 = ERC20(_main_lp_token).balanceOf(self)
    assert new_balance > old_balance, "Deposit failed"
    total_supply: uint256 = self.totalSupply
    # calculate mint amount as increas LP token amount * totalSupply / old LP balance
    if total_supply > 0:
        new_balance = (new_balance - old_balance) * total_supply / old_balance
    assert new_balance >= min_amount, "High Slippage"
    self._mint(msg.sender, new_balance)
    log Deposit(token_address, msg.sender, amount, new_balance)
    return new_balance

@internal
def _withdraw(lp_token: address, _main_pool: address, out_token: address, i: int128, out_amount: uint256) -> uint256:
    """
    @notice withdraw from curve pool using one token only
    @param lp_token main curve LP address
    @param _main_pool main curve pool to withdraw tokens
    @param out_token token address to withdraw from the main curve pool
    @param i out token index
    @param out_amount curve LP token amount to withdraw from curve pool
    @return withdrawn token amount
    """
    _main_deposit: address = self.main_deposit
    old_balance: uint256 = ERC20(out_token).balanceOf(self)
    if self.is_crypto_pool:
    # if the pool requires uint256 type indexes
        if _main_deposit == IS_A_POOL_IN_DEPOSIT:
        # if main_deposit is address(1), mail_pool requires one argument more
            self.safe_approve(lp_token, _main_pool, out_amount)
            CryptoAPool(_main_pool).remove_liquidity_one_coin(out_amount, convert(i, uint256), 1, True)
        elif _main_deposit == ZERO_ADDRESS:
        # we can withdraw from the main pool directly
            self.safe_approve(lp_token, _main_pool, out_amount)
            CryptoPool(_main_pool).remove_liquidity_one_coin(out_amount, convert(i, uint256), 1)
        elif _main_deposit == self.zap_deposit:
        # withdraw using ZAP deposit contract
            self.safe_approve(lp_token, _main_deposit, out_amount)
            CryptoZapDeposit(_main_deposit).remove_liquidity_one_coin(_main_pool, out_amount, convert(i, uint256), 1)
        else:
        # withdraw using deposit contract
            self.safe_approve(lp_token, _main_deposit, out_amount)
            CryptoPool(_main_deposit).remove_liquidity_one_coin(out_amount, convert(i, uint256), 1)
    else:
    # if the pool requires int128 type indexes
        if _main_deposit == IS_A_POOL_IN_DEPOSIT:
        # if main_deposit is address(1), mail_pool requires one argument more
            self.safe_approve(lp_token, _main_pool, out_amount)
            CrvAPool(_main_pool).remove_liquidity_one_coin(out_amount, i, 1, True)
        elif _main_deposit == ZERO_ADDRESS:
        # we can withdraw from the main pool directly
            self.safe_approve(lp_token, _main_pool, out_amount)
            CrvPool(_main_pool).remove_liquidity_one_coin(out_amount, i, 1)
        elif _main_deposit == self.zap_deposit:
        # withdraw using ZAP deposit contract
            self.safe_approve(lp_token, _main_deposit, out_amount)
            CrvZapDeposit(_main_deposit).remove_liquidity_one_coin(_main_pool, out_amount, i, 1)
        else:
        # withdraw using deposit contract
            self.safe_approve(lp_token, _main_deposit, out_amount)
            CrvPool(_main_deposit).remove_liquidity_one_coin(out_amount, i, 1)
    # returns withdrawn token amount
    return ERC20(out_token).balanceOf(self) - old_balance

@external
@payable
@nonreentrant("lock")
def withdraw(token_address: address, amount: uint256, i: int128, swap_route: DynArray[SwapRoute, MAX_SWAP], min_amount: uint256) -> uint256:
    """
    @notice Withdraw token
    @param token_address withdraw token address
    @param amount withdraw vault balance amount(not token amount)
    @param i withdraw token index of the main pool
    @param swap_route token swap route after withdraw from curve pool, users will get the final token of the swap route
    @param min_amount minimum amount of withdrawn token from withdraw
    @return withdrawn token amount
    """
    out_token: address = token_address
    lp_token: address = self.main_lp_token
    out_amount: uint256 = amount * ERC20(lp_token).balanceOf(self) / self.totalSupply
    _main_pool: address = self.main_pool
    # withdraw token from the curve pool
    out_amount = self._withdraw(lp_token, _main_pool, out_token, i, out_amount)
    self._burn(msg.sender, amount)
    for route in swap_route:
        # swap token with swap route
        if route.swap_pool != ZERO_ADDRESS:
            out_amount = self._swap(route.swap_pool, route.i, route.j, out_token, route.j_token, route.is_underlying, out_amount, route.is_crypto_pool)
            out_token = route.j_token
    assert out_amount >= min_amount, "High Slippage"
    # transfer token to user
    if out_token == VETH:
        send(msg.sender, out_amount)
    else:
        self.safe_transfer(out_token, msg.sender, out_amount)
    log Withdraw(out_token, msg.sender, out_amount, amount)
    return out_amount

@external
def update_pool(_out_token: address, old_i: int128, swap_route: DynArray[SwapRoute, MAX_SWAP], new_pool: address, new_deposit: address, new_i: int128, new_pool_coin_count: uint8, new_lp_token: address, new_is_crypto_pool: bool, new_lp_min_amount: uint256):
    """
    @notice update pool information
    @param _out_token withdraw token address from the old pool
    @param old_i withdraw token index of the old pool
    @param swap_route token swap route from withdrawing to depositing into the new pool
    @param new_pool new main curve pool
    @param new_deposit new main deposit address
    @param new_i deposit token index of new main pool
    @param new_pool_coin_count coin count of new main pool
    @param new_lp_token curve LP token address of the new main pool
    @param new_is_crypto_pool true if new main pool coin index type is uint256
    @param new_lp_min_amount minimum amount of new curve lp token
    """
    assert self.validators[msg.sender], "Not Validator"
    out_token: address = _out_token
    lp_token: address = self.main_lp_token
    out_amount: uint256 = ERC20(lp_token).balanceOf(self)
    from_amount: uint256 = out_amount
    _main_pool: address = self.main_pool
    # withdraw token from the old pool
    out_amount = self._withdraw(lp_token, _main_pool, out_token, old_i, out_amount)
    for route in swap_route:
        # swap token with swap route
        if route.swap_pool != ZERO_ADDRESS:
            out_amount = self._swap(route.swap_pool, route.i, route.j, out_token, route.j_token, route.is_underlying, out_amount, route.is_crypto_pool)
            out_token = route.j_token
    # deposit token into the new pool
    self._deposit(new_pool, new_deposit, new_pool_coin_count, new_i, out_token, out_amount)
    to_amount: uint256 = ERC20(new_lp_token).balanceOf(self)
    assert to_amount >= new_lp_min_amount, "High Slippage"
    # update states
    self.main_pool = new_pool
    self.main_deposit = new_deposit
    self.main_pool_coin_count = new_pool_coin_count
    self.main_lp_token = new_lp_token
    self.is_crypto_pool = new_is_crypto_pool
    log Updated(_main_pool, new_pool, block.timestamp, from_amount, to_amount)

@external
def make_fee(amount: uint256):
# make admin fee to the admin address
    assert msg.sender == self.admin
    self._mint(msg.sender, amount)

@external
def transfer_admin(_admin: address):
# transfer admin permission
    assert msg.sender == self.admin and _admin != ZERO_ADDRESS
    self.admin = _admin

@external
def set_validator(_validator: address, _value: bool):
# register new validator or remove validator
    assert msg.sender == self.admin
    self.validators[_validator] = _value

@external
@payable
def __default__():
# to make possible to receive ETH
    pass

# emergency functions
@external
def set_main_pool(_new_pool: address):
    assert msg.sender == self.admin
    self.main_pool = _new_pool

@external
def set_main_deposit(_new_deposit: address):
    assert msg.sender == self.admin
    self.main_deposit = _new_deposit

@external
def set_main_pool_coin_count(_new_main_pool_coin_count: uint8):
    assert msg.sender == self.admin
    self.main_pool_coin_count = _new_main_pool_coin_count

@external
def set_is_crypto_pool(_new_is_crypto_pool: bool):
    assert msg.sender == self.admin
    self.is_crypto_pool = _new_is_crypto_pool

@external
def set_main_lp_token(_new_main_lp_token: address):
    assert msg.sender == self.admin
    self.main_lp_token = _new_main_lp_token

@external
def set_zap_deposit(_new_zap_deposit: address):
    assert msg.sender == self.admin
    self.zap_deposit = _new_zap_deposit

@external
def pause(_paused: bool):
    assert msg.sender == self.admin
    self.paused = _paused