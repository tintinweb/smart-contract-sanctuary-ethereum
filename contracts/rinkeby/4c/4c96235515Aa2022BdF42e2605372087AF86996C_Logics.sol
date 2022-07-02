// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILogics.sol";
import "./ProxyStorage.sol";

contract Logics is ILogics, ProxyStorage {
    function setMsg(bytes32 message) external override {
        _message = message;
    }

    function getMsg() external view override returns (bytes32) {
        return _message;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProxyStorage {
    address internal _initializationOwnerAddress;
    address internal _setupAddress;
    mapping(bytes4 => address) internal _methodsImplementations;

    bytes32 internal _message;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILogics {
    function setMsg(bytes32 message) external;
    function getMsg() external view returns (bytes32);
}