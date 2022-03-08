/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract UAChat {
  address public owner = msg.sender;

struct UAMessage {
    address sender;
    address receiver;
    string message;
    uint createdAt;
}


  string public title;

  mapping (address => UAMessage[]) private uaMessages;

  event SentMessage(address from, address to, string _message);


  // this function runs when the contract is deployed
  constructor() {
    // set initial title
    title = "UAChat";
  }

  modifier ownerOnly() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }
  
  // function that only contract owner can run, to set a new message
  function setTitle(string memory _title) 
    public 
    ownerOnly 
    returns(string memory) 
  {
    // title must not be empty
    require(bytes(_title).length > 0);

    // set new title
    title = _title;
    return title;
  }

  function sendMessage(address _receiver, string memory _message) public returns(bool success)  {
      // message must not be empty
      require(bytes(_message).length > 0);
      // send message to x
      UAMessage memory uaMessage;
      uaMessage.sender = msg.sender;
      uaMessage.receiver = _receiver;
      uaMessage.message = _message;
      uaMessage.createdAt = block.timestamp;
      uaMessages[msg.sender].push(uaMessage);
      uaMessages[_receiver].push(uaMessage);

      emit SentMessage(msg.sender, _receiver, _message);
      return true;
  }

  //get all the strings in array form
  function getMessages() view public returns(UAMessage[] memory) {
      return uaMessages[msg.sender];
  }
}