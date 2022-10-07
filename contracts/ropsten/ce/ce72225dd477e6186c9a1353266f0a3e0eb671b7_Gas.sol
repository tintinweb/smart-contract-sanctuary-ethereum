/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental SMTChecker;

contract Gas {

    function gasLimit() public view returns (uint) {
        return block.gaslimit;
    }

}