/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData;
    address public proprietario;

    constructor() {
        proprietario = msg.sender;
    }

    function set(uint x) public {
        require(msg.sender == proprietario, "Non sei il proprietario");
        storedData = x;
    }

    function get() public view returns (uint) {
        require(msg.sender == proprietario, "Non sei il proprietario");
        return storedData;
    }
}