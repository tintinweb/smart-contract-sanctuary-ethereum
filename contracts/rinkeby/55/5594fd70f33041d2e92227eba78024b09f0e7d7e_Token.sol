/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <0.9.0;

contract Token {

    string public name = "My Token";
    string public symbol = "MTK";
    uint public decimals = 18;
    uint public totalSupply = 1000000 * (10 ** decimals);

    constructor(uint _x) public {
        totalSupply = _x;
    }

}