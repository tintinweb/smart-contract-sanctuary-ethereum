/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Name {
    event SetName(string name);
    mapping(address => string) public names;

    function getName() public pure returns (address) {
        return address(0);
    }

    function setName(string memory _name) public {
        names[msg.sender] = _name;
        emit SetName(_name);
    }
}