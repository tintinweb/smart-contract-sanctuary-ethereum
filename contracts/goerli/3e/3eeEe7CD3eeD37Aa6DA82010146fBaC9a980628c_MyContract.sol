// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    struct Identity {
        
        string name;
        uint age;
        string[] documents;
        mapping(address => bool) authorized;
    }
     mapping(address => Identity) identities;
     uint256 public nbreidentity=0;
      event IdentityCreated(address indexed owner);
    event DocumentAdded(address indexed owner, string document);
    event AuthorizationGranted(address indexed owner, address indexed authorized);
    event AuthorizationRevoked(address indexed owner, address indexed authorized);
    function createIdentity(string memory _name, uint _age) public {
        Identity storage newIdentity = identities[msg.sender];
        newIdentity.name = _name;
        newIdentity.age = _age;
        emit IdentityCreated(msg.sender);
    }
    function addDocument(string memory _document) public {
        Identity storage identity = identities[msg.sender];
        identity.documents.push(_document);
        emit DocumentAdded(msg.sender, _document);
    }
     
    function grantAuthorization(address _authorized) public {
        Identity storage identity = identities[msg.sender];
        identity.authorized[_authorized] = true;
        emit AuthorizationGranted(msg.sender, _authorized);
    }
    
    function revokeAuthorization(address _authorized) public {
        Identity storage identity = identities[msg.sender];
        identity.authorized[_authorized] = false;
        emit AuthorizationRevoked(msg.sender, _authorized);
    }
     function getIdentity(address _owner) public view returns(string memory, uint, string[] memory) {
        Identity storage identity = identities[_owner];
        require(identity.authorized[msg.sender], "Access denied");
        return (identity.name, identity.age, identity.documents);
    }
}