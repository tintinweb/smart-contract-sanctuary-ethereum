/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface Winner {
    function attempt() external;
}

contract Proxy {
    address contractAddress;

    constructor(address contract_) {
        contractAddress = contract_;
    }

    function leethack() public {
        Winner(contractAddress).attempt();
    }
}