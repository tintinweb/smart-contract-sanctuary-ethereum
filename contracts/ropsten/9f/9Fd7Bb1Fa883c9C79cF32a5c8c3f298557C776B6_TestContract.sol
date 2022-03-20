// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the CallerAuthenticator using Schnorr protocol
 */
interface CallerAuthenticatorInterface {
    /**
     * @dev Returns the token ID if authenticated. Otherwise, it reverts.
     */
    function processAuthentication(uint256 request_id, bytes32 message, address originAddress) external returns (uint256);

    function calculateProof(address senderAddress) external returns (bytes32);
}

// https://ropsten.etherscan.io/address/0xFc8b533cE7d9e97981A673693ed247a54F86CC30#code
contract TestContract {
	event ResultVal(uint256 id);
	event ResultCalcProof(bytes32 msg, bytes32 proof, address sender, bool result);

	CallerAuthenticatorInterface private authenticator;
	constructor (address authenticatorAddress) {
		authenticator = CallerAuthenticatorInterface(authenticatorAddress);
	}

	function testAuthenricate(uint256 request_id, bytes32 message) public returns (uint256) {
		uint256 result = authenticator.processAuthentication(request_id, message, msg.sender);
		emit ResultVal(result);
		return result;
	}

	function testCalculateProof(bytes32 message) public returns (bytes32, bytes32, address, bool) {
		bytes32 proof = authenticator.calculateProof(msg.sender);
		emit ResultCalcProof(message, proof, msg.sender, message == proof);
		return (message, proof, msg.sender, message == proof);
	}
}