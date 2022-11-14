/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleDonationManager {
    // uint256 immutable minDonation = 42;
    // uint256 immutable maxDonation = 555;
    
    // address immutable owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;   

    address immutable owner;   

    constructor()  {
        owner = msg.sender;
    }
}