# @version ^0.3.0

# @dev Implementation of urtoken.org urtoken contract.
# Contract allows only transfer by owner; and mint, burn by controller contract
# @author Robert Mutua (https://github.com/freelancer254)
# https://github.com/freelancer254/

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

name: public(String[64]) #must follow the ERC20 name but with prefix ur e.g urUSD COIN
symbol: public(String[32]) #urUSDC
decimals: public(uint256) #same as the mirrored erc20

# NOTE: By declaring `balanceOf` as public, vyper automatically generates a 'balanceOf()' getter
#       method to allow access to account balances.

balanceOf: public(HashMap[address, uint256])

# By declaring `totalSupply` as public, we automatically create the `totalSupply()` getter
totalSupply: public(uint256)
controllerContract: public(address) #the contract address which will facilitate mint & burns

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _controllerContract: address):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.controllerContract = _controllerContract

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    assert _to != empty(address), "Invalid Address - No Direct Burns"
    assert _to.is_contract == False, "Cannot Send to Contract"
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    #only controllerContract allowed
    assert msg.sender == self.controllerContract, "Not Authorised"
    assert _to != empty(address)
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(empty(address), _to, _value)

@external
def burnFrom(_from: address, _value: uint256) -> bool:
    """
    @dev Burn an amount of the token from a given account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    #only controllercontract allowed
    assert msg.sender == self.controllerContract, "Not Authorised"
    assert _from != empty(address)
    self.totalSupply -= _value
    self.balanceOf[_from] -= _value
    log Transfer(_from, empty(address), _value)
    return True