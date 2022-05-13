// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title BluesTranslationProxy
 * @dev Translate the getters of the Blues contract to the proxy contract.
 */

interface ERC721 {
	function ownerOf(uint tokenID) external view returns(address);
}

contract BluesAggregator {
	ERC721 private immutable bluesNft;
  ERC721 private immutable bluesStaking;
  address constant staking_address = 0x569Cc6a45a008D94473C2a7F476e6C54A9354A3F;

	constructor(address safeERC721Address, address translatedStakingAddress) {
		bluesNft = ERC721(safeERC721Address);
    bluesStaking = ERC721(translatedStakingAddress);
	}

	function ownerOf(uint tokenID) external view returns (address) {
    address owner = bluesNft.ownerOf(tokenID);
    address stakingOwner = bluesStaking.ownerOf(tokenID);
    if (owner != staking_address) {
      return owner;
    } else {
      return stakingOwner;
    }
  }
}