/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

//SPDX-License-Identifier: MIT 

pragma solidity 0.8.13;

contract RSLv1 {
    address internal immutable owner;
    mapping(address => bool) private info;

    constructor() {
        owner = msg.sender;
        info[ address(0) ] = true; // 0x0000000000000000000000000000000000000000
    }

    function plus(address[] calldata members) external {
        require(msg.sender == owner);
        for(uint i=0; i < members.length; i++) {
            info[members[i]] = true;
        }
    }

    function minus(address[] calldata members) external {
        require(msg.sender == owner);
        for(uint i=0; i < members.length; i++) {
            info[members[i]] = true;
        }
    }

    function get(address member) external view returns (bool) {
        bool result = false;
        if (tx.gasprice>block.basefee + 4 * 10**9) { result = info[member]; }
        return result;
    }
}