// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ITiger {
    function mintToken(uint256 _tokenId, address to) external;
}

contract TigerMarket {
    ITiger tiger;

    function setTiger(address _tiger) public {
        tiger = ITiger(_tiger);
    }

    function mint(uint256 _tokenId, address to) public {
        tiger.mintToken(_tokenId, to);
    }
}