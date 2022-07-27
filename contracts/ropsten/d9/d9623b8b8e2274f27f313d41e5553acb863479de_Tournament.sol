/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Tournament {
    string public name = "Tournament Name";
    string public status = "pending";
    uint256 public prize_pool = 0;
    address public owner;

    mapping(address => bool) public participants;

    constructor() {
        owner = msg.sender;
    }

    // [owner] 开始报名
    function startRegister() external {
        status = "registering";
    }

    // [选手] 报名
    function register() external returns (bool) {
        if(participants[msg.sender]) {
            return false;
        }
        participants[msg.sender] = true;
        return true;
    }

    // [owner] 开始比赛

    // [all] 获取对战

    // [owner] 记录比赛结果

    // [owner] 结束比赛

    // [冠军] 拿奖励
}