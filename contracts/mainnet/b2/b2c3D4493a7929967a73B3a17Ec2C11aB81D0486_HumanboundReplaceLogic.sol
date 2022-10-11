// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/extendable/extensions/replace/StrictReplaceLogic.sol";
import { HumanboundPermissionState, HumanboundPermissionStorage } from "../../storage/HumanboundPermissionStorage.sol";

contract HumanboundReplaceLogic is StrictReplaceLogic {
    modifier onlyOperatorOrSelf() virtual {
        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();

        require(
            _lastCaller() == state.operator || _lastCaller() == address(this),
            "HumanboundReplaceLogic: unauthorised"
        );
        _;
    }

    // Overrides the previous implementation of modifier to remove owner checks
    modifier onlyOwner() override {
        _;
    }

    function replace(address oldExtension, address newExtension) public override onlyOperatorOrSelf {
        super.replace(oldExtension, newExtension);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import "./IReplaceLogic.sol";
import "../extend/IExtendLogic.sol";
import "../retract/IRetractLogic.sol";
import {ExtendableState, ExtendableStorage} from "../../storage/ExtendableStorage.sol";
import {RoleState, Permissions} from "../../storage/PermissionStorage.sol";

// Requires the Extendable to have been extended with both ExtendLogic and RetractLogic
// Only allows replacement of extensions that share the exact same interface
// Safest ReplaceLogic extension
contract StrictReplaceLogic is ReplaceExtension {
    /**
     * @dev see {Extension-constructor} for constructor
    */

    /**
     * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner`
    */
    modifier onlyOwner virtual {
        address owner = Permissions._getState().owner;
        require(_lastCaller() == owner, "unauthorised");
        _;
    }

    /**
     * @dev see {IReplaceLogic-replace} Replaces an old extension with a new extension that matches the old interface.
     *
     * Uses RetractLogic to remove old and ExtendLogic to add new.
     *
     * Strictly only allows replacement of extensions with new implementations of the same interface.
    */
    function replace(address oldExtension, address newExtension) public override virtual onlyOwner {
        require(newExtension.code.length > 0, "Replace: new extend address is not a contract");

        IExtension old = IExtension(payable(oldExtension));
        IExtension newEx = IExtension(payable(newExtension));

        Interface[] memory oldInterfaces = old.getInterface();
        Interface[] memory newInterfaces = newEx.getInterface();

        // require the interfaceIds implemented by the old extension is equal to the new one
        bytes4 oldFullInterface = oldInterfaces[0].interfaceId;
        bytes4 newFullInterface = newInterfaces[0].interfaceId;

        for (uint256 i = 1; i < oldInterfaces.length; i++) {
            oldFullInterface = oldFullInterface ^ oldInterfaces[i].interfaceId;
        }

        for (uint256 i = 1; i < newInterfaces.length; i++) {
            newFullInterface = newFullInterface ^ newInterfaces[i].interfaceId;
        }
        
        require(
            newFullInterface == oldFullInterface, 
            "Replace: interface of new does not match old, please only use identical interfaces"
        );

        // Initialise both prior to state change for safety
        IRetractLogic retractLogic = IRetractLogic(payable(address(this)));
        IExtendLogic extendLogic = IExtendLogic(payable(address(this)));

        // remove old extension by using current retract logic instead of implementing conflicting logic
        retractLogic.retract(oldExtension);

        // attempt to extend with new extension
        try extendLogic.extend(newExtension) {
            // success
        }  catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory err) { // if it fails, check if this is due to extend being replaced
            if (Errors.catchCustomError(err, ExtensionNotImplemented.selector)) { // make sure this is a not implemented error due to removal of Extend
                // use raw delegate call to re-extend the extension because we have just removed the Extend function
                (bool extendSuccess, ) = newExtension.delegatecall(abi.encodeWithSignature("extend(address)", newExtension));
                require(extendSuccess, "Replace: failed to replace extend");
            } else {
                uint errLen = err.length;
                assembly {
                    revert(err, errLen)
                }
            }
        }

        emit Replaced(oldExtension, newExtension);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct HumanboundPermissionState {
    address operator;
}

library HumanboundPermissionStorage {
    bytes32 constant STORAGE_NAME = keccak256("humanboundtoken.v1:permission");

    function _getState() internal view returns (HumanboundPermissionState storage permissionState) {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            permissionState.slot := position
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IExtension.sol";
import "../errors/Errors.sol";
import "../utils/CallerContext.sol";
import "../erc165/IERC165Logic.sol";

/**
 *  ______  __  __  ______  ______  __   __  _____   ______  ______  __      ______    
 * /\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  __-./\  __ \/\  == \/\ \    /\  ___\
 * \ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \ \/\ \ \  __ \ \  __<\ \ \___\ \  __\
 *  \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\ \____-\ \_\ \_\ \_____\ \_____\ \_____\
 *   \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/____/ \/_/\/_/\/_____/\/_____/\/_____/
 *
 *  Base contract for Extensions in the Extendable Framework
 *  
 *  Inherit and implement this contract to create Extension contracts!
 *
 *  Implements the EIP-165 standard for interface detection of implementations during runtime.
 *  Uses the ERC165 singleton pattern where the actual implementation logic of the interface is
 *  deployed in a separate contract. See ERC165Logic. Deterministic deployment guarantees the
 *  ERC165Logic contract to always exist as static address 0x16C940672fA7820C36b2123E657029d982629070
 *
 *  Define your custom Extension interface and implement it whilst inheriting this contract:
 *      contract YourExtension is IYourExtension, Extension {...}
 *
 */
abstract contract Extension is CallerContext, IExtension, IERC165, IERC165Register {
    address constant ERC165LogicAddress = 0x16C940672fA7820C36b2123E657029d982629070;

    /**
     * @dev Constructor registers your custom Extension interface under EIP-165:
     *      https://eips.ethereum.org/EIPS/eip-165
    */
    constructor() {
        Interface[] memory interfaces = getInterface();
        for (uint256 i = 0; i < interfaces.length; i++) {
            Interface memory iface = interfaces[i];
            registerInterface(iface.interfaceId);

            for (uint256 j = 0; j < iface.functions.length; j++) {
                registerInterface(iface.functions[j]);
            }
        }

        registerInterface(type(IExtension).interfaceId);
    }

    function supportsInterface(bytes4 interfaceId) external override virtual returns(bool) {
        (bool success, bytes memory result) = ERC165LogicAddress.delegatecall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceId));

        if (!success) {
            assembly {
                revert(result, returndatasize())
            }
        }

        return abi.decode(result, (bool));
    }

    function registerInterface(bytes4 interfaceId) public override virtual {
        (bool success, ) = ERC165LogicAddress.delegatecall(abi.encodeWithSignature("registerInterface(bytes4)", interfaceId));

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Unidentified function signature calls to any Extension reverts with
     *      ExtensionNotImplemented error
    */
    function _fallback() internal virtual {
        revert ExtensionNotImplemented();
    }

    /**
     * @dev Fallback function passes to internal _fallback() logic
    */
    fallback() external payable virtual {
        _fallback();
    }
    
    /**
     * @dev Payable fallback function passes to internal _fallback() logic
    */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Virtual override declaration of getFunctionSelectors() function to silence compiler
     *
     * Must be implemented in inherited contract.
    */
    function getInterface() override public virtual returns(Interface[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";

/**
 * @dev Interface for ReplaceLogic extension
*/
interface IReplaceLogic {
    /**
     * @dev Emitted when `extension` is successfully extended
     */
    event Replaced(address oldExtension, address newExtension);

    /**
     * @dev Replaces `oldExtension` with `newExtension`
     *
     * Performs consecutive execution of retract and extend.
     * First the old extension is retracted using RetractLogic.
     * Second the new extension is attached using ExtendLogic.
     *
     * Since replace does not add any unique functionality aside from a
     * composition of two existing functionalities, it is best to make use
     * of those functionalities, hence the re-use of RetractLogic and 
     * ExtendLogic.
     * 
     * However, if custom logic is desired, exercise caution during 
     * implementation to avoid conflicting methods for add/removing extensions
     *
     * Requirements:
     * - `oldExtension` must be an already attached extension
     * - `newExtension` must be a contract that implements IExtension
    */
    function replace(address oldExtension, address newExtension) external;
}

abstract contract ReplaceExtension is IReplaceLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function replace(address oldExtension, address newExtension) external;\n";
    }
    /**
     * @dev see {IExtension-getInterfaceId}
    */
    function getInterface() override virtual public pure returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](1);
        functions[0] = IReplaceLogic.replace.selector;

        interfaces[0] = Interface(
            type(IReplaceLogic).interfaceId,
            functions
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import {ExtendableState, ExtendableStorage} from "../../storage/ExtendableStorage.sol";

/**
 * @dev Interface for ExtendLogic extension
*/
interface IExtendLogic {
    /**
     * @dev Emitted when `extension` is successfully extended
     */
    event Extended(address extension);
    
    /**
     * @dev Emitted when extend() is called and contract owner has not been set
     */
    event OwnerInitialised(address newOwner);

    /**
     * @dev Extend function to extend your extendable contract with new logic
     *
     * Integrate with ExtendableStorage to persist state
     *
     * Sets the known implementor of each function of `extension` as the current call context
     * contract.
     *
     * Emits `Extended` event upon successful extending.
     *
     * Requirements:
     *  - `extension` contract must implement EIP-165.
     *  - `extension` must inherit IExtension
     *  - Must record the `extension` by both its interfaceId and address
     *  - The functions of `extension` must not already be extended by another attached extension
    */
    function extend(address extension) external;

    /**
     * @dev Returns a string-formatted representation of the full interface of the current
     *      Extendable contract as an interface named IExtended
     *
     * Expects `extension.getSolidityInterface` to return interface-compatible syntax with line-separated
     * function declarations including visibility, mutability and returns.
    */
    function getFullInterface() external view returns(string memory fullInterface);

    /**
     * @dev Returns an array of interfaceIds that are currently implemented by the current
     *      Extendable contract
    */
    function getExtensionsInterfaceIds() external view returns(bytes4[] memory);
    /**
     * @dev Returns an array of function selectors that are currently implemented by the current
     *      Extendable contract
    */
    function getExtensionsFunctionSelectors() external view returns(bytes4[] memory);

    /**
     * @dev Returns an array of all extension addresses that are currently attached to the
     *      current Extendable contract
    */
    function getExtensionAddresses() external view returns(address[] memory);
}

/**
 * @dev Abstract Extension for ExtendLogic
*/
abstract contract ExtendExtension is IExtendLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function extend(address extension) external;\n"
                "function getFullInterface() external view returns(string memory);\n"
                "function getExtensionsInterfaceIds() external view returns(bytes4[] memory);\n"
                "function getExtensionsFunctionSelectors() external view returns(bytes4[] memory);\n"
                "function getExtensionAddresses() external view returns(address[] memory);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
    */
    function getInterface() override virtual public pure returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](5);
        functions[0] = IExtendLogic.extend.selector;
        functions[1] = IExtendLogic.getFullInterface.selector;
        functions[2] = IExtendLogic.getExtensionsInterfaceIds.selector;
        functions[3] = IExtendLogic.getExtensionsFunctionSelectors.selector;
        functions[4] = IExtendLogic.getExtensionAddresses.selector;

        interfaces[0] = Interface(
            type(IExtendLogic).interfaceId,
            functions
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import {ExtendableState, ExtendableStorage} from "../../storage/ExtendableStorage.sol";

/**
 * @dev Interface for RetractLogic extension
*/
interface IRetractLogic {
    /**
     * @dev Emitted when `extension` is successfully removed
     */
    event Retracted(address extension);

    /**
     * @dev Removes an extension from your Extendable contract
     *
     * Requirements:
     * - `extension` must be an attached extension
    */
    function retract(address extension) external;
}

abstract contract RetractExtension is IRetractLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function retract(address extension) external;\n";
    }

    /**
     * @dev see {IExtension-getImplementedInterfaces}
    */
    function getInterface() override virtual public pure returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](1);
        functions[0] = IRetractLogic.retract.selector;

        interfaces[0] = Interface(
            type(IRetractLogic).interfaceId,
            functions
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Storage struct used to hold state for Extendable contracts
 */
struct ExtendableState {
    // Array of full interfaceIds extended by the Extendable contract instance
    bytes4[] implementedInterfaceIds;

    // Array of function selectors extended by the Extendable contract instance
    mapping(bytes4 => bytes4[]) implementedFunctionsByInterfaceId;

    // Mapping of interfaceId/functionSelector to the extension address that implements it
    mapping(bytes4 => address) extensionContracts;
}

/**
 * @dev Storage library to access storage slot for the state struct
 */
library ExtendableStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:extendable-state");

    function _getState()
        internal 
        view
        returns (ExtendableState storage extendableState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            extendableState.slot := position
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Storage struct used to hold state for Permissioning roles
 */
struct RoleState {
    address owner;
    // Can add more for DAOs/multisigs or more complex role capture for example:
    // address admin;
    // address manager:
}

/**
 * @dev Storage library to access storage slot for the state struct
 */
library Permissions {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:permissions-state");

    function _getState()
        internal 
        view
        returns (RoleState storage roleState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            roleState.slot := position
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Interface {
    bytes4 interfaceId;
    bytes4[] functions;
}

/**
 * @dev Interface for Extension
*/
interface IExtension {
    /**
     * @dev Returns a full view of the functional interface of the extension
     *
     * Must return a list of the functions in the interface of your custom Extension
     * in the same format and syntax as in the interface itself as a string, 
     * escaped-newline separated.
     *
     * OPEN TO SUGGESTIONS FOR IMPROVEMENT ON THIS METHODOLOGY FOR 
     * DEEP DESCRIPTIVE RUNTIME INTROSPECTION
     *
     * Intent is to allow developers that want to integrate with an Extendable contract
     * that will have a constantly evolving interface, due to the nature of Extendables,
     * to be able to easily inspect and query for the current state of the interface and
     * integrate with it.
     *
     * See {ExtendLogic-getSolidityInterface} for an example.
    */
    function getSolidityInterface() external pure returns(string memory);

    /**
     * @dev Returns the interface IDs that are implemented by the Extension
     *
     * These are full interface IDs and ARE NOT function selectors. Full interface IDs are
     * XOR'd function selectors of an interface. For example the interface ID of the ERC721
     * interface is 0x80ac58cd determined by the XOR or all function selectors of the interface.
     * 
     * If an interface only consists of a single function, then the interface ID is identical
     * to that function selector.
     * 
     * Provides a simple abstraction from the developer for any custom Extension to 
     * be EIP-165 compliant out-of-the-box simply by implementing this function. 
     *
     * Excludes any functions either already described by other interface definitions
     * that are not developed on top of this backbone i.e. EIP-165, IExtension
    */
    function getInterface() external returns(Interface[] memory interfaces);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev  ExtensionNotImplemented error is emitted by Extendable and Extensions
 *       where no implementation for a specified function signature exists
 *       in the contract
*/
error ExtensionNotImplemented();


/**
 * @dev  Utility library for contracts to catch custom errors
 *       Pass in a return `result` from a call, and the selector for your error message
 *       and the `catchCustomError` function will return `true` if the error was found
 *       or `false` otherwise
*/
library Errors {
    function catchCustomError(bytes memory result, bytes4 errorSelector) internal pure returns(bool) {
        bytes4 caught;
        assembly {
            caught := mload(add(result, 0x20))
        }

        return caught == errorSelector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CallerState, CallerContextStorage} from "../storage/CallerContextStorage.sol";

/**
 * @dev CallerContext contract provides Extensions with proper caller-scoped contexts.
 *      Inherit this contract with your Extension to make use of caller references.
 *
 * `msg.sender` may not behave as developer intends when using within Extensions as many
 * calls may be exchanged between intra-contract extensions which result in a `msg.sender` as self.
 * Instead of using `msg.sender`, replace it with 
 *      - `_lastExternalCaller()` for the most recent caller in the call chain that is external to this contract
 *      - `_lastCaller()` for the most recent caller
 *
 * CallerContext provides a deep callstack to track the caller of the Extension/Extendable contract
 * at any point in the execution cycle.
 *
*/
contract CallerContext {
    /**
     * @dev Returns the most recent caller of this contract that came from outside this contract.
     *
     * Used by extensions that require fetching msg.sender that aren't cross-extension calls.
     * Cross-extension calls resolve msg.sender as the current contract and so the actual
     * caller context is obfuscated.
     * 
     * This function should be used in place of `msg.sender` where external callers are read.
     */
    function _lastExternalCaller() internal view returns(address) {
        CallerState storage state = CallerContextStorage._getState();

        for (uint i = state.callerStack.length - 1; i >= 0; i--) {
            address lastSubsequentCaller = state.callerStack[i];
            if (lastSubsequentCaller != address(this)) {
                return lastSubsequentCaller;
            }
        }

        revert("_lastExternalCaller: end of stack");
    }

    /**
     * @dev Returns the most recent caller of this contract.
     *
     * Last caller may also be the current contract.
     *
     * If the call is directly to the contract, without passing an Extendable, return `msg.sender` instead
     */
    function _lastCaller() internal view returns(address) {
        CallerState storage state = CallerContextStorage._getState();
        if (state.callerStack.length > 0)
            return state.callerStack[state.callerStack.length - 1];
        else
            return msg.sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
    function supportsInterface(bytes4 interfaceId) external returns (bool);
}


/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Uses Extendable storage pattern to populate the registered interfaces storage variable.
 */
interface IERC165Register {
    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function registerInterface(bytes4 interfaceId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct CallerState {
    // Stores a list of callers in the order they are received
    // The current caller context is always the last-most address
    address[] callerStack;
}

library CallerContextStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:caller-state");

    function _getState()
        internal 
        view
        returns (CallerState storage callerState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            callerState.slot := position
        }
    }
}