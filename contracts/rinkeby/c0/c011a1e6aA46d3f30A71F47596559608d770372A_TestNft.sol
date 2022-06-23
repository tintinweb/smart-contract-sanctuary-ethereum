/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract TestNft{

    uint public price = 100;

    function updatePrice(uint x) public {

        price = x;
    }
}