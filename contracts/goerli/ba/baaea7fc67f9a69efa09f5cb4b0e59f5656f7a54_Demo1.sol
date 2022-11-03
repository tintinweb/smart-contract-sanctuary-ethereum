/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Demo1 {

    uint public a;
    mapping(address => uint) public b;
    mapping(address => uint) public c;

    function init() public {
		a = 1;
        b[address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4)] = 1;
        c[address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4)] = 2;
    }

    function getB(address addr) public view returns(uint256) {
        return b[addr];
    }

    function getC(address addr) public view returns(uint256) {
        return c[addr];
    }
}