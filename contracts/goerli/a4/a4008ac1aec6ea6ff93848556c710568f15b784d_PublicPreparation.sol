/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract PublicPreparation{

    address public owner;
    mapping (uint32 => string) preparation_info;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the FAIRCHAIN Smart Contracts' admin has access rights.");
        _;
    }

    event ProductionPreparationHashLog(uint32 production_id, string hash);

    function set(uint32 _production_id, string memory _preparation_hash) public onlyOwner{
        preparation_info[_production_id] = _preparation_hash;
        emit ProductionPreparationHashLog(_production_id, _preparation_hash);
    }

    function get(uint32 _production_id) public view returns (string memory){
        return preparation_info[_production_id];
    }
}