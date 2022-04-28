# @version 0.3.3
# @dev EU Minter Logic
# @author pacdao.eth
# @license MIT

interface NFT:
    def balanceOf(addr: address) -> uint256: view
    def mint(addr: address, isGold: bool) -> bool: nonpayable
    def setTokenURI(tokenId: uint256, newURI: String[128]): nonpayable
    def setContractURI(newURI: String[128]): nonpayable
    def setDefaultMetadata(newURI: String[128]): nonpayable
    def transferMinter(newAddr: address): nonpayable

NFT_ADDR: immutable(address)
MAX_MINT: immutable(uint256)

mint_price: public(uint256)
whitelist_tokens: public(DynArray[address, 4])
owner: public(address)
is_active: public(bool)
has_minted: public(HashMap[address, bool])

@external
def __init__(nft_addr: address, whitelist_tokens: DynArray[address, 4]):
    NFT_ADDR = nft_addr
    MAX_MINT = 10
    self.owner = msg.sender
    self.mint_price = 42000000000000000
    self.whitelist_tokens = whitelist_tokens
    self.is_active = True


@external
@payable
def __default__():
    pass


@external
@pure
def nft_addr() -> address:
    return NFT_ADDR


@internal
@view
def _is_whitelisted(user: address) -> bool:
    for addr in self.whitelist_tokens:
        if NFT(addr).balanceOf(user) > 0:
            return True
    return False


@external
@view
def is_whitelisted(user: address) -> bool:
    """
    @dev Check if an address is whitelisted to mint a free copy
         If the free whitelist mint has been used it will be stored in has_minted
    @param user Address to check for whitelist status
    @return Returns true if user is whitelisted
    """

    return self._is_whitelisted(user)


@internal
@view
def _user_price_for_quantity(quantity: uint256, user: address) -> uint256:
    assert quantity > 0  # dev: Non-zero Quantity Required
    if self._is_whitelisted(user) and self.has_minted[user] == False:
        return (quantity - 1) * self.mint_price
    else:
        return quantity * self.mint_price


@external
@view
def user_price_for_quantity(quantity: uint256, user: address) -> uint256:
    """
    @dev Check price for user to mint a quantity of NFTs
         Pass this value of ETH to the mint function
    @param quantity Number of NFTs to mint
    @param user User to check
    @return Price in wei 
    """

    return self._user_price_for_quantity(quantity, user)

@internal
def _pseudorandom_number(seed: uint256) -> uint256:
    return (block.number * block.timestamp * seed) % 10


@internal
def _mint(addr: address):
    if self._pseudorandom_number(NFT(NFT_ADDR).balanceOf(addr)) == 0:
        NFT(NFT_ADDR).mint(addr, True)
    else:
        NFT(NFT_ADDR).mint(addr, False)


@external
@payable
def mint(quantity: uint256):
    """
    @dev Function to mint tokens
         Can mint up to 10 per batch
         Min price is value of wei from user_price_per_quantity function
    @param quantity Number of NFTs to mint 
    """

    assert quantity > 0, "No Quantity Specified"
    assert quantity <= MAX_MINT, "Too many mints"
    assert self.is_active, "Mint Period Ended"
    assert msg.value >= self._user_price_for_quantity(
        quantity, msg.sender
    ), "Insufficient Funds"

    for i in range(10):
        if i >= quantity:
            break
        self._mint(msg.sender)

    if self._is_whitelisted(msg.sender) and self.has_minted[msg.sender] == False:
        self.has_minted[msg.sender] = True


@external
def mint_for(mint_address: address):
    """
    @dev Admin mint function
    @param mint_address Recipient of NFT
    """

    assert msg.sender == self.owner  # dev: Only Admin
    self._mint(mint_address)


@external
def withdraw():
    """
    @dev Withdraw ETH to beneficiary address
    """


    send(self.owner, self.balance)


@external
def set_mint_price(mint_price: uint256):
    """
    @dev Admin function to update mint price
    """


    assert msg.sender == self.owner  # dev: Only Admin
    self.mint_price = mint_price


@external
def set_owner(new_owner: address):
    """
    @dev Admin function to set new owner
    """

    assert msg.sender == self.owner  # dev: Only Admin
    self.owner = new_owner


@external
def set_nft_minter(new_owner: address):
    """
    @dev Admin function to update minter address on NFT
    """

    assert msg.sender == self.owner  # dev: Only Admin
    NFT(NFT_ADDR).transferMinter(new_owner)


@external
def set_token_uri(token_id: uint256, new_uri: String[128]):
    """
    @dev Admin function to update a token URI 
    """

    assert msg.sender == self.owner  # dev: Only Admin
    NFT(NFT_ADDR).setTokenURI(token_id, new_uri)


@external
def set_contract_uri(new_uri: String[128]):
    """
    @dev Admin function to update the NFT's contract URI
    """

    assert msg.sender == self.owner  # dev: Only Admin
    NFT(NFT_ADDR).setContractURI(new_uri)


@external
def set_is_active(is_active: bool):
    """
    @dev Admin function to disable minting
    """

    assert msg.sender == self.owner  # dev: Only Admin
    self.is_active = is_active


@external
def set_whitelist_addrs(tokens: DynArray[address, 4]):
    """
    @dev Admin function to update whitelist tokens
    """

    assert msg.sender == self.owner  # dev: Only Admin
    self.whitelist_tokens = tokens


@external
def set_default_metadata(new_uri: String[128]):
    """
    @dev Admin function to update default token metadata
    """

    assert msg.sender == self.owner  # dev: Only Admin
    NFT(NFT_ADDR).setDefaultMetadata(new_uri)