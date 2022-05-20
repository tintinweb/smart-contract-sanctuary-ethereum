// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface INinja {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint(uint8 numTokens) external payable;
}

contract Ninja {
    address to = 0x9A0c66926ae19246D312c3Be6af6EEF1edE9D26E;

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        return bytes4(keccak256('onERC721Received(address, address, uint256, bytes)'));
    }

    function ninja(address contractAddr) external {
        INinja(contractAddr).mint{value: 0}(2);/*
        INinja(contractAddr).transferFrom(address(this), to, 1);
        INinja(contractAddr).transferFrom(address(this), to, 2);
        INinja(contractAddr).mint{value: 0}(2);
        INinja(contractAddr).transferFrom(address(this), to, 3);
        INinja(contractAddr).transferFrom(address(this), to, 4);
        INinja(contractAddr).mint{value: 0}(2);
        INinja(contractAddr).transferFrom(address(this), to, 5);
        INinja(contractAddr).transferFrom(address(this), to, 6);*/
    }
}