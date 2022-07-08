// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    event Minted(uint256 tokenId, address to);

    function verify(uint256 id, address to) public returns (uint256) {
        emit Minted(id, to);
        require(id == 1, "Failed!");
        return id;
    }
}