//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FakeNFTMarketplace {

    mapping(uint256 => address) public tokens;

    uint256 nftPrice = 0.1 ether;

    function  purchase(uint256 _tokenId) external payable  {
        require(msg.value == nftPrice, "The NFT costs 0.1 ether");
        tokens[_tokenId] = msg.sender;
    }

    function  getPrice() view public  returns (uint256) {
        return nftPrice;
    }

    function  available(uint256 _tokenId) view public returns(bool) {
        if(tokens[_tokenId] == address(0)){

            return true;
        }

    return false; 
    }       

}