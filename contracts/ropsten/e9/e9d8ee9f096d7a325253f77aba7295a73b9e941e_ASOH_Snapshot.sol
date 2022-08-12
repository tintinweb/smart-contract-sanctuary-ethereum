/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address account) external view returns (uint256);
}

contract ASOH_Snapshot {

    function snapshotBalance(
        address nft, 
        uint256 from, 
        uint256 to, 
        address account
    ) public view returns (uint256[] memory) {
        
        uint256 count = 0;
        IERC721 INFT = IERC721(nft);
        uint256[] memory tokenIds = new uint256[](INFT.balanceOf(account));
        for (uint256 i = from; i < to; i++) {
            address owner = INFT.ownerOf(i);
            if (owner == account) {
                tokenIds[count] = i;
                count++;
            }
        }

        return tokenIds;
    }
}