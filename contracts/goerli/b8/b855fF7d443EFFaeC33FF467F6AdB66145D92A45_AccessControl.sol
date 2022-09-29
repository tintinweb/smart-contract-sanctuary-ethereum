// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

contract AccessControl {
    uint public val;

    //Runs only first time, comment below function when running upgrade script
    function initialize(uint _val) external {
        val = _val;
    }
}