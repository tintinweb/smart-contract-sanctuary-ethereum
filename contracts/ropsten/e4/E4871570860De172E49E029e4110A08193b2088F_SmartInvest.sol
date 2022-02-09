/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SmartInvest {
  mapping (address => uint256) private _investments;
  address[] private _investors;
  uint256 private _nextPayout;

  constructor() {
  }

  function Invest() payable public {
    if (msg.value == 0)
    {
      revert();
    }
    
    _investors.push(msg.sender);
    _investments[msg.sender] = msg.value;

    uint256 neededPayout = _investments[_investors[_nextPayout]] / 100 * 110;

    while (address(this).balance >= neededPayout)
    {
      address payable sendTo = payable(_investors[_nextPayout]);
      sendTo.transfer(neededPayout);
      _nextPayout++;
      neededPayout = _investments[_investors[_nextPayout]] / 100 * 110;
    }
  }
}