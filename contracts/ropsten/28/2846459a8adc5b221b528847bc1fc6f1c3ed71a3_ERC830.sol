/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC830 {

    function transfer(address to, uint tokenId) external;

    function sellLimit(uint tokenId, uint price) external;

    function buyLimit(uint tokenId) external payable;

    function cancelSellLimit(uint tokenId) external;

    function ownerOf(uint tokenId) external returns (address);

    event Sold(address indexed from, address indexed to, uint tokenId, uint price);
    
    event Transfer(address indexed from, address indexed to, uint tokenId);

    event SoldLimit(address indexed seller, uint tokenId, uint price);
    
}

interface Metadata {
 
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

}

contract ERC830 is IERC830, Metadata{
    
    mapping (uint => bytes) image;
    mapping (uint => address) owner;
    mapping (address => uint) balance;
    mapping (uint => sellOrder) marketPlace;
    string _imageHash;
    string _name;
    string _symbol; 
    uint _totalSupply;
    uint mintIndex = 0;

    struct sellOrder {
        address seller;
        uint price;
        bool isForSell;
    }

    constructor (string memory NFT_name, string memory NFT_symbol, uint NFT_Supply, string memory NFT_imageHash) {
        _name = NFT_name;
        _symbol = NFT_symbol;
        _totalSupply = NFT_Supply;
        _imageHash = NFT_imageHash;
    }

    function imageHash() public view returns (string memory) {
        return _imageHash;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function ownerOf(uint tokenId) public view returns (address) {
        return owner[tokenId];
    }

    function balanceOf(address _owner) public view returns (uint) {
        return balance[_owner];
    }

    function MarketPlace(uint tokenId) public view returns(sellOrder memory) {
        return marketPlace[tokenId];
    }

    function mint() public {
        owner[++mintIndex] = msg.sender;
        balance[msg.sender] += 1;
    }

    function sellLimit(uint tokenId, uint price) public {
        require(owner[tokenId] == msg.sender, "You are not owner!");
        marketPlace[tokenId].seller = msg.sender;
        marketPlace[tokenId].price = price;
        marketPlace[tokenId].isForSell = true;

        emit SoldLimit(msg.sender, tokenId, price);
    }

    function buyLimit(uint tokenId) public payable {
        require(marketPlace[tokenId].isForSell == true, "NFT is not for sell!");
        (bool sent, ) = marketPlace[tokenId].seller.call{value: marketPlace[tokenId].price}("");
        require(sent == true, "Send Ether Fail!");

        owner[tokenId] = msg.sender;
        balance[msg.sender] += 1;
        balance[marketPlace[tokenId].seller] -= 1;

        emit Sold(msg.sender, marketPlace[tokenId].seller, tokenId, marketPlace[tokenId].price);

        marketPlace[tokenId].price = 0; 
        marketPlace[tokenId].seller = address(0);
        marketPlace[tokenId].isForSell = false;
    }

    function cancelSellLimit(uint tokenId) public {
        require(owner[tokenId] == msg.sender, "You are not owner!");
        marketPlace[tokenId].price = 0; 
        marketPlace[tokenId].seller = address(0);
        marketPlace[tokenId].isForSell = false;
    }

    function transfer(address to, uint tokenId) public {
        require(owner[tokenId] == msg.sender, "You are not NFT owner!");
        require(to != address(0), "Transfer Fail!");
        owner[tokenId] = to;
        balance[msg.sender] -= 1;
        balance[to] += 1;

        emit Transfer(msg.sender, to, tokenId);
    }

}