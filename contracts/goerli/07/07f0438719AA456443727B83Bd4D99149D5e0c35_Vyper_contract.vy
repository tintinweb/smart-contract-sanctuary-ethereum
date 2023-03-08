# @version 0.3.7
interface MintableToken: 
    def balanceOf(_user: address) -> uint256: view
    def isMinter(_minter: address) -> bool: view
    def mint(_recipient: address, _amount: uint256) -> bool: nonpayable

struct TokenConfig:
    tokenAddress: address
    amount: uint256

# storage variables
tokenConfig: public(HashMap[address, TokenConfig])
tokenIndexes: public(HashMap[uint256, address])
totalTokens: public(uint256)

owner: public(address)
pendingOwner: public(address)


@external
def __init__(_owner: address):
    assert _owner != empty(address)
    self.owner = _owner

    
@internal
def _validateMinter(_tokenAddress: address):
    assert _tokenAddress != empty(address), "Invalid token"
    mintable: MintableToken = MintableToken(_tokenAddress)

    assert mintable.isMinter(self), "Not a minter"


@external
def setToken(_tokenAddress: address, _amount: uint256):
    assert msg.sender == self.owner, "Only the owner can set tokens"
    
    self._validateMinter(_tokenAddress)
    
    if self.tokenConfig[_tokenAddress].tokenAddress == empty(address):
        self.tokenIndexes[self.totalTokens] = _tokenAddress
        self.totalTokens = self.totalTokens + 1
    
    self.tokenConfig[_tokenAddress] = TokenConfig({
        tokenAddress: _tokenAddress,
        amount: _amount,
    })


@external
def fund(_wallet: address = msg.sender):
    for i in range(max_value(uint256)):
        if i >= self.totalTokens:
            break

        tokenAddress: address = self.tokenIndexes[i]
        config: TokenConfig = self.tokenConfig[tokenAddress]

        if config.amount == 0:
            continue

        token: MintableToken = MintableToken(config.tokenAddress)
        userBalance: uint256 = token.balanceOf(_wallet)
 
        if userBalance >= config.amount:
            continue
             
        transferAmount: uint256 = config.amount - userBalance
        token.mint(_wallet, transferAmount) 


@external
def updateOwner(_pendingOwner: address):
    assert msg.sender == self.owner, "# dev: only governance can update"
    assert _pendingOwner != empty(address), "# dev: cannot be 0x0"
    self.pendingOwner = _pendingOwner


@external
def acceptOwner():
    curOwner: address = self.owner
    newOwner: address = msg.sender 
    assert newOwner == self.pendingOwner, "# dev: only pendingOwner can accept"
    self.owner = newOwner
    self.pendingOwner = empty(address)