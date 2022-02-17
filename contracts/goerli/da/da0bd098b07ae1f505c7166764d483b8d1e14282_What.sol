/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract What {
    mapping(address => uint256) public data;
    function set(uint256 n) external {
        data[msg.sender] = n;
    }

    function set2(uint256 n,address any) external {
        data[any] = n;
    }

    function retrieve()external view returns(uint256,address){
        return (data[msg.sender],msg.sender);
    }

}