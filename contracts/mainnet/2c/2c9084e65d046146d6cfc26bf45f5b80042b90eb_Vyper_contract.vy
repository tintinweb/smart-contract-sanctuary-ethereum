# @version 0.3.7

"""
@title Current Thing ERC-20 Token ($THING)
@author npcers.eth
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

# Contract Specific Addresses
npc: public(address)
owner: public(address)
minter: public(address)

# Epoch
current_epoch: public(uint256)
current_thing_archive: public(HashMap[uint256, String[256]])


@external
def __init__():
    self.name = "Current Thing"
    self.symbol = "THING"
    self.decimals = 18
    self.owner = msg.sender
    self.minter = msg.sender
    self.current_epoch = 0
    self.current_thing_archive[0] = "Genesis Thing"


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
    @dev Beware that changing an allowance with this method brings the risk that someone may use both the old and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
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
    assert _to != empty(address)
    self.balances[_from] -= _value
    self.balances[_to] += _value
    log Transfer(_from, _to, _value)


@external
def transfer(_to: address, _value: uint256) -> bool:
    """
    @notice Transfer tokens to a specified address
    @dev Vyper does not allow underflows, so attempting to transfer more tokens than an account has will revert
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
    @dev Vyper does not allow underflows, so attempting to transfer more tokens than an account has will revert
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
@view
def current_thing() -> String[256]:
    """
    @notice The Current Thing
    @return What NPCs support
    """
    return self.current_thing_archive[self.current_epoch]


@external
def new_current_thing(current_thing: String[256]):
    """
    @notice Store a new current thing
    @dev Only admin or authorized minter, updates a new epoch
    @param current_thing The new current thing
    """
    assert msg.sender in [self.owner, self.minter]
    self.current_epoch += 1
    self.current_thing_archive[self.current_epoch] = current_thing


@internal
def _mint(addr: address, amount: uint256):
    self.balances[addr] += amount
    self.totalSupply += amount


@external
def mint(recipient: address, amount: uint256):
    """
    @notice Mint tokens
    @param recipient Receiver of tokens
    @param amount Quantity to mint
    @dev Only owner or minter
    """

    assert msg.sender in [self.owner, self.minter]
    self._mint(recipient, amount)


@external
def admin_set_owner(new_owner: address):
    """
    @notice Update owner of contract
    @param new_owner New contract owner address
    """
    assert msg.sender == self.owner  # dev: "Admin Only"
    self.owner = new_owner


@external
def admin_set_minter(new_minter: address):
    """
    @notice Update authorized minter address
    @param new_minter New contract owner address
    """
    assert msg.sender == self.owner  # dev: "Admin Only"
    self.minter = new_minter


@external
def admin_set_npc_addr(addr: address):
    """
    @notice Update Address for NPC NFT
    @param addr New address
    """

    assert msg.sender == self.owner
    self.npc = addr