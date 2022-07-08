/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test_data {
    mapping(address => string) internal data;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyowner(){
        require(msg.sender == owner,"only owner!!!!!");
        _;
    }

    function write_data(string memory write_data_) public {
        data[msg.sender] = write_data_;
    }

    function get_data() public view returns (string memory){
        return data[msg.sender];
    }

    function get_data_creator(address addr) public view onlyowner() returns (string memory){
        return data[addr];
    }
}