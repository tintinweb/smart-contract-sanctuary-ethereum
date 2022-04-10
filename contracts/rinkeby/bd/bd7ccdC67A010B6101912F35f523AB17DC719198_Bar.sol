// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

//Keep it simple, no inheritance
//For V2 add mapping
//For V3 add struct
contract Bar {

    uint public a;
    uint public b;
    mapping(uint => bool) public exists;


    function initialize(uint _a, uint _b) external {
        a = _a;
        b = _b;
    }

    function product() external returns(uint) {
        return a * b;
    }

    function updateMapping(uint value, bool _exists) external {
        exists[value] = _exists;
    }

    

}