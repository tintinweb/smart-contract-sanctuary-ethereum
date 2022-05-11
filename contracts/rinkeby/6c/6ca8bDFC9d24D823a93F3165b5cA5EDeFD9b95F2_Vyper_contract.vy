# @version ^0.2

from vyper.interfaces import ERC20

interface UniswapV2Router02:
    def factory() -> address: nonpayable
    def addLiquidityETH(
        token: address,
        amountTokenDesired: uint256,
        amountTokenMin: uint256,
        amountETHMin: uint256,
        to: address,
        deadline: uint256
    ) -> uint256[3]: nonpayable

WETHAddress: address
Factory: address

UNISWAP: constant(address) = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
SUSD: constant(address) = 0x970C963166351B901c642B8CB49920536C3127e6
WETH: constant(address) = 0xc778417E063141139Fce010982780140Aa0cD5Ab

@external
def __init__():
    self.Factory = UniswapV2Router02(UNISWAP).factory()
    
@external
@view
def getFactoryAddress() -> address:
    return self.Factory

@external
@payable
def addLP(amountTokenDes: uint256) -> bool:
    ERC20(SUSD).transferFrom(msg.sender, self, amountTokenDes)
    ERC20(SUSD).approve(UNISWAP, amountTokenDes)
    
    res: Bytes[128] = raw_call(
        UNISWAP,
        concat(
            method_id("addLiquidityETH(address,uint256,uint256,uint256,address,uint256)"),
            convert(SUSD, bytes32),
            convert(amountTokenDes, bytes32),
            convert(amountTokenDes * 995 / 1000, bytes32),
            convert(msg.value * 995 / 1000, bytes32),
            convert(self, bytes32),
            convert(block.timestamp, bytes32),
        ),
        max_outsize=128,
    )
    return True