/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract Kartenauomat {
    uint Karten_anzahl = 10;

    function Karten_ausgeben() public{
        Karten_anzahl = Karten_anzahl - 1;
    }
}