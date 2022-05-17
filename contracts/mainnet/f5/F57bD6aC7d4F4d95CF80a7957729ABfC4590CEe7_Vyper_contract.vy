# @version 0.3.3
# @License Copyright (c) Swap.Dance, 2022 - all rights reserved
# @Author Alexey K
# Swap.Dance Router and Basic Helper

from vyper.interfaces import ERC20

interface IWETH:
    def deposit(): payable

interface Exchange:
    def swap_tokens(
        amount_in: uint256,
        amount_out_min: uint256,
        token_in: address,
        expiry: uint256
    ) -> Swapped: nonpayable

interface ERC20D:
    def kLast() -> decimal: view
    def token_a() -> address: view
    def token_b() -> address: view
    def decimals() -> uint256: view
    def pair_params() -> uint256: view
    def totalSupply() -> uint256: view
    def balanceOf(station: address) -> uint256: view

struct Swapped:
    amount_out: uint256
    token_out: address

struct AmountsOut:
    station_array: address[10]
    tokens_in_array: address[10]
    amount_in_array: uint256[10]
    amount_out_array: uint256[10]

struct AddLiquidity:
    amount_a: uint256
    amount_b: uint256
    liquidity: uint256
    super_pool_liquidity: uint256

struct RemoveLiquidity:
    amount_out_a: uint256
    amount_out_b: uint256
    super_pool_liquidity: uint256

event ReceiveEth:
    amount: uint256
    sender: indexed(address)

# Constants
WETH: immutable(address)
OWNER: immutable(address)
A: constant(decimal) = 51922968585348.28
DENOMINATOR: constant(decimal) = 10000.0
MINIMUM_LIQUIDITY: constant(decimal) = 0.000000001
DECIMAL18: constant(decimal) = 1000000000000000000.0


@external
def __init__(_weth: address):
    OWNER = msg.sender
    WETH = _weth


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
def send_token_approve(token_in: address, amount_in: uint256, station: address):
    approve_token_swap_response: Bytes[32] = raw_call(
        token_in,
        _abi_encode(
            station,
            amount_in,
            method_id=method_id("approve(address,uint256)")
        ),
        max_outsize=32,
    )
    if len(approve_token_swap_response) > 0:
        assert convert(approve_token_swap_response, bool), "Approve failed!"


@internal
@view
def get_price(
    station: address,
    token_in: address,
    amount_in: uint256, 
) -> uint256:

    token1: address = ERC20D(station).token_a()
    token2: address = ERC20D(station).token_b()
    params: uint256 = ERC20D(station).pair_params()

    token_fee: decimal = empty(decimal)
    staked: uint256 = bitwise_and(params, 2 ** 2 - 1)
    station_type: uint256 = bitwise_and(shift(params, -4), 2 ** 2 - 1)
    token_fees_a: uint256 = bitwise_and(shift(params, -16), 2 ** 16 - 1)
    token_fees_b: uint256 = bitwise_and(shift(params, -32), 2 ** 16 - 1)
    decimal_diff_a: uint256 = bitwise_and(shift(params, -128), 2 ** 64 - 1)
    decimal_diff_b: uint256 = shift(params, -192)

    balance_a: uint256 = ERC20(token1).balanceOf(station) * decimal_diff_a
    balance_b: uint256 = ERC20(token2).balanceOf(station) * decimal_diff_b

    X: decimal = empty(decimal)
    Y: decimal = empty(decimal)
    Z: decimal = empty(decimal)
    AMOUNT_OUT: decimal = empty(decimal)
    token_out_decimal: uint256 = empty(uint256)
    
    if token_in == token1:
        X = convert(balance_a, decimal) / DECIMAL18
        Y = convert(balance_b, decimal) / DECIMAL18
        Z = convert(amount_in * decimal_diff_a, decimal) / DECIMAL18
        token_fee = convert(token_fees_b, decimal)
        token_out_decimal = decimal_diff_b
    elif token_in == token2:
        X = convert(balance_b, decimal) / DECIMAL18
        Y = convert(balance_a, decimal) / DECIMAL18
        Z = convert(amount_in * decimal_diff_b, decimal) / DECIMAL18
        token_fee = convert(token_fees_a, decimal)
        token_out_decimal = decimal_diff_a
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

    return convert(AMOUNT_OUT * DECIMAL18, uint256) / token_out_decimal


@external
@view
def get_amount_out(
    station: address,
    token_in: address,
    amount_in: uint256, 
) -> uint256:
    return self.get_price(station, token_in, amount_in)
    

@external
@view
def get_amounts_out(
    stations: address[10],
    tokens_in: address[10],
    _amount_in: uint256, 
) -> AmountsOut:
    idx: uint256 = 0
    amount_in: uint256 = _amount_in
    station: address = empty(address)
    amount_out: uint256 = empty(uint256)
    token_in: address = empty(address)
    station_array: address[10] = empty(address[10])
    tokens_in_array: address[10] = empty(address[10])
    amount_in_array: uint256[10] = empty(uint256[10])
    amount_out_array: uint256[10] = empty(uint256[10]) 

    for i in range(10):
        station = stations[idx]
        token_in = tokens_in[idx]
        if station != ZERO_ADDRESS:
            amount_out = self.get_price(station, token_in, amount_in)
            station_array[idx] = station
            tokens_in_array[idx] = token_in
            amount_in_array[idx] = amount_in
            amount_out_array[idx] = amount_out
            amount_in = amount_out
        else:
            break

        idx += 1
        
    return AmountsOut({
        station_array: station_array,
        tokens_in_array: tokens_in_array,
        amount_in_array: amount_in_array,
        amount_out_array: amount_out_array
    })
    

