/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721Enumerable is ERC721 {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract CollectNFTData{
    function getERC721TokenIDs(address contractAddress) public view returns (uint256[] memory){
        ERC721Enumerable assetContract = ERC721Enumerable(contractAddress);

        uint256 totalSupply = assetContract.totalSupply();
        uint256[] memory tokenIDs = new uint256[](totalSupply);
        for(uint256 i = 0; i < totalSupply; i++){
            tokenIDs[i] = assetContract.tokenByIndex(i);
        }

        return tokenIDs;
    }
}