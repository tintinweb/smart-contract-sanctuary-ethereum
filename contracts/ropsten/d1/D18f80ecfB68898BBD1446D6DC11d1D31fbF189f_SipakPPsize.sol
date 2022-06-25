/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT

// Specify the version of solidity
pragma solidity ^0.8.15;

// Define the contract
contract SipakPPsize {

    // Create "storage" vaiable pp_size
    // Setting the value to default of 1 (cm) as of sympathy
    uint pp_size = 1;
    
    // This function writes onto the blockchian and does use gas
    // as a state is being changed
    function setPPsize(uint _pp_size) public {
        pp_size = _pp_size;
    }
    
    // This function gets read and returns the value of `pp_size` from
    // the blockchain and uses no gas as we used `view`.
    function getPPsize() public view returns (uint) {
        return pp_size;
    }
}