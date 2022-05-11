/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

pragma solidity ^0.4.17;

contract Inbox{
  string public message;

  function getMessage() public view returns(string) {
    return message;
  }
  function setMessage(string newMessage) public {
    message = newMessage;
    
  }
}