pragma solidity ^0.8.9;
// SPDX-License-Identifier: UNLICENSED

contract Web {
    struct NFT {
        uint256 tokenId;
        address owner;
        string title;
        string description;
        uint256 price;
        string image;
    }

    struct User {
        string name;
        string profilePicture;
        string username;
    }

    mapping(uint256 => NFT) public nfts;
    mapping(address => User) public users;

    uint256 public numberOfNFTs = 0;

    event NFTAdded(uint256 tokenId, address owner, string title, string description, uint256 price, string image);
    event NFTSold(uint256 tokenId, address seller, address buyer, uint256 price);

    function addUser(string memory _name, string memory _profilePicture, string memory _username) public {
        users[msg.sender] = User(_name, _profilePicture, _username);
    }

    function addNFT(string memory _title, string memory _description, uint256 _price, string memory _image) public {
        uint256 tokenId = numberOfNFTs;

        nfts[tokenId] = NFT(tokenId, msg.sender, _title, _description, _price, _image);
        numberOfNFTs++;

        emit NFTAdded(tokenId, msg.sender, _title, _description, _price, _image);
    }

    function buyNFT(uint256 _tokenId) public payable {
        NFT storage nft = nfts[_tokenId];
        require(nft.owner != address(0), "Invalid NFT tokenId");
        require(msg.value >= nft.price, "Insufficient funds");

        address payable seller = payable(nft.owner);
        address payable buyer = payable(msg.sender);
        uint256 price = nft.price;

        nft.owner = buyer;
        nft.price = 0;

        seller.transfer(price);
        if (msg.value > price) {
            buyer.transfer(msg.value - price);
        }

        emit NFTSold(_tokenId, seller, buyer, price);
    }
}