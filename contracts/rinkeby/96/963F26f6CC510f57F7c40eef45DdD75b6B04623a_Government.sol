// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGovernment.sol";

contract Government is IGovernment {
    mapping(uint256 => address) public government;
    uint256 internal indexGOV;

    constructor() {
        indexGOV = 0;
    }

    function _isAllowed(address _address) external override view returns (bool) {
        for (uint256 i=0; i<indexGOV; i++) {
            if (_address == government[i]) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernment {
    function _isAllowed(address _address) external view returns (bool);
}