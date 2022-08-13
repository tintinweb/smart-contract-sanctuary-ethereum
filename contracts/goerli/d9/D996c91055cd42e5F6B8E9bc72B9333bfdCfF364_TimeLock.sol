/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract TimeLock {
  uint256 private constant _version = 1;
  address private immutable _your_team_account;

  constructor() public payable {
    _your_team_account = msg.sender;
  }

  modifier onlyYourTeam() {
    require(msg.sender == _your_team_account, 'not-your-team-account');
    _;
  }

  mapping(address => uint256) public balances;
  mapping(address => uint256) public lockTime;

  function deposit() public payable onlyYourTeam {
    balances[msg.sender] += msg.value;
    lockTime[msg.sender] = now + 1 weeks;
  }

  function increaseLockTime(uint256 _secondsToIncrease) public onlyYourTeam {
    lockTime[msg.sender] += _secondsToIncrease;
  }

  function withdraw() public onlyYourTeam {
    require(balances[msg.sender] > 0);
    require(now > lockTime[msg.sender]);
    msg.sender.transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }
}