/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract CryptoPass {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    struct Certificate {
        bytes hashFunction;
        bytes certFileHash;
        bool published;
    }

    mapping(bytes => Certificate) public certificateBySerialNumber;

    modifier onlyOwner() {
        require(owner == msg.sender, "Unauthorized");
        _;
    }

    function publishCertificate(
        bytes memory serialnumber,
        bytes memory hashFunction,
        bytes memory certFileHash
    ) public onlyOwner {
        Certificate storage certificate = certificateBySerialNumber[
            serialnumber
        ];

        require(!certificate.published, "Certificate already published");

        certificate.hashFunction = hashFunction;
        certificate.certFileHash = certFileHash;
        certificate.published = true;
    }
}