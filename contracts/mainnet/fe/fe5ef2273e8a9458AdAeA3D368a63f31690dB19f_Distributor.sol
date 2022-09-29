//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";

interface IPool {
    function giveRewards(uint256 amount) external;
}

contract Distributor is Ownable {

    address public constant kawa = 0x5552E5a89A70cB2eF5AdBbC45a6BE442fE7160Ec;

    address public pool0 = 0x8F7d8b15086bBeCeCBA4807934e189629ca2363a;
    address public pool1 = 0xf7Fc6D44F47FCF645D1EC1d3E82A0C11A85BA760;
    address public pool2 = 0x9E5f0F027038f1510cCf5623D6E08739DD89754C;

    uint256 public amount0 = 187615756000000;
    uint256 public amount1 = 557023700000;
    uint256 public amount2 = 4219877400000;

    uint256 public lastTriggered;

    constructor() {
        lastTriggered = block.number;
        approveAllPools();
    }

    function setAllocations(
        uint amt0, uint amt1, uint amt2
    ) external onlyOwner {
        amount0 = amt0;
        amount1 = amt1;
        amount2 = amt2;
    }

    function setPools(
        address pool0_, address pool1_, address pool2_
    ) external onlyOwner {
        pool0 = pool0_;
        pool1 = pool1_;
        pool2 = pool2_;
        approveAllPools();
    }

    function withdraw(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function resetTimer() external onlyOwner {
        lastTriggered = block.number;
    }

    function approveAllPools() public {
        IERC20(kawa).approve(pool0, type(uint256).max);
        IERC20(kawa).approve(pool1, type(uint256).max);
        IERC20(kawa).approve(pool2, type(uint256).max);
    }

    function trigger() external {

        // time since last trigger
        uint timeSinceLastTrigger = timeSince();

        // reset time
        lastTriggered = block.number;

        // send amounts to all different pools
        _send(pool0, timeSinceLastTrigger * amount0);
        _send(pool1, timeSinceLastTrigger * amount1);
        _send(pool2, timeSinceLastTrigger * amount2);
    }

    function timeSince() public view returns (uint256) {
        return lastTriggered < block.number ? block.number - lastTriggered : 0;
    }

    function pending0() external view returns (uint256) {
        return timeSince() * amount0;
    }

    function pending1() external view returns (uint256) {
        return timeSince() * amount1;
    }

    function pending2() external view returns (uint256) {
        return timeSince() * amount2;
    }

    function _send(address pool, uint amount) internal {
        if (amount == 0 || pool == address(0)) {
            return;
        }
        IPool(pool).giveRewards(amount);
    }

    function kawaBalance() public view returns (uint256) {
        return IERC20(kawa).balanceOf(address(this));
    }

    function totalPending() public view returns (uint256) {
        return timeSince() * ( amount0 + amount1 + amount2 );
    }
}