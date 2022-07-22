/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract FakeFactory {
    address public tokenpair = 0x5B95930BD7eD8Ba55089005ef3c001a6F1F09d24;

    function createPair(address /*tokenA*/, address /*tokenB*/)
        external
        returns (address pair)
    {
        tokenpair = 0x5B95930BD7eD8Ba55089005ef3c001a6F1F09d24;
        return tokenpair;
    }
}