/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract PublicFirst{

    address public owner;
    mapping (uint32 => string) first_info;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the FAIRCHAIN Smart Contracts' admin has access rights.");
        _;
    }

    event FirstMaturationHashLog(uint32 production_id, string hash);
    function set(uint32 _production_id, string memory _first_hash) public onlyOwner{
        first_info[_production_id] = _first_hash;
        emit FirstMaturationHashLog(_production_id, _first_hash);
    }

    function get(uint32 _production_id) public view returns (string memory){
        return first_info[_production_id];
    }
}