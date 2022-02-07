// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Wonder {
  event Hatch(address indexed from, uint256 indexed tokenId);

  function hatchEgg(uint256 _tokenId) external {
    emit Hatch(msg.sender, _tokenId);
  }

  function hatchEgg(address _from, uint256 _tokenId) external {
    emit Hatch(_from, _tokenId);
  }
}