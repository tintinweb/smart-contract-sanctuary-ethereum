// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Test {
    function test() external payable returns(uint, uint) {
        uint beforeGas = gasleft();
        block.coinbase.transfer(msg.value);
        uint afterGas = gasleft();
        return (beforeGas, afterGas);
    }
}