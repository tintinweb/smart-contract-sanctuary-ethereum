/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Oracle {
    address public owner;
    string public oracleData;

    event RequestEvent(address sender);
    event FilledRequest(string rData);

    constructor() {
        owner = msg.sender;
    }

    function request() public returns (string memory) {
        emit RequestEvent(msg.sender);
        return "sent";
    }

    function fill(string memory requestData) public returns (string memory) {
        oracleData = requestData;
        emit FilledRequest(requestData);
        return oracleData;
    }
}