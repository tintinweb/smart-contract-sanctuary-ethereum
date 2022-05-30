# @version >=0.3.3

from vyper.interfaces import ERC20

interface chainlinkPrice:
    def latestAnswer() -> int256: view

DEV_ADDRESS: constant(address) = ZERO_ADDRESS
CHAINLINK_BNB_PRICE_CONTRACT: constant(address) = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE

startBNBPrice: public(int256)
endBNBPrice: public(int256)
startBlock: public(uint256)
bonusPool: public(uint256)
bullJoinGameTotalAmount: public(uint256)
bearJoinGameTotalAmount: public(uint256)
bonusRatio: public(uint256)
initialization: public(bool)
owner: public(address)

reflexer: HashMap[address, address]
is_reflexer: HashMap[address, HashMap[address, bool]]
getBonusAmount: HashMap[address, uint256]
getReflexerCount: HashMap[address, uint256]
joinGameAmount: HashMap[address, uint256]

bullHolderList: DynArray[address, 100000000]
bearHolderList: DynArray[address, 100000000]

@external
def __init__():
    self.owner = msg.sender

@internal
@view
def _get_bnb_price() -> int256:
    bnbPrice: int256 = chainlinkPrice(CHAINLINK_BNB_PRICE_CONTRACT).latestAnswer()
    return bnbPrice

@external
@payable
def startGaming(start: bool):
    # 开始游戏
    assert msg.sender == self.owner, "Only owner"
    self.initialization = start
    self.startBNBPrice = self._get_bnb_price()
    self.startBlock = block.timestamp

@external
@view
def getReflexer(sender: address, spender: address) -> bool:
    # 查询是否是推荐人
    return self.is_reflexer[sender][spender]

@external
@view
def getReflexerAddress(sender: address) -> address:
    # 查询邀请人地址
    return self.reflexer[sender]

@external
@view
def getJoinGameAmount(sender: address) -> uint256:
    # 查询入金金额
    return self.joinGameAmount[sender]

@external
def linkReflexer(spender: address):
    # 用户设置自己的推荐人
    assert self.is_reflexer[msg.sender][spender] != True, "Spender is reflexer"
    self.is_reflexer[msg.sender][spender] = True
    self.reflexer[msg.sender] = spender

@external
def setReflexer(sender: address, spender: address):
    # 管理员设置推荐人
    assert msg.sender == self.owner, "Only owner"
    self.is_reflexer[sender][spender] = True
    self.reflexer[sender] = spender

@internal
def _bull_fee(_sender: address, _amountIn: uint256):
    # 总15%
    # 牛： 5%推荐，3%开发，7%奖池
    
    bullBonusFee: uint256 = _amountIn * 5 / 100
    devFee: uint256 = _amountIn * 3 / 100
    poolFee: uint256 = _amountIn * 7 / 100

    if self.reflexer[_sender] != ZERO_ADDRESS:
        send(self.reflexer[_sender], bullBonusFee)
        send(self.owner, devFee)
        self.bonusPool += poolFee
        self.getBonusAmount[_sender] += bullBonusFee
    else:
        send(self.owner, bullBonusFee)
        send(self.owner, devFee)
        self.bonusPool += poolFee
        self.getBonusAmount[self.owner] += bullBonusFee

@internal
def _bear_fee(_sender: address, _amountIn: uint256):
    # 熊： 10%推荐，3%开发，2%奖池
    bearBonusFee: uint256 = _amountIn * 10 / 100
    devFee: uint256 = _amountIn * 3 / 100
    poolFee: uint256 = _amountIn * 2 / 100

    if self.reflexer[_sender] != ZERO_ADDRESS:
        send(self.reflexer[_sender], bearBonusFee)
        send(self.owner, devFee)
        self.bonusPool += poolFee
        self.getBonusAmount[_sender] += bearBonusFee
    else:
        send(self.owner, bearBonusFee)
        send(self.owner, devFee)
        self.bonusPool += poolFee
        self.getBonusAmount[self.owner] += bearBonusFee

@internal
def _bonus_pool_distribution():
    bnbPrice: int256 = self._get_bnb_price()

    if bnbPrice >= self.startBNBPrice:
        # 价格涨，分给熊阵营
        length: uint256 = len(self.bearHolderList)
        # dynArray: address[length] = self.bearHolderList

        # for i in range(length):
        for bearHolder in self.bearHolderList:
            bearHolderJoinGameAmount: uint256 = self.joinGameAmount[bearHolder]
            joinGameAmountRatio: uint256 = bearHolderJoinGameAmount / self.bearJoinGameTotalAmount * (10 ** 18)
            bonusPoolRatio: uint256 = self.bearJoinGameTotalAmount / self.bonusPool * (10 ** 18)
            send(bearHolder, joinGameAmountRatio * bonusPoolRatio)

    else:
        for bullHolder in self.bullHolderList:
            bullHolderJoinGameAmount: uint256 = self.joinGameAmount[bullHolder]
            joinGameAmountRatio: uint256 = bullHolderJoinGameAmount / self.bullJoinGameTotalAmount * (10 ** 18)
            bonusPoolRatio: uint256 = self.bullJoinGameTotalAmount / self.bonusPool * (10 ** 18)
            send(bullHolder, joinGameAmountRatio * bonusPoolRatio)


@external
@payable
def joinBull():
    assert self.initialization == True, "Game is over"
    assert msg.sender != ZERO_ADDRESS, "Not zero address"
    assert msg.value >= 10000000000000000, "Party amount must exceed 0.01"

    # 分配奖金
    self._bull_fee(msg.sender, msg.value)        

    # 添加地址到列表
    self.bullHolderList.append(msg.sender)
    
    # 统计入金
    self.joinGameAmount[msg.sender] += msg.value
    self.bullJoinGameTotalAmount += msg.value

    # 每6小时分配奖池
    if block.timestamp >= (self.startBlock + 7200):
        self._bonus_pool_distribution()
        self.startBNBPrice = self._get_bnb_price()
        self.startBlock = block.timestamp

@external
@payable
def joinBear():
    assert self.initialization == True, "Game is over"
    assert msg.sender != ZERO_ADDRESS, "Not zero address"
    assert msg.value >= 10000000000000000, "Party amount must exceed 0.01"

    # 分配奖金
    self._bear_fee(msg.sender, msg.value)        

    # 添加地址到列表
    self.bearHolderList.append(msg.sender)
    
    # 统计入金
    self.joinGameAmount[msg.sender] += msg.value
    self.bearJoinGameTotalAmount += msg.value
   
    if block.timestamp >= (self.startBlock + 7200):
        self._bonus_pool_distribution()
        self.startBNBPrice = self._get_bnb_price()
        self.startBlock = block.timestamp

@external
def emergencyExitGame():
    assert msg.sender == self.owner, "Only owner"

    send(self.owner, self.balance)