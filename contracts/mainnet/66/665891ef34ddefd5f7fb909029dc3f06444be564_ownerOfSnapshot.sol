/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Easy Snapshotting of ERC721 Owners 

// Note: Make sure that if you are querying an ERC721 which
// reverts on ownerOf address(0) to omit those tokenIds in the
// passed array argument.

// Author: 0xInuarashi
// https://twitter.com/0xinuarashi || 0xInuarashi#1234

interface iERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract ownerOfSnapshot {
    function snapshotOwnerOf(address contract_, uint256[] calldata tokenIds_) 
    external view returns (address[] memory) {
        uint256 l = tokenIds_.length;
        address[] memory _addresses = new address[](l);
        for (uint256 i = 0; i < l; i++) {
            _addresses[i] = iERC721(contract_).ownerOf(tokenIds_[i]);
        }
        return _addresses;
    }    
}