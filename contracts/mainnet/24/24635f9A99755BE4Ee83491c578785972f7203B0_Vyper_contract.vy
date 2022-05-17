# @version 0.3.3
# @License Copyright (c) Swap.Dance, 2022 - all rights reserved
# @Author Alexey K
# Swap.Dance Dynamic/Stable Station Template
# Station type: 1 - Dynamic, 0 - Stable

# Stable curve:
# K = (X - A)^2 + (Y - B)^2
# A & B constant
# A == B == 51922968585348.28

# Dynamic curve:
# Price = X/Y

from vyper.interfaces import ERC20

interface ERC20D:
    def name() -> String[32]: view
    def symbol() -> String[32]: view
    def deployer() -> address: view

struct Price:
    token1: address
    token2: address
    staked: uint256
    amount_out: uint256
    station_type: uint256
    decimal_diff_a: uint256
    decimal_diff_b: uint256

struct Swapped:
    amount_out: uint256
    token_out: address

event TokenSwaps:
    receiver: indexed(address)
    token_a: address
    token_b: address
    amount_a: uint256
    amount_b: uint256

event AddLiquidity:
    sender: indexed(address)
    token1: address
    token2: address
    token_amount1: uint256
    token_amount2: uint256

event RemoveLiquidity:
    receiver: indexed(address)
    token1: address
    token2: address
    token_amount1: uint256
    token_amount2: uint256

event NewTokenFees:
    token1: indexed(address)
    token2: indexed(address)
    token_fee1: uint256
    token_fee2: uint256

event NewTokenPair:
    station: indexed(address)
    token_a: address
    token_b: address
    params: uint256

event NewStationFees:
    station: indexed(address)
    station_fee: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event LockStation:
    owner: indexed(address)
    lock_status: uint256

event NewOwner:
    old_owner: indexed(address)
    new_owner: indexed(address)

event NewPot:
    station: indexed(address)
    new_pot: indexed(address)

# Swap Variables
pot: public(bool)
lock: public(bool)
owner: public(address)
kLast: public(decimal)
token_a: public(address)
token_b: public(address)
reserves: public(uint256)
init_time: public(uint256) # time setup
twap_block: public(uint256) # observations block
super_pool: public(address)
pot_station: public(address)
pair_params: public(uint256)
nonces: public(HashMap[address, uint256])
observations: public(HashMap[uint256, uint256]) #twap block number / shift prices

# LP Token
name: public(String[77])
symbol: public(String[68])
decimals: public(uint8)
totalSupply: public(uint256)
station_reserve: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

# Constants
SWD_TOKEN: immutable(address)
DOMAIN_SEPARATOR: public(bytes32)
A: constant(decimal) = 51922968585348.28
DENOMINATOR: constant(decimal) = 10000.0
MINIMUM_LIQUIDITY: constant(decimal) = 0.000000001
DECIMAL18: constant(decimal) = 1000000000000000000.0
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")


@external
def __init__(
    _swd: address
):
    self.owner = msg.sender
    self.lock = True
    self.pot = True
    SWD_TOKEN = _swd


@external
def initialize(
    token_a: address,
    token_b: address,
    token_fees_a: uint256,
    token_fees_b: uint256,
    station_type: uint256,
    expiry: uint256
):
    assert self.pot, "Wrong Copy"
    assert expiry >= block.timestamp, "Expiry Time"
    deployer_response: Bytes[32] = raw_call(
        self.owner,
        _abi_encode(
            token_a,
            token_b,
            token_fees_a,
            token_fees_b,
            station_type,
            method_id=method_id("register_new_pool(address,address,uint256,uint256,uint256)")
        ),
        max_outsize=32,
    )
    if len(deployer_response) > 0:
        assert convert(deployer_response, bool), "Setup failed!"


@external
def initialize_pot_station(station: address, expiry: uint256):
    assert self.pot, "Wrong Copy"
    assert expiry >= block.timestamp, "Expiry Time"
    deployer_response: Bytes[32] = raw_call(
        self.owner,
        _abi_encode(
            station,
            method_id=method_id("register_new_pot(address)")
        ),
        max_outsize=32,
    )
    if len(deployer_response) > 0:
        assert convert(deployer_response, bool), "Setup failed!"


