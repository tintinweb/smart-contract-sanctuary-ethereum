/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// File: contracts/FileStorage.sol



pragma solidity ^0.8.5;


/// @title Nestcoin Library - A decentralised library
/// @author Team Probation - Blockgames - Game phase
/// @notice You can use this contract just to see the workings of a decentralized Library storage system
/// @dev All function calls are currently implemented without side effects
contract Filestorage {

/// @dev Three state variables are declared, name which is public and  countPublic and countPrivate whch are assign the value 0
    string public name;
    uint countPublic = 0;
    uint countPrivate = 0;
    
    enum Status { Public, Private }


 
/// @dev The the Publicfile struct takes in count-number of files, owner's address, the ipfsHash of the file and status for public files
    struct Publicfile {
        string title;
        Status visibility;
        string ipfsHash;
        string description;
        address owner;
        uint count;
    }
/// @dev The the Privatefile struct takes in count-number of files, the ipfsHash of the file and status for private files
    struct Privatefile {
        string title;
        Status visibility;
        string ipfsHash;
        string description;
        address owner;
        uint count;
    }
/// @dev The the sharedFile struct takes in the address of the person sharing the file, the Hash of the shared file
    struct sharedFile {
        address shared_by;
        string shared_hash;
    }
/// @dev Here private and shared files are mapped to an address*
    mapping (uint => Publicfile) public publicfiles;
    mapping (address => Privatefile[]) public privatefiles;
    mapping (address => sharedFile[]) public shared_files;

 /// @notice Uploads the file*
/// @param count The number of file uploaded 
/// @param owner The address of the file owner
/// @param Hash The Hash of the file uploaded
/// @param status The status of the file
    event FileCreation ( uint count, address owner, string Hash, Status status);


/// @notice This upload files based on their stauses wheather public or private



function addFile ( string memory _title, Status  _visibility, string memory _ipfsHash, string memory _description,  address _owner ) public {
      if(keccak256(abi.encodePacked(_visibility)) == keccak256(abi.encodePacked("public"))) {
            countPublic ++;
            publicfiles[countPublic] = Publicfile( _title,  _visibility, _ipfsHash,  _description,  msg.sender, countPublic);
            emit FileCreation(countPublic, msg.sender, _ipfsHash, Status.Public );
        }
    else {
        countPrivate ++;
        privatefiles[_owner].push(Privatefile(_title,  _visibility, _ipfsHash,  _description,  _owner, countPublic ));
        emit FileCreation(countPrivate, _owner, _ipfsHash, Status.Private );
    }
    }
    
    /// @notice Retrieve public files
    /// @return returns uploaded public files
    function retrievePublicFile () public view returns(Publicfile[] memory) {
      Publicfile[] memory public_files = new Publicfile[] (countPublic);
      for(uint i=0; i<countPublic; i++) {
        Publicfile storage public_file = publicfiles[i];
            public_files[i] = public_file;
      }
      return public_files;
  }
   
  /// @notice Retrieve private files
  /// @return returns uploaded private files accessible only to the uploader
  /// @param _address The address of the uploader
  function retrievePrivateFile (address _address) public view returns (Privatefile[] memory)  {
      require(msg.sender == _address, "You do not have Access to retrieve this file");
      return privatefiles[_address];
  }

  /// @notice Shares uploaded files
  /// @param _share_to The address you want to share the uploaded file with 
  /// @param _hashed_file The hash of the file to be shared
  function shareFile ( address _share_to, string memory _hashed_file ) public {
      require( _share_to != address(0), "Actual address is required");
      require(msg.sender != _share_to, "You cannot share to yourself");
      shared_files[_share_to].push(sharedFile(msg.sender, _hashed_file));
  }
  
  /// @notice Retrieves files shared with your address
  /// @param _address The address the file is shared to
  /// @return Returns the files shared with an address
  function getSharedFile(address _address) public view returns (sharedFile[] memory) {
      return shared_files[_address];
  }
}