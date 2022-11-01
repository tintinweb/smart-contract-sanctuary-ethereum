/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract BirdDB {
   
   address public owner;

   /**
    * @notice Who are all the birds?
   */
   // this is only used for convenient listing of all active Birds
   // where possible, the `birdDB` mapping is used 
   address[] internal birds;

   /* We assume a bad actor could:
      - introduce fake timestamps, in which case the other birds will disagree, and file error reports against this bird
      - maliciciously file error reports against honest birds ("smear campaign")
      Hence, we need to keep track of ErrorsMade and ErrorsReported.
   */  
   struct Bird {
      string  BirdID;
      address Address;
      string  URI;
      bytes32 PubKey;
      bytes1  PubKeyPrefix;
      uint    TimeJoined;
      uint    TimeErrorsMade;       // how many errors did this Bird make, according to the other Birds?
      uint    TimeErrorsDiscovered; // how many errors did this bird discover and report?
      uint    SignatureErrorsMade;  // errors in the standard Dove signature
      uint    SignatureErrorsDiscovered;
      uint    TMPCAbortsCaused;
      uint    TMPCErrorsDiscovered;
   }

   mapping (address => Bird) birdDB;

   event BirdAdded(address, string);
   event BirdRemoved(address, string);
   event URIupdated(address, string);
   event BirdReported(address, uint /*error type*/);

   constructor() {
      owner = msg.sender;
   }

   /**
    * @notice A method to check if an address is a bird.
    * @param _address The address to verify.
    * @return bool Whether the address is a bird
   */
   function isBird(address _address)
       public
       view
       returns(bool)
   {
       return birdDB[_address].TimeJoined > 0;
   }

   /**
    * @notice A method to check if an address is a Bird and get its position in the birds array.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a bird, and if so, its position in the birds array.
    */
   function birdIndex(address _address)
       public
       view
       returns(bool, uint256)
   {

       for (uint256 s = 0; s < birds.length; s += 1){
           if (_address == birds[s]) return (true, s);
       }
       return (false, 0);
   }

   /**
    * @notice Get all registered birds and their URI.
    * @return Array of valid birds and their details.
    */
    // not really for production use
   function getAllBirds()
       public
       view
       returns(Bird[] memory)
   {
       Bird[] memory _validBirds;
       _validBirds = new Bird[](birds.length);
       for (uint256 s = 0; s < birds.length; s += 1){
           _validBirds[s] = birdDB[birds[s]];
       }
       return _validBirds;
   }

   /**
    * @notice Get my details.
    * @return Details for this bird.
    */
    // not really for production use
   function getMyInfo()
       public
       view
       returns(Bird memory)
   {
       return birdDB[msg.sender];
   }

   /**
    * @notice A method to add a bird.
    * @param _birdID The ID of the bird to add.
    * @param _uri The URI of the bird.
    */
   function addBird(string memory _birdID, 
    string memory _uri,
    bytes32 _pubKey,
    bytes1 _pubKeyPrefix)
       public
   {
      address birdAddress = msg.sender;

      require(
         birdDB[birdAddress].TimeJoined == 0,
         'Bird already exists in birdsDB'
      );

      (bool _isBird, ) = birdIndex(birdAddress);

      require(
         _isBird == false,
         'Internal Error: Bird exists in birds array but not in birdsDB'
      );

      // create and save the bird
      birdDB[birdAddress] = Bird({
         BirdID: _birdID,
         Address: birdAddress,
         URI: _uri,
         PubKey: _pubKey,
         PubKeyPrefix: _pubKeyPrefix,
         TimeJoined: block.timestamp,
         TimeErrorsMade: 0,
         TimeErrorsDiscovered: 0,
         SignatureErrorsMade: 0,
         SignatureErrorsDiscovered: 0,
         TMPCAbortsCaused: 0,
         TMPCErrorsDiscovered: 0
      });

      // add to convenience bird enumeration array
      birds.push(birdAddress);

      emit BirdAdded(birdAddress, _birdID);

   }

   /**
    * @notice A method to update a Bird's URI.
    * @param _newURI The new URI.
    */
   function updateURI(string memory _newURI)
       public
   {
      address birdAddress = msg.sender;

      require(
         birdDB[birdAddress].TimeJoined > 0,
         'Bird not registered'
      );

      birdDB[birdAddress].URI = _newURI;

      emit URIupdated(birdAddress, _newURI);

   }

   /**
    * @notice A method to remove a bird.
    * @param _address The bird to remove.
    */
   function removeBird(address _address)
       public
   {
       (bool _isBird, uint256 s) = birdIndex(_address);
       // take the last address, overwrite the to-be-removed 
       // address at index s, and then, delete the last array slot
       // This jumbles the order, but we don't care about 
       // order here 
       if(_isBird){
           birds[s] = birds[birds.length - 1];
           birds.pop();
           // FIXME function order here is not ideal
           emit BirdRemoved(_address, birdDB[_address].BirdID);
           delete birdDB[_address];
       }
   }

   /**
    * @notice A method to report potentially malfunctioning Birds.
    * @param _offendingAddress The contract address of the bird to report.
    */
   function reportTimeError(address _offendingAddress)
       public
   {
      address myAddress = msg.sender;

      require(birdDB[myAddress].TimeJoined > 0,'You do not exist yet; addBird() first');
      require(birdDB[_offendingAddress].TimeJoined > 0,'Offending Bird does not exist');
      require(_offendingAddress != myAddress,'Cannot report yourself');

      birdDB[_offendingAddress].TimeErrorsMade += 1;
      birdDB[myAddress].TimeErrorsDiscovered += 1;

      emit BirdReported(_offendingAddress, 1 /*error type*/);
   }

   /**
    * @notice A method to report potentially malsigning Birds.
    * @param _offendingAddress The contract address of the bird to report.
    */
   function reportSignatureError(address _offendingAddress)
       public
   {
      address myAddress = msg.sender;

      require(birdDB[myAddress].TimeJoined > 0,'You do not exist yet; addBird() first');
      require(birdDB[_offendingAddress].TimeJoined > 0,'Offending Bird does not exist');
      require(_offendingAddress != myAddress,'Cannot report yourself');

      birdDB[_offendingAddress].SignatureErrorsMade += 1;
      birdDB[myAddress].SignatureErrorsDiscovered += 1;

      emit BirdReported(_offendingAddress, 2 /*error type*/);
   }

   /**
    * @notice A method to report potentially dishonest Birds.
    * @param _offendingAddress The contract address of the bird to report.
    */
   function reportTMPCError(address _offendingAddress)
       public
   {
      address myAddress = msg.sender;

      require(birdDB[myAddress].TimeJoined > 0,'You do not exist yet; addBird() first');
      require(birdDB[_offendingAddress].TimeJoined > 0,'Offending Bird does not exist');
      require(_offendingAddress != myAddress,'Cannot report yourself');

      birdDB[_offendingAddress].TMPCAbortsCaused += 1;
      birdDB[myAddress].TMPCErrorsDiscovered += 1;

      emit BirdReported(_offendingAddress, 3 /*error type*/);
   }

}