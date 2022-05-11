// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
interface BluesStaking {
	function getTokenOwner(uint tokenID) external view returns(address);
}

contract BluesTranslationProxy {
	BluesStaking internal bluesStaking = BluesStaking(0x569Cc6a45a008D94473C2a7F476e6C54A9354A3F);

	function ownerOf(uint tokenID) external view returns (address) {
			return bluesStaking.getTokenOwner(tokenID);
	}
}