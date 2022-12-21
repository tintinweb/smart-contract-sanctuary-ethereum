// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/Multicall.sol";
import "./IGlobals.sol";

/// @notice Contract storing global configuration values.
contract Globals is IGlobals, Multicall {
    address public multiSig;
    address public pendingMultiSig;
    // key -> word value
    mapping(uint256 => bytes32) private _wordValues;
    // key -> word value -> isIncluded
    mapping(uint256 => mapping(bytes32 => bool)) private _includedWordValues;

    error OnlyMultiSigError();
    error OnlyPendingMultiSigError();
    error InvalidBooleanValueError(uint256 key, uint256 value);

    modifier onlyMultisig() {
        if (msg.sender != multiSig) {
            revert OnlyMultiSigError();
        }
        _;
    }

    modifier onlyPendingMultisig() {
        if (msg.sender != pendingMultiSig) {
            revert OnlyPendingMultiSigError();
        }
        _;
    }

    constructor(address multiSig_) {
        multiSig = multiSig_;
    }

    function transferMultiSig(address newMultiSig) external onlyMultisig {
        pendingMultiSig = newMultiSig;
    }

    function acceptMultiSig() external onlyPendingMultisig {
        multiSig = pendingMultiSig;
        delete pendingMultiSig;
    }

    function getBytes32(uint256 key) external view returns (bytes32) {
        return _wordValues[key];
    }

    function getUint256(uint256 key) external view returns (uint256) {
        return uint256(_wordValues[key]);
    }

    function getBool(uint256 key) external view returns (bool) {
        uint256 value = uint256(_wordValues[key]);
        if (value > 1) {
            revert InvalidBooleanValueError(key, value);
        }
        return value != 0;
    }

    function getAddress(uint256 key) external view returns (address) {
        return address(uint160(uint256(_wordValues[key])));
    }

    function getImplementation(uint256 key) external view returns (Implementation) {
        return Implementation(address(uint160(uint256(_wordValues[key]))));
    }

    function getIncludesBytes32(uint256 key, bytes32 value) external view returns (bool) {
        return _includedWordValues[key][value];
    }

    function getIncludesUint256(uint256 key, uint256 value) external view returns (bool) {
        return _includedWordValues[key][bytes32(value)];
    }

    function getIncludesAddress(uint256 key, address value) external view returns (bool) {
        return _includedWordValues[key][bytes32(uint256(uint160(value)))];
    }

    function setBytes32(uint256 key, bytes32 value) external onlyMultisig {
        _wordValues[key] = value;
    }

    function setUint256(uint256 key, uint256 value) external onlyMultisig {
        _wordValues[key] = bytes32(value);
    }

    function setBool(uint256 key, bool value) external onlyMultisig {
        _wordValues[key] = value ? bytes32(uint256(1)) : bytes32(0);
    }

    function setAddress(uint256 key, address value) external onlyMultisig {
        _wordValues[key] = bytes32(uint256(uint160(value)));
    }

    function setIncludesBytes32(uint256 key, bytes32 value, bool isIncluded) external onlyMultisig {
        _includedWordValues[key][value] = isIncluded;
    }

    function setIncludesUint256(uint256 key, uint256 value, bool isIncluded) external onlyMultisig {
        _includedWordValues[key][bytes32(value)] = isIncluded;
    }

    function setIncludesAddress(uint256 key, address value, bool isIncluded) external onlyMultisig {
        _includedWordValues[key][bytes32(uint256(uint160(value)))] = isIncluded;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/Implementation.sol";

// Single registry of global values controlled by multisig.
// See `LibGlobals` for all valid keys.
interface IGlobals {
    function getBytes32(uint256 key) external view returns (bytes32);

    function getUint256(uint256 key) external view returns (uint256);

    function getBool(uint256 key) external view returns (bool);

    function getAddress(uint256 key) external view returns (address);

    function getImplementation(uint256 key) external view returns (Implementation);

    function getIncludesBytes32(uint256 key, bytes32 value) external view returns (bool);

    function getIncludesUint256(uint256 key, uint256 value) external view returns (bool);

    function getIncludesAddress(uint256 key, address value) external view returns (bool);

    function setBytes32(uint256 key, bytes32 value) external;

    function setUint256(uint256 key, uint256 value) external;

    function setBool(uint256 key, bool value) external;

    function setAddress(uint256 key, address value) external;

    function setIncludesBytes32(uint256 key, bytes32 value, bool isIncluded) external;

    function setIncludesUint256(uint256 key, uint256 value, bool isIncluded) external;

    function setIncludesAddress(uint256 key, address value, bool isIncluded) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

import "../utils/LibRawResult.sol";

abstract contract Multicall {
    using LibRawResult for bytes;

    /// @notice Perform multiple delegatecalls on ourselves.
    function multicall(bytes[] calldata multicallData) external {
        for (uint256 i; i < multicallData.length; ++i) {
            (bool s, bytes memory r) = address(this).delegatecall(multicallData[i]);
            if (!s) {
                r.rawRevert();
            }
        }
    }
}