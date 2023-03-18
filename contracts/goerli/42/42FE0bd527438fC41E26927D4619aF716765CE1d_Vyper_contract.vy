# @version 0.3.7

interface MintableToken: 
    def balanceOf(_user: address) -> uint256: view
    def isMinter(_minter: address) -> bool: view
    def mint(_recipient: address, _amount: uint256) -> bool: nonpayable

struct TokenConfig:
    tokenAddress: address
    apy: uint256
    receiver: address

# storage variables
tokenConfig: public(HashMap[address, HashMap[address, TokenConfig]]) # Token => Receiver => TokenConfig
tokenReceiversCount: public(HashMap[address, uint256]) # Token => Receivers Count
tokenReceiversIndex: public(HashMap[address, HashMap[uint256, address]]) # Token => index => Receiver 
tokenIndexes: public(HashMap[uint256, address]) # index => Token 
totalTokens: public(uint256)

owner: public(address)
pendingOwner: public(address)

lastReward: public(uint256)

ONE_YEAR: constant(uint256) = 365 * 24 * 60 * 60 # 31_536_000 Seconds

@external
def __init__(_owner: address):
    assert _owner != empty(address)
    self.owner = _owner
    self.lastReward = block.timestamp

    
@internal
def _validateMinter(_tokenAddress: address):
    assert _tokenAddress != empty(address), "Invalid token"
    mintable: MintableToken = MintableToken(_tokenAddress)

    assert mintable.isMinter(self), "Not a minter"


@external
def setToken(_tokenAddress: address, _apy: uint256, _receiver: address):
    assert msg.sender == self.owner, "Only the owner can set tokens"
    assert _receiver != empty(address)
    
    self._validateMinter(_tokenAddress)
    if self.tokenReceiversCount[_tokenAddress] == 0:
        self.tokenIndexes[self.totalTokens] = _tokenAddress
        self.totalTokens = self.totalTokens + 1

    if self.tokenConfig[_tokenAddress][_receiver].tokenAddress == empty(address):
        self.tokenReceiversIndex[_tokenAddress][self.tokenReceiversCount[_tokenAddress]] = _receiver
        self.tokenReceiversCount[_tokenAddress] += 1
    
    self.tokenConfig[_tokenAddress][_receiver] = TokenConfig({
        tokenAddress: _tokenAddress,
        apy: _apy,
        receiver: _receiver,
    })


@external
def giveRewards():
    now: uint256 = block.timestamp

    timeSpent: uint256 = now - self.lastReward
    self.lastReward = now

    for i in range(max_value(uint256)):
        if i == self.totalTokens:
            break
        
        tokenAddress: address = self.tokenIndexes[i]
        tokenReceiversCount: uint256 = self.tokenReceiversCount[tokenAddress]

        for j in range(max_value(uint256)):
            if j == tokenReceiversCount:
                break

            receiver: address = self.tokenReceiversIndex[tokenAddress][j] 
            config: TokenConfig = self.tokenConfig[tokenAddress][receiver]

            if config.apy == 0:
                continue

            token: MintableToken = MintableToken(config.tokenAddress)
            tokenBalance: uint256 = token.balanceOf(config.receiver)
            reward: uint256 = config.apy * tokenBalance * timeSpent / ONE_YEAR / 100_00 #100%
            
            token.mint(config.receiver, reward) 


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