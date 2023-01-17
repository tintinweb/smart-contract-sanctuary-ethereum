# @version 0.3.7
# @notice NPC-ers Minter
# @author npcers.eth
# @license MIT

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

# Addresses
owner: public(address)
nft_addr: public(address)
token_addr: public(address)

# Mint Parameters
min_price: public(uint256)

# Coupon!
coupon_token: public(address)
whitelist: public(HashMap[address, bool])
used_coupon: public(HashMap[address, uint256])
whitelist_max: public(uint256)

# Airdrop!
is_erc20_drop_live: public(bool)
erc20_drop_quantity: public(uint256)

# Constants
MAX_MINT: constant(uint256) = 6000
BATCH_LIMIT: constant(uint256) = 10

WITHDRAW_LIST: constant(address[4]) = [
    0xccBF601eB2f5AA2D5d68b069610da6F1627D485d, 
    0xAdcB949a288ec2500c1109f9876118d064c40dA6,
    0xc59eae56D3F0052cdDe752C10373cd0B86451EB2,
    0x84865Bb349998D6b813DB7Cc0F722fD0A94e6e27
]

WITHDRAW_PCT: constant(uint256[4]) = [
    25,
    25,
    25,
    15
]


@external
def __init__():
    self.owner = msg.sender
    self.min_price = as_wei_value(0.008, "ether")
    self.whitelist_max = 3
    self.erc20_drop_quantity = 1000 * 10**18
    self.is_erc20_drop_live = True
       

@internal
@view
def _has_coupon(addr: address) -> bool:
    has_coupon: bool = False
    if self.used_coupon[addr] >= self.whitelist_max:
        has_coupon = False
    elif self.whitelist[addr] == True:
        has_coupon = True
    elif self.coupon_token == empty(address):
        has_coupon = False
    elif ERC20(self.coupon_token).balanceOf(addr) > 0:
        has_coupon = True

    return has_coupon


@external
@view
def has_coupon(addr: address) -> bool:
    """
    @notice Check if the user is authorized for free mints
    @param addr Address to check eligibility
    @return bool True if eligible
    """
    return self._has_coupon(addr)


@internal
@view
def _mint_price(quantity: uint256, addr: address) -> uint256:
    if self._has_coupon(addr):
        mints_left: uint256 = self.whitelist_max - self.used_coupon[addr]
        return self.min_price * (quantity - min(quantity, mints_left))
    else:
        return self.min_price * quantity


@external
@view
def mint_price(quantity: uint256, addr: address) -> uint256:
    """
    @notice Calculate price of minting a quantity of NFTs for a specific address
    @param quantity Number of NFTs to mint
    @param addr Address to mint for
    """
    return self._mint_price(quantity, addr)


@external
@payable
def mint(quantity: uint256):
    """
    @notice Mint up to MAX_MINT NFTs at a time.  Also supplies $THING if drop is live.
    @param quantity The number of NFTs to mint
    """
    assert quantity <= BATCH_LIMIT  # dev: Mint batch capped
    assert msg.value >= self._mint_price(quantity, msg.sender)
    supply: uint256 = ERC721(self.nft_addr).totalSupply()

    assert supply + quantity < MAX_MINT  # dev: Exceed max mint cap

    for i in range(BATCH_LIMIT):
        if i >= quantity:
            break

        ERC721(self.nft_addr).mint(msg.sender)

    if self.is_erc20_drop_live:
        ThingToken(self.token_addr).mint(
            msg.sender, quantity * self.erc20_drop_quantity
        )

    if self._has_coupon(msg.sender):
        self.used_coupon[msg.sender] += min(
            quantity, self.whitelist_max - self.used_coupon[msg.sender]
        )


@external
def premint(target: address):
    """
    @notice Treasury reserves
    @dev Revert if somebody has already minted
    """
    assert ERC721(self.nft_addr).totalSupply() == 0
    for i in range(100):
        ERC721(self.nft_addr).mint(target)

@external
def admin_set_nft_addr(addr: address):
    """
    @notice Update NFT address
    @param addr New contract address
    """
    assert msg.sender == self.owner
    self.nft_addr = addr


@external
def admin_set_token_addr(addr: address):
    """
    @notice Update address of ERC-20 token
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
def withdraw():
    """
    @notice Withdraw funds to withdraw list
    @dev Anybody can call, triggers withdraw in proportion, remainder to owner
    """
    init_bal : uint256 = self.balance

    for i in range(4):
        send(WITHDRAW_LIST[i], init_bal * WITHDRAW_PCT[i] / 100)
    
    send(self.owner, self.balance)


@external
def admin_update_coupon_token(token: address):
    """
    @notice Holders of any ERC20 coupon token are eligible for free mint
    @param token Address of ERC20 token
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.coupon_token = token


@external
def admin_add_to_whitelist(addr: address):
    """
    @notice Whitelist a specific address for free mints i
    @dev defined by whitelist_max
    @param addr Address to add to whitelist
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.whitelist[addr] = True


@external
def admin_mint_erc20(addr: address, quantity: uint256):
    """
    @notice Mint $THING tokens to a specific address
    @param addr Address to mint ERC20 for
    @param quantity Number of tokens to mint
    """

    assert self.owner == msg.sender
    ThingToken(self.token_addr).mint(addr, quantity)


@external
def admin_mint_nft(addr: address):
    """
    @notice Mint an NFT to a specific address
    @param addr Address to mint to
    """

    assert self.owner == msg.sender
    ERC721(self.nft_addr).mint(addr)


@external
def admin_update_whitelist_max(max_val: uint256):
    """
    @notice Update number of free mints whitelisted useres get
    @param max_val New value for whitelist cap
    """

    assert self.owner == msg.sender
    self.whitelist_max = max_val


@external
def admin_update_erc20_drop_live(status: bool):
    """
    @notice Update if $THING tokens also distributed on mint
    @param status Boolean True for token distribution, False for no
    """

    assert self.owner == msg.sender
    self.is_erc20_drop_live = status


@external
def admin_update_erc20_drop_quantity(quantity: uint256):
    """
    @notice Update quantity of tokens disbursed on mint
    @param quantity New number of tokens
    """

    assert self.owner == msg.sender
    self.erc20_drop_quantity = quantity


@external
def admin_update_mint_price(new_value: uint256):
    """
    @notice Update mint price
    @param new_value New mint price
    """

    assert self.owner == msg.sender
    self.min_price = new_value