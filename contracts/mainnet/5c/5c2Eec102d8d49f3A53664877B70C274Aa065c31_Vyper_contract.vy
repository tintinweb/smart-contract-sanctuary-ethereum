# @version 0.3.3
# @License Copyright (c) Swap.Dance, 2022 - all rights reserved
# @Author Alexey K
# Swap.Dance Deployer

interface SUPER:
    def drop_distribution_balances(
        tokens: address[10]
    ) -> bool: nonpayable

interface ERC20D:
    def lock() -> bool: view
    def token_a() -> address: view
    def token_b() -> address: view
    def name() -> String[32]: view
    def symbol() -> String[32]: view
    def decimals() -> uint256: view
    def pair_params() -> uint256: view
    def pot_station() -> address: view
    def totalSupply() -> uint256: view
    def balanceOf(station: address) -> uint256: view

struct PairInfo:
    station: address
    token_a: address
    token_b: address
    pot_station: address
    token_name_a: String[32]
    token_symbol_a: String[32]
    token_name_b: String[32]
    token_symbol_b: String[32]
    token_decimals_a: uint256
    token_decimals_b: uint256
    token_balance_a: uint256
    token_balance_b: uint256
    station_token_balance: uint256
    pot_station_swd_balance: uint256
    params: uint256
    staked: uint256
    station_type: uint256
    locked: uint256
    station_approved: uint256
    token_fees_a: uint256
    token_fees_b: uint256
    station_fees: uint256
    decimal_diff_a: uint256
    decimal_diff_b: uint256

struct BlockInfo:
    station_array: address[30]
    pot_array: address[30]
    token_array_a: address[30]
    token_array_b: address[30]
    token_array_name_a: bytes32[30]
    token_array_name_b: bytes32[30]
    token_array_symbols: bytes32[30]
    pair_params_array: uint256[30]
    token_array_decimals_balances: uint256[30]
    station_pot_array_balances: uint256[30]

event NewOwner:
    old_owner: indexed(address)
    new_owner: indexed(address)
    
event NewGuardian:
    guardian: indexed(address)

# Variables
done: bool
owner_agree: bool
guardian_agree: bool
owner: public(address)
guardian: public(address)
exchange_count: public(uint256)
exchange_info: public(HashMap[uint256, uint256])
pot_station_list: public(HashMap[address, address])
exchange_pairs_list: public(HashMap[uint256, address])
approved_tokens: public(HashMap[uint256, HashMap[address, bool]])

# Constants
STATION: immutable(address)
SWD_TOKEN: immutable(address)
SUPER_POOL: immutable(address)
POT_STATION: immutable(address)
MAX_STEPS: constant(int128) = 30


@external
def __init__(
    swd_token: address,
    super_pool: address,
    pot_station: address,
    station: address,
):
    self.owner = msg.sender
    SWD_TOKEN = swd_token
    SUPER_POOL = super_pool
    POT_STATION = pot_station
    STATION = station
    

