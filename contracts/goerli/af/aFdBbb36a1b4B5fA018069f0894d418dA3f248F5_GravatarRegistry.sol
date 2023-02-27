/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.0;
 
contract GravatarRegistry {
  event NewGravatar(uint id, address owner, string displayName, string imageUrl);
  event UpdatedGravatar(uint id, address owner, string displayName, string imageUrl);
 
  struct Gravatar {
    address owner;
    string displayName;
    string imageUrl;
  }
 
  Gravatar[] public gravatars;
 
  mapping (uint => address) public gravatarToOwner;
  mapping (address => uint) public ownerToGravatar;
 
  function createGravatar(string calldata _displayName, string calldata _imageUrl) public {
    require(ownerToGravatar[msg.sender] == 0);
    gravatars.push(Gravatar(msg.sender, _displayName, _imageUrl));
    uint id = gravatars.length - 1;
 
    gravatarToOwner[id] = msg.sender;
    ownerToGravatar[msg.sender] = id;
 
    emit NewGravatar(id, msg.sender, _displayName, _imageUrl);
  }
 
  function getGravatar(address owner) public view returns (string memory, string memory) {
    uint id = ownerToGravatar[owner];
    return (gravatars[id].displayName, gravatars[id].imageUrl);
  }
 
  function updateGravatarName(string calldata _displayName) public {
    require(ownerToGravatar[msg.sender] != 0);
    require(msg.sender == gravatars[ownerToGravatar[msg.sender]].owner);
 
    uint id = ownerToGravatar[msg.sender];
 
    gravatars[id].displayName = _displayName;
    emit UpdatedGravatar(id, msg.sender, _displayName, gravatars[id].imageUrl);
  }
 
  function updateGravatarImage(string calldata _imageUrl) public {
    require(ownerToGravatar[msg.sender] != 0);
    require(msg.sender == gravatars[ownerToGravatar[msg.sender]].owner);
 
    uint id = ownerToGravatar[msg.sender];
 
    gravatars[id].imageUrl =  _imageUrl;
    emit UpdatedGravatar(id, msg.sender, gravatars[id].displayName, _imageUrl);
  }
 
  // the gravatar at position 0 of gravatars[]
  // is fake
  // it's a mythical gravatar
  // that doesn't really exist
  // dani will invoke this function once when this contract is deployed
  // but then no more
  function setMythicalGravatar() public {
    require(msg.sender == 0xBA8B604410ca76AF86BDA9B00Eb53B65AC4c41AC);
    gravatars.push(Gravatar(address(0x0), " ", " "));
  }
}