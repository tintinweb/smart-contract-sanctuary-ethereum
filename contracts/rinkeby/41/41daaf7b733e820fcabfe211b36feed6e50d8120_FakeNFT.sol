// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract FakeNFT {
    address treasury = 0xbad06297eB7878502E045319a7c4a8904b49BEEF;
    mapping (address => uint256) public nftCounterPerOwner;
    mapping (uint256 => address) public nftOwner;

    uint256 constant nftPriceMult = 10**16;


    // fake price, nft price is nftId * e16
    function getPrice(uint256 nftId) public pure returns (uint256) {
        return nftId*nftPriceMult;
    }

    function buy(address onBehalfOf, uint256 nftId) external payable {
        require(msg.value == getPrice(nftId), "WRONG ETH VALUE");
        require(nftOwner[nftId] == address(0), "NFT ALREADY OWNED");
        nftOwner[nftId] = onBehalfOf;
        nftCounterPerOwner[onBehalfOf]++;

        (bool success,) = treasury.call{value: msg.value}("");
        require(success, "COULD NOT SEND FUND TO TREASURY");
    }
}