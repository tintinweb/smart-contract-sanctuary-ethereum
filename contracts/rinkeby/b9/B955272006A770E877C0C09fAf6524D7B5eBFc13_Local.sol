// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILocal.sol";
import "../government/Government.sol";

contract Local is ILocal, Government {
    modifier onlyGovernment() {
        require(msg.sender == government[0], "You're not allowed");
        _;
    }

    mapping(string => address) public local;

    function _addAllowance(address _address, string memory _local) 
        external override onlyGovernment 
    {
        government[indexGOV++] = _address;
        local[_local] = _address;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILocal {
    function _addAllowance(address _address, string memory _local) external;
}

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