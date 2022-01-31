/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

pragma solidity ^0.8.0;

interface NFT {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract checkUnclaimedBulk {

    function checkUnclaimed(uint256 tokenStart, uint256 tokenEnd, address collection) external view returns (uint256[] memory) {
        NFT nft = NFT(collection);
        uint256[] memory unclaimed = new uint256[](tokenEnd - tokenStart +1);
        uint256 count;
        for (uint i = tokenStart; i<=tokenEnd; i++) {
                try nft.ownerOf(i) returns (address) {
                } catch {
                    unclaimed[count]=i;
                    count++;                
                }

            }
        return unclaimed;
    }
}