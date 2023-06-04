/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HorseRace {
    uint256 constant private STATE_FACTOR = 10; // 狀態乘數
    uint256 constant private DISTANCE_MIN = 400; // 場地最小距離
    uint256 constant private DISTANCE_MAX = 1600; // 場地最大距離
    uint256 constant private STAMINA_MIN = 0; // 耐力最小值
    uint256 constant private STAMINA_MAX = 1600; // 耐力最大值
    uint256 constant private SPEED_MIN = 0; // 速度最小值
    uint256 constant private SPEED_MAX = 30; // 速度最大值
    uint256 constant private SPEED_OFFSET = 70; // 速度偏移值
    uint256 constant private MOD_FACTOR = 10; // 取模因子
    uint256 constant private BET_AMOUNT = 100 wei; // 下注金額
    uint256 constant private WINNING_MULTIPLIER = 150; // 獲勝倍率

    struct Horse {
        uint256 speed; // 速度
        uint256 stamina; // 耐力
        uint256 state; // 狀態
    }

    struct RaceResult {
        uint256 winningHorseIndex; // 獲勝馬匹的索引
        bool isBetWon; // 是否贏得下注
    }

    Horse[] public horses;
    RaceResult[] public raceResults;
    uint256 public currentRaceIndex;
    uint256 public currentBetHorseIndex;
    uint256 public currentBetAmount;

    constructor() payable {
        currentRaceIndex = 1;
    }

    // 生成隨機屬性的馬匹
    function generateHorse() private view returns (Horse memory) {
        uint256 randomState = getRandomNumber(0, 4, 1);
        uint256 randomStamina = (getRandomNumber(STAMINA_MIN, STAMINA_MAX, 2) + 400) / 20;
        uint256 randomSpeed = getRandomNumber(SPEED_MIN, SPEED_MAX, 3) + SPEED_OFFSET;

        return Horse(randomSpeed, randomStamina, randomState);
    }

    // 生成指定範圍內的隨機數字
    function getRandomNumber(uint256 min, uint256 max, uint256 RANDOM_SEED) private view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, RANDOM_SEED)));
        return (randomHash % (max - min + 1)) + min;
    }

    // 開始新一局比賽
    function startNewRace() public payable {
        require(msg.value >= BET_AMOUNT, "Insufficient bet amount");
        require(currentBetAmount == 0, "Previous bet is still in progress");

        // 初始化四匹馬
        for (uint256 i = 0; i < 4; i++) {
            horses.push(generateHorse());
        }

        currentRaceIndex++;
        currentBetAmount = BET_AMOUNT;
    }

    // 選擇下注的馬匹
    function placeBet(uint256 horseIndex) public payable {
        require(msg.value >= BET_AMOUNT, "Insufficient bet amount");
        require(horseIndex < horses.length, "Invalid horse index");
        require(currentBetAmount == 0, "Previous bet is still in progress");

        currentBetHorseIndex = horseIndex;
        currentBetAmount = msg.value;
    }

    // 結算比賽結果
    function settleRace() public {
        require(currentBetAmount > 0, "No bet in progress");

        uint256 totalY = 0;
        uint256 DISTANCE = getRandomNumber(1, 4, 4)*400;
        uint256[] memory results = new uint256[](horses.length);

        // 計算每匹馬的結果
        for (uint256 i = 0; i < horses.length; i++) {
            Horse memory horse = horses[i];
            uint256 state = horse.state + STATE_FACTOR-2;
            uint256 speed = horse.speed * state / STATE_FACTOR;
            uint256 stamina = horse.stamina * state / STATE_FACTOR;
            int256 x = 20 * int(stamina) - int(DISTANCE);
            uint256 y;
            if (x > 0) {
                y = speed * DISTANCE;
            } else {
                y = speed * DISTANCE - (7 * speed * uint256(x)) / 10;
            }
            totalY += y;
            results[i] = y;
        }

        // 找到隨機數對應的獲勝馬匹
        uint256 randomNumber = getRandomNumber(0, totalY - 1, 5);
        uint256 cumulativeY = 0;
        uint256 winningHorseIndex;
        for (uint256 i = 0; i < results.length; i++) {
            cumulativeY += results[i];
            if (randomNumber < cumulativeY) {
                winningHorseIndex = i;
                break;
            }
        }

        raceResults.push(RaceResult(winningHorseIndex, false));

        // 檢查是否贏得下注
        if (winningHorseIndex == currentBetHorseIndex) {
            uint256 winningAmount = currentBetAmount + (currentBetAmount * WINNING_MULTIPLIER) / 100;
            payable(msg.sender).transfer(winningAmount);
            raceResults[currentRaceIndex - 2].isBetWon = true;
        }

        // 重置狀態
        delete horses;
        currentBetHorseIndex = 0;
        currentBetAmount = 0;
    }
}