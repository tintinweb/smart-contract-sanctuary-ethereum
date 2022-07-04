/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// File: financeDept.sol


pragma solidity ^0.8.4;

// must know job salary + reg ID
// import functions to know company owners
// import ability to mint new tokens from Reg Dollars
// import ability to know if user is owner of a regular 

contract FinanceDept {

    // mapping(uint => uint) lastClaimed;
    // mapping(uint => uint) balance;
    // uint duration = 1 days;
    // address REGULAR_DOLLAR_ADDRESS = 0x0000000000000000000000000000000000000000;

    constructor() {
    }

    // Calculate unclaimed
    function calculateUnclaimed(uint _timeStamp, uint _salary, uint _level) public returns (uint) {
        uint maxCheckinTime = 2 weeks;

        return 69;
    }

    // //  Multiplier based on ownership of multiple of the same companies.. at time of claim.
    // function getMultiplier(address _address) public returns (uint) {

    // }

    // function checkOwner() public returns (bool){
    //     // you can only claim if you still own the regular. 
    // }

}