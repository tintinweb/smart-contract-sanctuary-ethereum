//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Boxv2
{
    uint256 private val;
    event changedval(uint256 newval);

    function store(uint256 newval) public
    {
        val = newval;
        emit changedval(newval);
    }

    function get() public view returns(uint256)
    {
        return val;
    }

    function increment() public
    {
        val = val+1;
        emit changedval(val);
    }
}