/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract LuckDraw {

    address public owner;

    // 平台运营费地址
    address payable private platAddr = payable(0x80726ff457551fe0FD4966750ecDC61a7BB84f75);

    // 奖池接收比例：90%
    uint8 constant public poolFee = 90;

    // 一轮多少区块：72h * 3600s / 15s = 17280
    uint16 constant public blocksPerRound = 20;

    // 开奖前多少个区块停止投注，建议不低于6（交易确认需要6个区块）
    uint8 constant public stopBetBlocks = 1;

    // 每个奖池单次投注金额
    uint256 constant private pool1BetValue = 1 * 10 ** 16;  // 10%奖池单次投注金额为0.01eth
    uint256 constant private pool5BetValue = 5 * 10 ** 16;  // 50%奖池单次投注金额为0.05eth
    uint256 constant private pool8BetValue = 1 * 10 ** 17;  // 80%奖池单次投注金额为0.1eth

    // 每轮区块起始高度
    uint256 public roundStartHeight;
    // 每轮区块截止高度（即开奖高度）
    uint256 public roundEndHeight;

    // 游戏状态枚举
    // 0.可投注
    // 1.投注结束，确定了每个奖池中奖的注数(此状态不可投注，留给后端给用户开奖, 后端调用nextRound之后 开启下一轮)
    enum GameState{AcceptBet, SendReward}
    GameState public gameState;

    // 游戏轮次
    uint32 public round;

    // 映射：奖池id -> 投注金额
    mapping(uint8 => uint256) public betValue;

    // 映射：奖池id -> 奖池余额
    mapping(uint8 => uint256) public poolBalance;

    // 映射：奖池id -> 本轮单注中奖金额
    mapping(uint8 => uint256) public bonusForEachBet;


    // 用户开奖结构体
    struct User{
        uint32 userId;  // 用户id
        uint32 betCounter;  // 第几注中的奖
    }

    // 用户id计数器
    uint32 private userIdCounter;

    // 映射：地址 -> userId
    mapping(address => uint32) public addressToUserId;

    // 映射：userId -> 地址
    mapping(uint32 => address) public userIdToAddress;

    // 映射：userId -> 用户投注计数器
    mapping(uint32 => uint32) private betCounter;

    // 映射：兑奖记录(userId -> {betCounter -> 是否兑奖})
    mapping(uint32 => mapping(uint32 => bool)) public sendReward;

    // 映射：userId -> 用户中奖余额累计
    mapping(uint32 => uint256) public userBalance;

    // 事件：投注
    event Bet(uint32 indexed round, uint8 poolId, uint32 indexed userId, uint32 betCounter);

    // 事件：开启轮次
    event Start(uint32 indexed round, uint256 startHeight, uint256 endHeight);

    // 事件：设置各奖池中奖总注数
    event SetTotalWinnerCount(uint32 indexed round, uint32 pool1WinnerCount, uint32 pool5WinnerCount, uint32 pool8WinnerCount);

    // 事件：兑奖
    event SendReward(uint32 indexed round, uint32 indexed userId, uint32 betCounter);

    // 事件：提现
    event Withdraw(address indexed userId, uint256 value);

    // 函数修饰符
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function!");
        _;
    }

    // 构造函数
    constructor() {
        owner = msg.sender;
        betValue[1] = pool1BetValue;
        betValue[5] = pool5BetValue;
        betValue[8] = pool8BetValue;
        initPool();
    }

    // 初始化奖池
    function initPool() private {
        round++;
        roundStartHeight = block.number;
        roundEndHeight = roundStartHeight + blocksPerRound;
        // 判断轮次开始区块高度 > 结束区块高度 - 开奖前停止投注高度(6)
        require(roundStartHeight < roundEndHeight - stopBetBlocks, "Round end block height should be greater than the start block height add stopBetBlocks!");
        // 游戏状态：可投注
        gameState = GameState.AcceptBet;
        // 释放事件: 游戏开始
        emit Start(round, roundStartHeight, roundEndHeight);
    }

    // 合约方法：投注
    function bet(uint8 poolId) external payable {
        // 判断入参poolId是否合法
        require(poolId==1 || poolId==5 || poolId==8, "poolId is invalid.");
        // 判断当前游戏状态是否为可投注
        require(gameState==GameState.AcceptBet, "GameState is not AcceptBet, please wait for next round!");
        // 判断当前区块高度 < (当前轮次结束高度 - 截止投注区块数)
        require(block.number < roundEndHeight - stopBetBlocks, "block number is greater than roundEndHeight, please wait for next round!");

        // 该奖池单次投注金额
        uint256 _betValue = betValue[poolId];

        // 判断用户投注金额是否等于奖池单次投注金额
        require(msg.value==_betValue, "Invalid bet value.");

        // 转入奖池里的金额（90%）
        uint256 _toPoolAmount = _betValue * poolFee / 100;

        // 转入平台地址的金额(10%) = 投注金额 - 转入奖池金额
        uint256 _toPlatAmount = _betValue - _toPoolAmount;
        // 将这部分金额转账到平台地址
        platAddr.transfer(_toPlatAmount);

        // 更新奖池的余额
        poolBalance[poolId] += _toPoolAmount;

        // 更新用户的投注信息
        // 获取userId
        uint32 _userId = getUserId();

        // 更新用户投注计数器
        betCounter[_userId]++;

        // 释放事件：投注
        emit Bet(round, poolId, _userId, betCounter[_userId]);
    }

    // 合约私有方法：获取userId
    function getUserId() private returns (uint32) {
        uint32 _userId = addressToUserId[msg.sender];
        if(_userId==0) {
            userIdCounter++;
            _userId = userIdCounter;
            addressToUserId[msg.sender] = _userId;
            userIdToAddress[_userId] = msg.sender;
            return _userId;
        } else {
            return _userId;
        }
    }

    // 合约方法：设置本轮游戏每个奖池总共中奖的次数（owner才能调用）
    function setTotalWinnerCount(
        uint32 pool1TotalWinnerCount,
        uint32 pool5TotalWinnerCount,
        uint32 pool8TotalWinnerCount) external onlyOwner {
        // 判断当前是否未可投注状态
        require(gameState==GameState.AcceptBet, "Current game state is not AcceptBet.");
        // 要求当前区块高度大于开奖的区块高度（即本轮结束区块高度），只有到开奖时才能设置
        require(block.number > roundEndHeight, "Current block height is not the endBlockHeight.");

        // 计算并设置每个奖池单注中奖金额
        calcBonus(1, pool1TotalWinnerCount);
        calcBonus(5, pool5TotalWinnerCount);
        calcBonus(8, pool8TotalWinnerCount);

        // 更新游戏状态为：已兑奖
        gameState = GameState.SendReward;

        // 释放事件：兑奖
        emit SetTotalWinnerCount(round, pool1TotalWinnerCount, pool5TotalWinnerCount, pool8TotalWinnerCount);
    }

    // 合约私有方法：计算并设置每个奖池单次投注的中奖金额
    function calcBonus(uint8 poolId, uint32 totalWinnerCount) private {
        if(totalWinnerCount==0) {
            bonusForEachBet[poolId] = 0;
        } else {
            // 每个奖池单次投注中奖金额 = 奖池余额 / 中奖注数（hash数非人数）
            bonusForEachBet[poolId] = poolBalance[poolId] / totalWinnerCount;
        }
    }

    // 合约方法：开奖,给某个奖池中奖的用户进行开奖，可以多次调用
    function drawPrize(uint8 poolId, User[] memory users) external onlyOwner {
        // 判断游戏当前状态是否为已兑奖
        require(gameState==GameState.SendReward, "Game state is not SendReward.");
        // 判断单次投注中奖金额是否合法
        require(bonusForEachBet[poolId] > 0, "Bonus for each bet shoud be greater than zero.");

        // 循环处理每一个user
        for(uint i=0; i<users.length; i++) {
            // 判断奖池余额是否 > 0
            uint256 _poolBalance = poolBalance[poolId];
            require(_poolBalance > 0, "Insufficient pool balance.");
            // 用户id和第几注中奖
            uint32 _userId = users[i].userId;
            uint32 _betCounter = users[i].betCounter;

            // 判断兑奖是否成功
            if(sendReward[_userId][_betCounter] == false) { // 未兑奖
                sendReward[_userId][_betCounter] == true; // 修改为已兑奖

                // 单笔中奖金额
                uint256 _bonus = bonusForEachBet[poolId];

                // 判断该奖池余额是否足够该笔中奖金额
                if(_poolBalance >= _bonus) {
                    // 扣减奖池余额
                    poolBalance[poolId] -= _bonus;
                    // 增加用户余额
                    userBalance[_userId] += _bonus;
                } else { // 不够该笔中奖金额
                    // 扣减奖池余额为0
                    poolBalance[poolId] = 0;
                    // 增加用户余额，将奖池余额全部给他
                    userBalance[_userId] += _poolBalance;
                }

                // 释放事件：兑奖
                emit SendReward(round, _userId, _betCounter);
            }

        }
    }

    // 合约外部方法：开启下一轮（只能由owner调用）
    function nextRound() external onlyOwner {
        // 判断当前游戏状态是否为已兑奖
        require(gameState==GameState.SendReward, "Game state is not SendReward.");
        // 重新初始化奖池
        initPool();
    }

    // 合约外部方法：用户提现
    function withdraw() external {
        uint32 _userId = getUserId();
        // 获取用户余额
        uint256 _userBalance = userBalance[_userId];
        // 判断用户账户余额是否>0
        require(_userBalance > 0, "Balance not enough.");
        // 将用户账户余额设置为0（防止重复提现）
        userBalance[_userId] = 0;
        // 从合约转账到用户地址
        payable(msg.sender).transfer(_userBalance);
        // 释放事件：提现
        emit Withdraw(msg.sender, _userBalance);
    }

    // receive()函数：接收外部转入的以太币
    receive() external payable {
        platAddr.transfer(msg.value);
    }

    // fallback()函数：兜底
    fallback() external payable {
        platAddr.transfer(msg.value);
    }

    // destroy()函数：销毁合约
    function destroy() public payable onlyOwner {
        selfdestruct(platAddr);
    }

}