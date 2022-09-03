// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract CallFunc {
	address payable public owner;
	address payable public target = payable(0xd33C69361e00f01C3085ac77ab2fA13bE10376E8);

	constructor() payable {
		owner = payable(msg.sender);
	}

	event Response(bool success, bytes data);

	function transferToContract() external {
		require(address(this).balance >= 0.001 ether, 'Should > 0.001 ether');
		require(msg.sender == owner, 'Olny owner :)');

		// Send ether
		(bool success, bytes memory data) = target.call{ value: 0.001 ether }('');

		require(success, 'Transfer ether to contract failed');

		emit Response(success, data);
	}

	function claimFromContract() external {
		require(msg.sender == owner, 'Olny owner :)');

		// Claim ether
		(bool success, bytes memory data) = target.call(
			abi.encodeWithSignature('claim(uint256)', 1)
		);

		require(success, 'Claim from contract failed');

		emit Response(success, data);
	}

	function interactive() external {
		require(address(this).balance >= 0.001 ether, 'Should > 0.001 ether');
		require(msg.sender == owner, 'Olny owner :)');

		// Send ether
		(bool success, bytes memory data) = target.call{ value: 0.001 ether }('');

		require(success, 'Transfer ether to contract failed');

		emit Response(success, data);

		// Claim ether
		(bool successClaim, bytes memory dataClaim) = target.call(
			abi.encodeWithSignature('claim(uint256)', 1)
		);

		emit Response(successClaim, dataClaim);

		require(successClaim, 'Claim failed');
	}

	function claim() external {
		require(msg.sender == owner, 'Olny owner :)');

		(bool success, bytes memory data) = owner.call{ value: address(this).balance }('');

		require(success, 'Failed to claim Ether');

		emit Response(success, data);
	}
}