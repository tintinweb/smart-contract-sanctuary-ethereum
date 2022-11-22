// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AllowList} from "./abstract/AllowList.sol";
import {ITokenAuth} from "./interfaces/ITokenAuth.sol";

/// @title TokenAuth - Token allowlist
/// @notice An allowlist of approved ERC20 tokens.
contract TokenAuth is ITokenAuth, AllowList {
    string public constant NAME = "TokenAuth";
    string public constant VERSION = "0.0.1";

    constructor(address _controller) AllowList(_controller) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Controllable} from "./Controllable.sol";
import {IAllowList} from "../interfaces/IAllowList.sol";

/// @title AllowList - Tracks approved addresses
/// @notice An abstract contract for tracking allowed and denied addresses.
abstract contract AllowList is IAllowList, Controllable {
    mapping(address => bool) public allowed;

    modifier onlyAllowed() {
        if (!allowed[msg.sender]) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) Controllable(_controller) {}

    /// @inheritdoc IAllowList
    function denied(address caller) external view returns (bool) {
        return !allowed[caller];
    }

    /// @inheritdoc IAllowList
    function allow(address caller) external onlyController {
        allowed[caller] = true;
        emit Allow(caller);
    }

    /// @inheritdoc IAllowList
    function deny(address caller) external onlyController {
        allowed[caller] = false;
        emit Deny(caller);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "../interfaces/IControllable.sol";

/// @title Controllable - Controller management functions
/// @notice An abstract base contract for contracts managed by the Controller.
abstract contract Controllable is IControllable {
    address public controller;

    modifier onlyController() {
        if (msg.sender != controller) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) {
        if (_controller == address(0)) {
            revert ZeroAddress();
        }
        controller = _controller;
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address) external virtual onlyController {
        revert InvalidDependency(_name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "./IControllable.sol";

interface IAllowList is IControllable {
    event Allow(address caller);
    event Deny(address caller);

    /// @notice Check whether the given `caller` address is allowed.
    /// @param caller The caller address.
    /// @return True if caller is allowed, false if caller is denied.
    function allowed(address caller) external view returns (bool);

    /// @notice Check whether the given `caller` address is denied.
    /// @param caller The caller address.
    /// @return True if caller is denied, false if caller is allowed.
    function denied(address caller) external view returns (bool);

    /// @notice Add a caller address to the allowlist.
    /// @param caller The caller address.
    function allow(address caller) external;

    /// @notice Remove a caller address from the allowlist.
    /// @param caller The caller address.
    function deny(address caller) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAnnotated {
    /// @notice Get contract name.
    /// @return Contract name.
    function NAME() external returns (string memory);

    /// @notice Get contract version.
    /// @return Contract version.
    function VERSION() external returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICommonErrors {
    /// @notice The provided address is the zero address.
    error ZeroAddress();
    /// @notice The attempted action is not allowed.
    error Forbidden();
    /// @notice The requested entity cannot be found.
    error NotFound();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ICommonErrors} from "./ICommonErrors.sol";

interface IControllable is ICommonErrors {
    /// @notice The dependency with the given `name` is invalid.
    error InvalidDependency(bytes32 name);

    /// @notice Get controller address.
    /// @return Controller address.
    function controller() external returns (address);

    /// @notice Set a named dependency to the given contract address.
    /// @param _name bytes32 name of the dependency to set.
    /// @param _contract address of the dependency.
    function setDependency(bytes32 _name, address _contract) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAllowList} from "./IAllowList.sol";
import {IAnnotated} from "./IAnnotated.sol";

interface ITokenAuth is IAllowList, IAnnotated {}