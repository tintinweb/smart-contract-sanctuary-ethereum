/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract PublicCollection{

    address public owner;

    mapping(uint32 => string) collections;

    event CollectionHashLog(uint32 collection_id, string hash);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the FAIRCHAIN Smart Contracts' admin has access rights.");
        _;
    }

    function set(uint32 _collection_id, string memory _collection_root) public onlyOwner {
        collections[_collection_id] = _collection_root;
        emit CollectionHashLog(_collection_id, _collection_root);
    }

    function get(uint32 _collection_id) public view returns (string memory){
        return collections[_collection_id];
    }
}