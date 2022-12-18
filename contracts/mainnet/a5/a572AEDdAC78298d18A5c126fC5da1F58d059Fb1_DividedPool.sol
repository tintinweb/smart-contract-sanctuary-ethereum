// SPDX-License-Identifier: MIT
// Author: Daniel Von Fange (@DanielVF)

import {ERC20} from "ERC20.sol";
import {ERC721} from "ERC721.sol";

pragma solidity ^0.8.16;

contract DividedPool is ERC20 {
    ERC721 public immutable collection;
    uint256 public constant SHARDS_PER_NFT = 100e18;

    event DepostNFT(address indexed collection, uint256 indexed tokenId, address indexed user);
    event WithdrawNFT(address indexed collection, uint256 indexed tokenId, address indexed user);
    event SweepNFT(address indexed collection, uint256 indexed tokenId, address indexed user);

    constructor() ERC20("", "", 18) {
        ERC721 _collection = ERC721(IDividedFactory(msg.sender).deployNftContract());
        collection = _collection;
        name = string.concat("Divided ", _collection.name());
        symbol = string.concat("d", _collection.symbol());
    }

    function nftIn(uint256 tokenId) external returns (bool) {
        collection.transferFrom(msg.sender, address(this), tokenId); // Because Reentrancy
        _mint(msg.sender, SHARDS_PER_NFT);
        emit DepostNFT(address(collection), tokenId, msg.sender);
        return true;
    }

    function nftOut(uint256 tokenId) external returns (bool) {
        _burn(msg.sender, SHARDS_PER_NFT);
        collection.transferFrom(address(this), msg.sender, tokenId);
        emit WithdrawNFT(address(collection), tokenId, msg.sender);
        return true;
    }

    function swap(uint256 fromTokenId, uint256 toTokenId) external returns (bool) {
        collection.transferFrom(msg.sender, address(this), fromTokenId);
        collection.transferFrom(address(this), msg.sender, toTokenId);
        emit DepostNFT(address(collection), fromTokenId, msg.sender);
        emit WithdrawNFT(address(collection), toTokenId, msg.sender);
        return true;
    }

    function sweep(uint256 tokenId) external returns (bool) {
        collection.transferFrom(address(this), msg.sender, tokenId); // Because Reentrancy
        uint256 count = collection.balanceOf(address(this));
        require(this.totalSupply() <= count * SHARDS_PER_NFT);
        emit SweepNFT(address(collection), tokenId, msg.sender);
        emit WithdrawNFT(address(collection), tokenId, msg.sender);
        return true;
    }
}

interface IDividedFactory {
    function deployNftContract() external returns (address);
}