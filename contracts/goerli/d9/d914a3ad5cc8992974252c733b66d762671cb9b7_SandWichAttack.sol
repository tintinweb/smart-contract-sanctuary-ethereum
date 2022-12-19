/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-31
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract SandWichAttack {
    uint256 public sandwich_attack_cnt = 0;
    address public wallet;

    function sandwichAttack(address _wallet ) external {
        sandwich_attack_cnt ++;
        wallet = _wallet;
    }
}