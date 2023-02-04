/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract nft {

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // Variables
    mapping (uint256 => address) public tokenOwner;
    mapping (uint256 => uint256) public tokenIdToIndex;
    mapping (uint256 => string) public tokenURI;
    uint256 public totalSupply;

    // Methods
    function mint(address _to, uint256 _tokenId, string memory _uri) public {
        require(tokenOwner[_tokenId] == address(0), "Token already minted.");

        tokenIdToIndex[totalSupply] = _tokenId;
        tokenOwner[_tokenId] = _to;
        tokenURI[_tokenId] = _uri;
        totalSupply++;

        emit Transfer(address(0), _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(tokenOwner[ _tokenId] == msg.sender, "You are not the owner of this token.");

        tokenOwner[_tokenId] = _to;

        emit Transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this token.");

        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getOwner(uint256 _tokenId) public view returns (address) {
        return tokenOwner[_tokenId];
    }

    function getTokenIdByIndex(uint256 _index) public view returns (uint256) {
        return tokenIdToIndex[_index];
    }

    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
        return tokenURI[_tokenId];
    }
}