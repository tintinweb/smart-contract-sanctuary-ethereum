// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    event Verified(uint256 indexed tokenId, address indexed to);

    function verify(uint256 id, address to) public returns (uint256) {
        require(id == 1, "Not Verified");
        emit Verified(id, to);
        return id;
    }
}