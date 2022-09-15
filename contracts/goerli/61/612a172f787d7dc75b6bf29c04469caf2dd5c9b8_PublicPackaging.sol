/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract PublicPackaging{

    address public owner;
    mapping (uint32 => string) packaging_info;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the FAIRCHAIN Smart Contracts' admin has access rights.");
        _;
    }
    event ProductPackagingHashLog(uint32 lot, string hash);

    function set(uint32 _packaging_lot, string memory _packaging_hash) public onlyOwner{
        packaging_info[_packaging_lot] = _packaging_hash;
        emit ProductPackagingHashLog(_packaging_lot, _packaging_hash);
    }

    function get(uint32 _packaging_lot) public view returns (string memory){
        return packaging_info[_packaging_lot];
    }
}