/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.6;



// File: LandTitleBackup.sol

contract LandTitleBackup {
// variables & mappings

mapping(uint256 => string) public titleCurrentInfo; // current owner & associated info

mapping(uint256 => mapping(uint256 => string)) public titleHistoricalInfo; // past owners and their info

mapping(uint256 => uint256) public transferCounter; // needed for keeping track of historical info

address public admin = 0x602cdfBebF739CEf6D8020BbBe80006b4207FEAa; // only admin can make changes


constructor () public {}

// call on a land title transfer to update ownership & historical information
function updateLandTitle(uint256 titleID, string memory newOwner, string memory oldOwner) public {
  require(msg.sender == admin);

  // record ownership (I'm using a string but can change to some kind of ID # instead)
  titleCurrentInfo[titleID] = newOwner;
  titleHistoricalInfo[titleID][transferCounter[titleID]] = oldOwner;
  transferCounter[titleID] = transferCounter[titleID] + 1;

  }

// call for migration of current land title info
function addLandTitle(uint256 titleID, string memory newOwner) public {
  require(msg.sender == admin);

  // Adding existing land title to the contract
  titleCurrentInfo[titleID] = newOwner;

  }
}