// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    string public constant owner = "Mustapha SLIMANI";
    address public ownerAddress;

    constructor() payable {
        ownerAddress = msg.sender;
    }
}