@external
def register_new_pool(
        token_a: address,
        token_b: address,
        token_fees_a: uint256,
        token_fees_b: uint256,
        station_type: uint256
) -> bool:
    decimal_diff_a: uint256 = empty(uint256)
    decimal_diff_b: uint256 = empty(uint256)
    decimal_a: uint256 = ERC20D(token_a).decimals()
    decimal_b: uint256 = ERC20D(token_b).decimals()
    token_pair: uint256 = bitwise_xor(convert(token_a, uint256), convert(token_b, uint256))
    assert self.exchange_pairs_list[token_pair] == ZERO_ADDRESS, "Pair already exist"
    assert token_a not in [STATION, ZERO_ADDRESS]
    assert token_b not in [STATION, ZERO_ADDRESS]
    assert msg.sender == STATION, "Wrong sender"
    assert token_a != token_b, "Token1 = Token2"
    assert station_type <= 1, "Wrong station type"
    assert decimal_a != 0 and decimal_b != 0, "Token decimal cant be zero"
    assert token_fees_a >= 1 and token_fees_a <= 99, "Wrong Token Fees"
    assert token_fees_b >= 1 and token_fees_b <= 99, "Wrong Token Fees"

    if decimal_a == 18 and decimal_b == 18:
        decimal_diff_a = 1
        decimal_diff_b = 1
    elif decimal_a < 18 and decimal_b < 18:
        decimal_diff_a = 10 ** (18 - decimal_a)
        decimal_diff_b = 10 ** (18 - decimal_b)
    elif decimal_a == 18 and decimal_b < 18:
        decimal_diff_a = 1
        decimal_diff_b = 10 ** (18 - decimal_b)
    elif decimal_a < 18 and decimal_b == 18:
        decimal_diff_a = 10 ** (18 - decimal_a)
        decimal_diff_b = 1
    else:
        raise "Decimals too big"

    new_pool: address = ZERO_ADDRESS
    #
    
    addr_salt: bytes32 = keccak256(
        concat(
            convert(msg.sender, bytes32),
            convert(token_pair, bytes32),
            convert(token_a, bytes32),
            convert(token_b, bytes32))
            )
    new_pool = create_forwarder_to(STATION, salt = addr_salt)

    self.exchange_count += 1
    count: uint256 = self.exchange_count
    self.exchange_pairs_list[token_pair] = new_pool
    self.exchange_info[count] = token_pair
    self.exchange_info[token_pair] = count
    # Super pool fees is 9 that equals 1.665% for stable
    # and 3.709% for dynamic pool by default
    # Station lock is 0 by default
    # Proof of trade is False by default
    station_approved: uint256 = 0

    check_token_a: bool = self.approved_tokens[0][token_a]
    check_token_b: bool = self.approved_tokens[0][token_b]
    
    if True in [check_token_a, check_token_b]:
        self.approved_tokens[1][new_pool] = True
        station_approved = 1
    else:
        self.approved_tokens[1][new_pool] = False

    locked: uint256 = 0
    staked: uint256 = 0
    station_fees: uint256 = 9

    pair_params: uint256 = bitwise_or(
        staked, bitwise_or(
            shift(station_type, 4), bitwise_or(
                shift(locked, 6), bitwise_or(
                    shift(station_approved, 8), bitwise_or(
                        shift(token_fees_a, 16), bitwise_or(
                            shift(token_fees_b, 32), bitwise_or(
                                shift(station_fees, 64), bitwise_or(
                                    shift(decimal_diff_a, 128), shift(decimal_diff_b, 192)))))))))

    pool_response: Bytes[32] = raw_call(
        new_pool,
        _abi_encode(
            token_a, 
            token_b, 
            SUPER_POOL, 
            pair_params, 
            method_id=method_id("setup(address,address,address,uint256)")
        ),
        max_outsize=32,
    )
    if len(pool_response) > 0:
        assert convert(pool_response, bool), "Pool setup failed"

    super_response: Bytes[32] = raw_call(
        SUPER_POOL,
        _abi_encode(
            new_pool, 
            method_id=method_id("add_approved_tokens(address)")
        ),
        max_outsize=32,
    )
    if len(super_response) > 0:
        assert convert(super_response, bool), "Super pool response failed"

    return True


@external
def register_new_pot(station: address) -> bool:
    assert self.approved_tokens[1][station], "Station not approved"
    assert self.pot_station_list[station] == ZERO_ADDRESS, "Station has PoT"
    assert msg.sender == STATION, "Wrong sender"

    new_pot: address = create_forwarder_to(POT_STATION)
    proof_of_trade: uint256 = 1

    pot_response: Bytes[32] = raw_call(
        new_pot,
        _abi_encode(
            station, 
            method_id=method_id("setup(address)")
        ),
        max_outsize=32,
    )
    if len(pot_response) > 0:
        assert convert(pot_response, bool), "PoT setup failed"

    station_response: Bytes[32] = raw_call(
        station,
        _abi_encode(
            proof_of_trade,
            new_pot,
            method_id=method_id("stake_review(uint256,address)")
        ),
        max_outsize=32,
    )
    if len(station_response) > 0:
        assert convert(station_response, bool), "Station response failed"

    swd_token_response: Bytes[32] = raw_call(
        SWD_TOKEN,
        _abi_encode(
            station,
            new_pot,
            method_id=method_id("register_pot(address,address)")
        ),
        max_outsize=32,
    )
    if len(swd_token_response) > 0:
        assert convert(swd_token_response, bool), "SWD response failed"

    self.pot_station_list[station] = new_pot
    return True


