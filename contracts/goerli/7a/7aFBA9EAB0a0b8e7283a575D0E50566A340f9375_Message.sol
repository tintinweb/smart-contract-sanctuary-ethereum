// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Message {
   string private message ="hello world";

    function setMessage(string memory _message) public  {
        message = _message;
    }
    
   function getMessage() public view returns (string memory) {
    return message;
   }
}