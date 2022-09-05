/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: none
pragma solidity 0.8.16;

contract ExternalStateChannel {
    event WriteExternalState(address indexed from, string indexed key, string value);
    string contractName;
    address owner;
    uint256 guardCounter;

    constructor() {
        contractName = "ExternalStateChannel";
        owner = msg.sender;
        guardCounter = 1;
    }

    function externalize(string calldata key, string calldata value) external returns (bool success) {
        emit WriteExternalState(msg.sender, key, value);
        success = true;
    }


}