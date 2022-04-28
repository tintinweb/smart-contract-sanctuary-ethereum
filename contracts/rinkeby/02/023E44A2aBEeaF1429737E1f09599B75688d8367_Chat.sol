/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Chat {
  struct Message {
    string message;
    uint256 time;
  }


  // Chat logic
  event MessageSent(address indexed from, address indexed to);
  mapping(address => string) private aliases; // alias of accounts
  mapping(address => mapping(address => Message[])) private chat; // chat history

  // Entry-fee to interact with contract 
  uint256 private entryFee;
  mapping(address => bool) private hasPaidFee; // keep track of which users have paid entry fee
  modifier feePaid() {
    require(hasPaidFee[msg.sender], "User must pay the entry fee first.");
    _;
  }

  // Make ownable
  address private owner;
  modifier ownerOnly() {
    require(msg.sender == owner, "Unauthorized.");
    _;
  }
  function changeOwner(address newOwner) public ownerOnly {
    owner = newOwner;
  }

  // Self-destruct this contract
  function selfDestruct() public ownerOnly {
    selfdestruct(payable(owner));
  }

  receive() external payable {}

  fallback() external payable {}

  constructor() {
    owner = msg.sender;
    entryFee = 10000 gwei;
  }

  ///////////  CHAT  ////////////
  function sendMessage(string memory _text, address _to) public feePaid {
    chat[msg.sender][_to].push(Message(_text, block.timestamp));
    emit MessageSent(msg.sender, _to);
  }

  function getMessages(address _from, address _to) public view feePaid returns (Message[] memory) {
    require((_from == msg.sender) || (_to == msg.sender), "Either the receiver or sender must be you.");
    return chat[_from][_to];
  }

  //////////// ALIAS ////////////
  function setAlias(string memory _alias) public feePaid {
    require(bytes(_alias).length < 20, "Alias too long");
    aliases[msg.sender] = _alias;
  }

  function getAlias(address user) public view feePaid returns (string memory) {
    return aliases[user];
  }

  ////////////  FEE  ////////////
  function payEntryFee() public payable {
    require(!hasPaidFee[msg.sender], "User has already paid the entry fee.");
    require(msg.value >= entryFee, "Insufficient amount for the entry fee..");

    // send extra back
    if (msg.value > entryFee) {
      payable(msg.sender).transfer(msg.value - entryFee);
    }
 
    hasPaidFee[msg.sender] = true;
  }

  function getUserFeePaid() public view returns (bool) {
    return hasPaidFee[msg.sender];
  }

  function getEntryFee() public view returns (uint256) {
    return entryFee;
  }

  function changeEntryFee(uint256 amount) public ownerOnly {
    entryFee = amount;
  }
}