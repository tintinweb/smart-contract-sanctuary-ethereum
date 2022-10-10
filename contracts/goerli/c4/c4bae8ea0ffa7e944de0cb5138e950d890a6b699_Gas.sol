/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.3;
contract Gas {
    function testGasrefund()public view returns (uint) {
        return tx.gasprice;

    }
}