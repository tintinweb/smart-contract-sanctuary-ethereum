// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter{

    uint256 public counter;

    address public owner;

    modifier onlyOwner {
      require(msg.sender == owner, "not owner");
      _;
    }

    constructor() {
      owner = msg.sender;
    }


    function count() public onlyOwner {
        counter += 1;
    }

    function add(uint256 x) public onlyOwner{
        counter += x;
    }

}