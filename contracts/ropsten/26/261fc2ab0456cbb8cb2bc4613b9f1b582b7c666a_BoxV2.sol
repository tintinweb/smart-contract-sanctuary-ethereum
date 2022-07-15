/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
// Будем апгрейлить этот контракт с контракта Box
pragma solidity 0.8.10;

contract BoxV2 {
    uint public val;
// эта функция не нужна так как это уже вторая версия контракта
    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }
}