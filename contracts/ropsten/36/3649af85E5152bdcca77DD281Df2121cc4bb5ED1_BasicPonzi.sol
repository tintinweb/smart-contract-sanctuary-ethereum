/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract BasicPonzi {
  mapping (address => uint256) private _investments;
  address[] private _investors;
  uint256 private _nextPayout;

  constructor() {
    _investors.push(msg.sender);
    _investments[msg.sender] = 10^18;
  }

  function Invest() payable public {
    if (msg.value == 0)
    {
      revert();
    }
    _investors.push(msg.sender);
    _investments[msg.sender] = msg.value;

    uint256 neededPayout = 2 * _investments[_investors[_nextPayout]];

    if (address(this).balance >= neededPayout)
    {
      address payable sendTo = payable(_investors[_nextPayout]);
      sendTo.transfer(neededPayout);
      _nextPayout++;
    }
  }
}