// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
  uint256[] votes;

  function doVote(uint256 _vote) public {
    votes.push(_vote);
  }

  function retrieve() public view returns (uint256[] memory) {
    return votes;
  }
}