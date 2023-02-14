//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract FakeNFTMarketplace{

    //have puchase function if its not already minted
    //check if its available -- should be in address 0x00
    //should have a track of tokenIds and addresses
    //price of NFT should be 0.01 eth

    mapping (uint256 => address) public tokens;
    uint256 NFTPrice = 0.01 ether;

    function purchase(uint256 _tokenId) public payable{
        require(msg.value > NFTPrice, "You do not have enough balance to purchase this NFT");
        require(tokens[_tokenId] == address(0), "This NFT is not available");
        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external view returns (uint256){
        return NFTPrice;
    }

    function available(uint256 _tokenId) external view returns(bool){
        if(tokens[_tokenId] == address(0)){
            return true;
        } else{
            return false;
        }
    }
}