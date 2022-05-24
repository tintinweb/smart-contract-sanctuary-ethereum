// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

/* See contracts/COMPILERS.md */
pragma solidity 0.8.9;

import "@openzeppelin/contracts-v4.4/utils/introspection/ERC165.sol";
import "./OrderedCallbacksArray.sol";
import "./interfaces/IBeaconReportReceiver.sol";

/**
  * @title Contract defining an composite post-rebase beacon receiver for the Lido oracle
  *
  * Contract adds permission modifiers.
  * Only the `ORACLE` address can invoke `processLidoOracleReport` function.
  */
contract CompositePostRebaseBeaconReceiver is OrderedCallbacksArray, IBeaconReportReceiver, ERC165 {
    address public immutable ORACLE;

    modifier onlyOracle() {
        require(msg.sender == ORACLE, "MSG_SENDER_MUST_BE_ORACLE");
        _;
    }

    constructor(
        address _voting,
        address _oracle
    ) OrderedCallbacksArray(_voting, type(IBeaconReportReceiver).interfaceId) {
        require(_oracle != address(0), "ORACLE_ZERO_ADDRESS");

        ORACLE = _oracle;
    }

    function processLidoOracleReport(
        uint256 _postTotalPooledEther,
        uint256 _preTotalPooledEther,
        uint256 _timeElapsed
    ) external virtual override onlyOracle {
        uint256 callbacksLen = callbacksLength();

        for (uint256 brIndex = 0; brIndex < callbacksLen; brIndex++) {
            IBeaconReportReceiver(callbacks[brIndex])
                .processLidoOracleReport(
                    _postTotalPooledEther,
                    _preTotalPooledEther,
                    _timeElapsed
                );
        }
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return (
            _interfaceId == type(IBeaconReportReceiver).interfaceId
            || super.supportsInterface(_interfaceId)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

/* See contracts/COMPILERS.md */
pragma solidity 0.8.9;

import "@openzeppelin/contracts-v4.4/utils/introspection/ERC165Checker.sol";

import "./interfaces/IOrderedCallbacksArray.sol";

/**
  * @title Contract defining an ordered callbacks array supporting add/insert/remove ops
  *
  * Contract adds permission modifiers atop of `IOrderedCallbacksArray` interface functions.
  * Only the `VOTING` address can invoke storage mutating (add/insert/remove) functions.
  */
contract OrderedCallbacksArray is IOrderedCallbacksArray {
    using ERC165Checker for address;

    uint256 public constant MAX_CALLBACKS_COUNT = 16;
    bytes4 constant INVALID_INTERFACE_ID = 0xffffffff;

    address public immutable VOTING;
    bytes4 public immutable REQUIRED_INTERFACE;

    address[] public callbacks;

    modifier onlyVoting() {
        require(msg.sender == VOTING, "MSG_SENDER_MUST_BE_VOTING");
        _;
    }

    constructor(address _voting, bytes4 _requiredIface) {
        require(_requiredIface != INVALID_INTERFACE_ID, "INVALID_IFACE");
        require(_voting != address(0), "VOTING_ZERO_ADDRESS");

        VOTING = _voting;
        REQUIRED_INTERFACE = _requiredIface;
    }

    function callbacksLength() public view override returns (uint256) {
        return callbacks.length;
    }

    function addCallback(address _callback) external override onlyVoting {
        _insertCallback(_callback, callbacks.length);
    }

    function insertCallback(address _callback, uint256 _atIndex) external override onlyVoting {
        _insertCallback(_callback, _atIndex);
    }

    function removeCallback(uint256 _atIndex) external override onlyVoting {
        uint256 oldCArrayLength = callbacks.length;
        require(_atIndex < oldCArrayLength, "INDEX_IS_OUT_OF_RANGE");

        emit CallbackRemoved(callbacks[_atIndex], _atIndex);

        for (uint256 cIndex = _atIndex; cIndex < oldCArrayLength-1; cIndex++) {
            callbacks[cIndex] = callbacks[cIndex+1];
        }

        callbacks.pop();
    }

    function _insertCallback(address _callback, uint256 _atIndex) private {
        require(_callback != address(0), "CALLBACK_ZERO_ADDRESS");
        require(_callback.supportsInterface(REQUIRED_INTERFACE), "BAD_CALLBACK_INTERFACE");

        uint256 oldCArrayLength = callbacks.length;
        require(_atIndex <= oldCArrayLength, "INDEX_IS_OUT_OF_RANGE");
        require(oldCArrayLength < MAX_CALLBACKS_COUNT, "MAX_CALLBACKS_COUNT_EXCEEDED");

        emit CallbackAdded(_callback, _atIndex);

        callbacks.push();

        if (oldCArrayLength > 0) {
            for (uint256 cIndex = oldCArrayLength; cIndex > _atIndex; cIndex--) {
                callbacks[cIndex] = callbacks[cIndex-1];
            }
        }

        callbacks[_atIndex] = _callback;
    }
}

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

/**
  * @title Interface defining a callback that the quorum will call on every quorum reached
  */
interface IBeaconReportReceiver {
    /**
      * @notice Callback to be called by the oracle contract upon the quorum is reached
      * @param _postTotalPooledEther total pooled ether on Lido right after the quorum value was reported
      * @param _preTotalPooledEther total pooled ether on Lido right before the quorum value was reported
      * @param _timeElapsed time elapsed in seconds between the last and the previous quorum
      */
    function processLidoOracleReport(uint256 _postTotalPooledEther,
                                     uint256 _preTotalPooledEther,
                                     uint256 _timeElapsed) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

/**
  * @title Interface defining an ordered callbacks array supporting add/insert/remove ops
  */
interface IOrderedCallbacksArray {
    /**
      * @notice Callback added event
      *
      * @dev emitted by `addCallback` and `insertCallback` functions
      */
    event CallbackAdded(address indexed callback, uint256 atIndex);

    /**
      * @notice Callback removed event
      *
      * @dev emitted by `removeCallback` function
      */
    event CallbackRemoved(address indexed callback, uint256 atIndex);

    /**
      * @notice Callback length
      * @return Added callbacks count
      */
    function callbacksLength() external view returns (uint256);

    /**
      * @notice Add a `_callback` to the back of array
      * @param _callback callback address
      *
      * @dev cheapest way to insert new item (doesn't incur additional moves)
      */
    function addCallback(address _callback) external;

    /**
      * @notice Insert a `_callback` at the given `_atIndex` position
      * @param _callback callback address
      * @param _atIndex callback insert position
      *
      * @dev insertion gas cost is higher for the lower `_atIndex` values
      */
    function insertCallback(address _callback, uint256 _atIndex) external;

    /**
      * @notice Remove a callback at the given `_atIndex` position
      * @param _atIndex callback remove position
      *
      * @dev remove gas cost is higher for the lower `_atIndex` values
      */
    function removeCallback(uint256 _atIndex) external;

    /**
      * @notice Get callback at position
      * @return Callback at the given `_atIndex`
      *
      * @dev function reverts if `_atIndex` is out of range
      */
    function callbacks(uint256 _atIndex) external view returns (address);
}