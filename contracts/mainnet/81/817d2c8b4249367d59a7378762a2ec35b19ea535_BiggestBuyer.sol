/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library BiggestBuyer {
    struct Data {
        uint256 initHour;
        uint256 rewardFactor;
        mapping(uint256 => address) biggestBuyerAccount;
        mapping(uint256 => uint256) biggestBuyerAmount;
        mapping(uint256 => uint256) biggestBuyerPaid;
    }

    uint256 private constant FACTOR_MAX = 10000;

    event UpdateBiggestBuyerRewordFactor(uint256 value);

    event BiggestBuyerPayout(uint256 hour, address indexed account, uint256 value);

    function init(Data storage data) public {
        data.initHour = getCurrentHour();
        updateRewardFactor(data, 500); //5% from liquidity
    }

    function updateRewardFactor(Data storage data, uint256 value) public {
        require(value <= 1000, "invalid biggest buyer reward percent"); //max 10%
        data.rewardFactor = value;
        emit UpdateBiggestBuyerRewordFactor(value);
    }

    function getCurrentHour() private view returns (uint256) {
        return block.timestamp / (1 hours);
    }

    // starts at 0 and increments at the turn of the hour every hour
    function getHour(Data storage data) public view returns (uint256) {
        uint256 currentHour = getCurrentHour();
        return currentHour - data.initHour;
    }

    function handleBuy(Data storage data, address account, uint256 amount) public {
        uint256 hour = getHour(data);

        if(amount > data.biggestBuyerAmount[hour]) {
            data.biggestBuyerAmount[hour] = amount;
            data.biggestBuyerAccount[hour] = account;
        }
    }

    function calculateBiggestBuyerReward(Data storage data, uint256 liquidityTokenBalance) public view returns (uint256) {
        return liquidityTokenBalance * data.rewardFactor / FACTOR_MAX;
    }

    function payBiggestBuyer(Data storage data, uint256 hour, uint256 liquidityTokenBalance) public returns (address, uint256) {
        require(hour < getHour(data), "Hour is not complete");
        if(
            data.biggestBuyerAmount[hour] == 0 ||
            data.biggestBuyerPaid[hour] > 0) {
            return (address(0), 0);
        }

        address winner = data.biggestBuyerAccount[hour];

        uint256 amountWon = calculateBiggestBuyerReward(data, liquidityTokenBalance);

        //Set to 1 so the check for if payment occurred will succeed
        if(amountWon == 0) {
            amountWon = 1;
        }

        data.biggestBuyerPaid[hour] = amountWon;

        emit BiggestBuyerPayout(hour, winner, amountWon);

        return (winner, amountWon);
    }

    function getBiggestBuyer(Data storage data, uint256 hour) public view returns (address, uint256, uint256) {
        return (
            data.biggestBuyerAccount[hour],
            data.biggestBuyerAmount[hour],
            data.biggestBuyerPaid[hour]);
    }
}