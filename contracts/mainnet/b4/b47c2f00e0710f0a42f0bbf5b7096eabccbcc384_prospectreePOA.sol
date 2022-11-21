/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
// prospectree Proof-of-Asset Smart contract

pragma solidity >=0.6.0 <=0.8.0;

contract prospectreePOA {

    // Declare Variables

    uint256 public assetIdCounter;
    address public owner;
    uint256 public registerCardsCount;
    uint256 public startingCounter;
    mapping (uint256 => bool) public registeredCards;
    mapping (address => uint256[]) public registeredCardsPerUser;
    mapping (address => uint256) public registeredCardsCountPerUser;

    // Declare Struct Asset

    struct asset {
        uint256 assetId;
        uint256 assetTimestamp;
        bytes32 assetHash;
        address assetOwner;
        uint256 noOfTrees;
        string assetURI;
    }

    asset[] assetRecords;


    // Constructor

    constructor() public {
        assetIdCounter=1000;
        startingCounter = assetIdCounter;
        owner = msg.sender;
    }

    // SETTER FUNCTIONS

    // Register a PoA

    function registerAsset(bytes32 _assetHash, address _assetOwner, uint256 _noOfTrees, string memory _assetURI) public {
        require(msg.sender==owner);
        asset memory newAsset = asset(assetIdCounter, block.timestamp, _assetHash, _assetOwner,  _noOfTrees, _assetURI);
        assetRecords.push(newAsset);
        registeredCards[assetIdCounter] = true;
	registeredCardsPerUser[_assetOwner].push(assetIdCounter);
        registeredCardsCountPerUser[_assetOwner] = registeredCardsCountPerUser[_assetOwner] + 1;
        assetIdCounter = assetIdCounter + 1;
        registerCardsCount = registerCardsCount +1;
    }

    // Update PoA URI
    function updateURI(uint256 _cardID, string memory _assetURI) public {
        require(msg.sender==owner);
        uint256 temp;
        temp = _cardID - startingCounter;
        assetRecords[temp].assetURI = _assetURI;
    }

    // Update PoA Owner
    function updateAssetOwner(uint256 _cardID, address _assetOwner) public {
        require(msg.sender==owner);
        uint256 temp;
        temp = _cardID - startingCounter;
        assetRecords[temp].assetOwner = _assetOwner;
	registeredCardsPerUser[_assetOwner].push(_cardID);
        registeredCardsCountPerUser[_assetOwner] = registeredCardsCountPerUser[_assetOwner] + 1;
    }

    // Update Smart Contract Owner
    function updateSmartContractOwner(address _owner) public {
        require(msg.sender==owner);
        owner=_owner;
    }


    // RETRIEVE FUNCTIONS

    // Retrieve Using For Loops
    // Retrieve a Proof-of-Asset

    function retrieveAsset(uint256 _cardID) public view returns (uint256, uint256, bytes32, address, uint256, string memory) {
        uint256 temp;
        for (uint256 i=0; i<=assetRecords.length-1; i++) {
            if (_cardID == assetRecords[i].assetId) {
            temp = i;
            }
        }
        return (assetRecords[temp].assetId, assetRecords[temp].assetTimestamp, assetRecords[temp].assetHash, assetRecords[temp].assetOwner, assetRecords[temp].noOfTrees, assetRecords[temp].assetURI);
    }

    // Retrieve POA Owner
    function retrieveAssetOwner(uint256 _cardID) public view returns (address) {
        uint256 temp;
        for (uint256 i=0; i<=assetRecords.length-1; i++) {
            if (_cardID == assetRecords[i].assetId) {
            temp = i;
            }
        }
        return (assetRecords[temp].assetOwner);
    }

    // Retrieve POA noOfTrees
    function retrieveAssetNoTrees(uint256 _cardID) public view returns (uint256) {
        uint256 temp;
        for (uint256 i=0; i<=assetRecords.length-1; i++) {
            if (_cardID == assetRecords[i].assetId) {
            temp = i;
            }
        }
        return (assetRecords[temp].noOfTrees);
    }

    // Optimized Retrieve Functions
    // Retrieve Using Indexes
    // Retrieve a Proof-of-Asset

    function retrieveAssetFromIndex(uint256 _cardID) public view returns (uint256, uint256, bytes32, address, uint256, string memory) {
        uint256 temp;
        temp = _cardID - startingCounter;
        return (assetRecords[temp].assetId, assetRecords[temp].assetTimestamp, assetRecords[temp].assetHash, assetRecords[temp].assetOwner, assetRecords[temp].noOfTrees, assetRecords[temp].assetURI);
    }

    // Retrieve POA Owner
    function retrieveAssetOwnerFromIndex(uint256 _cardID) public view returns (address) {
        uint256 temp;
        temp = _cardID - startingCounter;
        return (assetRecords[temp].assetOwner);
    }

    // Retrieve POA noOfTrees
    function retrieveAssetNoTreesFromIndex(uint256 _cardID) public view returns (uint256) {
        uint256 temp;
        temp = _cardID - startingCounter;
        return (assetRecords[temp].noOfTrees);
    }


}