@external
def setup(
    token_a: address,
    token_b: address,
    super_pool: address,
    pair_params: uint256
) -> bool:
    assert self.owner == ZERO_ADDRESS, "Zero Address"
    assert msg.sender == ERC20D(SWD_TOKEN).deployer()
    self.pot = False
    self.lock = False
    self.token_a = token_a
    self.token_b = token_b
    self.owner = msg.sender
    self.super_pool = super_pool
    self.pair_params = pair_params
    # LP Token Details
    self.name = concat("Swap.Dance: ", 
        ERC20D(token_a).symbol(), "/",
        ERC20D(token_b).symbol())
    self.symbol = concat(
        "xDx", ERC20D(token_a).symbol(),
        "x", ERC20D(token_b).symbol())
    self.totalSupply = 0
    self.decimals = 18
    self.init_time = block.timestamp
    
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert("Swap.Dance AMM", Bytes[14])),
            convert(chain.id, bytes32),
            convert(self, bytes32)
        )
    )

    log NewTokenPair(self, token_a, token_b, pair_params)
    return True


@external
def permit(
    owner: address, 
    spender: address, 
    amount: uint256, 
    expiry: uint256, 
    signature: Bytes[65]
) -> bool:
    """
    @notice
        Approves spender by owner's signature to expend owner's tokens.
        See https://eips.ethereum.org/EIPS/eip-2612.
    @param owner The address which is a source of funds and has signed the Permit.
    @param spender The address which is allowed to spend the funds.
    @param amount The amount of tokens to be spent.
    @param expiry The timestamp after which the Permit is no longer valid.
    @param signature A valid secp256k1 signature of Permit by owner encoded as r, s, v.
    @return True, if transaction completes successfully
    """
    assert owner != ZERO_ADDRESS  # dev: invalid owner
    assert expiry == 0 or expiry >= block.timestamp  # dev: permit expired
    nonce: uint256 = self.nonces[owner]
    digest: bytes32 = keccak256(
        concat(
            b'\x19\x01',
            self.DOMAIN_SEPARATOR,
            keccak256(
                concat(
                    PERMIT_TYPE_HASH,
                    convert(owner, bytes32),
                    convert(spender, bytes32),
                    convert(amount, bytes32),
                    convert(nonce, bytes32),
                    convert(expiry, bytes32),
                )
            )
        )
    )
    # NOTE: signature is packed as r, s, v
    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)
    assert ecrecover(digest, v, r, s) == owner  # dev: invalid signature
    self.allowance[owner][spender] = amount
    self.nonces[owner] = nonce + 1
    log Approval(owner, spender, amount)
    return True



@internal
def pack_params(
    staked: uint256, 
    station_type: uint256, 
    locked: uint256, 
    station_approved: uint256, 
    token_fees_a: uint256, 
    token_fees_b: uint256,
    station_fees: uint256,
    decimal_diff_a: uint256,
    decimal_diff_b: uint256
) -> uint256:

    pair_params: uint256 = bitwise_or(
        staked, bitwise_or(
            shift(station_type, 4), bitwise_or(
                shift(locked, 6), bitwise_or(
                    shift(station_approved, 8), bitwise_or(
                        shift(token_fees_a, 16), bitwise_or(
                            shift(token_fees_b, 32), bitwise_or(
                                shift(station_fees, 64), bitwise_or(
                                    shift(decimal_diff_a, 128), shift(decimal_diff_b, 192)))))))))
    return pair_params

