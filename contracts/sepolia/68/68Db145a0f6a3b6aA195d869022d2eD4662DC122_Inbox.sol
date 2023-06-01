/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.9;

contract Inbox{

	string public message; 

	constructor(string memory _initialMessage){
		message = _initialMessage;
	}	

	function setMessage(string memory _newMessage) public {
		message = _newMessage;
	}	

}