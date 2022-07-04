# @version 0.3.3

struct SwapRoute:
    to_token: address
    fee: uint24

struct ExactInputSingleParams:
    tokenIn: address
    tokenOut: address
    fee: uint24
    recipient: address
    deadline: uint256
    amountIn: uint256
    amountOutMinimum: uint256
    sqrtPriceLimitX96: uint160

struct MintParams:
    token0: address
    token1: address
    fee: uint24
    tickLower: int24
    tickUpper: int24
    amount0Desired: uint256
    amount1Desired: uint256
    amount0Min: uint256
    amount1Min: uint256
    recipient: address
    deadline: uint256

struct IncreaseLiquidityParams:
    tokenId: uint256
    amount0Desired: uint256
    amount1Desired: uint256
    amount0Min: uint256
    amount1Min: uint256
    deadline: uint256

struct DecreaseLiquidityParams:
    tokenId: uint256
    liquidity: uint128
    amount0Min: uint256
    amount1Min: uint256
    deadline: uint256

struct CollectParams:
    tokenId: uint256
    recipient: address
    amount0Max: uint128
    amount1Max: uint128

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

token0: address
token1: address
fee: uint24
tickLower: int24
tickUpper: int24
liquidity: uint128

tokenId: public(uint256)

validators: public(HashMap[address, bool]) # validators who can update pool
admin: public(address) # admin

NONFUNGIBLE_POSITION_MANAGER: constant(address) = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88
SWAP_ROUTER: constant(address) = 0xE592427A0AEce92De3Edee1F18E0157C05861564
UNISWAP_V3_FACTORY: constant(address) = 0x1F98431c8aD98523631AE4a59f267346ea31F984
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
MAX_SWAP: constant(uint256) = 4 # MAX count of swap steps
MAX_UINT128: constant(uint128) = 2 ** 128 - 1

interface ERC20:
    def balanceOf(_to: address) -> uint256: view

interface WrappedEth:
    def deposit(): payable
    def withdraw(amount: uint256): nonpayable

interface SwapRouter:
    def exactInputSingle(params: ExactInputSingleParams) -> uint256: payable

interface NonfungiblePositionManager:
    def mint(params: MintParams) -> (uint256, uint128, uint256, uint256): payable
    def increaseLiquidity(params: IncreaseLiquidityParams) -> (uint128, uint256, uint256): payable
    def decreaseLiquidity(params: DecreaseLiquidityParams) -> (uint256, uint256): payable
    def collect(params: CollectParams) -> (uint256, uint256): payable
    def burn(tokenId: uint256): payable

interface UniswapV3Factory:
    def getPool(tokenA: address, tokenB: address, fee: uint24) -> address: view

interface UniswapV3Pool:
    def slot0() -> (uint160, int24, uint16, uint16, uint16, uint8, bool): view

@external
def __init__(_name: String[64], _symbol: String[32], _token0: address, _token1: address, _fee: uint24, _tickLower: int24, _tickUpper: int24):
    """
    @notice Contract constructor
    @param _name ERC20 standard name
    @param _symbol ERC20 standard symbol
    """
    self.name = _name
    self.symbol = _symbol
    self.admin = msg.sender
    self.validators[msg.sender] = True
    self.token0 = _token0
    self.token1 = _token1
    self.fee = _fee
    self.tickLower = _tickLower
    self.tickUpper = _tickUpper

# ERC20 common functions

