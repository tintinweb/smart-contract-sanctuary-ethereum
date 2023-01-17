# @version ^0.3.7

"""
@title ERC-20 Wrapper for ERC-721 Token
@notice Based on the ERC-20 token standard as defined at
        https://eips.ethereum.org/EIPS/eip-20

         :=+******++=-:                 
      -+*+======------=+++=:            
     #+========------------=++=.        
    #+=======------------------++:      
   *+=======--------------------:++     
  =*=======------------------------*.   
 .%========-------------------------*.  
 %+=======-------------------------:-#  
+*========--------------------------:#  
%=========--------------------------:#. 
%=========--------------------+**=--:++ 
#+========-----=*#%#=--------#@@@@+-::*:
:%[email protected]@@@%[email protected]@@@#-::+=
 -#[email protected]@@%=----=*=--+**=-::#:
  :#[email protected]%=------::% 
    #[email protected]%=------:=+
    .%[email protected]%------::#
     #[email protected]%-------+
     %===------------*%%%%%%%%@@#-----#.
     %====-----------============----#: 
     *+==#+----------+##%%%%%%%%@--=*.  
     -#==+%=---------=+=========--*=    
      +===+%+--------------------*-     
       =====*#=------------------#      
       .======*#*=------------=*+.      
         -======+*#*+--------*+         
          .-========+***+++=-.          
             .-=======:           

"""

from vyper.interfaces import ERC20
from vyper.interfaces import ERC721

implements: ERC20


event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
totalSupply: public(uint256)

balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]

NFT: immutable(ERC721)
MAX_SUPPLY: constant(uint256) = 6000

owned_tokens: public(HashMap[uint256, uint256])  # internal id => ERC721 id
current_counter: public(uint256)


@external
def __init__(name: String[64], symbol: String[32], nft_addr: address):
    self.name = name
    self.symbol = symbol
    self.decimals = 18
    self.totalSupply = 0
    NFT = ERC721(nft_addr)


@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @notice Getter to check the current balance of an address
    @param _owner Address to query the balance of
    @return Token balance
    """
    return self.balances[_owner]


@view
@external
def allowance(_owner: address, _spender: address) -> uint256:
    """
    @notice Getter to check the amount of tokens that an owner allowed to a spender
    @param _owner The address which owns the funds
    @param _spender The address which will spend the funds
    @return The amount of tokens still available for the spender
    """
    return self.allowances[_owner][_spender]


@external
def approve(_spender: address, _value: uint256) -> bool:
    """
    @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
    @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    @return Success boolean
    """
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    """
    @dev Internal shared logic for transfer and transferFrom
    """
    assert self.balances[_from] >= _value, "Insufficient balance"
    self.balances[_from] -= _value
    self.balances[_to] += _value


    log Transfer(_from, _to, _value)


@external
def transfer(_to: address, _value: uint256) -> bool:
    """
    @notice Transfer tokens to a specified address
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param _to The address to transfer to
    @param _value The amount to be transferred
    @return Success boolean
    """
    self._transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    """
    @notice Transfer tokens from one address to another
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param _from The address which you want to send tokens from
    @param _to The address which you want to transfer to
    @param _value The amount of tokens to be transferred
    @return Success boolean
    """
    assert self.allowances[_from][msg.sender] >= _value, "Insufficient allowance"
    self.allowances[_from][msg.sender] -= _value
    self._transfer(_from, _to, _value)
    return True


@external
def wrap(ids: DynArray[uint256, 100]):
    assert NFT.isApprovedForAll(msg.sender, self), "No Approval"

    _counter: uint256 = self.current_counter
    for _token_id in ids:
        assert NFT.ownerOf(_token_id) == msg.sender, "Non-Owner"
        NFT.transferFrom(msg.sender, self, _token_id)
        self.owned_tokens[_counter] = _token_id
        _counter += 1

    self.balances[msg.sender] += len(ids) * 10**self.decimals
    self.current_counter += len(ids)

@internal
def _unwrap_one(target: address):
    assert self.balances[msg.sender] >= 10 ** self.decimals, "Insufficient balance"
    assert self.current_counter > 0, "Supply drained"

    self.current_counter -= 1   
    NFT.transferFrom(self, target, self.owned_tokens[self.current_counter])
    self.balances[target] -= 10**self.decimals
    self.owned_tokens[self.current_counter] = 0

@external
def unwrap(qty: uint256):
    """
    @notice Convert wrapped NFTs into NFT
    @dev Must have 10 ** 18 tokens per NFT
    @param qty Number of NFTs to unwrap
    """
    assert self.balances[msg.sender] >= 10 ** self.decimals * qty, "Insufficient balance"
    
    for i in range(MAX_SUPPLY):
        if i >= qty:
            break

        self._unwrap_one(msg.sender)