@internal
def new_params(
    params: uint256,
    _staked: uint256,
    _locked: uint256,
    _token_fees_a: uint256,
    _token_fees_b: uint256,
    _station_fees: uint256
) -> uint256:
    assert params > 0
    new_params: uint256 = 0
    staked: uint256 = bitwise_and(params, 2 ** 2 - 1)
    station_type: uint256 = bitwise_and(shift(params, -4), 2 ** 2 - 1)
    locked: uint256 = bitwise_and(shift(params, -6), 2 ** 2 - 1)
    station_approved: uint256 = bitwise_and(shift(params, -8), 2 ** 2 - 1)
    token_fees_a: uint256 = bitwise_and(shift(params, -16), 2 ** 16 - 1)
    token_fees_b: uint256 = bitwise_and(shift(params, -32), 2 ** 16 - 1)
    station_fees: uint256 = bitwise_and(shift(params, -64), 2 ** 16 - 1)
    decimal_diff_a: uint256 = bitwise_and(shift(params, -128), 2 ** 64 - 1)
    decimal_diff_b: uint256 = shift(params, -192)
    if _staked == 0 or _staked == 1:
        assert _token_fees_a == 0
        assert _token_fees_b == 0
        assert _station_fees == 0
        assert _locked == 2
        new_params = self.pack_params(
            _staked, 
            station_type, 
            locked, 
            station_approved, 
            token_fees_a, 
            token_fees_b, 
            station_fees, 
            decimal_diff_a, 
            decimal_diff_b
        )
    elif _token_fees_a > 0 and _token_fees_b > 0:
        assert _staked == 2
        assert _locked == 2
        assert _station_fees == 0
        new_params = self.pack_params(
            staked, 
            station_type, 
            locked, 
            station_approved, 
            _token_fees_a, 
            _token_fees_b, 
            station_fees, 
            decimal_diff_a, 
            decimal_diff_b
        )
    elif _station_fees > 0:
        assert _staked == 2
        assert _locked == 2
        assert _token_fees_a == 0
        assert _token_fees_b == 0
        new_params = self.pack_params(
            staked, 
            station_type, 
            locked, 
            station_approved, 
            token_fees_a, 
            token_fees_b, 
            _station_fees, 
            decimal_diff_a, 
            decimal_diff_b
        )
    elif _locked == 0 or _locked == 1:
        assert _staked == 2
        assert _token_fees_a == 0
        assert _token_fees_b == 0
        assert _station_fees == 0
        new_params = self.pack_params(
            staked, 
            station_type, 
            _locked, 
            station_approved, 
            token_fees_a, 
            token_fees_b, 
            station_fees, 
            decimal_diff_a, 
            decimal_diff_b
        )

    return new_params


@external
def stake_review(staked: uint256, pot_address: address) -> bool:
    assert msg.sender == self.owner, "Deployer only"
    assert staked <= 1, "Wrong Stake Num"
    params: uint256 = self.pair_params
    new_params: uint256 = self.new_params(params, staked, 2, 0, 0, 0)
    self.pair_params = new_params
    self.pot_station = pot_address
    log NewPot(self, pot_address)
    return True


@external
def token_fees_review(
    token_fees_a: uint256,
    token_fees_b: uint256
) -> bool:
    assert msg.sender == self.owner, "Deployer only"
    params: uint256 = self.pair_params
    new_params: uint256 = self.new_params(params, 2, 2, token_fees_a, token_fees_b, 0)
    self.pair_params = new_params
    log NewTokenFees(self.token_a, self.token_b, token_fees_a, token_fees_b)
    return True


@external
def station_fees_review(station_fees: uint256) -> bool:
    assert msg.sender == self.owner, "Deployer only"
    params: uint256 = self.pair_params
    new_params: uint256 = self.new_params(params, 2, 2, 0, 0, station_fees)
    self.pair_params = new_params
    log NewStationFees(self, station_fees)
    return True


@internal
def _transfer(sender: address, receiver: address, amount: uint256):
    assert receiver not in [self, ZERO_ADDRESS]
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount
    log Transfer(sender, receiver, amount)


@internal
def safe_transfer_in(token_in: address, amount_in: uint256, _from: address):
    response_in: Bytes[32] = raw_call(
        token_in,
        _abi_encode(
            _from,
            self,
            amount_in,
            method_id=method_id("transferFrom(address,address,uint256)")
        ),
        max_outsize=32,
    )
    if len(response_in) > 0:
        assert convert(response_in, bool), "Transfer /swap in/ failed!"    


@internal
def safe_transfer_out(token_out: address, amount_out: uint256, to: address):
    response_out: Bytes[32] = raw_call(
        token_out,
        _abi_encode(
            to,
            amount_out,
            method_id=method_id("transfer(address,uint256)")
        ),
        max_outsize=32,
    )
    if len(response_out) > 0:
        assert convert(response_out, bool), "Transfer out failed!"


