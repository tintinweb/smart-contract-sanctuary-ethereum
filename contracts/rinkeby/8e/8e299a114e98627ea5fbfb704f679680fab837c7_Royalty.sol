/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Royalty {
    uint256 public totalRoyalty; //Total Royalty that is in Contract
    IERC721 public nft; //ERC721 contract

    //Mapping from tokenId to withrawed royalty amount
    mapping(uint256 => uint256) private withrawedAmount;
    
    constructor(IERC721 nftContractAddr) {
        nft = nftContractAddr;
    }

    receive() external payable {
        totalRoyalty = totalRoyalty + msg.value; //when the contract receives royalty, update total royalty
    }

    function withdraw() public {
        for (uint256 i = 0; i < nft.balanceOf(msg.sender); i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, i);
            uint256 totalSupply = nft.totalSupply();
            if (totalRoyalty / totalSupply > withrawedAmount[tokenId]) {
                uint256 pending = totalRoyalty / totalSupply - withrawedAmount[tokenId];
                payable(msg.sender).transfer(pending);
            }
        }
    }
}