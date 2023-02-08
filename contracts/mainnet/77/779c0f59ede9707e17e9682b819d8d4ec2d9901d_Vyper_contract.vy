# @version ^0.3

from vyper.interfaces import ERC20


OWNER_ADDR: immutable(address)
WETH_ADDR: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
V3_FACTORY: constant(address) = 0x1F98431c8aD98523631AE4a59f267346ea31F984

MAX_PAYLOADS: constant(uint256) = 16
MAX_PAYLOAD_BYTES: constant(uint256) = 1024


struct payload:
    target: address
    calldata: Bytes[MAX_PAYLOAD_BYTES]
    value: uint256


@external
@payable
def __init__():
    OWNER_ADDR = msg.sender
    
    # wrap initial Ether to WETH
    if msg.value > 0:
        raw_call(
            WETH_ADDR,
            method_id('deposit()'),
            value=msg.value
        )


@external
@payable
def execute_payloads(
    payloads: DynArray[payload, MAX_PAYLOADS],
    start_token_address: address
    ):
    
    assert msg.sender == OWNER_ADDR, "ERR_OWNER"

    start_token: ERC20 = ERC20(start_token_address)
    start_amount: uint256 = start_token.balanceOf(self)
   
    for _payload in payloads:
        raw_call(
            _payload.target,
            _payload.calldata,
            value=_payload.value,
        )

    assert start_token.balanceOf(self) >= start_amount, "ERR_BALANCE"


@internal
@pure
def verifyCallback(
    tokenA: address, 
    tokenB: address, 
    fee: uint24
) -> address:   
            
    token0: address = tokenA
    token1: address = tokenB

    if convert(tokenA,uint160) > convert(tokenB,uint160):        
        token0 = tokenB
        token1 = tokenA
        
    return convert(
        slice(
            convert(
                convert(
                    keccak256(
                        concat(
                            b'\xFF',
                            convert(V3_FACTORY,bytes20),
                            keccak256(
                                _abi_encode(
                                    token0,
                                    token1,
                                    fee
                                )
                            ),
                            0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54,
                        )
                    ),
                    uint256
                ),
                bytes32
            ),
            12,
            20,
        ),
        address
    )


@external
@payable
def uniswapV3SwapCallback(
    amount0: int256, 
    amount1: int256, 
    data: Bytes[32]
):

    # get the token0/token1 addresses and fee reported by msg.sender
    token0: address = extract32(
        raw_call(
            msg.sender,
            method_id('token0()'),
            max_outsize=32,
        ),
        0,
        output_type=address
    )

    token1: address = extract32(
        raw_call(
            msg.sender,
            method_id('token1()'),
            max_outsize=32,
        ),
        0,
        output_type=address
    )

    fee: uint24 = extract32(
        raw_call(
            msg.sender,
            method_id('fee()'),
            max_outsize=32,
        ),
        0,
        output_type=uint24
    )
    
    assert msg.sender == self.verifyCallback(token0,token1,fee), "!V3LP"

    # transfer token back to pool
    if amount0 > 0:
        raw_call(
            token0,
            _abi_encode(
                msg.sender,
                amount0,
                method_id=method_id('transfer(address,uint256)')
            )
        )
    elif amount1 > 0:
        raw_call(
            token1,
            _abi_encode(
                msg.sender,
                amount1,
                method_id=method_id('transfer(address,uint256)')
            )
        )


@external
@payable
def __default__():
    # accept basic Ether transfers to the contract with no calldata
    if len(msg.data) == 0:
        return
    
    # revert on all other calls
    else:
        raise