// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INft {
    function owner() external view returns (address); //doesn't work
    function name() external view returns (string calldata); //works
    function ownerOf(uint256 tokenId) external view returns (address); //works
}

contract Test {
    //works
    function getNftTokenOwner(address _nft, uint256 _tokenId) external view returns (address){
        return INft(_nft).ownerOf(_tokenId);
    }
    
}