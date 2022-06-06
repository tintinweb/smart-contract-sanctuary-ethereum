/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test2 {
    
    mapping(address => uint256) private presaleBalances;
    
    function test3(address[] memory addresses) public {
        for( uint i; i < addresses.length; ++i ){
            presaleBalances[addresses[i]] += 1;
        }
    }

    function up(address address_) public {
        presaleBalances[address_] += 1;
    }
}