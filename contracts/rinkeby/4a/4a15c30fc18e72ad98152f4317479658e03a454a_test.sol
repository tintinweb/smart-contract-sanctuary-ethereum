/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.1;

contract test {
    uint pizzalike;
    uint pizzahate;
    uint hamlike;
    uint hamhate;

    function pizza_like() public returns(uint) {
        pizzalike = pizzalike + 1;
        return pizzalike;
    }

    function pizza_hate() public returns(uint) {
        pizzahate = pizzahate + 1;
        return pizzahate;
    }

    function ham_like() public returns(uint) {
        hamlike = hamlike + 1;
        return hamlike;
    }

    function ham_hate() public returns(uint) {
        hamhate = hamhate + 1;
        return hamhate;
    }
}