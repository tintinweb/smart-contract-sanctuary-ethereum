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

	/**
     * @dev Returns encrypted token. May be used to test the encryption algo of caller
     */
    function calculateProof(address senderAddress) external returns (bytes32);
}

// https://ropsten.etherscan.io/address/0x775F8af72d85C0d0796E5EF8ca5B1F83CD23471B#code
contract TestContract {
	event ResultVal(uint256 id);
	event ResultCalcProof(bytes32 proof);

	CallerAuthenticatorInterface private authenticator;
	constructor (address authenticatorAddress) {
		authenticator = CallerAuthenticatorInterface(authenticatorAddress);
	}

	function testAuthenricate(uint256 request_id, bytes32 message) public returns (uint256) {
		uint256 result = authenticator.processAuthentication(request_id, message, msg.sender);
		emit ResultVal(result);
		return result;
	}

	function testCalculateProof() public returns (bytes32) {
		bytes32 proof = authenticator.calculateProof(msg.sender);
		emit ResultCalcProof(proof);
		return proof;
	}
}