@internal
def mint_reward(staked: uint256, trade_count: uint256):
    if staked == 1 and trade_count > 0:
        minter_response: Bytes[32] = raw_call(
            SWD_TOKEN,
            _abi_encode(
                trade_count,
                method_id=method_id("mint_proof_of_trade(uint256)")
            ),
            max_outsize=32,
        )
        if len(minter_response) > 0:
            assert convert(minter_response, bool), "Mint failed!"
    
        reserves_a_b: uint256 = self.reserves
        reserve_a: uint256 = bitwise_and(reserves_a_b, 2 ** 120 - 1)
        reserve_b: uint256 = bitwise_and(shift(reserves_a_b, -120), 2 ** 120 - 1)
        new_reserves: uint256 = reserve_a + shift(reserve_b, 120) + shift(0, 240)
        self.reserves = new_reserves


@external
def force_reward():
    params: uint256 = self.pair_params
    staked: uint256 = bitwise_and(params, 2 ** 2 - 1)
    assert staked == 1, "Not allowed for reward"
    reserves_a_b: uint256 = self.reserves
    trade_count: uint256 = shift(reserves_a_b, -240)
    assert trade_count > 0, "Trade count 0"
    self.mint_reward(staked, trade_count)


@external
def transfer(receiver: address, amount: uint256) -> bool:
    self._transfer(msg.sender, receiver, amount)
    return True


