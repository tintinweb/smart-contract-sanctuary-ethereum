// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

contract Claim {

   //Emitted when update function is called
   //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
   event UpdatedMessages(string oldStr, string newStr);

   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
    struct ClaimInfo {
        string accidentDateTime;
        string accidentLocation;
        string accidentDetails; 
        string[] otherCars;
        uint256 amount;
        address walletAddress;
   }
   // map carPlateNo to claim details
   mapping(string => ClaimInfo[]) allClaims;
   // bytes32[] public carPlateNo;
    struct queryInfo {
        string accidentDateTime;
        string accidentLocation;
        string accidentDetails; 
        string[] otherCars;
   }

    // no need for constructor
//    constructor() {
//    }

   function addClaim(
       string memory _carPlateNo, 
       string memory _accidentDateTime, 
       string memory _accidentLocation, 
       string memory _accidentDetails, 
       string[] memory _otherCars,
       uint256 _amount,
       address _walletAddress) public {
    //   ClaimInfo storage newClaim = allClaims[_carPlateNo];
   //  carPlateNo.push(_carPlateNo);
    ClaimInfo memory newClaim;
    newClaim.accidentDateTime = _accidentDateTime;
    newClaim.accidentLocation = _accidentLocation;
    newClaim.accidentDetails = _accidentDetails;
    newClaim.otherCars = _otherCars;
    newClaim.amount = _amount;
    newClaim.walletAddress =  _walletAddress;
    allClaims[_carPlateNo].push(newClaim);
   }

   function getClaims(string memory _carPlateNo) public view returns (
      // uint256, bytes19, bytes32, bytes32, bytes32[] memory, uint256, address) {
      ClaimInfo[] memory) {
         ClaimInfo[] storage queryClaimArr = allClaims[_carPlateNo];
         // string memory dateTimeStr = queryClaimArr[0].accidentDateTime;
         // string memory locationStr = queryClaimArr[0].accidentLocation;
         // string memory detailsStr = queryClaimArr[0].accidentDetails;
         // string memory otherCars = queryClaimArr[0].;
         if (queryClaimArr.length > 0) {
            ClaimInfo[] memory id = new ClaimInfo[](queryClaimArr.length);
            for (uint i=0; i<queryClaimArr.length; i++) {
               ClaimInfo storage claim = queryClaimArr[i];
               // claim.accidentDateTime = queryClaimArr[i].accidentDateTime;
               // claim.accidentLocation = queryClaimArr[i].accidentLocation;
               // claim.accidentDetails = queryClaimArr[i].accidentDetails;
               // claim.otherCars = queryClaimArr[i].otherCars;
               id[i] = claim;
            }
            return id;
         }
   }
}