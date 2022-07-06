/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

//"SPDX-License-Identifier:UNLICENSED"
pragma solidity 0.8.7;

contract TestContract {
    // Container of the greeting
    string private greeting;
    
    
    /** @dev Function to set a new greeting.
      * @param newGreeting The new greeting message. 
      */
    function setGreeting(string memory newGreeting) public {
        greeting = newGreeting;
    }
    
    /** @dev Function to greet. 
      * @return The greeting string. 
      */
    function greet() public view returns (string memory) {
        return greeting;
    }
}