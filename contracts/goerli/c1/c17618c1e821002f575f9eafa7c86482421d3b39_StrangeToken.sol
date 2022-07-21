/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


contract StrangeToken {
    struct MintParam {
        uint128 base;
        uint8 multi;
    }

    struct Info {
        string name;
        string symbol;
    }

    string name = "StrangeToken";
    string symbol = "ST";
    mapping(address => uint256) balanceOf;

    function mint(MintParam calldata params, address addr) public returns (MintParam memory) {
        uint256 amount = params.base * params.multi;
        balanceOf[addr] = amount;

        return params;
    }

    function burnAll() public returns (uint256) {
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;

        return amount;
    }

    function balanceOfAddresses(address a, address b) public view returns (uint256, uint256) {
        return (balanceOf[a], balanceOf[b]);
    }

    function info() public view returns (Info memory) {
        Info memory result = Info({name: name, symbol: symbol});

        return result;
    }
}