/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract setNumberContract{
    address reserved;
    uint256 public number;
    
     /**
     * @dev upgrades the implementation of the proxy
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function setNumber(uint256 _number) public {
        number = _number * 15;
    }
}