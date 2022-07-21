/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract User {

    event Result(uint);

    function add(uint a) public payable returns (uint){
        emit Result(a);
        return a;
    }

    function sub() external pure returns (bytes4){
        bytes4 sel = this.add.selector;
        return sel;
    }
}