@internal
@view
def super_pool_fees(
    kLast: decimal,
    reserves: decimal,
    decimal_total_sup: decimal,
    station_fees: uint256
) -> decimal:
    outdated: decimal = kLast
    D_T_S: decimal = decimal_total_sup
    station_reserve: decimal = reserves
    SUPERPOOL_LIQUIDITY: decimal = empty(decimal)
    if station_reserve > 0.0:
        station_reserve = sqrt(station_reserve)
        outdated = sqrt(outdated)
        if station_reserve > outdated:
            D1: decimal = D_T_S * (station_reserve - outdated)
            D2: decimal = station_reserve * (convert(station_fees, decimal) / DENOMINATOR) + outdated
            SUPERPOOL_LIQUIDITY = D1/D2
            SUPERPOOL_LIQUIDITY = SUPERPOOL_LIQUIDITY / 30.0

    if SUPERPOOL_LIQUIDITY > 0.0:
        return SUPERPOOL_LIQUIDITY
    else:
        return empty(decimal)

        
@external
@view
def calc_add_liquidity(
    station: address,
    token_amount_a: uint256,
    token_amount_b: uint256
) -> AddLiquidity:

    amount_a: uint256 = empty(uint256)
    amount_b: uint256 = empty(uint256)
    station_reserve: decimal = empty(decimal)
    token1: address = ERC20D(station).token_a()
    token2: address = ERC20D(station).token_b()
    params: uint256 = ERC20D(station).pair_params()
    
    station_type: uint256 = bitwise_and(shift(params, -4), 2 ** 2 - 1)
    station_fees: uint256 = bitwise_and(shift(params, -64), 2 ** 16 - 1)
    decimal_diff_a: uint256 = bitwise_and(shift(params, -128), 2 ** 64 - 1)
    decimal_diff_b: uint256 = shift(params, -192)

    token_balance_a: uint256 = ERC20(token1).balanceOf(station) * decimal_diff_a
    token_balance_b: uint256 = ERC20(token2).balanceOf(station) * decimal_diff_b

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
            else:
                d_X: decimal = (D_T_B * D_B_A) / D_B_B
                assert d_X <= D_T_A
                amount_a = convert(d_X * DECIMAL18, uint256) / decimal_diff_a
                amount_b = token_amount_b
    elif station_type == 0:
        assert token_amount_a > 0 and token_amount_b > 0, "Amount a/b = 0"
        assert token_amount_a * decimal_diff_a == token_amount_b * decimal_diff_b, "Amount a != b"
        amount_a = token_amount_a
        amount_b = token_amount_b

    liquidity: decimal = empty(decimal)
    total_pool_tokens: uint256 = ERC20D(station).totalSupply()
    N_T_A: decimal = convert(amount_a * decimal_diff_a, decimal) / DECIMAL18
    N_T_B: decimal = convert(amount_b * decimal_diff_b, decimal) / DECIMAL18
    D_T_S: decimal = convert(total_pool_tokens, decimal) / DECIMAL18
    
    outdated: decimal = ERC20D(station).kLast()
    SUPERPOOL_LIQUIDITY: decimal = empty(decimal)

    #calc potential super pool fee
    if station_type == 1: 
        station_reserve = D_B_A * D_B_B
    else:
        station_reserve = D_B_A + D_B_B

    SUPERPOOL_LIQUIDITY = self.super_pool_fees(outdated, station_reserve, D_T_S, station_fees)
    
    D_T_S = D_T_S + SUPERPOOL_LIQUIDITY
    # mint LP tokens
    if total_pool_tokens == 0:
        liquidity = sqrt(D_T_A * D_T_B) - MINIMUM_LIQUIDITY
    else:
        liquidity1: decimal = N_T_A * D_T_S / D_B_A
        liquidity2: decimal = N_T_B * D_T_S / D_B_B
        liquidity = min(liquidity1, liquidity2)

    return AddLiquidity({
        amount_a: amount_a,
        amount_b: amount_b,
        liquidity: convert(liquidity * DECIMAL18, uint256),
        super_pool_liquidity: convert(SUPERPOOL_LIQUIDITY * DECIMAL18, uint256)
    })
    

