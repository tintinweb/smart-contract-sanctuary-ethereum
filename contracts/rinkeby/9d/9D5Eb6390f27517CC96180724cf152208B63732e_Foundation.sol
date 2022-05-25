/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.23 <0.9.0;

contract Foundation {
    string public name;
    address public _owner;
    constructor(
        string memory _name
    ) public {
        name = _name;
        _owner = msg.sender;
    }
}