@external
def register_deployer():
    assert msg.sender == self.owner, "Owner only"
    swd_response: Bytes[32] = raw_call(
        SWD_TOKEN,
        method_id("register_deployer()"),
        max_outsize=32,
    )
    if len(swd_response) > 0:
        assert convert(swd_response, bool), "Register failed!"


@external
def remove_token_pair(token_a: address, token_b: address):
    assert msg.sender == self.owner, "Owner only"
    lock_status: uint256 = 1
    token_pair: uint256 = bitwise_xor(
        convert(token_a, uint256),
        convert(token_b, uint256))
    count: uint256 = self.exchange_info[token_pair]
    station_addr: address = self.exchange_pairs_list[token_pair]
    assert station_addr != ZERO_ADDRESS, "Station not registred"
    self.exchange_info[count] = 0
    self.exchange_info[token_pair] = 0
    self.approved_tokens[1][station_addr] = False
    self.exchange_pairs_list[token_pair] = ZERO_ADDRESS
    pot_addr: address = self.pot_station_list[station_addr]
    if pot_addr != ZERO_ADDRESS:
        self.pot_station_list[station_addr] = ZERO_ADDRESS
        pot_response: Bytes[32] = raw_call(
            pot_addr,
            _abi_encode(
                lock_status,
                method_id=method_id("update_lock(uint256)")
            ),
            max_outsize=32,
        )
        if len(pot_response) > 0:
            assert convert(pot_response, bool), "PoT response failed"

    station_response: Bytes[32] = raw_call(
        station_addr,
        _abi_encode(
            lock_status,
            method_id=method_id("update_lock(uint256)")
        ),
        max_outsize=32,
    )
    if len(station_response) > 0:
        assert convert(station_response, bool), "Station response failed"

    super_response: Bytes[32] = raw_call(
        SUPER_POOL,
        _abi_encode(
            station_addr,
            method_id=method_id("remove_approved_tokens(address)")
        ),
        max_outsize=32,
    )
    if len(super_response) > 0:
        assert convert(super_response, bool), "Super pool response failed"


@external
def add_approved_tokens(new_token: address):
    assert msg.sender == self.owner, "Owner only"
    assert new_token != ZERO_ADDRESS, "ZERO ADDRESS"
    assert not self.approved_tokens[0][new_token]
    self.approved_tokens[0][new_token] = True


@external
def remove_approved_tokens(new_token: address):
    assert msg.sender == self.owner, "Owner only"
    assert self.approved_tokens[0][new_token]
    self.approved_tokens[0][new_token] = False


# super pool control
@external
def super_pool_drop_balances(tokens: address[10]) -> bool:
    assert msg.sender == self.owner, "Owner only"
    SUPER(SUPER_POOL).drop_distribution_balances(tokens)
    return True


@external
def lock_super_pool(lock: uint256) -> bool:
    assert msg.sender == self.owner, "Owner only"
    super_response: Bytes[32] = raw_call(
        SUPER_POOL,
        _abi_encode(
            lock,
            method_id=method_id("update_lock(uint256)")
        ),
        max_outsize=32,
    )
    if len(super_response) > 0:
        assert convert(super_response, bool), "Super pool response failed"
    return True


# station control
@external
def lock_station(station: address, lock: uint256):
    assert msg.sender == self.owner, "Owner only"
    assert lock <= 1, "1 Locked, 0 Unlocked"
    pot_addr: address = self.pot_station_list[station]

    if pot_addr != ZERO_ADDRESS:
        pot_response: Bytes[32] = raw_call(
            pot_addr,
            _abi_encode(
                lock,
                method_id=method_id("update_lock(uint256)")
            ),
            max_outsize=32,
        )
        if len(pot_response) > 0:
            assert convert(pot_response, bool), "PoT response failed"

    station_response: Bytes[32] = raw_call(
        station,
        _abi_encode(
            lock,
            method_id=method_id("update_lock(uint256)")
        ),
        max_outsize=32,
    )
    if len(station_response) > 0:
        assert convert(station_response, bool), "Station response failed"


