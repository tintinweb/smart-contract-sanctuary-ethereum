/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract BalanceFetcher {

    function fetch (address _address) external view returns (uint) {
        return _address.balance;
    }

}