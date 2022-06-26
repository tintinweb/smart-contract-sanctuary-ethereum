/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: GPL-3.0
// 指定编译器版本为0.8.7
pragma solidity =0.8.7;

contract Vote {

    event Voted(address indexed voter, uint8 proposal);
// 记录已投票的地址:
    mapping(address => bool) public voted;
// 记录投票终止时间:
    uint256 public endTime;
// 记录得票数量:
    uint256 public proposalA;
    uint256 public proposalB;
    uint256 public proposalC;

    constructor(uint256 _endTime) {
        endTime = _endTime;
    }

function vote(uint8 _proposal) public {
//如果断言失败，将抛出错误并中断执行。
        require(block.timestamp < endTime, "Vote expired.");
        require(_proposal >= 1 && _proposal <= 3, "Invalid proposal.");
// msg.sender表示调用方地址:

        require(!voted[msg.sender], "Cannot vote again.");
        voted[msg.sender] = true;
        if (_proposal == 1) {
            proposalA ++;
        }
        else if (_proposal == 2) {
            proposalB ++;
        }
        else if (_proposal == 3) {
            proposalC ++;
        }
        emit Voted(msg.sender, _proposal);
    }

    function votes() public view returns (uint256) {
        return proposalA + proposalB + proposalC;
    }
}