@external
def unstake_station(station: address):
    assert msg.sender == self.owner, "Owner only"
    assert self.pot_station_list[station] != ZERO_ADDRESS, "Station hasn't PoT"
    station_response: Bytes[32] = raw_call(
        station,
        _abi_encode(
            empty(uint256),
            empty(address),
            method_id=method_id("stake_review(uint256,address)")
        ),
        max_outsize=32,
    )
    if len(station_response) > 0:
        assert convert(station_response, bool), "Station response failed"


@external
def update_token_fees(station: address, token_fees_a: uint256, token_fees_b: uint256):
    assert msg.sender == self.owner, "Owner only"
    assert token_fees_a >= 1 and token_fees_a <= 99, "Wrong token fees"
    assert token_fees_b >= 1 and token_fees_b <= 99, "Wrong token fees"
    station_response: Bytes[32] = raw_call(
        station,
        _abi_encode(
            token_fees_a,
            token_fees_b,
            method_id=method_id("token_fees_review(uint256,uint256)")
        ),
        max_outsize=32,
    )
    if len(station_response) > 0:
        assert convert(station_response, bool), "Station response failed"


@external
def update_station_fees(station: address, station_fees: uint256):
    assert msg.sender == self.owner, "Owner only"
    assert station_fees >= 5 and station_fees <= 30, "Wrong station fees"
    station_response: Bytes[32] = raw_call(
        station,
        _abi_encode(
            station_fees,
            method_id=method_id("station_fees_review(uint256)")
        ),
        max_outsize=32,
    )
    if len(station_response) > 0:
        assert convert(station_response, bool), "Station response failed"


@external
@view
def get_pair(
    token_a: address,
    token_b: address,
) -> (
    uint256,
    address
):
    token_pair: uint256 = bitwise_xor(convert(token_a, uint256), convert(token_b, uint256))
    if self.exchange_pairs_list[token_pair] == ZERO_ADDRESS:
        return (0, ZERO_ADDRESS)
    else:
        station: address = self.exchange_pairs_list[token_pair]
        return (token_pair, station)


