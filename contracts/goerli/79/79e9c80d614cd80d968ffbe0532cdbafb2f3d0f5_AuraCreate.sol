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

// File: contracts/AuraCreate.sol




pragma solidity ^0.8.12;

contract AuraCreate is AuraStorage  {

    //Events: ===========================================================================================

    event CollectionCreated (
        bytes32 indexed CollectionID,
        string CollectionName,
        string CollectionDescription,
        address CollectionOwner,
        uint256 CreationTime
    );

    event PoapCreated (
        bytes32 indexed PoapID,
        string PoapName,
        string PoapDescription,
        string PoapLocation,
        uint256 Starts,
        uint256 Ends,
        address PoapOwner,
        uint256 CreationTime
    );

    //Helper Functions: =======================================================================================

    function hashIDStr (string calldata str) internal view returns (bytes32) { //collison hash 
        return keccak256(abi.encodePacked(str, block.timestamp, block.difficulty)); 
    }  

    //Primary Functions:  ===========================================================================================

    //Create Collection:
    function createCollection (string calldata _collectionName, string calldata _collectionDesc) external {

        //Requires:
        require (bytes(_collectionName).length <= 50, "Collection name cannot surpass 50 bytes."); 
        require (bytes(_collectionDesc).length <= 280, "Collection description cannot surpass 280 bytes.");
        require (takenNames[_collectionName] == false, "This collection name already exist."); 

        bytes32 collectionID = hashIDStr(_collectionName); //CollectionID 

        Collection storage newCollection = IDToCollection[collectionID]; //Pointer for assignment | ID => Struct mapping in storage contract 

        //Collection struct instance assignments 
        newCollection.collectionID = collectionID; 
        newCollection.collectionOwner = msg.sender; 
        
        newCollection.collectionName = _collectionName;
        newCollection.collectionDesc = _collectionDesc;

        //Push to mappings and arrays
        userCreatedCollections[msg.sender].push(collectionID);
        takenNames[_collectionName] = true;
        collectionIDs.push(collectionID);   
        
        //Increment state vars
        collectionsCreated++;

        emit CollectionCreated (collectionID, _collectionName, _collectionDesc, msg.sender, block.timestamp);    
    }

    //Create Poap: URI = [0] Name = [1] Desc = [2] Loc = [3] | start = [0] end = [1] maxCol = [2]
    function createPoap (string[] calldata _poapStrings, uint256[] calldata _poapUints) external {

        //String Requires:
        require (bytes(_poapStrings[1]).length <= 50, "Poap name cannot surpass 50 bytes.");
        require (bytes(_poapStrings[2]).length <= 280, "Poap description cannot surpass 280 bytes.");
        require (takenNames[_poapStrings[1]] == false, "Poap name already exist."); 

        //Time Requires: 
        require (_poapUints[0] > block.timestamp, "Poaps can not occur in the past."); 
        require (_poapUints[0] < _poapUints[1], "Poaps cannot end before they start."); 

        bytes32 poapID = hashIDStr(_poapStrings[1]); //poapID

        Poap storage newPoap = IDToPoap[poapID]; //Pointer for assignment | ID => Struct mapping in storage contract 

        //Poap struct instance assignments:
        newPoap.poapID = poapID; 
        newPoap.poapOwner = msg.sender;

        newPoap.poapBaseURI = _poapStrings[0];
        newPoap.poapName = _poapStrings[1]; 
        newPoap.poapDesc = _poapStrings[2]; 
        newPoap.poapLocation = _poapStrings[3];  
         
        newPoap.startTime = _poapUints[0];
        newPoap.endTime = _poapUints[1]; 
        newPoap.supply = _poapUints[2];
        newPoap.status = true; 

        //Push to mappings and arrays:
        userCreatedPoaps[msg.sender].push(poapID);
        takenNames[_poapStrings[1]] = true;
        poapIDs.push(poapID); 

        poapsCreated++;

        emit PoapCreated (poapID, newPoap.poapName, newPoap.poapDesc, newPoap.poapLocation,
        newPoap.startTime, newPoap.endTime, msg.sender, block.timestamp);  
    } 
}