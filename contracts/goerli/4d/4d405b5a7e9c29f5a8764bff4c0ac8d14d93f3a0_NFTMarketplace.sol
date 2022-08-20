// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    Counters.Counter private itemsSold;
    address payable owner;
    uint256 listPrice = 0.00032 ether;

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );

    mapping(uint256 => ListedToken) private idToListedToken;

    constructor() ERC721("NFTMarketplace", "NFTMARK") {
        owner = payable(msg.sender);
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    function getListedTokenForId(uint256 _tokenId) public view returns (ListedToken memory) {
        return idToListedToken[_tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return tokenIds.current();
    }

    function createToken(string memory _tokenURI, uint256 _price) public payable returns (uint) {
        tokenIds.increment();
        uint256 newTokenId = tokenIds.current();

        _safeMint(msg.sender, newTokenId);

        _setTokenURI(newTokenId, _tokenURI);

        createListedToken(newTokenId, _price);

        return newTokenId;
    }

    function createListedToken(uint256 _tokenId, uint256 _price) private {
        require(msg.value == listPrice, "Hopefully sending the correct price");
        require(_price > 0, "Make sure the price isn't negative");

        idToListedToken[_tokenId] = ListedToken(
            _tokenId,
            payable(address(this)),
            payable(msg.sender),
            _price,
            true
        );

        _transfer(msg.sender, address(this), _tokenId);
        emit TokenListedSuccess(
            _tokenId,
            address(this),
            msg.sender,
            _price,
            true
        );
    }
    
    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;

        for(uint i=0;i<nftCount;i++)
        {
            uint currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return tokens;
    }
    
    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totalItemCount = tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        for(uint i=0; i < totalItemCount; i++)
        {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        ListedToken[] memory items = new ListedToken[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) {
                uint currentId = i+1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 _tokenId) public payable {
        uint price = idToListedToken[_tokenId].price;
        address seller = idToListedToken[_tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        idToListedToken[_tokenId].currentlyListed = true;
        idToListedToken[_tokenId].seller = payable(msg.sender);
        itemsSold.increment();

        _transfer(address(this), msg.sender, _tokenId);
        approve(address(this), _tokenId);

        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }


}