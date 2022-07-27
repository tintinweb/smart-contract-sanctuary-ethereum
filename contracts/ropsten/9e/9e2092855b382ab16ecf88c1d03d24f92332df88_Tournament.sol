/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Tournament {
    string public name = "Tournament Name";
    uint public status = 0;
    uint256 public prize_pool = 0;
    uint256 public register_fee = 10000;
    address public owner;

    mapping(address => bool) public participants;

    constructor(string memory _name, uint256 _register_fee) {
        owner = msg.sender;
        name = _name;
        register_fee = _register_fee;
    }

    // [owner] 开始报名
    function startRegister() external {
        require(status == 0, "wrong status");
        status = 1;
    }

    // [选手] 报名
    function register() external payable returns (bool) {
        require(status == 1, "Can not register");
        require(participants[msg.sender]!=true, "Already registered");
        require(msg.value == register_fee, "Wrong register fee");
        participants[msg.sender] = true;
        prize_pool += msg.value;
        return true;
    }

    // [owner] 开始比赛

    // [all] 获取对战

    // [owner] 记录比赛结果

    // [owner] 结束比赛

    // [冠军] 拿奖励
}