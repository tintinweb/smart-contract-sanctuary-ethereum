//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";

contract CollectionManager {
    NFTCollection public newcollection;  // NFT Smart Contract

    uint256 public currentcollections;  // count of Current exist Collections
    string[] public collectionnames;  // Collection Names Array
    
    mapping(uint256 => NFTCollection) public nftcollectionsbyindex; // NFT Collection By Index
    mapping(string => NFTCollection) public nftcollectionsbyname; // NFT Collection By Collection Name
    mapping(string => bool) public collectionnameexists;  // Collections are exist. Collection should be Unique



    // Create Collection Function
    function creatcollection(string memory _collectionname, string memory _collectionsymbol) public {
        require(!collectionnameexists[_collectionname], "Collection name Should be Unique!");
        newcollection = new NFTCollection(_collectionname, _collectionsymbol);
        collectionnameexists[_collectionname] = true;
        collectionnames.push(_collectionname);
        currentcollections++;
        nftcollectionsbyindex[currentcollections] = newcollection;
        nftcollectionsbyname[_collectionname] = newcollection;
    }



    // Creat NFT Item by selected Collection
    function mintItem (string memory _collectionName, string memory _tokenURI) public {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        nftcollectionsbyname[_collectionName].safeMint(_tokenURI, msg.sender);
    }

    // Get Token Id by selected Collection
    function getTokenId (string memory _collectionName, address _addr) public view returns(uint256[] memory) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].getTokenId(_addr);
    }

    // Get Track by token id
    function getTrack (string memory _collectionName, uint256 _id) public view returns(address[] memory) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].getTrack(_id);
    }

    // Get TokenURI by token id
    function tokenURI (string memory _collectionName, uint256 _id) public view returns (string memory){
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].tokenURI(_id);
    }
    // Get Token Id By TokenURI
    function gettokenIdByTokenURI(string memory _collectionName , string memory _tokenURI) public view returns (uint256) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].gettokenIdByTokenURI(_tokenURI);
    }

    // Approve Function
    function approve(string memory _collectionName, address to, uint256 tokenId) public {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        nftcollectionsbyname[_collectionName].approve(to, tokenId, msg.sender);
    }

    // setApprovalForAll
    function setApprovalForAll (string memory _collectionName, address operator, bool approved) public {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        nftcollectionsbyname[_collectionName].setApprovalForAll(operator, approved, msg.sender);
    }

    // balance of function
    function balanceOf(string memory _collectionName, address owner) public view returns (uint256) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].balanceOf(owner);
    }

    // getApproved
    function getApproved(string memory _collectionName, uint256 _id) public view returns (address) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].getApproved(_id);
    }

    // isApprovedForAll
    function isApprovedForAll(string memory _collectionName, address owner, address operator) public view returns (bool) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].isApprovedForAll(owner, operator);
    }

    // name
    function name(string memory _collectionName) public view returns(string memory) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].name();
    }

    // Symbol
    function symbol(string memory _collectionName) public view returns(string memory) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].symbol();
    }

    // totalSupply
    function totalSupply (string memory _collectionName) public view returns(uint256) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].totalSupply();
    }

    // external collectionnameexists
    function Ex_collectionnameexists(string memory _collectionName) view external returns (bool) {
        return collectionnameexists[_collectionName];
    }

    // external collection contract by name
    function Ex_nftcollectionsbyname(string memory _collectionName) view external returns (NFTCollection) {
        return nftcollectionsbyname[_collectionName];
    }
    
    // ownerOf function
    function ownerOf (string memory _collectionName, uint256 _id) public view returns(address) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique!");
        return nftcollectionsbyname[_collectionName].ownerOf(_id);
    }
}