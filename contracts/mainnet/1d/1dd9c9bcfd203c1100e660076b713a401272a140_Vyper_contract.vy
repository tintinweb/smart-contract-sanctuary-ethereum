# @version 0.3.6

struct Deposit:
    lower_tick: int24
    liquidity: uint128
    depositor: address
    deadline: uint256

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

interface ERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def approve(_spender: address, _value: uint256) -> bool: nonpayable

interface WrappedEth:
    def deposit(): payable
    def withdraw(amount: uint256): nonpayable

interface NonfungiblePositionManager:
    def mint(params: MintParams) -> (uint256, uint128, uint256, uint256): payable
    def decreaseLiquidity(params: DecreaseLiquidityParams) -> (uint256, uint256): payable
    def collect(params: CollectParams) -> (uint256, uint256): payable
    def burn(tokenId: uint256): payable

NONFUNGIBLE_POSITION_MANAGER: constant(address) = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88
USDC: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 # USDC
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 # WETH
FEE_LEVEL: constant(uint24) = 500
POOL: constant(address) = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640 # USDC-WETH-500
MAX_SIZE: constant(uint256) = 127
ERROR: constant(int24) = 100 # 1%

event Deposited:
    token_id: indexed(uint256)
    depositor: indexed(address)
    amount: uint256
    lower_tick: int24
    upper_tick: int24
    lower_sqrt_price_x96: uint256
    deadline: uint256

event Withdrawn:
    token_id: indexed(uint256)
    withdrawer: indexed(address)
    recipient: indexed(address)
    amount0: uint256
    amount1: uint256

depositors: public(HashMap[uint256, Deposit])

@external
@payable
def deposit(lower_tick: int24, lower_sqrt_price_x96: uint256, upper_tick: int24, deadline: uint256):
    assert msg.value > 0, "Zero Value"
    WrappedEth(WETH).deposit(value=msg.value)
    ERC20(WETH).approve(NONFUNGIBLE_POSITION_MANAGER, msg.value)
    tokenId: uint256 = 0
    liquidity: uint128 = 0
    amount0: uint256 = 0
    amount1: uint256 = 0
    tokenId, liquidity, amount0, amount1 = NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).mint(MintParams({
        token0: USDC,
        token1: WETH,
        fee: FEE_LEVEL,
        tickLower: lower_tick,
        tickUpper: upper_tick,
        amount0Desired: 0,
        amount1Desired: msg.value,
        amount0Min: 0,
        amount1Min: 1,
        recipient: self,
        deadline: block.timestamp
    }))
    self.depositors[tokenId] = Deposit({
        lower_tick: lower_tick,
        liquidity: liquidity,
        depositor: msg.sender,
        deadline: deadline
    })
    log Deposited(tokenId, msg.sender, msg.value, lower_tick, upper_tick, lower_sqrt_price_x96, deadline)

@internal
def _withdraw(tokenId: uint256, recipient: address, liquidity: uint128):
    NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).decreaseLiquidity(DecreaseLiquidityParams({
        tokenId: tokenId,
        liquidity: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
    }))
    amount0: uint256 = 0
    amount1: uint256 = 0
    amount0, amount1 = NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).collect(CollectParams({
        tokenId: tokenId,
        recipient: self,
        amount0Max: max_value(uint128),
        amount1Max: max_value(uint128)
    }))
    NonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).burn(tokenId)
    self.depositors[tokenId] = Deposit({
        lower_tick: 0,
        liquidity: 0,
        depositor: empty(address),
        deadline: 0
    })
    if amount0 > 0:
        ERC20(USDC).transfer(recipient, amount0)
    if amount1 > 0:
        WrappedEth(WETH).withdraw(amount1)
        send(recipient, amount1)
    log Withdrawn(tokenId, msg.sender, recipient, amount0, amount1)

@external
@nonreentrant("lock")
def withdraw(tokenId: uint256):
    response_64: Bytes[64] = raw_call(
        POOL,
        method_id("slot0()"),
        max_outsize = 64,
        is_static_call = True
    )
    tick: int24 = unsafe_sub(convert(slice(response_64, 32, 32), int24), ERROR)
    deposit: Deposit = self.depositors[tokenId]
    assert tick <= deposit.lower_tick
    self._withdraw(tokenId, deposit.depositor, deposit.liquidity)

@external
@nonreentrant("lock")
def multiple_withdraw(tokenIds: DynArray[uint256, MAX_SIZE]):
    response_64: Bytes[64] = raw_call(
        POOL,
        method_id("slot0()"),
        max_outsize = 64,
        is_static_call = True
    )
    tick: int24 = unsafe_sub(convert(slice(response_64, 32, 32), int24), ERROR)
    for tokenId in tokenIds:
        deposit: Deposit = self.depositors[tokenId]
        assert tick <= deposit.lower_tick
        self._withdraw(tokenId, deposit.depositor, deposit.liquidity)

@external
@nonreentrant("lock")
def cancel(tokenId: uint256):
    deposit: Deposit = self.depositors[tokenId]
    assert deposit.depositor == msg.sender or deposit.deadline < block.timestamp
    self._withdraw(tokenId, deposit.depositor, deposit.liquidity)

@external
@nonreentrant("lock")
def multiple_cancel(tokenIds: DynArray[uint256, MAX_SIZE]):
    for tokenId in tokenIds:
        deposit: Deposit = self.depositors[tokenId]
        assert deposit.depositor == msg.sender or deposit.deadline < block.timestamp
        self._withdraw(tokenId, deposit.depositor, deposit.liquidity)

@external
@payable
def __default__():
    assert msg.sender == WETH