/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract Kill {

    constructor() payable{

    }

    function kill() external {
        selfdestruct(payable(msg.sender));
    }
	
}