/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

contract GasTest {
    constructor() {}

    function baseGasLeft() public view returns (uint) {
        return gasleft();
    }

    function testGas(uint input) public view returns (uint) {
        uint startGas = gasleft();
        
        unchecked {
            for (uint i; i < input; ++i) {}
        }

        return startGas - gasleft();
    }
}