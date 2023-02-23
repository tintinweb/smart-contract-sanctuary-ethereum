/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

/**
 *Submitted for verification at FtmScan.com on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTMigratooor {
	function migrate(IERC721 collection, address to, uint256[] calldata tokenIDs) public {
        uint256 len = tokenIDs.length;
        for (uint256 i = 0; i < len; i++) {
            collection.safeTransferFrom(msg.sender, to, tokenIDs[i]);
        }
	}
}