@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    if (self.allowance[sender][msg.sender] < MAX_UINT256):
        allowance: uint256 = self.allowance[sender][msg.sender] - amount
        self.allowance[sender][msg.sender] = allowance
        # NOTE: Allows log filters to have a full accounting of allowance changes
        log Approval(sender, msg.sender, allowance)
    self._transfer(sender, receiver, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@external
def increaseAllowance(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] += amount
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True


@external
def decreaseAllowance(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] -= amount
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True


@internal
def _mint(receiver: address, amount: uint256):
    self.balanceOf[receiver] += amount
    self.totalSupply += amount
    log Transfer(ZERO_ADDRESS, receiver, amount)


@internal
def _burn(sender: address, amount: uint256):
    self.balanceOf[sender] -= amount
    self.totalSupply -= amount
    log Transfer(sender, ZERO_ADDRESS, amount)


@internal
def calc_price(
    amount_in: uint256, 
    token_in: address
) -> Price:
    token1: address = self.token_a
    token2: address = self.token_b
    params: uint256 = self.pair_params
    token_fee: decimal = empty(decimal)
    staked: uint256 = bitwise_and(params, 2 ** 2 - 1)
    station_type: uint256 = bitwise_and(shift(params, -4), 2 ** 2 - 1)
    token_fees_a: uint256 = bitwise_and(shift(params, -16), 2 ** 16 - 1)
    token_fees_b: uint256 = bitwise_and(shift(params, -32), 2 ** 16 - 1)
    decimal_diff_a: uint256 = bitwise_and(shift(params, -128), 2 ** 64 - 1)
    decimal_diff_b: uint256 = shift(params, -192)
    balance_a: uint256 = ERC20(token1).balanceOf(self) * decimal_diff_a
    balance_b: uint256 = ERC20(token2).balanceOf(self) * decimal_diff_b

    X: decimal = empty(decimal)
    Y: decimal = empty(decimal)
    Z: decimal = empty(decimal)
    AMOUNT_OUT: decimal = empty(decimal)
    
    if token_in == token1:
        X = convert(balance_a, decimal) / DECIMAL18
        Y = convert(balance_b, decimal) / DECIMAL18
        Z = convert(amount_in * decimal_diff_a, decimal) / DECIMAL18
        token_fee = convert(token_fees_b, decimal)
    elif token_in == token2:
        X = convert(balance_b, decimal) / DECIMAL18
        Y = convert(balance_a, decimal) / DECIMAL18
        Z = convert(amount_in * decimal_diff_b, decimal) / DECIMAL18
        token_fee = convert(token_fees_a, decimal)
    else:
        raise "Wrong token_in"
    
    if station_type == 1:
        Y = Y - (Y * token_fee / DENOMINATOR)
        AMOUNT_OUT = (Y / (X + Z)) * Z
    elif station_type == 0:
        K: decimal = (X - A)*(X - A) + (Y - A)*(Y - A)
        E1: decimal = K - ((A - (X + Z)) * (A - (X + Z)))
        E2: decimal = sqrt(E1) + Y
        E3: decimal = E2 - A
        AMOUNT_OUT = E3 - (E3 * token_fee / DENOMINATOR)
        if AMOUNT_OUT > Y:
            AMOUNT_OUT = Y - (Z * token_fee / DENOMINATOR)
    
    return Price({
        token1: token1, 
        token2: token2, 
        staked: staked, 
        amount_out:convert(AMOUNT_OUT * DECIMAL18, uint256),
        station_type: station_type,
        decimal_diff_a: decimal_diff_a,
        decimal_diff_b: decimal_diff_b
    })

@internal
def update_twap(
    station_type: uint256,
    balance_a: decimal, 
    balance_b: decimal, 
    trade_count: uint256, 
    decimal_diff_a: uint256, 
    decimal_diff_b: uint256
):
    twap_block: uint256 = self.twap_block
    update_block: uint256 = block.timestamp
    time_elapsed: uint256 = update_block - twap_block
    if balance_a > 0.0 and balance_b > 0.0:

        new_reserves: uint256 = convert(balance_a * DECIMAL18, uint256) \
            + shift((convert(balance_b * DECIMAL18, uint256)), 120) \
            + shift(trade_count + 1, 240)
        assert trade_count < 65535, "Force the reward" # I think overflow will never happened
        self.reserves = new_reserves
        
        if time_elapsed >= 1800:
            # read twap
            TWAP: uint256 = self.observations[twap_block]
            PRICE_NEW1: decimal = empty(decimal)
            PRICE_NEW2: decimal = empty(decimal)

            if station_type == 1:
                PRICE_NEW1 = balance_a / balance_b
                PRICE_NEW2 = balance_b / balance_a
            else:
                PRICE_NEW1 = (A - balance_a) / (A - balance_b)
                PRICE_NEW2 = (A - balance_b) / (A - balance_a)
            
            PRICE_TWAP1_NEW: uint256 = convert(PRICE_NEW1 * DECIMAL18, uint256) / decimal_diff_a
            PRICE_TWAP2_NEW: uint256 = convert(PRICE_NEW2 * DECIMAL18, uint256) / decimal_diff_b
            
            if TWAP > 0:
                new_twap1: uint256 = (PRICE_TWAP1_NEW + bitwise_and(TWAP, 2 ** 128 - 1)) / 2
                new_twap2: uint256 = (PRICE_TWAP2_NEW + shift(TWAP, -128)) / 2
                self.observations[update_block] = new_twap1 + shift(new_twap2, 128)
            else:
                self.observations[update_block] = PRICE_TWAP1_NEW + shift(PRICE_TWAP2_NEW, 128)
            
            self.twap_block = block.timestamp


@internal
def super_pool_fee(
    D_B_A: decimal, 
    D_B_B: decimal, 
    D_T_S: decimal, 
    station_fees: uint256,
    station_type: uint256,
):
    # mint station fee 
    outdated: decimal = self.kLast
    s_pool: address = self.super_pool
    station_reserve: decimal = empty(decimal)

    if station_type == 1: 
        station_reserve = D_B_A * D_B_B
    else:
        station_reserve = D_B_A + D_B_B

    if station_reserve > 0.0:
        station_reserve = sqrt(station_reserve)
        outdated = sqrt(outdated)
        if station_reserve > outdated:
            D1: decimal = D_T_S * (station_reserve - outdated)
            D2: decimal = station_reserve * (convert(station_fees, decimal) / DENOMINATOR) + outdated
            SUPERPOOL_LIQUIDITY: decimal = D1/D2 * DECIMAL18

            if SUPERPOOL_LIQUIDITY > 0.0:
                self._mint(s_pool, convert(SUPERPOOL_LIQUIDITY / 30.0, uint256))


@external
@nonreentrant("The more you learn, the more you earn")
def swap_tokens(
    amount_in: uint256,
    amount_out_min: uint256,
    token_in: address,
    expiry: uint256
) -> Swapped:
    assert not self.lock, "Pool locked"
    assert expiry >= block.timestamp, "Expiry Time"
    assert amount_in > 0 and amount_out_min > 0, "Amount = 0"

    data_price: Price = self.calc_price(amount_in, token_in)

    token_out: address = empty(address)
    token1: address = data_price.token1
    token2: address = data_price.token2
    staked: uint256 = data_price.staked
    amount_out: uint256 = data_price.amount_out
    station_type: uint256 = data_price.station_type
    decimal_diff_a: uint256 = data_price.decimal_diff_a
    decimal_diff_b: uint256 = data_price.decimal_diff_b

    if token_in == token1:
        token_out = token2
        amount_out = amount_out / decimal_diff_b
    elif token_in == token2:
        amount_out = amount_out / decimal_diff_a
        token_out = token1
    else:
        raise "Wrong token_in"

    assert amount_out >= amount_out_min, "Amount out < Min amount out"
    
    self.safe_transfer_in(token_in, amount_in, msg.sender)
    self.safe_transfer_out(token_out, amount_out, msg.sender)

    # update reserves, twap & count of trade 
    # lazy method to mint new reward with add/remove liquidity or force it with a func
    token_balance_a: uint256 = ERC20(token1).balanceOf(self) * decimal_diff_a
    token_balance_b: uint256 = ERC20(token2).balanceOf(self) * decimal_diff_b

    D_B_A: decimal = convert(token_balance_a, decimal) / DECIMAL18
    D_B_B: decimal = convert(token_balance_b, decimal) / DECIMAL18

    reserves_a_b: uint256 = self.reserves
    reserve_a: uint256 = bitwise_and(reserves_a_b, 2 ** 120 - 1)
    reserve_b: uint256 = bitwise_and(shift(reserves_a_b, -120), 2 ** 120 - 1)
    trade_count: uint256 = shift(reserves_a_b, -240)
    
    D_R_A: decimal = convert(reserve_a, decimal) / DECIMAL18
    D_R_B: decimal = convert(reserve_b, decimal) / DECIMAL18

    #update
    if station_type == 1:
        assert D_B_A * D_B_B >= D_R_A * D_R_B, "Reserves less than must be"
    else:
        check_kLast: decimal = self.kLast
        assert D_B_A + D_B_B >= check_kLast, "Stable reserves less than must be"

    if staked == 0:
        trade_count = 0
    
    self.update_twap(
        station_type,
        D_B_A, 
        D_B_B, 
        trade_count,
        decimal_diff_a, 
        decimal_diff_b
    )

    log TokenSwaps(msg.sender, token_in, token_out, amount_in, amount_out)
    
    return Swapped({
        amount_out: amount_out, 
        token_out: token_out
    })



@external
@nonreentrant("The more you learn, the more you earn")
def add_liquidity(
    token_amount_a: uint256,
    amount_a_min: uint256,
    token_amount_b: uint256,
    amount_b_min: uint256,
    expiry: uint256
):
    assert not self.lock, "Pool locked"
    assert expiry >= block.timestamp, "Expiry Time"
    assert amount_a_min > 0 and amount_b_min > 0, "Amount min = 0"

    params: uint256 = self.pair_params
    staked: uint256 = bitwise_and(params, 2 ** 2 - 1)
    station_type: uint256 = bitwise_and(shift(params, -4), 2 ** 2 - 1)
    station_fees: uint256 = bitwise_and(shift(params, -64), 2 ** 16 - 1)
    decimal_diff_a: uint256 = bitwise_and(shift(params, -128), 2 ** 64 - 1)
    decimal_diff_b: uint256 = shift(params, -192)

    amount_a: uint256 = empty(uint256)
    amount_b: uint256 = empty(uint256)
    token_in_a: address = self.token_a
    token_in_b: address = self.token_b

    token_balance_a: uint256 = ERC20(token_in_a).balanceOf(self) * decimal_diff_a
    token_balance_b: uint256 = ERC20(token_in_b).balanceOf(self) * decimal_diff_b

    D_B_A: decimal = convert(token_balance_a, decimal) / DECIMAL18
    D_B_B: decimal = convert(token_balance_b, decimal) / DECIMAL18
    D_T_A: decimal = convert(token_amount_a * decimal_diff_a, decimal) / DECIMAL18
    D_T_B: decimal = convert(token_amount_b * decimal_diff_b, decimal) / DECIMAL18
    
    if station_type == 1:
        if token_balance_a == 0 and token_balance_b == 0:
            assert token_amount_a > 0 and token_amount_b > 0, "Amount a/b = 0"
            amount_a = token_amount_a
            amount_b = token_amount_b
        else:
            d_Y: decimal = (D_T_A * D_B_B) / D_B_A
            if d_Y <= D_T_B:
                amount_a = token_amount_a
                amount_b = convert(d_Y * DECIMAL18, uint256) / decimal_diff_b
                assert amount_b >= amount_b_min, "Amount B < Min amount B"
            else:
                d_X: decimal = (D_T_B * D_B_A) / D_B_B
                assert d_X <= D_T_A
                amount_a = convert(d_X * DECIMAL18, uint256) / decimal_diff_a
                amount_b = token_amount_b
                assert amount_a >= amount_a_min, "Amount A < Min amount A"
                
    elif station_type == 0:
        assert D_T_A > 0.0 and D_T_B > 0.0 and D_T_A == D_T_B, "Check amounts"
        amount_a = token_amount_a
        amount_b = token_amount_b
    
    # transfer
    self.safe_transfer_in(token_in_a, amount_a, msg.sender)
    self.safe_transfer_in(token_in_b, amount_b, msg.sender)

    liquidity: decimal = empty(decimal)
    total_pool_tokens: uint256 = self.totalSupply
    N_T_A: decimal = convert(amount_a * decimal_diff_a, decimal) / DECIMAL18
    N_T_B: decimal = convert(amount_b * decimal_diff_b, decimal) / DECIMAL18
    D_T_S: decimal = convert(total_pool_tokens, decimal) / DECIMAL18
    
    self.super_pool_fee(
        D_B_A,
        D_B_B,
        D_T_S, 
        station_fees, 
        station_type
    )
    # update TS and Decimal TS
    total_pool_tokens = self.totalSupply
    D_T_S = convert(total_pool_tokens, decimal) / DECIMAL18
    # mint LP tokens
    if total_pool_tokens == 0:
        liquidity = sqrt(D_T_A * D_T_B) - MINIMUM_LIQUIDITY
        self._mint(ZERO_ADDRESS, convert(MINIMUM_LIQUIDITY * DECIMAL18, uint256))
    else:
        liquidity1: decimal = N_T_A * D_T_S / D_B_A
        liquidity2: decimal = N_T_B * D_T_S / D_B_B
        liquidity = min(liquidity1, liquidity2)

    assert liquidity > 0.0, "Liquidity is Zero"

    self._mint(msg.sender, convert(liquidity * DECIMAL18, uint256))

    # update reserves & twap
    token_balance_a = ERC20(token_in_a).balanceOf(self) * decimal_diff_a
    token_balance_b = ERC20(token_in_b).balanceOf(self) * decimal_diff_b

    D_B_A = convert(token_balance_a, decimal) / DECIMAL18
    D_B_B = convert(token_balance_b, decimal) / DECIMAL18

    reserves_a_b: uint256 = self.reserves
    trade_count: uint256 = shift(reserves_a_b, -240)

    #update  
    if staked == 0:
        trade_count = 0
        
    self.update_twap(
        station_type,
        D_B_A, 
        D_B_B, 
        trade_count,
        decimal_diff_a, 
        decimal_diff_b
    )

    self.mint_reward(staked, trade_count)

    if station_type == 1:
        self.kLast = D_B_A * D_B_B
    else:
        self.kLast = D_B_A + D_B_B

    log AddLiquidity(msg.sender, token_in_a, token_in_b, amount_a, amount_b)


@external
@nonreentrant("The more you learn, the more you earn")
def remove_liquidity(
    pool_token_amount: uint256,
    amount_out_a_min: uint256,
    amount_out_b_min: uint256,
    expiry: uint256
):
    assert expiry >= block.timestamp, "Expiry Time"
    assert self.balanceOf[msg.sender] >= pool_token_amount, "You want too much"
    assert amount_out_a_min > 0 and amount_out_b_min > 0, "Amount min = 0"

    params: uint256 = self.pair_params
    token_out_a: address = self.token_a
    token_out_b: address = self.token_b
    total_pool_tokens: uint256 = self.totalSupply
    staked: uint256 = bitwise_and(params, 2 ** 2 - 1)
    station_type: uint256 = bitwise_and(shift(params, -4), 2 ** 2 - 1)
    station_fees: uint256 = bitwise_and(shift(params, -64), 2 ** 16 - 1)
    decimal_diff_a: uint256 = bitwise_and(shift(params, -128), 2 ** 64 - 1)
    decimal_diff_b: uint256 = shift(params, -192)

    token_balance_a: uint256 = ERC20(token_out_a).balanceOf(self) * decimal_diff_a
    token_balance_b: uint256 = ERC20(token_out_b).balanceOf(self) * decimal_diff_b

    D_B_A: decimal = convert(token_balance_a, decimal) / DECIMAL18
    D_B_B: decimal = convert(token_balance_b, decimal) / DECIMAL18
    D_T_S: decimal = convert(total_pool_tokens, decimal) / DECIMAL18
    D_T_A: decimal = convert(pool_token_amount, decimal) / DECIMAL18
    
    # mint station fee
    self.super_pool_fee(
        D_B_A,
        D_B_B,
        D_T_S, 
        station_fees, 
        station_type
    )
    # update TS and Decimal TS
    
    total_pool_tokens = self.totalSupply
    D_T_S = convert(total_pool_tokens, decimal) / DECIMAL18
    d_X: decimal = (D_T_A * D_B_A) / D_T_S
    d_Y: decimal = (D_T_A * D_B_B) / D_T_S
    
    amount_out_a: uint256 = convert(d_X * DECIMAL18, uint256) / decimal_diff_a
    amount_out_b: uint256 = convert(d_Y * DECIMAL18, uint256) / decimal_diff_b

    assert amount_out_a >= amount_out_a_min, "Amount out A < Min amount out A"
    assert amount_out_b >= amount_out_b_min, "Amount out B < Min amount out B"

    self._burn(msg.sender, pool_token_amount)
    self.safe_transfer_out(token_out_a, amount_out_a, msg.sender)
    self.safe_transfer_out(token_out_b, amount_out_b, msg.sender)
    
    # update reserves & twap
    token_balance_a = ERC20(token_out_a).balanceOf(self) * decimal_diff_a
    token_balance_b = ERC20(token_out_b).balanceOf(self) * decimal_diff_b

    D_B_A = convert(token_balance_a, decimal) / DECIMAL18
    D_B_B = convert(token_balance_b, decimal) / DECIMAL18

    reserves_a_b: uint256 = self.reserves
    trade_count: uint256 = shift(reserves_a_b, -240)
    
    #update
    if staked == 0:
        trade_count = 0
        
    self.update_twap(
        station_type,
        D_B_A, 
        D_B_B, 
        trade_count,
        decimal_diff_a, 
        decimal_diff_b
    )

    self.mint_reward(staked, trade_count)

    if station_type == 1:
        self.kLast = D_B_A * D_B_B
    else:
        self.kLast = D_B_A + D_B_B

    log RemoveLiquidity(msg.sender, token_out_a, token_out_b, amount_out_a, amount_out_b)


@external
def update_lock(lock: uint256) -> bool:
    assert not self.pot, "You cant lock template"
    assert msg.sender == self.owner, "Deployer only"
    self.lock = convert(lock, bool)
    params: uint256 = self.pair_params
    new_params: uint256 = self.new_params(params, 2, lock, 0, 0, 0)
    self.pair_params = new_params
    log LockStation(msg.sender, lock)
    return True


@external
def update_owner(new_owner: address) -> bool:
    assert msg.sender == self.owner, "Deployer only"
    assert self.pot
    self.owner = new_owner
    log NewOwner(msg.sender, new_owner)
    return True