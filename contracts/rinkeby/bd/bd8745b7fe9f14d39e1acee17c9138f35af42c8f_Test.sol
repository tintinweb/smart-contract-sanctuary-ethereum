/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Test {
    address tokenAdr = 0x952309485dc3981855fbF92B17ED08E2fb7dbb05;
    function check(uint256 tokenId) view external returns(address owner) {
        return IERC721(tokenAdr).ownerOf(tokenId);
    }
}