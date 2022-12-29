# @version >=0.3.4

OWNER_ADDR: immutable(address)
WETH_ADDR: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
FACTORY_ADDRESSES: HashMap[address, bool]

MAX_PAYLOADS: constant(uint256) = 16
MAX_PAYLOAD_BYTES: constant(uint256) = 1024

# ABI encoded length for MAX_PAYLOADS with MAX_PAYLOAD_BYTES calldata
ENC_PAYLOAD_LEN: constant(uint256) = 19008

# Encoded calldata length needed to pass full length payloads into a uniswapV2 callback.
UNIV2_CALLBACK_LEN: constant(uint256) = ENC_PAYLOAD_LEN + 32*5
# length calculation:
# 32 bytes: address
# 32 bytes: uint256
# 32 bytes: uint256
# 32 bytes: marker for calldata
# 32 bytes: offset for calldata
# 19008 bytes: values for encoded calldata
# total = 19168 bytes

struct payload:
    target: address
    calldata: Bytes[MAX_PAYLOAD_BYTES]
    value: uint256

@external
@payable
def __init__():
    OWNER_ADDR = msg.sender
    
    # add UniswapV2 and Sushiswap factory addresses to approved mapping
    self.FACTORY_ADDRESSES[
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        ] = True
    self.FACTORY_ADDRESSES[
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
        ] = True
    
    # wrap initial Ether to WETH
    if msg.value > 0:
        raw_call(
            WETH_ADDR,
            method_id('deposit()'),
            value=msg.value
        )


@external
@payable
def __default__():
    # accept basic Ether transfers to the contract with no calldata
    if len(msg.data) == 0:
        return
    # uniswapV2 callback logic
    elif slice(msg.data, 0, 4) == method_id(
        'uniswapV2Call(address,uint256,uint256,bytes)'
    ):

        # msg_sender can be faked by calldata, so check that msg.sender is a known pair registered at a known factory address
        lp_factory: address = extract32(
            raw_call(
                msg.sender,
                method_id('factory()'),
                max_outsize=32,
            ),
            0,
            output_type=address
        )

        assert self.FACTORY_ADDRESSES[lp_factory] == True, "UNAPPROVED FACTORY"     

        token0_addr: address = extract32(
            raw_call(
                msg.sender,
                method_id('token0()'),
                max_outsize=32
            ),
            0,
            output_type=address
        )

        token1_addr: address = extract32(
            raw_call(
                msg.sender,
                method_id('token1()'),
                max_outsize=32
            ),
            0,
            output_type=address
        )

        lp_addr: address = extract32(
            raw_call(
                lp_factory,
                _abi_encode(
                    token0_addr,
                    token1_addr,
                    method_id=method_id(
                        'getPair(address,address)'
                    )
                ),                
                max_outsize=32
            ),
            0,
            output_type=address
        )
        
        assert msg.sender == lp_addr, "UNREGISTERED LP"
        # pad with empty 32 byte chunks to fill the maximum calldata size, 
        # otherwise slice() will error if called past the boundary
        calldata: Bytes[UNIV2_CALLBACK_LEN] = concat(            
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),empty(bytes32),
            empty(bytes32),empty(bytes32),
        )
        
        padding_end: uint256 = 0

        # process the calldata in 32-byte increments
        for i in range(UNIV2_CALLBACK_LEN/32):
            if 4 + 32*i >= len(msg.data):
                # if we've reached the end of the calldata, mark the end of the padding for trimming
                padding_end = UNIV2_CALLBACK_LEN - 32*i
                break            
            else:
                # otherwise trim 32 bytes of padding from the start and append the next 32 byte chunk from msg.data
                calldata = concat(
                    slice(calldata, 32, UNIV2_CALLBACK_LEN - 32),
                    slice(msg.data, 4 + 32*i, 32),
                )

        # trim all padding by slicing from the end of the zero padding (the start of real data)
        calldata = slice(calldata, padding_end, UNIV2_CALLBACK_LEN - padding_end)

        msg_sender: address = empty(address)
        amount0Out: uint256 = 0
        amount1Out: uint256 = 0
        payload_bytes: Bytes[ENC_PAYLOAD_LEN] = b''

        # decode the calldata into the 3 arguments to swap() and the *encoded* payload in bytes
        msg_sender, amount0Out, amount1Out, payload_bytes = _abi_decode(
            calldata,
            (
                address,
                uint256,
                uint256,
                Bytes[ENC_PAYLOAD_LEN],
            )
        )
        
        assert msg_sender == self, "!OWNER calldata"

        self.deliver_payloads(
            _abi_decode(
                payload_bytes,
                DynArray[payload, MAX_PAYLOADS]
            )
        )
    # revert on all other calls
    else:
        raise

