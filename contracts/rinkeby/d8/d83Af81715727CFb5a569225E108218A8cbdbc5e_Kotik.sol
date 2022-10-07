/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Kotik {

    address payable kotikContract = 0x7BA2DeD678581bD961f19982967CD4F5f074266f;

    constructor() public payable {        
    }

    function recieve() public payable {
    }

    function selfDestroy() public { 
        selfdestruct(kotikContract);
    }
}