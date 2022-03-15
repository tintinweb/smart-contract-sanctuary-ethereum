/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract MarketRebalanceMocked {
    
    uint public rebalanceCounter;

    function rebalance() external {
        for(uint i; i < 100; i++ ) {}
        rebalanceCounter++;
    } 

    function isRebalanceNeeded() public view returns (bool) {  
        return true;
    }
}