// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    string greeeting = '';
		string greeting_two = '';

    constructor() {
       greeeting = 'hello';
			 greeting_two = 'hello';
    }

	  function getGreeting() public view returns(string memory){
			return greeeting;
		} 

		function getGreetingTwo() public view returns(string memory){
			return greeting_two;
	}
}