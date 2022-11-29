/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

pragma solidity ^0.4.17;

contract HelloWorld {
 // Define variable message of type string
 string message;

 // Write function to change the value of variable message
 function postMessage(string value) public returns (string) {
 message = value;
 return message;
 }
 
 // Read function to fetch variable message
 function getMessage() public view returns (string){
 return message;
 }
}