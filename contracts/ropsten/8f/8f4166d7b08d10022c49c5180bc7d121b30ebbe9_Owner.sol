/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
    uint256 public c;

    function hi( uint128 a , uint128 b) public  returns (uint256) {
        c = a+b; 
        return c;
    }
}