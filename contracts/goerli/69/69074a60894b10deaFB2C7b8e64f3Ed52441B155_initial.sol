/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// Solidity program to implement
// the above approach
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract initial
{
	string public message = "TEST VERIFY";

	function setMessage(string memory _newMessage) public
	{
		message = _newMessage;
	}
}