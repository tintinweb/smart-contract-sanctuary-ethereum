/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Vote {
    // Voted事件，有两个相关值:
    event Voted(address indexed voter, uint8 proposal);
// 记录已投票的地址:
    mapping(address => bool) public voted;
 // 记录投票终止时间:
    uint256 public endTime;
 // 记录得票数量:
    uint256 public proposalA;
    uint256 public proposalB;
    uint256 public proposalC;
    // 构造函数:
    constructor(uint256 _endTime) {
        endTime = _endTime;
    }

    function vote(uint8 _proposal) public {
        ////区块时间戳
        require(block.timestamp < endTime, "Vote expired."); //投票过期了。
        require(_proposal >= 1 && _proposal <= 3, "Invalid proposal."); //无效的提议。
        require(!voted[msg.sender], "Cannot vote again."); //不能投票
        // 给mapping增加一个key-value:
        voted[msg.sender] = true;
        if (_proposal == 1) {
            // 修改proposalA:
            proposalA ++;
        }
        else if (_proposal == 2) {
               // 修改proposalB:
            proposalB ++;
        }
        else if (_proposal == 3) {
             // 修改proposalC:
            proposalC ++;
        }
        //触发事件
        emit Voted(msg.sender, _proposal);
    }
    //计算一个多少票
    function votes() public view returns (uint256) {
        return proposalA + proposalB + proposalC;
    }
}