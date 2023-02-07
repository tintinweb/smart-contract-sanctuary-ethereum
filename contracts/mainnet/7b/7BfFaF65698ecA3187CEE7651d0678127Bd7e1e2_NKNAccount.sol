/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NKNAccount {
    mapping(address => string) private _ethMappings;

    function set(string memory addr) public {
        require(bytes(addr).length != 0, "addr length must be longer than 0");
        _ethMappings[msg.sender] = addr;
    }

    function del() public {
        string memory addr = _ethMappings[msg.sender];
        require(bytes(addr).length != 0);
        delete _ethMappings[msg.sender];
    }

    function getAddr() public view returns (string memory) {
        string memory addr = _ethMappings[msg.sender];
        require(bytes(addr).length != 0);
        return addr;
    }

    function queryAddr(address ethAddr) public view returns (string memory) {
        string memory addr = _ethMappings[ethAddr];
        require(bytes(addr).length != 0);
        return addr;
    }
}