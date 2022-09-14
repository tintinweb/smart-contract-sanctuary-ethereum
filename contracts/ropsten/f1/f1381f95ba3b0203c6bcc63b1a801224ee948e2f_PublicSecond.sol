/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract PublicSecond{

    mapping (uint32 => bytes) second_info;

    event SetSecondMaturation(uint32 production_id, bytes hash);

    function set(uint32 _production_id, bytes memory _second_hash) public{
        second_info[_production_id] = _second_hash;
        emit SetSecondMaturation(_production_id, _second_hash);
    }

    function get(uint32 _production_id) public view returns (bytes memory){
        return second_info[_production_id];
    }
}