@external
@view
def get_pair_info(pair_id: uint256) -> PairInfo:
    token_pair: uint256 = self.exchange_info[pair_id]
    if token_pair > 0:
        station: address = self.exchange_pairs_list[token_pair]
        
        token_a: address = ERC20D(station).token_a()
        token_name_a: String[32] = ERC20D(token_a).name()
        token_symbol_a: String[32] = ERC20D(token_a).symbol()
        token_decimals_a: uint256 = ERC20D(token_a).decimals()

        token_b: address = ERC20D(station).token_b()
        token_name_b: String[32] = ERC20D(token_b).name()
        token_symbol_b: String[32] = ERC20D(token_b).symbol()
        token_decimals_b: uint256 = ERC20D(token_b).decimals()

        pot_station: address = ERC20D(station).pot_station()

        token_balance_a: uint256 = ERC20D(token_a).balanceOf(station)
        token_balance_b: uint256 = ERC20D(token_b).balanceOf(station)
        station_token_balance: uint256 = ERC20D(station).totalSupply()

        pot_station_swd_balance: uint256 = 0
        if pot_station != ZERO_ADDRESS:
            pot_station_swd_balance = ERC20D(SWD_TOKEN).balanceOf(pot_station)

        params: uint256 = ERC20D(station).pair_params()
        staked: uint256 = bitwise_and(params, 2 ** 2 - 1)

        station_type: uint256 = bitwise_and(
            shift(params, -4), 2 ** 2 - 1)
        locked: uint256 = bitwise_and(
            shift(params, -6), 2 ** 2 - 1)
        station_approved: uint256 = bitwise_and(
            shift(params, -8), 2 ** 2 - 1)

        token_fees_a: uint256 = bitwise_and(
            shift(params, -16), 2 ** 16 - 1)
        token_fees_b: uint256 = bitwise_and(
            shift(params, -32), 2 ** 16 - 1)
        station_fees: uint256 = bitwise_and(
            shift(params, -64), 2 ** 16 - 1)
        decimal_diff_a: uint256 = bitwise_and(
            shift(params, -128), 2 ** 64 - 1)
        decimal_diff_b: uint256 = shift(params, -192)

        return PairInfo({
            station: station, 
            token_a: token_a,
            token_b: token_b, 
            pot_station: pot_station,
            token_name_a: token_name_a, 
            token_symbol_a: token_symbol_a,
            token_name_b: token_name_b, 
            token_symbol_b: token_symbol_b,
            token_decimals_a: token_decimals_a, 
            token_decimals_b: token_decimals_b,
            token_balance_a: token_balance_a, 
            token_balance_b: token_balance_b,
            station_token_balance: station_token_balance, 
            pot_station_swd_balance: pot_station_swd_balance,
            params: params, 
            staked: staked, 
            station_type: station_type, 
            locked: locked, 
            station_approved: station_approved, 
            token_fees_a: token_fees_a, 
            token_fees_b: token_fees_b,
            station_fees: station_fees, 
            decimal_diff_a: decimal_diff_a, 
            decimal_diff_b: decimal_diff_b
        })
    else:
        return PairInfo({
            station: ZERO_ADDRESS, 
            token_a: ZERO_ADDRESS,
            token_b: ZERO_ADDRESS, 
            pot_station: ZERO_ADDRESS,
            token_name_a: "NONE", 
            token_symbol_a: "NONE",
            token_name_b: "NONE", 
            token_symbol_b: "NONE",
            token_decimals_a: empty(uint256), 
            token_decimals_b: empty(uint256),
            token_balance_a: empty(uint256), 
            token_balance_b: empty(uint256),
            station_token_balance: empty(uint256), 
            pot_station_swd_balance: empty(uint256),
            params: empty(uint256), 
            staked: empty(uint256), 
            station_type: empty(uint256), 
            locked: empty(uint256), 
            station_approved: empty(uint256), 
            token_fees_a: empty(uint256), 
            token_fees_b: empty(uint256),
            station_fees: empty(uint256), 
            decimal_diff_a: empty(uint256), 
            decimal_diff_b: empty(uint256)
        })


