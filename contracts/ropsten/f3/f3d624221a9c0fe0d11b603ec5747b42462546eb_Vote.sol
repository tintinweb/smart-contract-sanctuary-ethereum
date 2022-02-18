/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.7;

contract Vote {
  
    event Voted(address indexed voter, uint8 proposal);

    mapping(address => bool) public voted; // 记录已经进行了投票的地址

    uint256 public endTime; // 记录投票的终止时间

    // 应该这是有三个分类，为的票的数量
    uint256 public proposalA;
    uint256 public proposalB;
    uint256 public proposalC;

    // 构造函数
    constructor(uint256 _endTime) {
        endTime = _endTime;
    }

    function vote(uint8 _proposal) public {
        require(block.timestamp < endTime, 'Vote expired.');
        require(_proposal >= 1 && _proposal <= 3, 'Invalid proposal.');
        require(!voted[msg.sender], 'Cannot vote again.');
        voted[msg.sender] = true;
        if (_proposal == 1) {
            proposalA++;
        } else if (_proposal == 2) {
            proposalB++;
        } else if (_proposal == 3) {
            proposalC++;
        }
        emit Voted(msg.sender, _proposal);
    }

    function votes() public view returns (uint256) {
        return proposalA + proposalB + proposalC;
    }
}