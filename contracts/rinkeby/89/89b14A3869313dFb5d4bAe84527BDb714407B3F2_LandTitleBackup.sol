/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.6;



// File: LandTitleBackup.sol

contract LandTitleBackup {
// variables & mappings

mapping(uint256 => string) public titleInfo; // current owner & associated info

mapping(uint256 => mapping(uint256 => string)) public interestInfo; // current owner & associated info

address public admin = 0x602cdfBebF739CEf6D8020BbBe80006b4207FEAa; // only admin can make changes


constructor () public {}

function updateLandTitle(uint256 titleID, string memory info) public {
  require(msg.sender == admin);
  // Add land title to contract
  titleInfo[titleID] = info;
  }

function updateLandTitleInterest(uint256 titleID, uint256 interestID, string memory info) public {
  require(msg.sender == admin);
  // Add land interest to contract
  interestInfo[titleID][interestID] = info;
  }


}