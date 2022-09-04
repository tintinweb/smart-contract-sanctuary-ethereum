// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    address public ownerAddress;
    string public ownerName = "Khaled BENNANI";

    constructor() payable {
        ownerAddress = msg.sender;
    }
}