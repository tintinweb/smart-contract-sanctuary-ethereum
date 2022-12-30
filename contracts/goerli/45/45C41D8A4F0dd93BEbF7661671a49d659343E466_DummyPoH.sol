// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IProofOfHumanity.sol";

contract DummyPoH is IProofOfHumanity {
    event Registered(address addr);

    mapping(address => bool) private _registered;

    constructor(address[] memory addrs) {
        for (uint256 i = 0; i < addrs.length; i++) {
            register(addrs[i]);
        }
    }

    function register(address addr) public {
        _registered[addr] = true;
        emit Registered(addr);
    }

    function isRegistered(address addr) public view returns (bool) {
        return _registered[addr];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IProofOfHumanity {
    function isRegistered(address addr) external view returns (bool);
}