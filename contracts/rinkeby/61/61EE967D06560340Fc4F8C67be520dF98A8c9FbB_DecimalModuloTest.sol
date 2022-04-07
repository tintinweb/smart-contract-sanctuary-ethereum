/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract DecimalModuloTest {

    function div(uint a, uint b) public pure returns (uint) {
        return a / b;
    }

    function mod(uint a, uint b) public pure returns (uint) {
        return a % b;
    }

    function currentTimestamp() public view returns (uint) {
        return block.timestamp;
    }

}