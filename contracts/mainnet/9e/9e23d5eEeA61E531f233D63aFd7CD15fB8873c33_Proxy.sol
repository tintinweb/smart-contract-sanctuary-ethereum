// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "./LibRawResult.sol";
import "./Implementation.sol";

/// @notice Base class for all proxy contracts.
contract Proxy {
    using LibRawResult for bytes;

    /// @notice The address of the implementation contract used by this proxy.
    Implementation public immutable IMPL;

    // Made `payable` to allow initialized crowdfunds to receive ETH as an
    // initial contribution.
    constructor(Implementation impl, bytes memory initCallData) payable {
        IMPL = impl;
        (bool s, bytes memory r) = address(impl).delegatecall(initCallData);
        if (!s) {
            r.rawRevert();
        }
    }

    // Forward all calls to the implementation.
    fallback() external payable {
        Implementation impl = IMPL;
        assembly {
            calldatacopy(0x00, 0x00, calldatasize())
            let s := delegatecall(gas(), impl, 0x00, calldatasize(), 0x00, 0)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(s) {
                revert(0x00, returndatasize())
            }
            return(0x00, returndatasize())
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

library LibRawResult {
    // Revert with the data in `b`.
    function rawRevert(bytes memory b) internal pure {
        assembly {
            revert(add(b, 32), mload(b))
        }
    }

    // Return with the data in `b`.
    function rawReturn(bytes memory b) internal pure {
        assembly {
            return(add(b, 32), mload(b))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

// Base contract for all contracts intended to be delegatecalled into.
abstract contract Implementation {
    error OnlyDelegateCallError();
    error OnlyConstructorError();

    address public immutable IMPL;

    constructor() {
        IMPL = address(this);
    }

    // Reverts if the current function context is not inside of a delegatecall.
    modifier onlyDelegateCall() virtual {
        if (address(this) == IMPL) {
            revert OnlyDelegateCallError();
        }
        _;
    }

    // Reverts if the current function context is not inside of a constructor.
    modifier onlyConstructor() {
        if (address(this).code.length != 0) {
            revert OnlyConstructorError();
        }
        _;
    }
}