/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Atlantis file manager
 * @author Atlantis team
 * @notice Keep track of the record of files you can view and share on the contract, the meta data for the 
 * file is stored on the contract but the file itseleis stored on IPFS
 * @dev Contract enables users to store, retrieve and share files on a decentralized file sharing system,
 * our contract is used to keep track of who can view a file and the access level of the files
 */
 
 // counter library
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// safe math library for handling simpl arithmentic operations
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/* This is the Atlantis file manager contract, it can
   be used to store, retrieve and share files on chain 
   using the ethereum block chain
*/
contract AtlantisFileManager {
    
    // We use an enumerator to store the various access level of our fo;es
    enum AccessLevel {
        PUBLIC,
        PRIVATE
    }

    // This is struct used to represent a file object on our contract
    struct File {
        uint256 tokenId;
        string name;
        address owner;
        string url;
        string description;
        AccessLevel access_level;
    }
    // This is a mapping that keeps track of files and the addresses that have access to it
    mapping(uint256 => mapping(address=>bool)) access;

    // Mapping of tokenIds to files objects
    mapping( uint256 => File) internal files;

    // Using counters from open zepplin
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    // @dev This is the counter used to keep track of the latest id of the tokens, it also helps us keep track of all the tokens we have
    Counters.Counter public _tokenIdCounter;

    modifier hasAccessToFile(uint256 _tokenId) {
        require(access[files[_tokenId].tokenId][msg.sender] == true || files[_tokenId].access_level == AccessLevel.PUBLIC, "you must have access to the file to get the file");
        _;
    }
    
    // @dev This is the method used to upload a file to our contract, the assumption is that the file has been pushed to ipfs
    function uploadFile(string memory _name, string memory _url, string memory _description) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current(); // generates a new tokenId
        _tokenIdCounter.increment();

        File memory _file = File(tokenId, _name, msg.sender, _url, _description, AccessLevel.PUBLIC); // creates a file struct
        files[tokenId] = _file; // store the file with its token id on the files map
        
        access[tokenId][msg.sender] = true; // give the owner access to the file
        return tokenId;
    }

    // @dev grant an address access to a file
    function grantAccess(uint256 _tokenId, address _account) external {

        // retrieve the file with the specified token id
        File memory _file = files[_tokenId];

        // check if the msg sender has access to the file
        require(access[_file.tokenId][msg.sender] == true, "you must have access to the file to grant access");

        // grant the account in the parameter access to the file
        access[_file.tokenId][_account] = true;
    }

    // @dev revoke an accounts access to a particular file
    function revokeAccess(uint256 _tokenId, address _account) external {

        // retrieve the file with the specified token id
        File memory _file = files[_tokenId]; 
        require(_file.owner == msg.sender, "you must be the owner to revoke access");

        // revoke an accounts access to the file
        access[_file.tokenId][_account] = false;
    }
    
    // @dev this method is used to get the meta data of a file after providing the token id of the file
    function getFileData(uint256 _tokenId) external view hasAccessToFile(_tokenId) returns(uint256 _id, string memory _name, address _owner, string memory _url, string memory _description, string memory _access_level){
        // retrieve the file with the specified token id
        File memory _file = files[_tokenId];
        string memory access_level = "public";
        // check if the file access is private
        if(_file.access_level == AccessLevel.PRIVATE){
        // if the file access is private only accounts with access can view the file
        access_level = "private";
        }
        // return the information about the file
        return (_file.tokenId, _file.name, _file.owner, _file.url, _file.description, access_level);

    }


    // @dev this function is used to make a file private and it can only be done by the owner of the file
    function makeFilePrivate(uint256 _tokenId) external {

        // retrieve a file with the specified token id
        File memory _file = files[_tokenId];

        // only the owner can make a file private
        require(_file.owner == msg.sender, "you must be the owner to make a file private");

        // set the file's access level to private
        files[_tokenId].access_level = AccessLevel.PRIVATE;
    }
    
    // @dev this function is used to make a file public and it can only be done by the owner fo the file
    function makeFilePublic(uint256 _tokenId) external {

        // retrieve a file with the specified token id
        File memory _file = files[_tokenId];

        // only owner can make a file public
        require(_file.owner == msg.sender, "you must be the owner to make a file public");

        // set the file's access level to public
        files[_tokenId].access_level = AccessLevel.PUBLIC;
    }
}