// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract CallFunc {
	address public owner;
	address payable public target = payable(0xd33C69361e00f01C3085ac77ab2fA13bE10376E8);

	constructor() {
		owner = msg.sender;
	}

	event Response(bool success, bytes data);

	function interactive() external payable {
		require(msg.value == 0.001 ether, 'Should match 0.001 ether');
		require(msg.sender == owner, 'Olny owner :)');

		target.transfer(msg.value);

		(bool success, bytes memory data) = target.call(
			abi.encodeWithSignature('claim(uint256)', 1)
		);

		require(success, 'Claim failed');

		emit Response(success, data);
	}
}