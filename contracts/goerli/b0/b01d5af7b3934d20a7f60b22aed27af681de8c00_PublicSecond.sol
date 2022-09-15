/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract PublicSecond{

    address public owner;
    mapping (uint32 => string) second_info;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the FAIRCHAIN Smart Contracts' admin has access rights.");
        _;
    }
    event SecondMaturationHashLog(uint32 production_id, string hash);

    function set(uint32 _production_id, string memory _second_hash) public onlyOwner{
        second_info[_production_id] = _second_hash;
        emit SecondMaturationHashLog(_production_id, _second_hash);
    }

    function get(uint32 _production_id) public view returns (string memory){
        return second_info[_production_id];
    }
}