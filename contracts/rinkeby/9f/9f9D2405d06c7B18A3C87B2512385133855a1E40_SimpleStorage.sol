/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    // Max size of uint8 is max no. possible in 8 bits
    // 2^8 + 2^7 + ..... 2^2 + 2^1 + 2^0 = 255
    uint8 a = 1 *(128+64+32+16+8+4+2+1);

    // max value = 127
    int8 a1 = 1*(64 + 32 + 16 + 8 + 4 + 2 + 1);
    // max value = -128
    int8 a2 = -1*(64 + 32 + 16 + 8 + 4 + 2 + 1 + 1);

    bool favouriteBool = false;

    string favouriteString = 'apoorv';

    uint256 b = 128+64+32+16+8+4+2+1;

    address addr = 0xB7e390864a90b7b923C9f9310C6F98aafE43F707;

    bytes32 favBytes = "cat";

    function getA() external view returns (int8) {
        return a2;
    }

}