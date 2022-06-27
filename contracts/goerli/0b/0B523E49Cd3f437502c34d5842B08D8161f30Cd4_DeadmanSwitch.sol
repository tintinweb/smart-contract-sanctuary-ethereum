// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DeadmanSwitch {
  mapping(address => uint256) public balances;
  mapping(address => address) public nominees;
  mapping(address => uint) public unlockTimes;


  function deposit() public payable {
    balances[msg.sender] += msg.value;
  }

  function upDateUnlockTime() public {
    // In goerli testnet, One block takes about 15s, so for 10 blocks => 150s 
    unlockTimes[msg.sender] = block.timestamp + 150;
  }

  function isUnlocked(address _depositorAddress) public view returns (bool) {
    return block.timestamp >= unlockTimes[_depositorAddress];
  }

  function setNominee(address _nominee) public {
    nominees[msg.sender] = _nominee;
  }

  function isTrustee(address _depositorAddress) public view returns (bool) {
    return msg.sender == nominees[_depositorAddress];
  }

  function withdrawBalance(address _depositorAddress) public {
    if (msg.sender == _depositorAddress) {
        payable(msg.sender).transfer(balances[_depositorAddress]);
        balances[msg.sender] = 0;
    }

    if (isTrustee(_depositorAddress) && isUnlocked(_depositorAddress)) {
      payable(nominees[_depositorAddress]).transfer(balances[_depositorAddress]);
      balances[_depositorAddress] = 0;
    }
  }
}