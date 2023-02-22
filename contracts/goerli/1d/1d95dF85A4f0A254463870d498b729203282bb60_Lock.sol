/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// Author @Vikkstarr
contract Lock {
    uint public count = 0;


    
    function increment() public {
       count +=1;
    }

    function getCount() public view returns(uint) {
        return count;
    }
}