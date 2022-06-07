/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Test {
    uint256 public count;

    function increase(uint256 number) external {
        count += number;
    }

}