@external
@view
def calc_remove_liquidity(
    station: address,
    pool_token_amount: uint256,
) -> RemoveLiquidity:    
    station_reserve: decimal = empty(decimal)
    token1: address = ERC20D(station).token_a()
    token2: address = ERC20D(station).token_b()
    params: uint256 = ERC20D(station).pair_params()
    
    station_type: uint256 = bitwise_and(shift(params, -4), 2 ** 2 - 1)
    station_fees: uint256 = bitwise_and(shift(params, -64), 2 ** 16 - 1)
    decimal_diff_a: uint256 = bitwise_and(shift(params, -128), 2 ** 64 - 1)
    decimal_diff_b: uint256 = shift(params, -192)
    
    total_pool_tokens: uint256 = ERC20D(station).totalSupply()
    token_balance_a: uint256 = ERC20(token1).balanceOf(station) * decimal_diff_a
    token_balance_b: uint256 = ERC20(token2).balanceOf(station) * decimal_diff_b
    
    D_B_A: decimal = convert(token_balance_a, decimal) / DECIMAL18
    D_B_B: decimal = convert(token_balance_b, decimal) / DECIMAL18
    D_T_S: decimal = convert(total_pool_tokens, decimal) / DECIMAL18
    D_T_A: decimal = convert(pool_token_amount, decimal) / DECIMAL18

    outdated: decimal = ERC20D(station).kLast()
    SUPERPOOL_LIQUIDITY: decimal = empty(decimal)

    #calc potential super pool fee
    if station_type == 1: 
        station_reserve = D_B_A * D_B_B
    else:
        station_reserve = D_B_A + D_B_B

    SUPERPOOL_LIQUIDITY = self.super_pool_fees(outdated, station_reserve, D_T_S, station_fees)

    D_T_S = D_T_S + SUPERPOOL_LIQUIDITY
    d_X: decimal = (D_T_A * D_B_A) / D_T_S
    d_Y: decimal = (D_T_A * D_B_B) / D_T_S
    
    amount_out_a: uint256 = convert(d_X * DECIMAL18, uint256) / decimal_diff_a
    amount_out_b: uint256 = convert(d_Y * DECIMAL18, uint256) / decimal_diff_b
    super_pool_share: uint256 = convert(SUPERPOOL_LIQUIDITY * DECIMAL18, uint256)

    return RemoveLiquidity({
        amount_out_a: amount_out_a,
        amount_out_b: amount_out_b,
        super_pool_liquidity: super_pool_share
    })


@external
@nonreentrant("All money is a matter of belief")
@payable
def direct_routing(
    expiry: uint256,
    main_token_out: address,
    stations_path: address[10],
    tokens_in_path: address[10],
    amounts_in_path: uint256[10],  
    amounts_out_path: uint256[10],
):
    station: address = stations_path[0]
    token_in: address = tokens_in_path[0]
    amount_in: uint256 = amounts_in_path[0]
    amount_out: uint256 = amounts_out_path[0]

    response_token_out: address = empty(address)
    response_amount_out: uint256 = empty(uint256)
    assert station != ZERO_ADDRESS, "Station is Zero Address"
    
    if msg.value > 0:
        assert token_in == WETH
        assert msg.value == amount_in
        IWETH(WETH).deposit(value = msg.value)
    else:
        self.safe_transfer_in(token_in, amount_in, msg.sender)
    
    for i in range(0, 9):
        if i == 0:
            # approve
            self.send_token_approve(token_in, amount_in, station)
            # swap
            swap_data: Swapped = Exchange(station).swap_tokens(amount_in, amount_out, token_in, expiry)
            response_token_out = swap_data.token_out
            response_amount_out = swap_data.amount_out
            assert amount_out <= response_amount_out, "Path amount < Response Amount Out" 
        else:
            station = stations_path[i]
            token_in = tokens_in_path[i]
            amount_in = amounts_in_path[i]
            amount_out = amounts_out_path[i]
            
            if station == ZERO_ADDRESS:
                break

            if response_amount_out > amount_in:
                amount_in = response_amount_out
            
            assert token_in == response_token_out, "New Token In != Response Token Out"
            # approve
            self.send_token_approve(token_in, amount_in, station)
            # swap
            swap_data: Swapped = Exchange(station).swap_tokens(amount_in, amount_out, token_in, expiry)
            response_token_out = swap_data.token_out
            response_amount_out = swap_data.amount_out
            assert amount_out <= response_amount_out, "Path amount < Response Amount Out" 
    
    # Loop done
    if main_token_out == ZERO_ADDRESS:
        assert response_token_out == WETH, "Must be WETH"
        weth_withdraw_response: Bytes[32] = raw_call(
            WETH,
            _abi_encode(
                response_amount_out,
                method_id=method_id("withdraw(uint256)")
            ),
            max_outsize=32,
        )
        if len(weth_withdraw_response) > 0:
            assert convert(weth_withdraw_response, bool), "Withdraw ETH failed!"
        send(msg.sender, response_amount_out)
    else:
        assert response_token_out == main_token_out, "Main token != Response token out"
        response_out: Bytes[32] = raw_call(
            main_token_out,
            _abi_encode(
                msg.sender,
                response_amount_out,
                method_id=method_id("transfer(address,uint256)")
            ),
            max_outsize=32,
        )
        if len(response_out) > 0:
            assert convert(response_out, bool), "Transfer /swap out/ failed!"


@external
@payable
def __default__():
    log ReceiveEth(msg.value, msg.sender)