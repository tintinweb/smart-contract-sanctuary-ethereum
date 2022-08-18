// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";

contract NFTMarketplace_CreatBy_LikeMoon is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private assetIds;
    Counters.Counter private itemsSold;
    address payable owner;
    uint256 listPrice = 0.0015 ether;

    struct ListedAssets {
        uint256 assetId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    event AssetListedSuccess (
        uint256 indexed assetId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );

    mapping(uint256 => ListedAssets) private idToListedAssets;

    constructor() ERC721("NFTMarketCreateByLikeMoon", "NftMM") {
        owner = payable(msg.sender);
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "You're not the Owner,you can't change the price.");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedAssets() public view returns (ListedAssets memory) {
        uint256 currentassetId = assetIds.current();
        return idToListedAssets[currentassetId];
    }

    function getListedAssetsForId(uint256 _assetId) public view returns (ListedAssets memory) {
        return idToListedAssets[_assetId];
    }

    function getCurrentAsset() public view returns (uint256) {
        return assetIds.current();
    }

    function createAsset(string memory _assetURI, uint256 _price) public payable returns (uint) {
        assetIds.increment();
        uint256 newassetId = assetIds.current();

        _safeMint(msg.sender, newassetId);

        _setTokenURI(newassetId, _assetURI);

        createListedAssets(newassetId, _price);

        return newassetId;
    }

    function createListedAssets(uint256 _assetId, uint256 _price) private {
        require(msg.value == listPrice, "You have to send same eth to contract.");
        require(_price > 0, "The prive is under zero.");

        idToListedAssets[_assetId] = ListedAssets(
            _assetId,
            payable(address(this)),
            payable(msg.sender),
            _price,
            true
        );

        _transfer(msg.sender, address(this), _assetId);
        emit AssetListedSuccess(
            _assetId,
            address(this),
            msg.sender,
            _price,
            true
        );
    }
    
    function getAllNFTs() public view returns (ListedAssets[] memory) {
        uint nftCount = assetIds.current();
        ListedAssets[] memory assets = new ListedAssets[](nftCount);
        uint currentIndex = 0;

        for(uint i=0;i<nftCount;i++)
        {
            uint currentId = i + 1;
            ListedAssets storage currentItem = idToListedAssets[currentId];
            assets[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return assets;
    }
    
    function getMyNFTs() public view returns (ListedAssets[] memory) {
        uint totalItemCount = assetIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        for(uint i=0; i < totalItemCount; i++)
        {
            if(idToListedAssets[i+1].owner == msg.sender || idToListedAssets[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        ListedAssets[] memory items = new ListedAssets[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(idToListedAssets[i+1].owner == msg.sender || idToListedAssets[i+1].seller == msg.sender) {
                uint currentId = i+1;
                ListedAssets storage currentItem = idToListedAssets[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 _assetId) public payable {
        uint price = idToListedAssets[_assetId].price;
        address seller = idToListedAssets[_assetId].seller;
        require(msg.value == price, "Please send enough ETH.");

        idToListedAssets[_assetId].currentlyListed = true;
        idToListedAssets[_assetId].seller = payable(msg.sender);
        itemsSold.increment();

        _transfer(address(this), msg.sender, _assetId);
        approve(address(this), _assetId);

        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }


}