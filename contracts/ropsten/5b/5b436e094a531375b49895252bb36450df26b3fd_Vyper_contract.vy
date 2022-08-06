# @version 0.3.3

from vyper.interfaces import ERC20

currentNumber: public(uint256)

@external
def setNumberFromMaxSupplyOfToken(_tokenAddress: address):
    token: ERC20 = ERC20(_tokenAddress)
    self.currentNumber = token.totalSupply()

@external
def setNumber(_number: uint256):
    self.currentNumber = _number