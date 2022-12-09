/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface ITokenURI{
    function tokenURI(uint256 _tokenId) external view returns(string memory);
}

contract SetTokenTest {
    ITokenURI public tokenuri;

    function setTokenURI(ITokenURI _tokenuri) external {
        tokenuri = _tokenuri;
    }
}