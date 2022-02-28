/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

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
}


contract TestContract {
	event ResultVal(uint256 id);
	CallerAuthenticatorInterface private authenticator;
	constructor (address authenticatorAddress) {
		authenticator = CallerAuthenticatorInterface(authenticatorAddress);
	}

	function test(uint256 request_id, bytes32 message) public returns (uint256) {
		uint256 result = authenticator.processAuthentication(request_id, message, msg.sender);
		emit ResultVal(result);
		return result;
	}
}