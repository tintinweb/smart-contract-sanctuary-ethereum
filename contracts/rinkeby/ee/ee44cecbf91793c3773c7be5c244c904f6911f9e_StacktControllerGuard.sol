// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../base/StacktGuardManager.sol";
import "openzeppelin-contracts/utils/Strings.sol";

// TODO:
// - singleton from gnosis safe
// - `setup`'s caller must be coming from a wallet
// - use error codes like gnosis / custom Error

contract StacktControllerGuard is BaseGuard {

    address internal safeAddress;
    mapping(address => address) internal controllers;
    address internal constant SENTINEL_CONTROLLERS = address(0x1);
    uint256 public controllersCount;

    // modifiers
    modifier authorized() {
        require(msg.sender == safeAddress, "Unauthorized");
        _;
    }

    // setup
    constructor (address _safeAddress, address[] memory _controllers) {

        // Ensure setup can only be called once
        require(controllers[SENTINEL_CONTROLLERS] == address(0), "Guard has already been initialized");

        // There has to be at least one controller
        require(_controllers.length >= 1, "There has to be at least one controller");

        // Initialize safeAddress
        safeAddress = _safeAddress;

        // Initialize controllers
        address currentController = SENTINEL_CONTROLLERS;
        for (uint256 i = 0; i < _controllers.length; i++) {
            // Controller address cannot be null.
            address controller = _controllers[i];
            require(controller != address(0) && controller != SENTINEL_CONTROLLERS && controller != address(this) && currentController != controller, "Invalid controller address provided");

            // No duplicate controllers allowed.
            require(controllers[controller] == address(0), "Address is already a controller");
            controllers[currentController] = controller;
            currentController = controller;
        }

        controllersCount = _controllers.length;
        controllers[currentController] = SENTINEL_CONTROLLERS;
    }

    function setSafeAddress(address _s) external {
        require(safeAddress == address(0), "Address already set");
        require(_s != address(0), "Invalid safe address");
        safeAddress = _s;
    }

    // update controllers
    function addController(address controller) external authorized {
        // address cannot be null or sentinel.
        require(controller != address(0) && controller != SENTINEL_CONTROLLERS, "Invalid controller address provided");

        // controller cannot be added twice
        require(controllers[controller] == address(0), "Address is already a controller");
        
        controllersCount += 1;
        controllers[controller] = controllers[SENTINEL_CONTROLLERS];
        controllers[SENTINEL_CONTROLLERS] = controller;
    }

    function removeController(address prevController, address controller) external authorized {
        // validate controller address and check that it corresponds to controller index.
        require(controller != address(0) && controller != SENTINEL_CONTROLLERS, "Invalid controller address provided");
        require(controllers[prevController] == controller, "Invalid prevController, controller pair provided");
        controllers[prevController] = controllers[controller];
        controllers[controller] = address(0);
        controllersCount -= 1;
    }

    // guard
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        bool refundGas,
        bytes memory signatures,
        address msgSender
    ) external view {
        // check is a controller
        require(controllers[tx.origin] != address(0));
    }

    function checkAfterExecution(bytes32 txHash, bool success) external {
        // do nothing
    }

    // views
    function getControllers() public view returns (address[] memory) {
        address[] memory array = new address[](controllersCount);

        // populate return array
        uint256 index = 0;
        address currentController = controllers[SENTINEL_CONTROLLERS];

        while (currentController != SENTINEL_CONTROLLERS) {
            array[index] = currentController;
            currentController = controllers[currentController];
            index++;
        }
        return array;
    }

    // fallback
    // solhint-disable-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import "safe-contracts/common/Enum.sol";
import "safe-contracts/common/SelfAuthorized.sol";
import "openzeppelin-contracts/utils/introspection/IERC165.sol";

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        bool refundGas,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract StacktGuardManager is SelfAuthorized {
    event ChangedGuard(address guard);
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    // keccak256("guard_manager.setup.address")
    bytes32 internal constant SETUP_STORAGE_SLOT = 0xac6b4b4c91b961f50b5cda5ba75b03d57713b69c71326dc577aa2ff0b32e0286;

    function setupGuard(address guard) internal {
        bool hasSetup;
        assembly {
            hasSetup := sload(SETUP_STORAGE_SLOT)
        }
        require(!hasSetup, "GS300");
        assembly {
            sstore(SETUP_STORAGE_SLOT, true)
        }
        if (guard != address(0)) {
            _setGuard(guard);
        }
    }

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {
        _setGuard(guard);
    }

    function getGuard() public view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }

    function _setGuard(address guard) private {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
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