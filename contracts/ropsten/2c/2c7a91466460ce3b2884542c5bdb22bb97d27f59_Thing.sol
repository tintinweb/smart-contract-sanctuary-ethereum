/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Thing{
    event Log(string msg);

    constructor(){
        emit Log("Ethereum is a product of love. Love for humans, love for what we can accomplish together, love for freedom.");
    }
}