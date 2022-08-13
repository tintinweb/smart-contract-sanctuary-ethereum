/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract test
{
    uint a;
    address c;
    string b;
    string d;
    mapping(uint256=>string) name;

    function enterName(string memory _name, uint256 _roolNumber) external 
    {
        name[_roolNumber] = _name;
    }

    function get(uint256 _roolNumber) external view returns(string memory)
    {
        return name[_roolNumber];
    }

    function alpha(uint _a,string memory _b,address _c,string memory _d) external
    {
       a=_a;
       b=_b;
       c=_c;
       d=_d;
    }
}