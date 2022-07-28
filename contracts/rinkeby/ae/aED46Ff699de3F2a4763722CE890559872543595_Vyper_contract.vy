# @version 0.3.3

"""
@title Current Thing
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


interface NPC:
    def ownerOf(tokenId: uint256) -> address: view
 

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
totalSupply: public(uint256)

balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]

npc: public(NPC)
MAX_NFT_SUPPLY: constant(uint256) = 10000
owner: address

YEAR: constant(uint256) = 86400 * 365
EMISSION_RATE: constant(uint256) = 1_000_000 * 10 ** 18 / YEAR

merkle_depth: constant(uint256) = 10

# Epoch
current_epoch : public(uint256)
current_thing: public(HashMap[uint256, String[128]]) 
epoch_merkle_roots: public(HashMap[uint256, bytes32])  # Map epoch to Merkle Root
epoch_bonus_amounts: public(HashMap[uint256, uint256]) # Map epoch to bonus
epoch_bonus_claims: public(HashMap[uint256, HashMap[address, bool]])

@external
def __init__():
    self.name = "Current Thing"
    self.symbol = "THING"
    self.decimals = 18
    self.owner = msg.sender
    self.current_epoch = 0
    self.current_thing[0] = "First Current Thing"


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
def allowance(_owner : address, _spender : address) -> uint256:
    """
    @notice Getter to check the amount of tokens that an owner allowed to a spender
    @param _owner The address which owns the funds
    @param _spender The address which will spend the funds
    @return The amount of tokens still available for the spender
    """
    return self.allowances[_owner][_spender]


@external
def approve(_spender : address, _value : uint256) -> bool:
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
def transfer(_to : address, _value : uint256) -> bool:
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
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
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
def set_nft_addr(addr: address):
    assert msg.sender == self.owner
    self.npc = NPC(addr)


@external
def new_current_thing(current_thing: String[128], bonus_amount: uint256,  merkle_root: bytes32):
    assert msg.sender == self.owner
    self.epoch_merkle_roots[self.current_epoch] = merkle_root
    self.epoch_bonus_amounts[self.current_epoch] = bonus_amount
    self.current_epoch += 1
    self.current_thing[self.current_epoch] = current_thing


@internal
def _mint(addr: address, amount: uint256):
    self.balances[addr] += amount
    self.totalSupply += amount
   

@external
def test_mint(addr: address, amount: uint256):
    self._mint(addr, amount)

@external
def claim_bonus(epoch: uint256, _leaf: bytes32, _index: uint256, _proof: bytes32[merkle_depth]):
    #assert self._calc_merkle_root(_leaf, _index, _proof) == self.epoch_merkle_roots[epoch]
    assert self.epoch_bonus_claims[epoch][msg.sender] != True, "Already claimed"
    assert self.epoch_bonus_amounts[epoch] > 0, "Bonus not set"

    self._mint(msg.sender, self.epoch_bonus_amounts[epoch])
    self.epoch_bonus_claims[epoch][msg.sender] = True

    

# MERKLE FUNCTIONS
@internal
@view
def _calc_merkle_root(
    _leaf: bytes32, _index: uint256, _proof: bytes32[merkle_depth]
) -> bytes32:
    """
    @dev Compute the merkle root
    @param _leaf Leaf hash to verify.
    @param _index Position of the leaf hash in the Merkle tree.
    @param _proof A Merkle proof demonstrating membership of the leaf hash.
    @return bytes32 Computed root of the Merkle tree.
    """
    computedHash: bytes32 = _leaf

    index: uint256 = _index

    for proofElement in _proof:
        if index % 2 == 0:
            computedHash = keccak256(concat(computedHash, proofElement))
        else:
            computedHash = keccak256(concat(proofElement, computedHash))
        index /= 2

    return computedHash


@external
@view
def calc_merkle_root(
    _leaf: bytes32, _index: uint256, _proof: bytes32[merkle_depth]
) -> bytes32:
    """
    @dev Compute the merkle root
    @param _leaf Leaf hash to verify.
    @param _index Position of the leaf hash in the Merkle tree, which starts with 1.
    @param _proof A Merkle proof demonstrating membership of the leaf hash.
    @return bytes32 Computed root of the Merkle tree.
    """
    return self._calc_merkle_root(_leaf, _index, _proof)


@external
@view
def verify_merkle_proof(
    _leaf: bytes32, _index: uint256, _rootHash: bytes32, _proof: bytes32[merkle_depth]
) -> bool:
    """
    @dev Checks that a leaf hash is contained in a root hash.
    @param _leaf Leaf hash to verify.
    @param _index Position of the leaf hash in the Merkle tree, which starts with 1.
    @param _rootHash Root of the Merkle tree.
    @param _proof A Merkle proof demonstrating membership of the leaf hash.
    @return bool whether the leaf hash is in the Merkle tree.
    """
    return self._calc_merkle_root(_leaf, _index, _proof) == _rootHash