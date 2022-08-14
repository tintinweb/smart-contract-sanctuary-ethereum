// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract MomentumChain {
  struct Record {
    uint256 timestamp;
    string link;
  }
  int256 public recordIndex = -1;
  address public challenger;
  address[] public registeredAddresses;
  Record[] public records;
  uint256 public endDate;
  uint256 public threeTimesBreakCounter;
  mapping(address => uint256) public balances;

  event Register(address);
  event UploadProgress(string link);
  event Distribute(address receiver, uint256 amount);
  event Sent(address to, uint256 amount);

  constructor() {
    challenger = msg.sender;
    endDate = block.timestamp + 21 days;
  }

  function register(address watcherAddress) public {
    registeredAddresses.push(watcherAddress);
  }

  function uploadProgress(string memory link) public {
    recordIndex++;
    records.push(Record(block.timestamp, link));
  }

  error InsufficientBalance(uint256 requested, uint256 available);

  function distribute(address receiver, uint256 amount) public {
    if (block.timestamp < endDate) revert("Challenge has not been ended yet.");

    if (amount > balances[msg.sender])
      revert InsufficientBalance({
        requested: amount,
        available: balances[msg.sender]
      });

    for (uint256 i = 0; i < registeredAddresses.length - 1; i++) {
      balances[msg.sender] -= amount;
      balances[receiver] += amount;
      emit Sent(receiver, amount);
    }
  }
}