/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract engine {
    function kill() public {
        selfdestruct(address(1));
    }

}