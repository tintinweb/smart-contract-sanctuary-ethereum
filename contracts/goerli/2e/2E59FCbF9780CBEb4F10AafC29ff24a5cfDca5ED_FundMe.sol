// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FundMe{
    uint256 public LuckyNumber=5;

    function retrive() public view returns(uint256){
        return LuckyNumber;
    }
    function store(uint256 Lucky) public {
        LuckyNumber =Lucky;
    }
}