@internal
def _mint(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS # dev: zero address
    assert _value > 0, "Zero mint"
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

@internal
def _burn(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS # dev: zero address
    assert _value > 0, "Zero burn"
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
def fee_reinvest(token_id: uint256, _token0: address, _token1: address):
    amount0: uint256 = ERC20(_token0).balanceOf(self)
    amount1: uint256 = ERC20(_token1).balanceOf(self)
    self.safe_approve(_token0, NONFUNGIBLE_POSITION_MANAGER, amount0)
    self.safe_approve(_token1, NONFUNGIBLE_POSITION_MANAGER, amount1)
    if amount0 > 0 and amount1 > 0:
        _liquidity: uint128 = 0
        _liquidity, amount0, amount1 = NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).increaseLiquidity(IncreaseLiquidityParams({
            tokenId: token_id,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        }))
        self.liquidity = convert(convert(self.liquidity, uint256) + convert(_liquidity, uint256), uint128)

@internal
def _mid_amount(_pool: address, _tickLower: int24, _tickUpper: int24, amount0: uint256, amount1: uint256) -> uint256:
    response: Bytes[224] = raw_call(_pool, method_id("slot0()"), max_outsize=224, is_static_call=True)
    tick: int256 = convert(slice(response, 32, 32), int256)
    tickLower: int256 = convert(_tickLower, int256)
    tickUpper: int256 = convert(_tickUpper, int256)
    if tickLower >= tick:
        return amount1
    elif tickUpper <= tick:
        return amount0
    elif amount0 == 0:
        return amount1 * convert((tickUpper - tick), uint256) / convert((tickUpper - tickLower), uint256)
    else:
        assert amount1 == 0, "Both token"
        return amount0 * convert((tick - tickLower), uint256) / convert((tickUpper - tickLower), uint256)

@external
@payable
@nonreentrant("lock")
def deposit(token_address: address, amount: uint256, swap_route: DynArray[SwapRoute, MAX_SWAP], min_amount: uint256) -> uint256:
    assert not self.paused, "Paused"
    in_token: address = token_address
    if token_address == WETH and msg.value >= amount:
        if msg.value > amount:
            send(msg.sender, msg.value - amount)
        WrappedEth(WETH).deposit(value=amount)
        in_token = WETH
    else:
        self.safe_transfer_from(token_address, msg.sender, self, amount)
    in_amount: uint256 = amount
    for route in swap_route:
        self.safe_approve(in_token, SWAP_ROUTER, in_amount)
        in_amount = SwapRouter(SWAP_ROUTER).exactInputSingle(ExactInputSingleParams({
            tokenIn: in_token,
            tokenOut: route.to_token,
            fee: route.fee,
            recipient: self,
            deadline: block.timestamp,
            amountIn: in_amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }))
        in_token = route.to_token
    out_token: address = self.token0
    _token1: address = self.token1
    mid_amount: uint256 = 0
    token_id: uint256 = self.tokenId
    _tickLower: int24 = self.tickLower
    _tickUpper: int24 = self.tickUpper
    _fee: uint24 = self.fee
    pool: address = UniswapV3Factory(UNISWAP_V3_FACTORY).getPool(out_token, _token1, _fee)
    if out_token == in_token:
        mid_amount = self._mid_amount(pool, _tickLower, _tickUpper, in_amount, 0)
        out_token = _token1
    else:
        mid_amount = self._mid_amount(pool, _tickLower, _tickUpper, 0, in_amount)
        assert in_token == _token1, "Wrong token"
    out_amount: uint256 = 0
    if mid_amount > 0:
        self.safe_approve(in_token, SWAP_ROUTER, mid_amount)
        out_amount = SwapRouter(SWAP_ROUTER).exactInputSingle(ExactInputSingleParams({
            tokenIn: in_token,
            tokenOut: out_token,
            fee: _fee,
            recipient: self,
            deadline: block.timestamp,
            amountIn: mid_amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }))
        in_amount -= mid_amount

    if convert(in_token, uint256) > convert(out_token, uint256):
        tmp_address: address = in_token
        in_token = out_token
        out_token = tmp_address
        tmp_uint256: uint256 = in_amount
        in_amount = out_amount
        out_amount = tmp_uint256

    _liquidity: uint128 = 0
    add_balance: uint256 = 0
    self.safe_approve(in_token, NONFUNGIBLE_POSITION_MANAGER, in_amount)
    self.safe_approve(out_token, NONFUNGIBLE_POSITION_MANAGER, out_amount)
    if token_id == 0:
        amount0: uint256 = 0
        amount1: uint256 = 0
        self.tokenId, _liquidity, amount0, amount1 = NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).mint(MintParams({
            token0: in_token,
            token1: out_token,
            fee: _fee,
            tickLower: _tickLower,
            tickUpper: _tickUpper,
            amount0Desired: in_amount,
            amount1Desired: out_amount,
            amount0Min: 0,
            amount1Min: 0,
            recipient: self,
            deadline: block.timestamp
        }))
        add_balance = convert(_liquidity, uint256)
        self.liquidity = _liquidity
    else:
        amount0: uint256 = 0
        amount1: uint256 = 0
        _liquidity, amount0, amount1 = NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).increaseLiquidity(IncreaseLiquidityParams({
            tokenId: token_id,
            amount0Desired: in_amount,
            amount1Desired: out_amount,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        }))
        old_liquidity: uint256 = convert(self.liquidity, uint256)
        self.liquidity = convert(old_liquidity + convert(_liquidity, uint256), uint128)
        add_balance = convert(_liquidity, uint256) * self.totalSupply / old_liquidity
        NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).collect(CollectParams({
            tokenId: token_id,
            recipient: self,
            amount0Max: MAX_UINT128,
            amount1Max: MAX_UINT128
        }))
        self.fee_reinvest(token_id, in_token, out_token)
    self._mint(msg.sender, add_balance)
    assert add_balance >= min_amount, "High Slippage"
    return add_balance

