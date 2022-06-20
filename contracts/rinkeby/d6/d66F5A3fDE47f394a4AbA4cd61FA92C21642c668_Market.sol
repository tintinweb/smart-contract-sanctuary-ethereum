//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Market is Ownable {

    mapping(address =>mapping(uint256 => Listing)) public listings;

    struct Listing {
        uint256 price;
        address seller;
        address owner;
        bool isListing;
        uint ownerCount;
        mapping(uint => address) previousOwners;
    }

    event List(address indexed owner, uint indexed tokenId, uint price, bool indexed isListing);

    function addListing(uint256 price, address contractAddr, uint256 tokenId) public {
        ERC721 token = ERC721(contractAddr);
        Listing storage item = listings[contractAddr][tokenId];
        require(token.ownerOf(tokenId) == msg.sender, "Seller has no token.");
        require(token.isApprovedForAll(msg.sender, address(this)), "Contract must be approved.");

        item.price = price;
        item.seller = msg.sender;
        item.owner = msg.sender;
        item.isListing = true;
        emit List(msg.sender, tokenId, item.price, item.isListing);
    }

    function cancelListing(address contractAddr, uint256 tokenId) public {
        ERC721 token = ERC721(contractAddr);
        Listing storage item = listings[contractAddr][tokenId];
        require(item.seller == msg.sender, "Unauthorized.");
        require(item.isListing, "This NFT is not listing.");
        require(token.isApprovedForAll(msg.sender, address(this)), "Contract must be approved.");

        item.isListing = false;
        emit List(msg.sender, tokenId, item.price, item.isListing);
    }

    function purchase(address contractAddr, uint256 tokenId, address referer, uint256 metaverseFee, uint256 previousOwnerFee, uint256 referalFee) public payable {
        Listing storage item = listings[contractAddr][tokenId];
        ERC721 token = ERC721(contractAddr);
        require(item.isListing, "This NFT is not for sell.");
        require(msg.sender != item.seller, "Buy from yourself.");
        require(msg.value >= item.price, "Insufficient funds sent.");
        payable(item.seller).transfer(item.price - (item.price / 20));
        payable(owner()).transfer(metaverseFee);
        if(referer != address(0)){
            payable(referer).transfer(referalFee);
        }
        for (uint i = 0; i < 5; i++) {
                if (item.previousOwners[i] != address(0)) {
                    payable(item.previousOwners[i]).transfer(previousOwnerFee);
                }
                else {
                    break;
                }
            }

        token.safeTransferFrom(item.seller, msg.sender, tokenId, "");
        item.owner = msg.sender;
        if(listings[contractAddr][tokenId].ownerCount <= 3) {
            item.previousOwners[item.ownerCount] = item.seller;
            item.ownerCount += 1;
        }
        else {
            item.previousOwners[item.ownerCount] = item.seller;
            item.ownerCount = 0;
        }

        item.isListing = false;
        emit List(msg.sender, tokenId, item.price, item.isListing);
    }

    function purchaseBatch(address contractAddr, uint256[] calldata tokenId, address referer, uint256 metaverseFee, uint256[] calldata previousOwnerFee, uint256 referalFee) public payable {
        for (uint j = 0; j < tokenId.length; j++) {
            Listing storage item = listings[contractAddr][tokenId[j]];
            ERC721 token = ERC721(contractAddr);
            require(item.isListing, "This NFT is not for sell.");
            require(msg.sender != item.seller, "Buy from yourself.");
            require(msg.value >= item.price, "Insufficient funds sent.");
            payable(item.seller).transfer(item.price - (item.price / 20));
            payable(owner()).transfer(metaverseFee);
            if(referer != address(0)){
                payable(referer).transfer(referalFee);
            }
            for (uint i = 0; i < 5; i++) {
                    if (item.previousOwners[i] != address(0)) {
                        payable(item.previousOwners[i]).transfer(previousOwnerFee[j]);
                    }
                    else {
                        break;
                    }
                }

            token.safeTransferFrom(item.seller, msg.sender, tokenId[j], "");
            item.owner = msg.sender;
            if(item.ownerCount <= 3) {
                item.previousOwners[item.ownerCount] = item.seller;
                item.ownerCount += 1;
            }
            else {
                item.previousOwners[item.ownerCount] = item.seller;
                item.ownerCount = 0;
            }

            item.isListing = false;
            emit List(msg.sender, tokenId[j], item.price, item.isListing);
        }
    }

    function purchaseERC20(address contractAddr, address coinAddr, uint256 tokenId, address referer, uint256 metaverseFee, uint256 previousOwnerFee, uint256 referalFee) public payable {
        Listing storage item = listings[contractAddr][tokenId];
        ERC721 token = ERC721(contractAddr);
        ERC20 coin = ERC20(coinAddr);
        require(item.isListing, "This NFT is not for sell.");
        require(msg.sender != item.seller, "Buy from yourself.");
        require(coin.balanceOf(msg.sender) >= item.price, "Insufficient funds sent.");
        coin.transferFrom(msg.sender, item.seller, item.price - (item.price / 20));
        coin.transferFrom(msg.sender, owner(), metaverseFee);
        if(referer != address(0)){
            coin.transferFrom(msg.sender, referer, referalFee);
        }
        for (uint i = 0; i < 5; i++) {
                if (item.previousOwners[i] != address(0)) {
                    coin.transferFrom(msg.sender, item.previousOwners[i], previousOwnerFee);
                }
                else {
                    break;
                }
            }

        token.safeTransferFrom(item.seller, msg.sender, tokenId, "");
        item.owner = msg.sender;
        if(listings[contractAddr][tokenId].ownerCount <= 3) {
            item.previousOwners[item.ownerCount] = item.seller;
            item.ownerCount += 1;
        }
        else {
            item.previousOwners[item.ownerCount] = item.seller;
            item.ownerCount = 0;
        }

        item.isListing = false;
        emit List(msg.sender, tokenId, item.price, item.isListing);
    }

    function purchaseERC20Batch(address contractAddr, address coinAddr, uint256[] calldata tokenId, address referer, uint256 metaverseFee, uint256[] calldata previousOwnerFee, uint256 referalFee) public payable {
        for (uint j = 0; j < tokenId.length; j++) {
            Listing storage item = listings[contractAddr][tokenId[j]];
            ERC721 token = ERC721(contractAddr);
            ERC20 coin = ERC20(coinAddr);
            require(item.isListing, "This NFT is not for sell.");
            require(msg.sender != item.seller, "Buy from yourself.");
            require(coin.balanceOf(msg.sender) >= item.price, "Insufficient funds sent.");
            coin.transferFrom(msg.sender, item.seller, item.price - (item.price / 20));
            coin.transferFrom(msg.sender, owner(), metaverseFee);
            if(referer != address(0)){
                coin.transferFrom(msg.sender, referer, referalFee);
            }
            for (uint i = 0; i < 5; i++) {
                    if (item.previousOwners[i] != address(0)) {
                        coin.transferFrom(msg.sender, item.previousOwners[i], previousOwnerFee[j]);
                    }
                    else {
                        break;
                    }
                }

            token.safeTransferFrom(item.seller, msg.sender, tokenId[j], "");
            item.owner = msg.sender;
            if(item.ownerCount <= 3) {
                item.previousOwners[item.ownerCount] = item.seller;
                item.ownerCount += 1;
            }
            else {
                item.previousOwners[item.ownerCount] = item.seller;
                item.ownerCount = 0;
            }

            item.isListing = false;
            emit List(msg.sender, tokenId[j], item.price, item.isListing);
        }
    }

    function getPrice(address contractAddr, uint tokenId) public view returns(uint256 price) {
        return listings[contractAddr][tokenId].price;
    }

    function getSeller(address contractAddr, uint tokenId) public view returns(address seller) {
        return listings[contractAddr][tokenId].seller;
    }

    function getIsListing(address contractAddr, uint tokenId) public view returns(bool isListing) {
        return listings[contractAddr][tokenId].isListing;
    }

    function getPrevOwner(address contractAddr, uint tokenId, uint prevIndex) public view returns(address prevOwner) {
        return listings[contractAddr][tokenId].previousOwners[prevIndex];
    }

    function getOwner(address contractAddr, uint tokenId) public view returns(address owner) {
        return listings[contractAddr][tokenId].owner;
    }
}