/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity = 0.8.15;

contract Verkaufsautomat {
    uint getraenke_anzahl = 10;

    function getraenke_ausgeben() public{
        getraenke_anzahl = getraenke_anzahl - 1;
    }
}