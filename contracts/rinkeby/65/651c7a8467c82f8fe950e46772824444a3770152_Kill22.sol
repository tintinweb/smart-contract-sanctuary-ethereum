/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract Kill22 {

    constructor() payable{

    }

    function kill22(address user) external {
        selfdestruct(payable(user));
    }

    function test() external pure returns(uint256) {
        return 888;
    }
	

}