@external
@nonpayable
def set_factory_flag(
    factory: address,
    flag: bool
):
    assert msg.sender == OWNER_ADDR, "!OWNER"
    self.FACTORY_ADDRESSES[factory] = flag


@internal
@payable
def deliver_payloads(
    payloads: DynArray[payload, MAX_PAYLOADS],
    return_on_first_failure: bool = False,  # optional argument
    execute_all_payloads: bool = False,  # optional argument    
):
    if return_on_first_failure:
        assert not execute_all_payloads, "CONFLICTING REVERT OPTIONS"
    if execute_all_payloads:
        assert not return_on_first_failure, "CONFLICTING REVERT OPTIONS"
   
    total_value: uint256 = 0
    for _payload in payloads:
        total_value += _payload.value
    assert total_value <= msg.value + self.balance, "INSUFFICIENT VALUE"
    
    if not execute_all_payloads and not return_on_first_failure:
        # default behavior, reverts on any payload failure
        for _payload in payloads:
            raw_call(
                _payload.target,
                _payload.calldata,
                value=_payload.value,
            )
    elif return_on_first_failure:
        # custom behavior, will execute payloads until the first failed call 
        # and break the loop without reverting the previous successful transfers
        for _payload in payloads:
            success: bool = raw_call(
                _payload.target,
                _payload.calldata,
                value=_payload.value,          
                revert_on_failure=False
            )
            if not success:
                break   
    elif execute_all_payloads:
        # custom behavior, will execute all payloads regardless of success
        for _payload in payloads:
            success: bool = raw_call(
                _payload.target,
                _payload.calldata,
                value=_payload.value,
                revert_on_failure=False
            )

@internal
@nonpayable
def pay_bribe(
    amount: uint256,
):
    if self.balance >= amount:
        send(block.coinbase, amount)
    else:        
        weth_balance: uint256 = extract32(
            raw_call(
                WETH_ADDR,
                _abi_encode(
                    self,
                    method_id = method_id('balanceOf(address)')
                ),
                max_outsize=32
            ),
            0,
            output_type=uint256
        )
        assert amount <= self.balance + weth_balance, "BRIBE EXCEEDS BALANCE"

        raw_call(
            WETH_ADDR,
            _abi_encode(
                amount - self.balance, 
                method_id = method_id('withdraw(uint256)')
            ),
        )

        send(block.coinbase, amount)


@external
@nonpayable
def execute_packed_payload(
    _target: address,
    _payload: Bytes[ENC_PAYLOAD_LEN],
    bribe_amount: uint256,
):
    assert msg.sender == OWNER_ADDR, "!OWNER"

    raw_call(
        _target,
        _payload,
    )

    # transfer the bribe
    if bribe_amount > 0:
        self.pay_bribe(bribe_amount)    

@external
@payable
def execute_payloads(
    payloads: DynArray[payload, MAX_PAYLOADS],
    bribe_amount: uint256,
    return_on_first_failure: bool = False,  # optional argument
    execute_all_payloads: bool = False,  # optional argument    
):
    assert msg.sender == OWNER_ADDR, "!OWNER"

    self.deliver_payloads(
        payloads,
        return_on_first_failure,
        execute_all_payloads
    )

    # transfer the bribe
    if bribe_amount > 0:
        self.pay_bribe(bribe_amount)