@external
@view
def get_data_block(_break: uint256, position: uint256) -> BlockInfo:
    idx: uint256 = 0
    pot_array: address[30] = empty(address[30])
    station_array: address[30] = empty(address[30])
    token_array_a: address[30] = empty(address[30])
    token_array_b: address[30] = empty(address[30])    

    pair_params_array: uint256[30] = empty(uint256[30])
    token_array_name_a: bytes32[30] = empty(bytes32[30])
    token_array_name_b: bytes32[30] = empty(bytes32[30])

    token_array_symbols: bytes32[30] = empty(bytes32[30])
    token_array_decimals_balances: uint256[30] = empty(uint256[30])
    station_pot_array_balances: uint256[30] = empty(uint256[30])
    
    START_RANGE: int128 = convert(position, int128)
    for i in range(START_RANGE, START_RANGE + MAX_STEPS):
        # add break
        if _break != 0:
            if idx == _break:
                break
        pair_id: uint256 = convert(i, uint256)
        token_pair: uint256 = self.exchange_info[pair_id]
        station: address = self.exchange_pairs_list[token_pair]
        if station != ZERO_ADDRESS:

            token_a: address = ERC20D(station).token_a()
            token_name_a: String[32] = ERC20D(token_a).name()
            token_symbol_a: String[32] = ERC20D(token_a).symbol()
            token_decimals_a: uint256 = ERC20D(token_a).decimals()

            token_b: address = ERC20D(station).token_b()
            token_name_b: String[32] = ERC20D(token_b).name()
            token_symbol_b: String[32] = ERC20D(token_b).symbol()
            token_decimals_b: uint256 = ERC20D(token_b).decimals()
            
            pot_station: address = ERC20D(station).pot_station()
            pair_params: uint256 = ERC20D(station).pair_params()

            token_balance_a: uint256 = ERC20D(token_a).balanceOf(station)
            token_balance_b: uint256 = ERC20D(token_b).balanceOf(station)
            station_token_balance: uint256 = ERC20D(station).totalSupply()

            pot_station_swd_balance: uint256 = 0
            if pot_station != ZERO_ADDRESS:
                pot_station_swd_balance = ERC20D(SWD_TOKEN).balanceOf(pot_station)

            get_token_name_bytes_a: Bytes[96] = _abi_encode(token_name_a)
            get_token_name_bytes_b: Bytes[96] = _abi_encode(token_name_b)
            # optimize symbols
            concat_symbols: String[65] = concat(token_symbol_a, "/", token_symbol_b)
            get_token_symbols_bytes: Bytes[160] = _abi_encode(concat_symbols)
            
            slice_name_bytes_a: bytes32 = extract32(slice(
                get_token_name_bytes_a, 64, 32), 0, output_type=bytes32)
            slice_name_bytes_b: bytes32 = extract32(slice(
                get_token_name_bytes_b, 64, 32), 0, output_type=bytes32)
            slice_symbols_bytes: bytes32 = extract32(slice(
                get_token_symbols_bytes, 64, 32), 0, output_type=bytes32)
            # optimize decimals, balances
            tokens_decimals_balances: uint256 = token_decimals_a \
                                    + shift(token_decimals_b, 6) \
                                    + shift(token_balance_a, 12) \
                                    + shift(token_balance_b, 124)
            station_pot_balances: uint256 = station_token_balance \
                                    + shift(pot_station_swd_balance, 128)

            station_array[idx] = station
            token_array_a[idx] = token_a
            token_array_b[idx] = token_b
            pot_array[idx] = pot_station
            pair_params_array[idx] = pair_params
            token_array_name_a[idx] = slice_name_bytes_a
            token_array_name_b[idx] = slice_name_bytes_b

            token_array_symbols[idx] = slice_symbols_bytes
            station_pot_array_balances[idx] = station_pot_balances
            token_array_decimals_balances[idx] = tokens_decimals_balances
            
        idx += 1
        
    return BlockInfo({
        station_array: station_array,
        pot_array: pot_array,
        token_array_a: token_array_a,
        token_array_b: token_array_b,
        token_array_name_a: token_array_name_a,
        token_array_name_b: token_array_name_b,
        token_array_symbols: token_array_symbols,
        pair_params_array: pair_params_array,
        token_array_decimals_balances: token_array_decimals_balances,
        station_pot_array_balances: station_pot_array_balances
    })


@external
def update_owner(new_owner: address):
    assert msg.sender == self.owner, "Owner only"
    assert self.owner_agree, "Owner not agree"
    assert self.guardian_agree, "Guardian not agree"
    self.owner = new_owner
    self.owner_agree = False
    self.guardian_agree = False
    log NewOwner(msg.sender, new_owner)


@external
def set_guardian(guardian: address):
    assert msg.sender == self.owner, "Owner only"
    assert not self.done, "Guardian already registred"
    assert guardian != ZERO_ADDRESS
    self.guardian_agree = False
    self.owner_agree = False
    self.guardian = guardian
    self.done = True
    log NewGuardian(guardian)


@external
def update_guardian():
    assert msg.sender == self.owner, "Owner only"
    assert self.done, "Guardian not registred"
    assert self.owner_agree, "Owner not agree"
    assert self.guardian_agree, "Guardian not agree"
    self.done = False


@external
def ask_guardian(agree: uint256):
    assert msg.sender == self.guardian, "Guardian only"
    assert self.owner_agree, "Owner not agree"
    assert agree <= 1, "1 Yes, 0 No"
    self.guardian_agree = convert(agree, bool)


@external
def ask_owner(agree: uint256):
    assert msg.sender == self.owner, "Owner only"
    assert agree <= 1, "1 Yes, 0 No"
    self.owner_agree = convert(agree, bool)