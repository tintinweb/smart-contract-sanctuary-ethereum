// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

contract WalletOfOwnerHelper {

    function walletOfOwner(address collectionAddress, address owner, uint256 startTokenID, uint256 endTokenID) public view returns (uint256[] memory) {
        IERC721 collection = IERC721(collectionAddress);
        uint256[] memory ownerTokens = new uint256[](collection.balanceOf(owner));
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for(uint256 i = startTokenID; i <= endTokenID; i++) {
            try collection.ownerOf(i) returns (address result) { currOwnershipAddr = result; } catch { currOwnershipAddr = address(0); }
            if(currOwnershipAddr == owner) {
                ownerTokens[tokenIdsIdx++] = i;
            }
            if(tokenIdsIdx == ownerTokens.length) { break; }
        }
        return ownerTokens;
    }
}