// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Storage {
    enum Status {OPENED, CLOSED, CANCELED}
    struct CreditData {
        bytes32 hash;
        Status status;
    }

    CreditData[] cd;
    mapping (bytes32=>uint256) hashToIndexCreditData;

    function create(bytes32 hash, uint8 status) external returns(CreditData memory) {
        cd.push(CreditData(hash, Status(status)));
        hashToIndexCreditData[hash] = cd.length - 1;
        return cd[hashToIndexCreditData[hash]];
    } 

    function getCreditData(bytes32 hash) external view returns(CreditData memory) {
        return cd[hashToIndexCreditData[hash]];
    }

    function changeStatus(bytes32 hash, uint8 newStatus) external returns(CreditData memory) {
        uint256 cdIndex = hashToIndexCreditData[hash];
        cd[cdIndex].status = Status(newStatus);
        return cd[cdIndex];
    }
}