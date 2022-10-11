// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract RewardSmoothingProtocol2 {
	mapping(address => bytes) validator;

	event RequestWithdrawal(bytes pubKey);
	event RewardsRecieved(uint256 value, uint256 indexed timestamp);
	event ValidatorRegistered(address indexed eth1_addr, string validator);
	event Withdrawal(address eth1_addr, bytes validator, uint256 value);

	function register(bytes memory pubKey) external payable {
		require(msg.value >= 0.001 ether, "R: not enough eth send");
		require(pubKey.length == 98, "R: pubKey with wrong format");
		require(pubKey[0] == "0", "R: make sure it uses 0x");
		require(pubKey[1] == "x", "R: make sure it uses 0x");

		validator[msg.sender] = pubKey;
		emit ValidatorRegistered(msg.sender, string(pubKey));
	}

	function requestWithdrawal() external returns (bytes32 requestId) {
		bytes memory pubKey = validator[msg.sender];
		require(bytes(pubKey).length > 0, "RSP: Validator not registered");
		emit RequestWithdrawal(pubKey);
	}

	function fulfillWithdrawal() external {
		
	}

	receive () external payable {
		emit RewardsRecieved(msg.value, block.timestamp);
	}
}