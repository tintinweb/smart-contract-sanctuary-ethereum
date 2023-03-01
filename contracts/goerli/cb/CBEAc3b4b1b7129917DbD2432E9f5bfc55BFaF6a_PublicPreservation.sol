// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract PublicPreservation{

    address public owner;
    mapping (uint32 => string) preservation_info;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the FAIRCHAIN Smart Contracts' admin has access rights.");
        _;
    }

    event ProductionPreservationHashLog(uint32 production_id, string hash);

    function set(uint32 _production_id, string memory _preservation_hash) public onlyOwner{
        preservation_info[_production_id] = _preservation_hash;
        emit ProductionPreservationHashLog(_production_id, _preservation_hash);
    }

    function get(uint32 _production_id) public view returns (string memory){
        return preservation_info[_production_id];
    }
}