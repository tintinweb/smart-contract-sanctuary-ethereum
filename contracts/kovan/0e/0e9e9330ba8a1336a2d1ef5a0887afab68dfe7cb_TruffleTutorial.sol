/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

//SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.4.22 <0.9.0;

contract TruffleTutorial {
  address public owner = msg.sender;
  string public message;

  // this function runs when the contract is deployed
  constructor() {
    // set initial message
    message = "Prigent pour juju Hello World!";
  }

  modifier ownerOnly() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }
  // function that only contract owner can run, to set a new message
  function setMessage(string memory _message) 
    public 
    ownerOnly 
    returns(string memory) 
  {
    // message must not be empty
    require(bytes(_message).length > 0);

    // set new message
    message = _message;
    return message;
  }
}