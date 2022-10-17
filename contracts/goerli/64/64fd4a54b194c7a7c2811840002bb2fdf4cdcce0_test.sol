/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract test {

    function computeNamehash(string memory _name) public pure returns (bytes32 namehash) {
        namehash = bytes32(0);
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
    }

    mapping(uint256 => bytes32) private _tokenIdToHash;
    mapping(uint256 => string) private _tokenIdToName;
    mapping(uint256 => address) private _tokenIdToOwner;

    uint256 private nextTokenId = 1;

    function mint(string memory name) public {
        bytes32 hash = computeNamehash(name);
        _tokenIdToHash[nextTokenId] = hash;
        _tokenIdToName[nextTokenId] = name;
        _tokenIdToOwner[nextTokenId] = msg.sender;
        nextTokenId++;
    }

    function getOwnerOf(uint256 tokenID) public view returns (address) {
        return _tokenIdToOwner[tokenID];
    }

    function getName(uint256 tokenID) public view returns (string memory) {
        return _tokenIdToName[tokenID];
    }

    function getHash(uint256 tokenID) public view returns (bytes32) {
        return _tokenIdToHash[tokenID];
    }

    function balanceOf(address owner) public view returns (uint) {
        uint count;
        for( uint i = 1; i < nextTokenId; ++i ){
          if( owner == getOwnerOf(i) )
            ++count;
        }
        return count;
    }

}