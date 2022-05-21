// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILogics.sol";
import "./LogicsStorage.sol";

contract Logics is ILogics, LogicsStorage {
    function setMsg_(bytes32 message) external override {
        _message = message;
    }

    function getMsg_() external view override returns (bytes32 message) {
        return _message;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProxyStorage {
    address internal _initializationOwnerAddress;
    address internal _middlewareAddress;
    mapping(bytes4 => address) internal _methodsImplementations;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyStorage.sol";

contract LogicsStorage is ProxyStorage {
    bytes32 internal _message;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILogics {
    function setMsg_(bytes32 message) external;
    function getMsg_() external view returns (bytes32 message);
}