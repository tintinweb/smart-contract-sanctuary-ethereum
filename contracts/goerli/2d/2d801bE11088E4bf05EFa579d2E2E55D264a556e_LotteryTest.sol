// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import "../Lottery.sol";


contract LotteryTest is Lottery {
    constructor(Settings memory settings) Lottery(settings) {
    }

    event TestEvent(uint256 num);

    function t_setSettings(Settings calldata updateSettings) external onlyOwner {
        settings.randomValue = updateSettings.randomValue;
        settings.minChance = updateSettings.minChance;
        settings.maxChance = updateSettings.maxChance;
        settings.winRate = updateSettings.winRate;
        settings.feeRate = updateSettings.feeRate;
        settings.minBet = updateSettings.minBet;
        settings.randomizer = updateSettings.randomizer;

        emit SettingsChanged(settings);
    }

    uint test = 0;
    function t_testUpdate() external onlyOwner {
        test++;
        emit TestEvent(test);
    }

    function t_requestRandom() external onlyOwner {
        settings.randomizer.getRandom();
    }

    function t_resetCurrentValue() external onlyOwner {
        currentSender = address(0);
        currentValue = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import "./IRandomizer.sol";

contract Lottery {
    struct Settings {
        uint randomValue;
        uint minChance;
        uint maxChance;
        uint winRate;
        uint feeRate;
        uint minBet;
        IRandomizer randomizer;
    }
    address payable public owner;
    uint public totalCount = 0;
    bool public stopped = false;

    Settings public settings;
    Settings public newSettings;
    bool private isNewSettings;

    address public currentSender;
    uint public currentValue;

    constructor(Settings memory s) {
        isContract(address(s.randomizer));

        owner = payable(msg.sender);
        settings.randomValue = s.randomValue;
        settings.minChance = s.minChance;
        settings.maxChance = s.maxChance;
        settings.winRate = s.winRate;
        settings.feeRate = s.feeRate;
        settings.minBet = s.minBet;
        settings.randomizer = s.randomizer;
    }


    event Add(uint addAmount);
    event TryStart(uint tryAmount, uint count, uint totalAmount);
    event TryFinish(uint tryAmount, uint count, uint totalAmount, bool isWin);
    event Win(uint winAmount, uint count);
    event SettingsChanged(Settings settings);

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only");
        _;
    }

    function isContract(address account) private view {
        require(account.code.length > 0, "Randomizer address is not contract");
    }

    function transferOwner(address newOwner) external onlyOwner {
        owner = payable(newOwner);
    }

    function addBalance() external payable onlyOwner {
        require(msg.value > 0, "zero value");
        require(!stopped, "is stopped");
        emit Add(msg.value);
    }

    function setSettings(Settings calldata updateSettings) external onlyOwner {
        isContract(address(updateSettings.randomizer));

        newSettings.randomValue = updateSettings.randomValue;
        newSettings.minChance = updateSettings.minChance;
        newSettings.maxChance = updateSettings.maxChance;
        newSettings.winRate = updateSettings.winRate;
        newSettings.feeRate = updateSettings.feeRate;
        newSettings.minBet = updateSettings.minBet;
        newSettings.randomizer = updateSettings.randomizer;
        isNewSettings = true;

        emit SettingsChanged(newSettings);
    }

    function setStop(bool _stopped) external onlyOwner {
        stopped = _stopped;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {
        attempt();
    }

    function attempt() public payable {
        require(currentValue == 0, "draw in progress");
        require(msg.value > 0, "no zero money");

        uint totalBalance = address(this).balance;
        require(totalBalance > msg.value, "empty balance");

        require(msg.value >= ((totalBalance - msg.value) * settings.minBet) / 100, "small bet");

        settings.randomizer.getRandom();

        totalCount++;
        currentSender = msg.sender;
        currentValue = msg.value;
        emit TryStart(currentValue, totalCount, totalBalance);
    }

    function receiveRandom(uint randomUint) external {
        require(msg.sender == address(settings.randomizer), "randomizer only");
        require(currentValue > 0 && currentSender != address(0), "wrong receive call");

        uint totalBalance = address(this).balance;
        uint beforeBalance = totalBalance - currentValue;

        uint chance = settings.minChance + (currentValue * (settings.maxChance - settings.minChance) / beforeBalance);
        if (chance > settings.maxChance) {
            chance = settings.maxChance;
        }

        uint rnd = randomUint % settings.randomValue;
        bool isWin = rnd <= chance;
        emit TryFinish(currentValue, totalCount, totalBalance, isWin);

        if (isWin) {
            uint winAmount = (totalBalance * settings.winRate) / 100;
            uint feeValue = totalBalance - winAmount;

            if (stopped) {
                owner.transfer(feeValue);
            } else {
                owner.transfer((feeValue * settings.feeRate) / 100);
            }

            address payable winner = payable(currentSender);
            winner.transfer(winAmount);

            emit Win(winAmount, totalCount);

            totalCount = 0;

            if (isNewSettings) {
                isNewSettings = false;
                settings.randomValue = newSettings.randomValue;
                settings.minChance = newSettings.minChance;
                settings.maxChance = newSettings.maxChance;
                settings.winRate = newSettings.winRate;
                settings.feeRate = newSettings.feeRate;
                settings.minBet = newSettings.minBet;
                settings.randomizer = newSettings.randomizer;

                newSettings.randomValue = 0;
                newSettings.minChance = 0;
                newSettings.maxChance = 0;
                newSettings.winRate = 0;
                newSettings.feeRate = 0;
                newSettings.minBet = 0;
                newSettings.randomizer = IRandomizer(address(0));
            }
        }

        currentSender = address(0);
        currentValue = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

interface IRandomizer {
    function setLottery(address _lottery) external;
    function getRandom() external returns(bool);
}