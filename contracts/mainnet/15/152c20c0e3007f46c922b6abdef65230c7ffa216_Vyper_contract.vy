# @version ^0.3.3

from vyper.interfaces import ERC20

interface IUniswapV2Router01:
    def factory() -> address: view

    def getAmountsOut(
        _amountIn: uint256,
        _path: DynArray[address, 1024]
    ) -> DynArray[uint256, 1024]: view

    def swapExactTokensForTokensSupportingFeeOnTransferTokens(
        _amountIn: uint256,
        _amountOutMin: uint256,
        _path:DynArray[address, 1024],
        _to: address,
        _deadline: uint256
    ): nonpayable

interface IWETH:
    def deposit(): payable
    def transfer(
        _to: address, 
        _value: uint256
    ) -> bool: nonpayable
    def withdraw(_value: uint256): nonpayable


executor: public(address)
WCOIN: public(address)
approveInfinity: public(uint256)

struct HoneyResponse:
    buyResult :         uint256
    tokenBalance :      uint256
    sellResult :        uint256
    buyCost :           uint256
    sellCost :          uint256
    amounts :    DynArray[uint256, 1024]

@external
def __init__():
    self.approveInfinity = 115792089237316195423570985008687907853269984665640564039457584007913129639935
    self.executor = msg.sender
    self.WCOIN=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2


@payable
@external
def honeyCheck(
    _buyToken: address,
    _targetTokenAddress : address,
    idexRouterAddress : address,
    )->HoneyResponse:

    buyPath : DynArray[address, 1024] = []
    sellPath : DynArray[address, 1024] = []
    amounts : DynArray[uint256, 1024] = []



    if _buyToken == self.WCOIN:
        buyPath = [self.WCOIN, _targetTokenAddress]
        sellPath = [_targetTokenAddress, self.WCOIN]

    else:
        buyPath = [self.WCOIN,_buyToken,  _targetTokenAddress]
        sellPath = [_targetTokenAddress, _buyToken, self.WCOIN]

    amounts  = IUniswapV2Router01(idexRouterAddress).getAmountsOut(msg.value, buyPath)
    IWETH(self.WCOIN).deposit(value=msg.value) 
    ERC20(self.WCOIN).approve(idexRouterAddress, self.approveInfinity)

    wCoinBalance : uint256 = ERC20(self.WCOIN).balanceOf(self)
    startBuyGas : uint256 = msg.gas
    one : uint256 = 1
    raw_call(
        idexRouterAddress,
        _abi_encode(            
            wCoinBalance,
            one,
            buyPath,
            self,
            block.timestamp + 10, 
            method_id=method_id("swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)")
        ),
        max_outsize=0,
        revert_on_failure=True
    )

    
    buyResult : uint256 = ERC20(_targetTokenAddress).balanceOf(self)
    finishBuyGas : uint256 = msg.gas

    ERC20(_targetTokenAddress).approve(idexRouterAddress, self.approveInfinity)

    startSellGas : uint256 = msg.gas

    raw_call(
        idexRouterAddress,
        _abi_encode(            
            buyResult,
            one,
            sellPath,
            self,
            block.timestamp + 10,
            method_id=method_id("swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)")
        ),
        max_outsize=0,
        revert_on_failure=True
    )
    
    finishSellGas : uint256 = msg.gas

    sellResult : uint256 = ERC20(self.WCOIN).balanceOf(self)
    tokenBalance : uint256 = ERC20(_targetTokenAddress).balanceOf(self)

    response: HoneyResponse = HoneyResponse({
        buyResult: buyResult,
        tokenBalance: tokenBalance,
        sellResult: sellResult,
        buyCost: startBuyGas - finishBuyGas,
        sellCost: startSellGas - finishSellGas,
        amounts: amounts
    })

    
    return response


@external
def recoverTokens(_token: address, _amount: uint256, _to: address):
    assert self.executor == msg.sender,"!EXECUTOR"
    sent: bool = ERC20(_token).transfer(_to, _amount)
    assert sent, "!TRANSFER"

@external
def recoverETH(_amount: uint256, _to: address):
    assert self.executor == msg.sender,"!EXECUTOR"
    send(_to, _amount)