/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


// check how solidity compiles "<=" to OPCODEs
contract LE {
    function le(uint256 x, uint256 y) external pure returns(uint256) {
        if (x<=y) {
            return 1;
        }
        return 0;
    }
}