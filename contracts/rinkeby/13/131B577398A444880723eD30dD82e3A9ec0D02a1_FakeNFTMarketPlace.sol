/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract FakeNFTMarketPlace
{
    mapping(uint => address) public tokens;
    uint nftPrice = 0.1 ether;

    function purchase(uint _tokenId) external payable
    {
        require(msg.value == nftPrice, "price is 0.1");
        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external view returns (uint)
    {
        return nftPrice;
    }

    function available(uint _tokenId) external view returns (bool)
    {
        if(tokens[_tokenId] == address(0)) return true;
        return false;
    }
}