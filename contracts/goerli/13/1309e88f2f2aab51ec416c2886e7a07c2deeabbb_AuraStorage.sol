/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12; 

contract AuraStorage {    

    //State Vars: ===========================================================================================

    uint256 public collectionsCreated = 0;
    uint256 public poapsCreated = 0; 
    uint256 public poapsCollected = 0;

    bytes32[] public collectionIDs; 
    bytes32[] public poapIDs; 
    uint256[] public tokenIDs; 
    
    //Structs: ===========================================================================================

    struct Collection {

        bytes32 collectionID;
        address collectionOwner; 
        
        string collectionName; 
        string collectionDesc;

        address[] collectionCollectors; 
        bytes32[] collectionPoaps;
        uint256[] collectionTokenIDs;    
    } 

    struct Poap {

        bytes32 poapID;

        address poapOwner;
        address[] poapCollectors; 

        string poapName;
        string poapDesc; 
        string poapLocation;
        string poapBaseURI;
        bytes32[] poapCollections; 

        uint256 startTime; 
        uint256 endTime; 
        uint256 supply;
        uint256[] poapTokenIDs;  

        bool gated; 
        bool status; //true = active | false = inactive

        mapping (address => bool) canMint; 
        mapping (address => bool) invites;  
    }

    //Mappings: ===========================================================================================

    mapping (string => bool) public takenNames; 

    //ID => Struct 
    mapping (bytes32 => Collection) public IDToCollection; //collectionID => poap struct instance
    mapping (bytes32 => Poap) public IDToPoap;  //poapID => poap struct instance 

    //User Mappings: 
    mapping (address => bytes32[]) public userPoaps;  //user address => array of poap ids they've collected
    mapping (address => bytes32[]) public userCreatedPoaps;
    mapping (address => uint256[]) public userTokenIDs;  
    mapping (address => bytes32[]) public userCollections; //user address => array of collector structs they own a poap from
    mapping (address => bytes32[]) public userCreatedCollections;   //user address => array of collector structs they created

    //Token Mappings:
    mapping (uint256 => mapping (bytes32 => bool)) public tokenInCollection; 

    //====================================================================================================================
}