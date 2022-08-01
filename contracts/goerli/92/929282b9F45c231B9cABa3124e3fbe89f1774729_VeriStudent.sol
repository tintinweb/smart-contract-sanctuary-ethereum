/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract VeriStudent {

  enum Progress {Pendent, Verified, Denied}

  struct Document {
      string name;
      string surname;
      string dateOfBirth;
      string email;
      string studentNumber;
      Progress progress;
      string uri;
      address account;      
  }

  mapping(bytes32 => Document) public documents;
  mapping(address => bool) public isAdmin;

  bytes32[] arrayDocuments;

  constructor() {
    isAdmin[msg.sender] = true;
  }

  function setDocument(string memory _name, string memory _surname, string memory _dateOfBirth, string memory _uri, string memory _email, string memory _studentNumber) public {
    
    Document memory document;
    document.name = _name;
    document.surname = _surname;
    document.dateOfBirth = _dateOfBirth;
    document.uri = _uri;
    document.progress = Progress.Pendent;
    document.account = msg.sender;
    document.email = _email;
    document.studentNumber = _studentNumber;

    bytes32 hash = keccak256(abi.encodePacked(_name, _surname, _dateOfBirth, _uri));

    documents[hash] = document;
    arrayDocuments.push(hash);

  }

  function getHash(string memory _name, string memory _surname, string memory _dateOfBirth, string memory _uri) public pure returns(bytes32) {
    bytes32 hash = keccak256(abi.encodePacked(_name, _surname, _dateOfBirth, _uri));
    return hash;
  }

  function setAdmin(address _newAdmin) public {
    require(isAdmin[msg.sender]);
    isAdmin[_newAdmin] = true;
  }

  function removeAdmin(address _removeAdmin) public {
    require(isAdmin[msg.sender]);
    isAdmin[_removeAdmin] = false;
  }

  function setVerified(bytes32 _hash) public {
    require(isAdmin[msg.sender]);
    documents[_hash].progress = Progress.Verified;
  }

  function setDenied(bytes32 _hash) public {
    require(isAdmin[msg.sender]);
    documents[_hash].progress = Progress.Denied;
  }

  function getListDocuments() public view returns(bytes32[] memory) {
    require(isAdmin[msg.sender]);
    return arrayDocuments;
  }


}