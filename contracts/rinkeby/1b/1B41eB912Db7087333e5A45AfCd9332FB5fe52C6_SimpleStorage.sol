/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage
{
    string public owner = "ankan";
    mapping (string => uint8) public person;

    function addFev(string calldata _name,uint8 _fev_num) public
    {
        person[_name] = _fev_num;
    }
}