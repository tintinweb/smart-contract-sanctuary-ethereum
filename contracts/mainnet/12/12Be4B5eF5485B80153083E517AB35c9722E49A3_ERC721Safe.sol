// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title BluesTranslationProxy
 * @dev Translate the getters of the Blues contract to the proxy contract.
 */

interface ERC721 {
	function ownerOf(uint tokenID) external view returns(address);
}

contract ERC721Safe {

	function ownerOf(uint tokenID) external returns (address) {
		 (bool success, bytes memory returnData) = address(0x427cE6c9E2a504aEB22dc3839FbC4f4B6ebD75bb).call(
			 abi.encodePacked(
			 ERC721.ownerOf.selector,
			 tokenID)
		);
		 if (!success) {
			 return 0x0000000000000000000000000000000000000000;
		 }
		return abi.decode(returnData, (address));
	}
}