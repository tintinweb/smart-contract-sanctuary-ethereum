// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.17;


contract HelloWorld
{
	event UpdatedMessages(string oldString, string newString);

	string public message;

	constructor(string memory initMessage)
	{
		message = initMessage;
	}

	function GetMessage() public view returns(string memory)
	{
		return message;
	}

	function Update(string memory newMessage) public
	{
		string memory oldMessage = message;
		message = newMessage;
		emit UpdatedMessages(oldMessage, newMessage);
	}
}