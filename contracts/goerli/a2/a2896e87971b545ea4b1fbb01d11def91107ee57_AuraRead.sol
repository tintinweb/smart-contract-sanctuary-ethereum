/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// File: https://github.com/BenRiekes/Smart-Contracts/blob/main/AuraStorage.sol

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

// File: contracts/AuraRead.sol

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.12;

contract AuraRead is AuraStorage {

    //Collection getters: 
    function getCollectionDetails (bytes32 _collectionID) external view returns (address, string memory, string memory) {
        return (IDToCollection[_collectionID].collectionOwner, IDToCollection[_collectionID].collectionName, 
        IDToCollection[_collectionID].collectionDesc); 
    }

    function getCollectionStats (bytes32 _collectionID) external view returns (address[] memory, bytes32[] memory, uint256[] memory, uint256[] memory) {

        uint256[] memory collectionStats;
        collectionStats[0] = IDToCollection[_collectionID].collectionCollectors.length;
        collectionStats[1] = IDToCollection[_collectionID].collectionPoaps.length; 
        collectionStats[2] = IDToCollection[_collectionID].collectionTokenIDs.length; 

        return (IDToCollection[_collectionID].collectionCollectors, IDToCollection[_collectionID].collectionPoaps,
        IDToCollection[_collectionID].collectionTokenIDs, collectionStats);
    }

    
    //Poap Getters:
    function getPoapDetails (bytes32 _poapID) external view returns (address, string[] memory, uint256[] memory, bool[] memory) {

        string[] memory poapStringDetails;
        poapStringDetails[0] = IDToPoap[_poapID].poapName;
        poapStringDetails[1] = IDToPoap[_poapID].poapDesc;
        poapStringDetails[2] = IDToPoap[_poapID].poapLocation; 
        poapStringDetails[3] = IDToPoap[_poapID].poapBaseURI; 

        uint256[] memory poapUintDetails; 
        poapUintDetails[0] = IDToPoap[_poapID].startTime;
        poapUintDetails[1] = IDToPoap[_poapID].endTime;
        poapUintDetails[2] = IDToPoap[_poapID].supply; 

        bool[] memory poapBoolDetails;
        poapBoolDetails[0] = IDToPoap[_poapID].gated;
        poapBoolDetails[1] = IDToPoap[_poapID].status; 

        return (IDToPoap[_poapID].poapOwner, poapStringDetails, poapUintDetails, poapBoolDetails); 
    }

    function getPoapStats (bytes32 _poapID) external view returns (address[] memory, bytes32[] memory, uint256[] memory, uint256[] memory) {

        uint256[] memory poapStats;
        poapStats[0] = IDToPoap[_poapID].poapCollectors.length; 
        poapStats[1] = IDToPoap[_poapID].poapCollections.length; 
        poapStats[2] = IDToPoap[_poapID].poapTokenIDs.length; 

        return (IDToPoap[_poapID].poapCollectors, IDToPoap[_poapID].poapCollections, IDToPoap[_poapID].poapTokenIDs, poapStats); 
    }


    //User getters: 
    function getPoapInviteStatus (address _user, bytes32 _poapID) external view returns (bool) {
        return IDToPoap[_poapID].invites[_user];  
    }

    //User Tokens From Collection
    function getUserCollectionTokens (address _user, bytes32 _collectionID) external view returns (uint256[] memory) {

        uint256[] memory collectionTokens; 
        uint256 counter = 0; 

        for (uint i = 0; i <= IDToCollection[_collectionID].collectionTokenIDs.length; i++) {

            if (IDToCollection[_collectionID].collectionTokenIDs[i] == userTokenIDs[_user][i]) {
                counter++;
                collectionTokens[counter] = userTokenIDs[_user][i]; 
            }
        }

        return collectionTokens; 
    }

}