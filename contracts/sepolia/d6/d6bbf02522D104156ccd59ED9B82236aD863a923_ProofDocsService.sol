/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ProofDocsService {
    struct Document {
        string docID;
        string hash;
        string docURL;
        bool flag;
    }

    address public owner;

    mapping(address => bool) public issuers;
    mapping(string => Document) public documents;

    event DocumentAdded(
        address indexed issuer,
        string indexed docID,
        string hash,
        string docURL
    );

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can perform this action."
        );
        _;
    }

    modifier onlyIssuer() {
        require(
            issuers[msg.sender] == true,
            "Only authorized issuers can perform this action."
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addIssuer(address _issuer) public onlyOwner {
        issuers[_issuer] = true;
    }

    function addDocument(
        string memory _docID,
        string memory _hash,
        string memory _docURL
    ) public onlyIssuer {
        require(
            !documents[_hash].flag,
            "Document with this hash already exists."
        );

        documents[_hash] = Document(_docID, _hash, _docURL, true);
        emit DocumentAdded(msg.sender, _docID, _hash, _docURL);
    }

    function checkDocument(string memory _hash)
        public
        view
        returns (
            string memory docID_,
            string memory hash_,
            string memory docURL_
        )
    {
        require(
            documents[_hash].flag,
            "Document with this hash doesn't exist."
        );

        return (
            documents[_hash].docID,
            documents[_hash].hash,
            documents[_hash].docURL
        );
    }
}