// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReturnName{

    function name() external view returns(string memory){
        return "Test contract";
    }
    function totalSupply() external view returns(uint){
        return 200000000000000;
    }
    function balanceOf(address owner) external view returns(uint){
        return address(this).balance;
    }
    receive() external payable{}
}