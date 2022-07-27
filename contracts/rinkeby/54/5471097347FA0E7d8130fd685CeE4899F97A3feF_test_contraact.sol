/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test_contraact{
    mapping(address => string) internal data;
    address public owner;

    constructor (){
        // 合约所有者
        owner = msg.sender;
    }

    modifier onlyowner(){
        // 先写require再写'_;'的目的是，先判断是否符合条件，再执行程序
        require(msg.sender == owner, "only owner!!!");
        _;
    }

    function write_data(string memory write_data_) public {
        data[msg.sender] = write_data_;
    }

    function get_data() public view returns (string memory){
        return data[msg.sender];
    }

    function get_data_owner(address addr) public view onlyowner returns (string memory){
        return data[addr];
    }
}