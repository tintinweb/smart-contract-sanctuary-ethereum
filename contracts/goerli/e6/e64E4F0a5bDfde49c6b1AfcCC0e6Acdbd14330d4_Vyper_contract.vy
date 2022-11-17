# @version 0.2.16

# Beneficiary receives the pool tokens at the end of each round
beneficiary: public(address)

roundStart: public(uint256)
roundEnd: public(uint256)

# Current state of auction
roundCount: public(uint256)
poolTotal: public(uint256)
poolStake: public(HashMap[address, uint256])

# Set to true at the end, disallows any change
ended: public(bool)

tokenName: public(String[40])
tokenSupply: public(uint256)

block_number: public(uint256)

interface daoTokenContract:
    def safeMint(_to: address, _tokenId: uint256): payable
    def name() -> String[40]: view
    def getPastTotalSupply(_block: uint256) -> uint256: payable

event Payment:
    sender: indexed(address)
    amount: uint256
    bal: uint256
    gasLeft: uint256

@external
def getCurrentBlockNumber():
    self.block_number = block.number

@external
def test(nft_addr: address, _to: address):
    # self.tokenName = daoTokenContract(nft_addr).name()
    
    # self.tokenId = daoTokenContract(nft_addr).getPastTotalSupply(block.number)
    daoTokenContract(nft_addr).safeMint(_to, self.tokenSupply + 1)

@external
def getDaoTokenTotal(nft_addr: address,):
    self.tokenSupply = daoTokenContract(nft_addr).getPastTotalSupply(self.block_number)

@external
def __init__():
    # self.daotoken_contract = daoTokenContract(_contract_addr)
    # self.beneficiary = _beneficiary # DAO addr
    self.roundEnd = block.timestamp
    self.ended = True
    

@external
@payable
def __default__():
    log Payment(msg.sender, msg.value, self.balance, msg.gas)

@external
@payable
def buy_tickets(_amount: uint256):
    assert self.ended == False
    self.poolStake[msg.sender] += _amount
    self.poolTotal += _amount

    log Payment(msg.sender, _amount, self.balance, msg.gas)

@external
def initRound():
    assert self.ended == True
    self.ended = False
    self.roundCount += 1
    self.roundStart = block.timestamp
    self.roundEnd = self.roundStart + 30
    self.poolTotal = 0
    # for addr in iter(self.poolStake):
    #     self.poolStake[addr] = 0
   
@external
def endRound():
    assert self.ended == False
    # assert block.timestamp >= self.roundEnd
    self.ended = True

    # Need to do chainlink VRF random number generation here
    # For now we will just select the highest poolstake

    send(self.beneficiary, self.poolTotal-1)

# 0x6bf96bf4B510877a8f885D5D00176AAb49A6AAD3

# @internal
# def getBalance():