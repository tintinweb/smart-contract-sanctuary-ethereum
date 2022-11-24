/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZaskoczMnie {
    bool zaskoczona = false;
    constructor(string memory compliment) {
        if (bytes(compliment).length > 0){
            zaskoczona = true;
        }
    }
}