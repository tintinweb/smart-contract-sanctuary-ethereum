// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephoneorigins {
    address public owner;
    event moo(address owneremit);

    constructor() public {
        owner = msg.sender;
    }

    function delegation(address _own) public {
        owner = _own;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }

    function getOwner() public {
        emit moo(owner);
    }
}