@external
@nonreentrant("lock")
def withdraw(token_address: address, amount: uint256, swap_route: DynArray[SwapRoute, MAX_SWAP], to_eth:bool, min_amount: uint256) -> uint256:
    token_id: uint256 = self.tokenId
    _token0: address = self.token0
    _token1: address = self.token1
    old_liquidity: uint256 = convert(self.liquidity, uint256)
    _liquidity: uint256 = old_liquidity * amount / self.totalSupply
    self.liquidity = convert(old_liquidity - _liquidity, uint128)
    self._burn(msg.sender, amount)
    amount0: uint256 = 0
    amount1: uint256 = 0
    amount0, amount1 = NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).decreaseLiquidity(DecreaseLiquidityParams({
        tokenId: token_id,
        liquidity: convert(_liquidity, uint128),
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
    }))
    NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).collect(CollectParams({
        tokenId: token_id,
        recipient: self,
        amount0Max: MAX_UINT128,
        amount1Max: MAX_UINT128
    }))
    from_token: address = _token0
    if token_address == from_token:
        from_token = _token1
        tmp_uint256: uint256 = amount0
        amount0 = amount1
        amount1 = tmp_uint256
    if amount0 > 0:
        self.safe_approve(from_token, SWAP_ROUTER, amount0)
        amount0 = SwapRouter(SWAP_ROUTER).exactInputSingle(ExactInputSingleParams({
            tokenIn: from_token,
            tokenOut: token_address,
            fee: self.fee,
            recipient: self,
            deadline: block.timestamp,
            amountIn: amount0,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        })) + amount1
    else:
        amount0 = amount1
    from_token = token_address
    for route in swap_route:
        self.safe_approve(from_token, SWAP_ROUTER, amount0)
        amount0 = SwapRouter(SWAP_ROUTER).exactInputSingle(ExactInputSingleParams({
            tokenIn: from_token,
            tokenOut: route.to_token,
            fee: route.fee,
            recipient: self,
            deadline: block.timestamp,
            amountIn: amount0,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }))
        from_token = route.to_token
    if to_eth and from_token == WETH:
        WrappedEth(WETH).withdraw(amount0)
        send(msg.sender, amount0)
    else:
        self.safe_transfer(from_token, msg.sender, amount0)
    self.fee_reinvest(token_id, _token0, _token1)
    assert amount0 >= min_amount, "High Slippage"
    return amount0

