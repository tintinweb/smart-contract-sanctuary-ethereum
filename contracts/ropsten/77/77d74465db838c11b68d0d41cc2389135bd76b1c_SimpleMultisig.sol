/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SimpleMultisig {

    address one;
    address two;

    event actioned(address indexed from, string message);


    mapping(address => bool) signed;

    constructor() {
        one = 0xc5D38778031a7943Bfd5ce6B02D5B9A86C38d58F;
        two = 0x9C4644aaD1311010BbCc7443FcF0Ca7bA178C320;
    }

    function Sign() public {
        require (msg.sender == one || msg.sender == two);
        require (!signed[msg.sender]);
        signed[msg.sender] = true;
    }

    function Action() public returns (bool) {
        require (signed[one] && signed[two]);
        emit actioned(msg.sender, "bla");
        return true;
    }
}