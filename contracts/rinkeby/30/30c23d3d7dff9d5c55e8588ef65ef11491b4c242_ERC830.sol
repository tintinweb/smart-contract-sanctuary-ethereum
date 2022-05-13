/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC830 {

    function transfer(address to, uint tokenId) external;

    function sellLimit(uint tokenId, uint price) external;

    function buyLimit(uint tokenId) external payable;

    function ownerOf(uint tokenId) external returns (address);

}

contract ERC830 is IERC830 {
    
    event Sold(address indexed from, address indexed to, uint tokenId, uint price);
    event Transfer(address indexed from, address indexed to, uint tokenId);
    
    receive() external payable {}

    struct sellOrder {
        address seller;
        uint price;
        bool isItSell;
    }

    mapping (uint => bytes) image;
    mapping (uint => address) owner;
    mapping (address => uint) NFT_balance;
    mapping (uint => sellOrder) marketPlace;
    mapping (address => uint) balance;
    uint index = 0;

    function mint() public {
        owner[++index] = msg.sender;
        NFT_balance[msg.sender] += 1;
    }

    function sellLimit(uint tokenId, uint price) public {
        require(owner[tokenId] == msg.sender, "You are not owner!");
        marketPlace[tokenId].seller = msg.sender;
        marketPlace[tokenId].price = price;
        marketPlace[tokenId].isItSell = true;
    }

    function buyLimit(uint tokenId) public payable {
        require(marketPlace[tokenId].isItSell == true, "NFT is not for sell!");
        (bool sent, ) = marketPlace[tokenId].seller.call{value: marketPlace[tokenId].price}("");
        require(sent == true, "Send Ether Fail!");
        owner[tokenId] = msg.sender;
        NFT_balance[msg.sender] += 1;

        emit Sold(msg.sender, marketPlace[tokenId].seller, tokenId, marketPlace[tokenId].price);

        marketPlace[tokenId].price = 0; 
        marketPlace[tokenId].seller = address(0);
        marketPlace[tokenId].isItSell = false;

    }

    function cancelSellLimit(uint tokenId) public {
        require(owner[tokenId] == msg.sender, "You are not owner!");
        marketPlace[tokenId].price = 0; 
        marketPlace[tokenId].seller = address(0);
    }

    function transfer(address to, uint tokenId) public {
        require(owner[tokenId] == msg.sender, "You are not NFT owner!");
        require(to != address(0), "Transfer Fail!");
        owner[tokenId] = to;
        NFT_balance[msg.sender] -= 1;
        NFT_balance[to] += 1;

        emit Transfer(msg.sender, to, tokenId);
    }

    function ownerOf(uint tokenId) public view returns (address) {
        return owner[tokenId];
    }

    function checkMarketPlace(uint tokenId) public view returns(sellOrder memory) {
        return marketPlace[tokenId];
    }
    
}