/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract ASOH_Snapshot {

    function snapshotBalance(
        address nft, 
        uint256 from, 
        uint256 to, 
        address account
    ) public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](from - to);
        uint256 count = 0;
        IERC721 iNft = IERC721(nft);
        for (uint256 i = from; i < to; i++) {
            address owner = iNft.ownerOf(i);
            if (owner == account) {
                tokenIds[count] = i;
                count++;
            }
        }

        return tokenIds;
    }
}