/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
this is for test purpose and only got a dump function
 */
contract TpImp1 {
    constructor(){}

    function whoami() external pure returns(string memory) {
        return "This is the TpImp1 contract";
    }
}

contract TpImp2 {
    constructor(){}

    function whoami() external pure returns(string memory) {
        return "This is the TpImp2 contract";
    }
}