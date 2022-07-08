// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    event Verified(uint256 indexed tokenId, address indexed to);
    event NotVerified(uint256 indexed tokenId, address indexed to);

    function verify(uint256 id, address to) public returns (uint256) {
        if (id == 1) {
            emit Verified(id, to);
        } else {
            emit NotVerified(id, to);
        }
        return id;
    }
}