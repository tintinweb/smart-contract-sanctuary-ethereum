/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract BlockTest {

    function getChainId() public view returns(uint256) {
        return block.chainid;
    }
	
}