/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract User {

    event Result(uint);

    function add(uint b) public payable returns (uint){
        emit Result(b);
        return b;
    }

    function sub() external pure returns (bytes4){
        bytes4 sel = this.add.selector;
        return sel;
    }
}