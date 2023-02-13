/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ERC721 {
    function mint(address to) external;
}

contract tools{
    constructor (){}
    function _mintLoop(address token,address _receiver, uint256 _mintAmount)  external{
        for (uint256 i = 0; i < _mintAmount; i++) {
            ERC721(token).mint(_receiver);
        }
    }
}