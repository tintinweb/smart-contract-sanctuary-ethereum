/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract CustomEventMock {
    event TokenMinted (uint indexed tokenId, bytes32 indexed tokenClass);

    function mint(uint tokenId, bytes32 tokenClass) public {
        emit TokenMinted(tokenId, tokenClass);
    }
}