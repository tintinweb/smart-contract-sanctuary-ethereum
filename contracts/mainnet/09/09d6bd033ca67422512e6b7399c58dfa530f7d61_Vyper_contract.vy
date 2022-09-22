#@version ^0.3.3

# @dev Implementation of urtoken.org controller contract.
# Contract handles conversion of erc20 to urtoken and vice versa
# @author Robert Mutua (https://github.com/freelancer254)
# https://github.com/freelancer254/

#events
event Deposit:
    erc20: indexed(address)
    urltoken: indexed(address)
    value: uint256


event Withdraw:
    erc20: indexed(address)
    urltoken: indexed(address)
    value: uint256


#ERC20 Interface to interact with ERC20 contracts
interface IERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def mint(_to: address, _value: uint256): nonpayable
    def transferFrom(_from: address, _to:address, _value: uint256) -> bool: nonpayable
    def burnFrom(_from: address, _value: uint256) -> bool: nonpayable
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_owner: address) -> uint256: view
    def allowance(_owner: address, _spender: address) -> uint256: view

supportedContracts: public(HashMap[address, address])
admin: public(address)

#constructor
@nonpayable
@external
def __init__():
    self.admin = msg.sender

@nonpayable
@external
def addSupportedContracts(erc20:DynArray[address, 10] , urtoken: DynArray[address, 10]) -> bool:
    #only admin allowed
    assert msg.sender == self.admin, "Not Authorised"
    #check lists are same length
    assert len(erc20) == len(urtoken), "List must be same size"
    #to keep track of index
    #vyper doesn't support index(list)
    i: int8 = convert(-1, int8) #assigned -1 to be incremented to 0,1,2,3 etc
    for _address in erc20:
        #increment i
        i += convert(1, int8)
        #add only when not set
        #prevents changing of urtoken contract in the future
        if self.supportedContracts[_address] == empty(address):
            self.supportedContracts[_address] = urtoken[i]
    return True

#the default function, similar to fallback fxn in solidity
#called when value is sent directly to the smart contract
@payable
@external
def __default__():
    pass

@nonpayable
@external
def deposit(erc20: address, _value: uint256) -> bool:
    assert self.supportedContracts[erc20] != empty(address), "Not Supported"
    #check value > 0
    assert _value > convert(0, uint256), "Invalid Amount"
    #transferFrom msg.sender
    IERC20(erc20).transferFrom(msg.sender, self, _value)
    #mint urtoken for msg.sender
    IERC20(self.supportedContracts[erc20]).mint(msg.sender, _value)
    #emit deposit event
    log Deposit(erc20, self.supportedContracts[erc20], _value)
    return True

@nonpayable
@external
def withdraw(erc20: address, _value: uint256) -> bool:
    assert self.supportedContracts[erc20] != empty(address), "Not Supported"
    #check _value > 0
    assert _value > convert(0, uint256), "Invalid Amount"
    #burn urtoken
    IERC20(self.supportedContracts[erc20]).burnFrom(msg.sender, _value)
    #send erc20
    IERC20(erc20).transfer(msg.sender, _value)
    #emit withdraw event
    log Withdraw(erc20, self.supportedContracts[erc20], _value)
    return True