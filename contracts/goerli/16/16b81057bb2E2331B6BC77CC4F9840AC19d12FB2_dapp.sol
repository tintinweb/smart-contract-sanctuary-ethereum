/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract dapp {
    string public name = "Hello World";

    function setName(string memory n) public {
        name = n;
    }
}