@external
def update_pool(token_address: address, swap_route: DynArray[SwapRoute, MAX_SWAP], _token0: address, _token1: address, _fee: uint24, _tickLower: int24, _tickUpper: int24, min_liquidity: uint128) -> uint128:
    assert self.validators[msg.sender]
    assert convert(_token0, uint256) < convert(_token1, uint256)
    assert _tickLower < _tickUpper
    token_id: uint256 = self.tokenId
    _liquidity: uint128 = self.liquidity
    NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).decreaseLiquidity(DecreaseLiquidityParams({
        tokenId: token_id,
        liquidity: _liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
    }))
    NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).collect(CollectParams({
        tokenId: token_id,
        recipient: self,
        amount0Max: MAX_UINT128,
        amount1Max: MAX_UINT128
    }))
    from_token: address = self.token0
    if token_address == from_token:
        from_token = self.token1
    amount0: uint256 = ERC20(from_token).balanceOf(self)
    amount1: uint256 = ERC20(token_address).balanceOf(self)    
    if amount0 > 0:
        self.safe_approve(from_token, SWAP_ROUTER, amount0)
        amount0 = SwapRouter(SWAP_ROUTER).exactInputSingle(ExactInputSingleParams({
            tokenIn: from_token,
            tokenOut: token_address,
            fee: self.fee,
            recipient: self,
            deadline: block.timestamp,
            amountIn: amount0,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        })) + amount1
    else:
        amount0 = amount1
    from_token = token_address
    for route in swap_route:
        self.safe_approve(from_token, SWAP_ROUTER, amount0)
        amount0 = SwapRouter(SWAP_ROUTER).exactInputSingle(ExactInputSingleParams({
            tokenIn: from_token,
            tokenOut: route.to_token,
            fee: route.fee,
            recipient: self,
            deadline: block.timestamp,
            amountIn: amount0,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }))
        from_token = route.to_token    
    out_token: address = _token0
    mid_amount: uint256 = 0
    pool: address = UniswapV3Factory(UNISWAP_V3_FACTORY).getPool(_token0, _token1, _fee)
    if out_token == from_token:
        mid_amount = self._mid_amount(pool, _tickLower, _tickUpper, amount0, 0)
        out_token = _token1
    else:
        mid_amount = self._mid_amount(pool, _tickLower, _tickUpper, 0, amount0)
        assert from_token == _token1, "Wrong token"
    in_amount: uint256 = amount0
    out_amount: uint256 = 0
    if mid_amount > 0:
        self.safe_approve(from_token, SWAP_ROUTER, mid_amount)
        out_amount = SwapRouter(SWAP_ROUTER).exactInputSingle(ExactInputSingleParams({
            tokenIn: from_token,
            tokenOut: out_token,
            fee: _fee,
            recipient: self,
            deadline: block.timestamp,
            amountIn: mid_amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }))
        in_amount -= mid_amount

    if convert(from_token, uint256) > convert(out_token, uint256):
        tmp_address: address = from_token
        from_token = out_token
        out_token = tmp_address
        tmp_uint256: uint256 = in_amount
        in_amount = out_amount
        out_amount = tmp_uint256

    self.safe_approve(from_token, NONFUNGIBLE_POSITION_MANAGER, in_amount)
    self.safe_approve(out_token, NONFUNGIBLE_POSITION_MANAGER, out_amount)
    self.tokenId, _liquidity, amount0, amount1 = NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).mint(MintParams({
        token0: from_token,
        token1: out_token,
        fee: _fee,
        tickLower: _tickLower,
        tickUpper: _tickUpper,
        amount0Desired: in_amount,
        amount1Desired: out_amount,
        amount0Min: 0,
        amount1Min: 0,
        recipient: self,
        deadline: block.timestamp
    }))
    self.liquidity = _liquidity
    self.token0 = _token0
    self.token1 = _token1
    self.fee = _fee
    self.tickLower = _tickLower
    self.tickUpper = _tickUpper
    assert _liquidity >= min_liquidity, "High Slippage"
    return _liquidity

@external
def reinvest_single_token(is_token0: bool, min_liquidity: uint128) -> uint128:
    token0: address = self.token0
    token1: address = self.token1
    fee: uint24 = self.fee
    tickLower: int24 = self.tickLower
    tickUpper: int24 = self.tickUpper
    mid_amount: uint256 = 0
    amount0: uint256 = ERC20(token0).balanceOf(self)
    amount1: uint256 = ERC20(token1).balanceOf(self)
    pool: address = UniswapV3Factory(UNISWAP_V3_FACTORY).getPool(token0, token1, fee)
    if is_token0:
        mid_amount = self._mid_amount(pool, tickLower, tickUpper, amount0, 0)
        self.safe_approve(token0, SWAP_ROUTER, mid_amount)
        amount1 += SwapRouter(SWAP_ROUTER).exactInputSingle(ExactInputSingleParams({
            tokenIn: token0,
            tokenOut: token1,
            fee: fee,
            recipient: self,
            deadline: block.timestamp,
            amountIn: mid_amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }))
        amount0 -= mid_amount
    else:
        mid_amount = self._mid_amount(pool, tickLower, tickUpper, 0, amount1)
        self.safe_approve(token1, SWAP_ROUTER, mid_amount)
        amount0 += SwapRouter(SWAP_ROUTER).exactInputSingle(ExactInputSingleParams({
            tokenIn: token1,
            tokenOut: token0,
            fee: fee,
            recipient: self,
            deadline: block.timestamp,
            amountIn: mid_amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }))
        amount1 -= mid_amount
    self.safe_approve(token0, NONFUNGIBLE_POSITION_MANAGER, amount0)
    self.safe_approve(token1, NONFUNGIBLE_POSITION_MANAGER, amount1)
    liquidity: uint128 = 0
    tokenId: uint256 = self.tokenId
    liquidity, amount0, amount1 = NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).increaseLiquidity(IncreaseLiquidityParams({
        tokenId: tokenId,
        amount0Desired: amount0,
        amount1Desired: amount1,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
    }))
    self.liquidity = convert(convert(self.liquidity, uint256) + convert(liquidity, uint256), uint128)
    assert liquidity >= min_liquidity, "High Slippage"
    return liquidity

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
def pause(_paused: bool):
    assert msg.sender == self.admin
    self.paused = _paused