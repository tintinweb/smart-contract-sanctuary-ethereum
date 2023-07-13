// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    string greeeting = '';

    constructor() payable {
       greeeting = 'hello';
    }

    

	  function getGreeting() public view returns(string memory){
			return greeeting;
		} 
}