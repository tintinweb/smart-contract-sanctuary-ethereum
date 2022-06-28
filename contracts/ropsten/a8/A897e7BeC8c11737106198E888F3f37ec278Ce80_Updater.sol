// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Updater {

    uint256 public number;
    uint256 public constant updateFee = 200;

    mapping(address => uint256) public stakedAmount;

    function updateNumber(uint256 _num) external {
        require(stakedAmount[msg.sender] >= updateFee, "Not enough staked");
        stakedAmount[msg.sender] -= updateFee;
        number = _num;
    }

    function stakeTokens(uint256 amount) external {
        stakedAmount[msg.sender] += amount;
    }

    function unstakeTokens(uint256 amount) external {
        uint256 userAmount = stakedAmount[msg.sender];
        if (amount > userAmount) {
            amount = userAmount;
        }

        stakedAmount[msg.sender] -= amount;
    }

}