/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract IsArt {

  bool public isArt; // defaults to false
  uint256 public yesVotes;
  uint256 public noVotes;


  function voteYes() public {
    yesVotes++;

    if(yesVotes < noVotes) {
        isArt = false;
    } else {
        isArt = true;
    }
  }

  function voteNo() public {
    noVotes++;

    if(yesVotes < noVotes) {
        isArt = false;
    } else {
        isArt = true;
    }
  }

  function viewVotes() public view returns (uint256, uint256) {
      return (yesVotes, noVotes);
  }

  function viewStatus() public view returns (bool) {
    
    // note: if the vote is tied, then the contract is considered art,
    // because anything provocative enough to cause such a split in
    // public opinion must surely be considered art
    //
    // note: the above note is a conceptual way to account for the fact
    // that a boolean can only store 'true' or 'false'. If you want
    // a variable to hold the possibility of a 3rd value, consider
    // using a uint8, where 0 = false, 1 = true, and 2 = tie;

    return isArt;
  }
}