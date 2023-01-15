// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Certificate {

    address private owner;
    mapping(string => bytes32) private certificateHash;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyowner {
        require(msg.sender==owner);
        _;
    }

    function addCertificate(
        string memory uid,
        string memory issuedTo,
        string memory issuer,
        string memory course,
        string memory issuedOn
    ) external onlyowner() {
        certificateHash[uid] = keccak256(abi.encodePacked(issuedTo, issuer, course, issuedOn));
    }

    function verifyCertificate(
        string memory uid,
        string memory issuedTo,
        string memory issuer,
        string memory course,
        string memory issuedOn
    ) external view returns (bool) {
        if( certificateHash[uid] ==  keccak256(abi.encodePacked(issuedTo, issuer, course, issuedOn)) )
            return true;
        else
            return false;
    }

}