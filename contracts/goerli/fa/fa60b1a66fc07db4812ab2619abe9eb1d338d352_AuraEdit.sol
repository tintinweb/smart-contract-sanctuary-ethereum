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

// File: contracts/AuraEdit.sol

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.12;

contract AuraEdit is AuraStorage {

    //Events: ===========================================================================================

    event PoapInvites (
        bytes32 indexed PoapID,
        string PoapName,
        address[] Invitations,
        uint256 TimeOfAddition
    );

    event PoapUninvites (
        bytes32 indexed PoapID,
        string PoapName,
        address[] Uninvitations,
        uint256 TimeOfRemoval
    );

    event AddedToCollection (
        bytes32 indexed PoapID,
        string PoapName,
        bytes32 indexed CollectionID,
        string CollectionName,
        uint256 TimeOfAddition
    );

    event RemovedFromCollection (
        bytes32 indexed PoapID,
        string PoapName,
        bytes32 indexed CollectionID,
        string CollectionName,
        uint256 TimeOfRemoval
    ); 


    //Helper Functions: ==============================================================================

    modifier inviteModif (bytes32 _poapID) {
        require (IDToPoap[_poapID].poapOwner == msg.sender, "You are not the owner of this poap."); 
        require (IDToPoap[_poapID].gated == true, "This poap is not gated."); 
        require (block.timestamp < IDToPoap[_poapID].endTime, "This poap has already ended.");
        _;
    }

    function checkMatch(bytes32 _poapID, bytes32 _collectionID) internal view returns (bool) {

        uint256 counter = 0; 

        if (IDToPoap[_poapID].poapCollections.length >= 1) {

            for (uint i = 0; i <= IDToPoap[_poapID].poapCollections.length; i++) {

                //if collectionID is not in poap collections array
                if (IDToPoap[_poapID].poapCollections[i] != _collectionID) {
                    counter++; //Increment counter

                    //if counter is equal to the amount of collections in the array
                } else if (counter == IDToPoap[_poapID].poapCollections.length) {
                    return false;  //the parameter collection ID is not the the poapCollections array
                }
            }

        } else if (IDToPoap[_poapID].poapCollections.length == 0) {
            return false; 
        }

       return true; 
    }

    function popIndex (bytes32 _poapID, bytes32 _collectionID) internal {

        //Local:
        bytes32[] memory poapArr;
        bytes32[] memory colArr;
        uint256[] memory colTokenArr;

        uint256 poapCounter = 0;
        uint256 colCounter = 0;
        uint256 tokenCounter = 0;    

        //Removes from poap struct array collections array
        for (uint i = 0; i <= IDToPoap[_poapID].poapCollections.length; i++) {

            if (IDToPoap[_poapID].poapCollections[i] != _collectionID) {

                poapCounter++;
                poapArr[poapCounter] = IDToPoap[_poapID].poapCollections[i]; //push into local array
            } 
        }

        //Removes from collection struct array poap array
        for (uint i = 0; i <= IDToCollection[_collectionID].collectionPoaps.length; i++) {

            if (IDToCollection[_collectionID].collectionPoaps[i] != _poapID) {

                colCounter++;
                colArr[colCounter] = IDToCollection[_collectionID].collectionPoaps[i]; //push into local array
            }
        }

        if (IDToPoap[_poapID].startTime <= block.timestamp) {

            for (uint i = 0; i <= IDToCollection[_collectionID].collectionTokenIDs.length; i++) {

                if (IDToPoap[_poapID].poapTokenIDs[i] != IDToCollection[_collectionID].collectionTokenIDs[i]) {

                    tokenCounter++;
                    colTokenArr[tokenCounter] = IDToCollection[_collectionID].collectionTokenIDs[i]; //push into local array
                }
            }
        }
    
        IDToPoap[_poapID].poapCollections = poapArr;
        IDToCollection[_collectionID].collectionPoaps = colArr;
        IDToCollection[_collectionID].collectionTokenIDs = colTokenArr;
    }

    //Invites: ========================================================================================

    //Add Invitations
    function addInvite (bytes32 _poapID, address[] calldata addInvites) external inviteModif(_poapID) {

        for (uint i = 0; i <= addInvites.length; i++) {

            if (IDToPoap[_poapID].invites[addInvites[i]] == false) {
                IDToPoap[_poapID].invites[addInvites[i]] = true; 
            }
        }

        emit PoapInvites ( _poapID, IDToPoap[_poapID].poapName, addInvites, block.timestamp); 
    }

    //Remove Invitations
    function unInvite (bytes32 _poapID, address[] calldata unInvites) external inviteModif(_poapID) {

        for (uint i = 0; i <= unInvites.length; i++) {

            if (IDToPoap[_poapID].invites[unInvites[i]] == true) {
                IDToPoap[_poapID].invites[unInvites[i]] = false; 
            }
        }

        emit PoapUninvites (_poapID, IDToPoap[_poapID].poapName, unInvites, block.timestamp);
    }

    //Add - Remove: =====================================================================================

    //Add to collection 
    function addPoapToCollection (bytes32 _poapID, bytes32 _collectionID) external {

        //Requires:
        require (IDToPoap[_poapID].poapOwner == msg.sender, "You are not the owner of this poap.");
        require (IDToCollection[_collectionID].collectionOwner == msg.sender, "You are not the owner of this collection");
        require (checkMatch(_poapID, _collectionID) == false, "This poap is already in this collection");  

        //Push into struct-arrays
        IDToPoap[_poapID].poapCollections.push(_collectionID);
        IDToCollection[_collectionID].collectionPoaps.push(_poapID);

        //If poap has already started change maping values for tokens and users
        if (IDToPoap[_poapID].startTime <= block.timestamp) {

            //User Collection Mapping
            for (uint i = 0; i <= IDToCollection[_collectionID].collectionCollectors.length; i++) {

                //Check if user is already in collection, if not push them into the array
                if (IDToPoap[_poapID].poapCollectors[i] != IDToCollection[_collectionID].collectionCollectors[i]) {

                    IDToCollection[_collectionID].collectionCollectors.push(IDToPoap[_poapID].poapCollectors[i]);
                } 

                //Add collectionID to user collections mapping
                userCollections[IDToPoap[_poapID].poapCollectors[i]].push(_collectionID); 
            }

            //Token IDs mapping
            for (uint i = 0; i <= IDToPoap[_poapID].poapTokenIDs.length; i++) {

                //Push current index tokenID into collection struct-array
                IDToCollection[_collectionID].collectionTokenIDs.push(IDToPoap[_poapID].poapTokenIDs[i]);

                //set token mapping
                //tokenAffiliation[IDToPoap[_poapID].poapTokenIDs[i]][_poapID].push(_collectionID);
                tokenInCollection[IDToPoap[_poapID].poapTokenIDs[i]][_collectionID] = true;  
            }
        } 

        emit AddedToCollection (_poapID, IDToPoap[_poapID].poapName, _collectionID, IDToCollection[_collectionID].collectionName, block.timestamp);  
    }


    function removePoapFromCollection (bytes32 _poapID, bytes32 _collectionID) external {

        //Requires:
        require (IDToPoap[_poapID].poapOwner == msg.sender, "You are not the owner of this poap.");
        require (IDToCollection[_collectionID].collectionOwner == msg.sender, "You are not the owner of this collection");
        require (checkMatch(_poapID, _collectionID) == true, "This poap is not in this collection");

        address[] memory dontPopArr; 

        if (IDToPoap[_poapID].startTime > block.timestamp) {

            popIndex(_poapID, _collectionID); //pops poapID and collectionID out of struct arrays

        } else if (IDToPoap[_poapID].startTime <= block.timestamp) {

            //Iterating through collection collectors
            for (uint i = 0; i <= IDToCollection[_collectionID].collectionCollectors.length; i++) {

                //Iterating through collectors token ids
                for (uint j = 0; j <= userTokenIDs[IDToCollection[_collectionID].collectionCollectors[i]].length; j++) {

                    address indexAddr = IDToCollection[_collectionID].collectionCollectors[i]; 
                    uint256 userTokenCounter = 0;

                    if (tokenInCollection[userTokenIDs[indexAddr][j]][_collectionID] == true) {

                        userTokenCounter++;

                    } else if (userTokenCounter >= 2) {

                        dontPopArr[dontPopArr.length + 1] =  IDToCollection[_collectionID].collectionCollectors[i]; 
                    }
                }
            }
            
            popIndex(_poapID, _collectionID); 
            IDToCollection[_collectionID].collectionCollectors = dontPopArr;

            emit RemovedFromCollection (_poapID, IDToPoap[_poapID].poapName, _collectionID, IDToCollection[_collectionID].collectionName, block.timestamp);  
        }  
    }
}