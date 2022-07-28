/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/**
一个合约=一个java class
部署一次合约相当于实例化这个java class
调用合约一次，相当于调用这个java bean的一个函数
 */
contract Vote {
  event Voted(address indexed voter, uint8 proposal); //定义事件，用于输出事件，第三方可以查看

  mapping(address => bool) public voted;

  uint256 public endTime;

  //选项
  uint256 public proposalA;
  uint256 public proposalB;
  uint256 public proposalC;

  //初始化构造函数
  constructor(uint256 _endTime) {
    endTime = _endTime;
  }

  /**投票
   */
  function vote(uint8 _proposal) public {
    //区块事件小于活动截止时间
    require(block.timestamp < endTime, 'Vote expired!');
    //只有3个选项
    require(_proposal >= 1 && _proposal <= 3, 'Invalid proposal.');
    //每个用户只能投一次票
    require(!voted[msg.sender], 'Cannot vote again.');
    //记录投票
    voted[msg.sender] = true;
    if (_proposal == 1) {
      proposalA++;
    } else if (_proposal == 2) {
      proposalB++;
    } else if (_proposal == 3) {
      proposalC++;
    }
    //发送event
    emit Voted(msg.sender, _proposal);
  }

  /**
  返回总票数
  带view 是只读方法
 */
  function votes() public view returns (uint256) {
    return proposalA + proposalB + proposalC;
  }
}