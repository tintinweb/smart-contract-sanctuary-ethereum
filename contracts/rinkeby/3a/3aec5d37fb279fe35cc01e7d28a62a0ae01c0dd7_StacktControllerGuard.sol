// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../base/Singleton.sol";
import "../base/StacktGuardManager.sol";

contract StacktControllerGuard is Singleton, BaseGuard {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error Unauthorized();
    error AlreadyInitialized();
    error AlreadyAController();
    error StacktWalletAddressAlreadySet();
    error InvalidStacktWalletAddress();
    error InvalidControllerAddress(address);
    error InvalidPreviousControllerAddress();
    error NotAController();

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    address internal stacktAddress;
    mapping(address => address) internal controllers;
    address internal constant SENTINEL_CONTROLLERS = address(0x1);
    uint256 public controllersCount;

    /* -------------------------------------------------------------------------- */
    /*                                  modifiers                                 */
    /* -------------------------------------------------------------------------- */
    modifier authorized() {
        if (msg.sender != stacktAddress) { revert Unauthorized(); }
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    setup                                   */
    /* -------------------------------------------------------------------------- */
    function setup(address[] memory _controllers) external {

        // Ensure setup can only be called once
        if (controllers[SENTINEL_CONTROLLERS] != address(0)) { revert AlreadyInitialized(); }

        // Initialize controllers
        address currentController = SENTINEL_CONTROLLERS;
        for (uint256 i = 0; i < _controllers.length; i++) {
            // controller
            address controller = _controllers[i];

            // check address
            if (
                controller == address(0) || 
                controller == SENTINEL_CONTROLLERS || 
                controller == address(this) || 
                currentController == controller
            ) {
                revert InvalidControllerAddress(controller);
            }

            // No duplicate controllers allowed.
            if (controllers[controller] != address(0)) { revert AlreadyAController(); }
            controllers[currentController] = controller;
            currentController = controller;
        }

        controllersCount = _controllers.length;
        controllers[currentController] = SENTINEL_CONTROLLERS;
    }

    function setStacktWalletAddress(address _s) external {
        if (stacktAddress != address(0)) { revert StacktWalletAddressAlreadySet(); }
        if (_s == address(0)) { revert InvalidStacktWalletAddress(); }
        stacktAddress = _s;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   public                                   */
    /* -------------------------------------------------------------------------- */
    function addController(address controller) external authorized {
        // address cannot be null or sentinel.
        if (controller == address(0) || controller == SENTINEL_CONTROLLERS) { 
            revert InvalidControllerAddress(controller);
        }

        // controller cannot be added twice
        if (controllers[controller] != address(0)) { revert AlreadyAController(); }
        
        controllersCount += 1;
        controllers[controller] = controllers[SENTINEL_CONTROLLERS];
        controllers[SENTINEL_CONTROLLERS] = controller;
    }

    function removeController(address prevController, address controller) external authorized {
        // validate controller address and check that it corresponds to controller index.
        if (controller == address(0) || controller == SENTINEL_CONTROLLERS) {
            revert InvalidControllerAddress(controller);
        }
        if (controllers[prevController] != controller) {
            revert InvalidPreviousControllerAddress();
        }
        controllers[prevController] = controllers[controller];
        controllers[controller] = address(0);
        controllersCount -= 1;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
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

    /* -------------------------------------------------------------------------- */
    /*                                    guard                                   */
    /* -------------------------------------------------------------------------- */
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 safeTxGas,
        bool refundGas,
        bytes memory signatures,
        address msgSender
    ) external view {
        if (controllersCount > 0) {
            if (controllers[tx.origin] == address(0)) {
                revert NotAController();
            }
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success) external {
        // do nothing
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// must be the first inherited contract
contract Singleton {
    address internal singleton;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../common/SelfAuthorized.sol";
import "openzeppelin-contracts/utils/introspection/IERC165.sol";

enum Operation { Call, DelegateCall }

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
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

contract StacktGuardManager is SelfAuthorized {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error AlreadySetup();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event ChangedGuard(address guard);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    // keccak256("guard_manager.setup.address")
    bytes32 internal constant SETUP_STORAGE_SLOT = 0xac6b4b4c91b961f50b5cda5ba75b03d57713b69c71326dc577aa2ff0b32e0286;

    /* -------------------------------------------------------------------------- */
    /*                                    setup                                   */
    /* -------------------------------------------------------------------------- */
    function setupGuard(address guard) internal {
        bool hasSetup;
        assembly {
            hasSetup := sload(SETUP_STORAGE_SLOT)
        }
        if (hasSetup) { revert AlreadySetup(); }
        assembly {
            sstore(SETUP_STORAGE_SLOT, true)
        }
        if (guard != address(0)) {
            _setGuard(guard);
        }
    }
    
    /* -------------------------------------------------------------------------- */
    /*                             getters and setters                            */
    /* -------------------------------------------------------------------------- */
    function getGuard() public view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        assembly {
            guard := sload(slot)
        }
    }

    function _setGuard(address guard) private {
        bytes32 slot = GUARD_STORAGE_SLOT;
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract SelfAuthorized {

    error NotSelfAuthorized();

    function requireSelfCall() private view {
        if (msg.sender != address(this)) { revert NotSelfAuthorized(); }
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