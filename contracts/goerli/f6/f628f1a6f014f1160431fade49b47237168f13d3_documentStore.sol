/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract documentStore{
    mapping (bytes32=>Document[]) public documents;

    struct Document{
        string name;
        string description;
        address sender;
    }

    // memory = local, can be changed, can be returned
    // calldata = local, can't be changed, can be returned
    // storage = saved after transaction ends
    function StoreDocument(bytes32 key, string calldata name, string calldata description) public returns (bool success) {
        Document memory doc = Document(name, description, msg.sender);
        documents[key].push(doc);
        return true;
    }
}