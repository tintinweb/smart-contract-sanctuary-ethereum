/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title hipotenusHesapla
 * @dev Implements voting process along with vote delegation
 */
contract hipotenusHesapla {

    function hipoHesapla(uint a, uint b) public returns (uint y) {
        uint x = a*a+b*b;
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
         }
        return y;
    }
}