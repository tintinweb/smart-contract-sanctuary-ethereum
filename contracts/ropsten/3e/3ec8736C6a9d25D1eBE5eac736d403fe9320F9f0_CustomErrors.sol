/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract CustomErrors {
    error Works(address);

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function callOnlyAdmin(address newAdmin) public {
        if (msg.sender != admin) {
            revert Works(msg.sender);
        }

        admin = newAdmin;
    }
}