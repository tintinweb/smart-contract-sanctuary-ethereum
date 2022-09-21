// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HelloWorld 
{
	string public message;
	
	event UpdateMessage(string oldStr, string newStr);
	
	constructor(string memory initMessage)
	{
		message = initMessage;
	}
	
	function update(string memory newMessage) public 
	{
		string memory oldMessage = message;
		message = newMessage;
		emit UpdateMessage(oldMessage, newMessage);
	}
}