/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Certificates address:  0xD185f1427B67D185859e10D5B6A2E7B976a25733

contract cert {
    address owner;
    uint256 public certCount = 0;

    struct Certificate {
        uint256 id;
        string name;
        string studentid;
        string email;
        string course;
        string date;
        string college;
        string term;
    }

    Certificate[] certs;

    constructor() payable {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(owner == msg.sender);
        _;
    }

    function getAllCertificates() public view returns (Certificate[] memory) {
        return certs;
    }

    function addCertificate(
        string memory name,
        string memory studentid,
        string memory email,
        string memory course,
        string memory date,
        string memory college,
        string memory term

    ) public {
        certCount++;
        certs.push(
            Certificate(
                certCount,
                name,
                studentid,
                email,
                course,
                date,
                college,
                term
            )
        );
    }

    event certadded(
        string name,
        string studentid,
        string email,
        string course,
        string date,
        string college,
        string term
    );
}