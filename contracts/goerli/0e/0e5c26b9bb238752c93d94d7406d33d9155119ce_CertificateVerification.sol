/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract CertificateVerification {
    //Emitted when update function is called
    //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
    event AddedDocument(string ipfs_hash, string id, uint256 timeAdded);
    event AddDocumentError(string ipfs_hash, string error);

    mapping(string => uint256) documentAddTimeMap; //contains when documents was added
    mapping(string => string) documentAddKeyMap; //contains who (public key) added the document

    constructor() {}

    function add_book(string memory ipfs_hash, string memory admin_id) public {
        //check if already added
        if (documentAddTimeMap[ipfs_hash] > 0) {
            //already added by someone else
            emit AddDocumentError(ipfs_hash, "already added");
        }
        //add now
        uint256 timeAdded = block.timestamp;
        documentAddTimeMap[ipfs_hash] = timeAdded;
        documentAddKeyMap[ipfs_hash] = admin_id;
        emit AddedDocument(ipfs_hash, admin_id, timeAdded);
    }

    function verifyDocument(string memory ipfs_hash)
        public
        view
        returns (bool)
    {
        if (documentAddTimeMap[ipfs_hash] > 0) return true;
        return false;
    }

    function getDocumentAddedTime(string memory ipfs_hash)
        public
        view
        returns (uint256)
    {
        return documentAddTimeMap[ipfs_hash];
    }

    function getDocumentAdderPublicId(string memory ipfs_hash)
        public
        view
        returns (string memory)
    {
        return documentAddKeyMap[ipfs_hash];
    }
}