// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract RewardSmoothingProtocol {
	uint256 counter;

	event RewardsRecieved(uint256 value, address sender);

	function increment() external {
		counter++;
	}

	receive () external payable {
		// Recieve validators proposal blocks rewards
		emit RewardsRecieved(msg.value, msg.sender);
	}
}