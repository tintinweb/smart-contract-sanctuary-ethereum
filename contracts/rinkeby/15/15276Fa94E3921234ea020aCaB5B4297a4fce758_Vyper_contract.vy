# @version 0.3.6
# @dev Implementation of ERC-721 non-fungible token standard.
# @author npc-ers.eth
# @license MIT
# Modified from: https://github.com/vyperlang/vyper/blob/de74722bf2d8718cca46902be165f9fe0e3641dd/examples/tokens/ERC721.vy

"""
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

interface ERC721:
    def mint(recipient: address): nonpayable
    def totalSupply() -> uint256: nonpayable

interface ThingToken:
    def mint(recipient: address, amount: uint256): nonpayable


owner: public(address)
nft_addr: public(address)
token_addr: public(address)

# Mint Parameters
min_price: public(uint256)

# Coupon!
coupon_token: public(address)
whitelist: public(HashMap[address, bool])
used_coupon: public(HashMap[address, bool])
MAX_MINT: constant(uint256) = 4000
BATCH_LIMIT: constant(uint256) = 10


@external
def __init__():
    self.owner = msg.sender
    self.min_price = as_wei_value(.008, 'ether') 


@internal
@view
def _has_coupon(addr: address) -> bool:
    has_coupon: bool = False
    if self.used_coupon[addr] == True:
        has_coupon = False
    elif self.whitelist[addr] == True:
        has_coupon = True
    elif self.coupon_token == empty(address):
        has_coupon = False
    elif self.used_coupon[addr]:
        has_coupon = False
    elif ERC20(self.coupon_token).balanceOf(addr) > 0:
        has_coupon = True

    return has_coupon


@external
@view
def has_coupon(addr: address) -> bool:
    """
    @notice Check if the user is authorized for one free mint
    @param addr Address to check eligibility
    @return bool True if eligible for one free mint
    """
    return self._has_coupon(addr)



@internal
@view
def _mint_price(quantity: uint256, addr: address) -> uint256:
    if self._has_coupon(addr):
        return self.min_price * (quantity - 1)
    else:
        return self.min_price * quantity

@external
@view
def mint_price(quantity: uint256, addr: address) -> uint256:
    return self._mint_price(quantity, addr)

@external
@payable
def mint(quantity: uint256):
    """
    @notice Reserve a batch of several NFTs at one time
    @param quantity The number of NFTs to mint
    """
    assert quantity <= BATCH_LIMIT  #dev: Mint batch capped
    assert msg.value >= self._mint_price(quantity, msg.sender)
    supply: uint256 = ERC721(self.nft_addr).totalSupply()

    assert supply + quantity < MAX_MINT # dev: Exceed max mint cap

    for i in range(BATCH_LIMIT):
        if i >= quantity:
            break
        
        ERC721(self.nft_addr).mint(msg.sender)
        ThingToken(self.token_addr).mint(msg.sender, 1000 * 10 ** 18)

    if self._has_coupon(msg.sender):
        self.used_coupon[msg.sender] = True

@external
def admin_set_nft_addr(addr: address):
    """
    @notice Update NFT Address
    @param addr New contract address
    """
    assert msg.sender == self.owner
    self.nft_addr = addr
    
@external
def admin_set_token_addr(addr: address):
    """
    @notice Update Token Address
    @param addr New contract address
    """
    assert msg.sender == self.owner
    self.token_addr = addr
 
@external
def admin_new_owner(new_owner: address):
    """
    @notice Update owner of minter contract
    @param new_owner New contract owner address
    """
    assert msg.sender == self.owner  # dev: "Admin Only"
    self.owner = new_owner


@external
def admin_withdraw(target: address, amount: uint256):
    """
    @notice Withdraw funds to admin
    @dev Can only be used if auctions have been disabled
    """
    assert self.owner == msg.sender  # dev: "Admin Only"

    send(target, amount)


@external
def admin_update_coupon_token(token: address):
    """
    @notice Holders of any ERC20 coupon token are eligible for one free random mint
    @param token Address of ERC20 token
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.coupon_token = token


@external
def admin_add_to_whitelist(addr: address):
    """
    @notice Whitelist a specific address for one free mint
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.whitelist[addr] = True


@external
def admin_mint(addr: address, quantity: uint256):
    assert self.owner == msg.sender
    ThingToken(self.token_addr).mint(addr, quantity)