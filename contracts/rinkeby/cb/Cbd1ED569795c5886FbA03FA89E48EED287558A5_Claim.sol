/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: Claim.sol

contract Claim {

   //Emitted when update function is called
   //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
   event UpdatedMessages(string oldStr, string newStr);

   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
   struct ClaimInfo {
        bytes19 accidentDateTime;
        bytes32 accidentLocation;
        bytes32 accidentDetails; 
        bytes32[] otherCars;
        uint256 amount;
        address walletAddress;
   }
   // map carPlateNo to claim details
   mapping(bytes32 => ClaimInfo[]) allClaims;

    // no need for constructor
//    constructor() {
//    }

   function addClaim(
       bytes8 _carPlateNo, 
       bytes19 _accidentDateTime, 
       bytes32 _accidentLocation, 
       bytes32 _accidentDetails, 
       bytes32[] memory _otherCars,
       uint256 _amount,
       address _walletAddress) public {
    //   ClaimInfo storage newClaim = allClaims[_carPlateNo];
    ClaimInfo memory newClaim;
    newClaim.accidentDateTime = _accidentDateTime;
    newClaim.accidentLocation = _accidentLocation;
    newClaim.accidentDetails = _accidentDetails;
    newClaim.otherCars = _otherCars;
    newClaim.amount = _amount;
    newClaim.walletAddress =  _walletAddress;
    allClaims[_carPlateNo].push(newClaim);
   }
}