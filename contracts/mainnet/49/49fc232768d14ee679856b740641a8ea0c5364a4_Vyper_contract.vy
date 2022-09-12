# @version ^0.3.3

from vyper.interfaces import ERC20

interface IUniswapV2Router01:
    def factory() -> address: view
    def WETH() -> address: view

    def getAmountsOut(
        _amountIn: uint256,
        _path: DynArray[address, 1024]
    ) -> uint256[2]: view

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
approveInfinity: public(uint256)

struct HoneyResponse:
    buyResult :         uint256
    tokenBalance :      uint256
    sellResult :        uint256
    buyCost :           uint256
    sellCost :          uint256
    amounts :    uint256[2]

@external
def __init__():
    self.approveInfinity = 115792089237316195423570985008687907853269984665640564039457584007913129639935
    self.executor = msg.sender

@payable
@external
def honeyCheck(
    _targetTokenAddress : address,
    idexRouterAddres : address 
    )->HoneyResponse:

    buyPath : DynArray[address, 1024] = [IUniswapV2Router01(idexRouterAddres).WETH(), _targetTokenAddress]
    sellPath : DynArray[address, 1024] = [_targetTokenAddress, IUniswapV2Router01(idexRouterAddres).WETH()]

    amounts : uint256[2] = IUniswapV2Router01(idexRouterAddres).getAmountsOut(msg.value, buyPath)
    # expectedAmount : uint256 = amounts[1]

    IWETH(IUniswapV2Router01(idexRouterAddres).WETH()).deposit(value=msg.value) 

    ERC20(IUniswapV2Router01(idexRouterAddres).WETH()).approve(idexRouterAddres, self.approveInfinity)

    wCoinBalance : uint256 = ERC20(IUniswapV2Router01(idexRouterAddres).WETH()).balanceOf(self)

    startBuyGas : uint256 = msg.gas

    IUniswapV2Router01(idexRouterAddres).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            wCoinBalance,
            1,
            buyPath,
            self,
            block.timestamp + 10
        )
    
    buyResult : uint256 = ERC20(_targetTokenAddress).balanceOf(self)
    finishBuyGas : uint256 = msg.gas

    ERC20(_targetTokenAddress).approve(idexRouterAddres, self.approveInfinity)

    startSellGas : uint256 = msg.gas

    IUniswapV2Router01(idexRouterAddres).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            buyResult,
            1,
            sellPath,
            self,
            block.timestamp + 10
        )
    
    finishSellGas : uint256 = msg.gas

    sellResult : uint256 = ERC20(IUniswapV2Router01(idexRouterAddres).WETH()).balanceOf(self)
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