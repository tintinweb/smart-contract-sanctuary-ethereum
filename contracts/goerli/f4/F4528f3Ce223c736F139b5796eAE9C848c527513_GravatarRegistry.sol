/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

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
    uint id = gravatars.length- 1;

    gravatarToOwner[id] = msg.sender;
    ownerToGravatar[msg.sender] = id;

    emit NewGravatar(id, msg.sender, _displayName, _imageUrl);
  }

  function updateGravatarName(string calldata _displayName) public {
    require(ownerToGravatar[msg.sender] != 0);
    require(msg.sender == gravatars[ownerToGravatar[msg.sender]].owner);

    uint id = ownerToGravatar[msg.sender];

    gravatars[id].displayName = _displayName;
    emit UpdatedGravatar(id, msg.sender, _displayName, gravatars[id].imageUrl);
  }
}