# @version 0.3.7

"""
@title TEST
@license GNU AGPLv3
"""

interface ERC20:
    def totalSupply() -> uint256: view
    def balanceOf(_account: address) -> uint256: view
    def transfer(recipient: address, amount: uint256) -> bool: nonpayable
    def allowance(owner: address, spender: address) -> uint256: view
    def approve(spender: address, amount: uint256) -> bool: nonpayable
    def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: nonpayable

event Transfer:
    sender: indexed(address)
    recipient: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

interface IDexFactory:
    def createPair(tokenA: address, tokenB: address) -> address: nonpayable

interface IDexRouter:
    def factory() -> address: view
    def WETH() -> address: view

    def addLiquidityETH(
        token: address,
        amountTokenDesired: uint256,
        amountTokenMin: uint256,
        amountETHMin: uint256,
        to: address,
        deadline: uint256
    ) -> (uint256, uint256, uint256): payable

    def swapExactTokensForETHSupportingFeeOnTransferTokens(
        amountIn: uint256,
        amountOutMin: uint256,
        path: address[2],
        to: address,
        deadline: uint256
    ): nonpayable