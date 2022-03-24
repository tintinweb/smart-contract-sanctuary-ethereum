/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Oracle {
    address public owner;
    uint256 public oracleData;

    event RequestEvent(address sender);
    event FilledRequest(uint256 rData);

    constructor() {
        oracleData = 1;
        owner = msg.sender;
    }

    function request() public returns (string memory) {
        emit RequestEvent(msg.sender);
        return "sent";
    }

    function fill(uint256 requestData) public returns (uint256) {
        oracleData = requestData;
        emit FilledRequest(requestData);
        return oracleData;
    }
}