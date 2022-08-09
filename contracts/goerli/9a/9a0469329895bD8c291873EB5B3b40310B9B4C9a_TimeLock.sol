// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract TimeLock {
  address private immutable _deployer;

  constructor() public payable {
    _deployer = msg.sender;
  }

  modifier onlyDeployer() {
    require(msg.sender == _deployer, 'not-deployer');
    _;
  }

  mapping(address => uint256) public balances;
  mapping(address => uint256) public lockTime;

  function deposit() public payable onlyDeployer {
    balances[msg.sender] += msg.value;
    lockTime[msg.sender] = now + 1 weeks;
  }

  function increaseLockTime(uint256 _secondsToIncrease) public onlyDeployer {
    lockTime[msg.sender] += _secondsToIncrease;
  }

  function withdraw() public onlyDeployer {
    require(balances[msg.sender] > 0);
    require(now > lockTime[msg.sender]);
    msg.sender.transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }
}