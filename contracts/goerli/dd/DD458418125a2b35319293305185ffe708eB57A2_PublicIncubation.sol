// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract PublicIncubation{

    address public owner;
    mapping (uint32 => string) incubation_info;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the FAIRCHAIN Smart Contracts' admin has access rights.");
        _;
    }

    event ProductionIncubationHashLog(uint32 production_id, string hash);

    function set(uint32 _production_id, string memory _incubation_hash) public onlyOwner{
        incubation_info[_production_id] = _incubation_hash;
        emit ProductionIncubationHashLog(_production_id, _incubation_hash);
    }

    function get(uint32 _production_id) public view returns (string memory){
        return incubation_info[_production_id];
    }
}