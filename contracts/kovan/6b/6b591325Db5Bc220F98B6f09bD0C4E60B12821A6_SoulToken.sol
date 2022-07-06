// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/erc721extendable/contracts/extensions/metadata/ERC721Metadata.sol";

contract SoulToken is ERC721Metadata {
    constructor(string memory name_, string memory symbol_, 
        address extendLogic,
        address approveLogic,
        address getterLogic,
        address onReceiveLogic,
        address transferLogic,
        address hooksLogic)
    ERC721Metadata(name_, symbol_, extendLogic, approveLogic, getterLogic, onReceiveLogic, transferLogic, hooksLogic) {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../base/ERC721.sol";

/**
 * @dev ERC721Metadata Extendable contract
 *
 * Constructor arguments take usual `name` and `symbol` arguments for the token
 * with additional extension addresses specifying where the functional logic
 * for each of the token features live which is passed to the Base ERC721 contract
 *
 * Metadata-specific extensions must be extended immediately after deployment by
 * calling the `finaliseERC721MetadataExtending` function.
 *
 */
contract ERC721Metadata is ERC721 {
    constructor(string memory name_, string memory symbol_, 
        address extendLogic,
        address approveLogic,
        address getterLogic,
        address onReceiveLogic,
        address transferLogic,
        address hooksLogic) 
    ERC721(name_, symbol_, extendLogic, approveLogic, getterLogic, onReceiveLogic, transferLogic, hooksLogic) {}

    /**
    * @dev Extends the contract with Metadata-specific functionalities
    *
    * Must be called immediately after contract deployment.
    *
    */
    function finaliseERC721MetadataExtending(
        address metadataGetterLogic,
        address setTokenURILogic,
        address mintLogic,
        address burnLogic
    ) public {
        IExtendLogic self = IExtendLogic(address(this));

        self.extend(metadataGetterLogic);
        self.extend(setTokenURILogic);
        self.extend(mintLogic);
        self.extend(burnLogic);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extendable/Extendable.sol";
import "@violetprotocol/extendable/extensions/extend/IExtendLogic.sol";
import { ERC721State, ERC721Storage } from "../../storage/ERC721Storage.sol";

/**
 * @dev Core ERC721 Extendable contract
 *
 * Constructor arguments take usual `name` and `symbol` arguments for the token
 * with additional extension addresses specifying where the functional logic
 * for each of the token features live.
 *
 */
contract ERC721 is Extendable {
    constructor(string memory name_, string memory symbol_, 
        address extendLogic,
        address approveLogic,
        address getterLogic,
        address onReceiveLogic,
        address transferLogic,
        address hooksLogic
    ) Extendable(extendLogic) {
        // Set the token name and symbol
        ERC721State storage erc721State = ERC721Storage._getState();
        erc721State._name = name_;
        erc721State._symbol = symbol_;

        // Attempt to extend the contract with core functionality
        // Must use low-level calls since contract has not yet been fully deployed
        (bool extendApproveSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("extend(address)", approveLogic)
        );
        require(extendApproveSuccess, "failed to initialise approve");

        (bool extendGetterSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("extend(address)", getterLogic)
        );
        require(extendGetterSuccess, "failed to initialise getter");
        
        (bool extendOnReceiveSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("extend(address)", onReceiveLogic)
        );
        require(extendOnReceiveSuccess, "failed to initialise onReceive");

        (bool extendTransferSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("extend(address)", transferLogic)
        );
        require(extendTransferSuccess, "failed to initialise transfer");

        (bool extendHooksSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("extend(address)", hooksLogic)
        );
        require(extendHooksSuccess, "failed to initialise hooks");

    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../errors/Errors.sol";
import {CallerState, CallerContextStorage} from "../storage/CallerContextStorage.sol";
import {ExtendableState, ExtendableStorage} from "../storage/ExtendableStorage.sol";
import {RoleState, Permissions} from "../storage/PermissionStorage.sol";
import "../extensions/permissioning/PermissioningLogic.sol";
import "../extensions/extend/ExtendLogic.sol";

/**
 *  ______  __  __  ______  ______  __   __  _____   ______  ______  __      ______    
 * /\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  __-./\  __ \/\  == \/\ \    /\  ___\
 * \ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \ \/\ \ \  __ \ \  __<\ \ \___\ \  __\
 *  \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\ \____-\ \_\ \_\ \_____\ \_____\ \_____\
 *   \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/____/ \/_/\/_/\/_____/\/_____/\/_____/
 *
 *  Core module for the Extendable framework
 *  
 *  Inherit this contract to make your contracts Extendable!
 *
 *  Your contract can perform ad-hoc addition or removal of functions
 *  which allows modularity, re-use, upgrade, and extension of your
 *  deployed contracts. You can make your contract immutable by removing
 *  the ability for it to be extended.
 *
 *  Constructor initialises owner-based permissioning to manage
 *  extending, where only the `owner` can extend the contract.
 *  
 *  You may change this constructor or use extension replacement to
 *  use a different permissioning pattern for your contract.
 *
 *  Requirements:
 *      - ExtendLogic contract must already be deployed
 */
contract Extendable {
    /**
     * @dev Contract constructor initialising the first extension `ExtendLogic`
     *      to allow the contract to be extended.
     *
     * This implementation assumes that the `ExtendLogic` being used also uses
     * an ownership pattern that only allows `owner` to extend the contract.
     * 
     * This constructor sets the owner of the contract and extends itself
     * using the ExtendLogic extension.
     *
     * To change owner or ownership mode, your contract must be extended with the
     * PermissioningLogic extension, giving it access to permissioning management.
     */
    constructor(address extendLogic) {
        // wrap main constructor logic in pre/post fallback hooks for callstack registration
        _beforeFallback();

        // extend extendable contract with the first extension: extend, using itself in low-level call
        (bool extendSuccess, ) = extendLogic.delegatecall(abi.encodeWithSignature("extend(address)", extendLogic));

        // check that initialisation tasks were successful
        require(extendSuccess, "failed to initialise extension");

        _afterFallback();
    }
    
    /**
     * @dev Delegates function calls to the specified `delegatee`.
     *
     * Performs a delegatecall to the `delegatee` with the incoming transaction data
     * as the input and returns the result. The transaction data passed also includes 
     * the function signature which determines what function is attempted to be called.
     * 
     * If the `delegatee` returns a ExtensionNotImplemented error, the `delegatee` is
     * an extension that does not implement the function to be called.
     *
     * Otherwise, the function execution fails/succeeds as determined by the function 
     * logic and returns as such.
     */
    function _delegate(address delegatee) internal virtual returns(bool) {
        bytes memory out;
        (bool success, bytes memory result) = delegatee.delegatecall(msg.data);

        // copy all returndata to `out` once instead of duplicating copy for each conditional branch
        assembly {
            returndatacopy(out, 0, returndatasize())
        }

        // if the delegatecall execution did not succeed
        if (!success) {
            // check if failure was due to an ExtensionNotImplemented error
            if (Errors.catchCustomError(result, ExtensionNotImplemented.selector)) {
                // cleanly return false if error is caught
                return false;
            } else {
                // otherwise revert, passing in copied full returndata
                assembly {
                    revert(out, returndatasize())
                }
            }
        } else {
            // otherwise end execution and return the copied full returndata

            // make sure to call _afterFallback before ending execution
            _afterFallback();
            assembly {
                return(out, returndatasize())
            }
        }
    }
    
    /**
     * @dev Internal fallback function logic that attempts to delegate execution
     *      to extension contracts
     *
     * Initially attempts to locate an interfaceId match with a function selector
     * which are extensions that house single functions (singleton extensions)
     * If none is found then attempt execution by cycling through extensions and
     * calling.
     *
     * If no implementations are found that match the requested function signature,
     * returns ExtensionNotImplemented error
     */
    function _fallback() internal virtual {
        _beforeFallback();
        ExtendableState storage state = ExtendableStorage._getStorage();

        bool ok = false;
        // if an extension exists that matches in the functionsig
        if (state.extensionContracts[msg.sig] != address(0x0)) {
            // call it
            _delegate(state.extensionContracts[msg.sig]);
        } else {                                                 
            // else cycle through all extensions to find it if exists
            // this is not the preferred method for usage and only acts as a fallback
            for (uint i = 0; i < state.interfaceIds.length; i++) {
                ok = _delegate(state.extensionContracts[state.interfaceIds[i]]);
                if (ok) break; // exit after first successful execution
            }
        }

        if (!ok) revert ExtensionNotImplemented(); // if there are no successful delegatecalls we assume no implementation.
        _afterFallback();
    }

    /**
     * @dev Default fallback function to catch unrecognised selectors.
     *
     * Used in order to perform extension lookups by _fallback().
     *
     * Core fallback logic sandwiched between caller context work.
     */
    fallback() external payable virtual {
        _fallback();
    }
    
    /**
     * @dev Payable fallback function to catch unrecognised selectors with ETH payments.
     *
     * Used in order to perform extension lookups by _fallback().
     */
    receive() external payable virtual {
        _fallback();
    }
    
    /**
     * @dev Virtual hook that is called before _fallback().
     */
    function _beforeFallback() internal virtual {
        CallerState storage state = CallerContextStorage._getStorage();
        state.callerStack.push(msg.sender);
    }
    
    /**
     * @dev Virtual hook that is called after _fallback().
     */
    function _afterFallback() internal virtual {
        CallerState storage state = CallerContextStorage._getStorage();
        state.callerStack.pop();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface for ExtendLogic extension
*/
interface IExtendLogic {
    /**
     * @dev Extend function to extend your extendable contract with new logic
     *
     * Integrate with ExtendableStorage to persist state 
     *
     * Requirements:
     *  - `extension` contract must implement EIP-165.
     *  - Must record the `extension` by both its interfaceId and address
     *  - `extension` must inherit IExtension
     *  - The interfaceId of the "candidate" extension must not match that of an existing 
     *    attached extension
    */
    function extend(address extension) external;

    /**
     * @dev Returns a string-formatted representation of the full interface of the current
     *      Extendable contract as an interface named IExtended
     *
     * Expects `extension.getInterface` to return interface-compatible syntax with line-separated
     * function declarations including visibility, mutability and returns.
    */
    function getCurrentInterface() external view returns(string memory fullInterface);

    /**
     * @dev Returns an array of interfaceIds that are currently supported by the current
     *      Extendable contract
    */
    function getExtensions() external view returns(bytes4[] memory);

    /**
     * @dev Returns an array of all extension addresses that are currently attached to the
     *      current Extendable contract
    */
    function getExtensionAddresses() external view returns(address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct ERC721State {
    // Token name
    string _name;

    // Token symbol
    string _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;

    // Mapping owner address to token count
    mapping(address => uint256) _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
}

library ERC721Storage {
    bytes32 constant STORAGE_NAME = keccak256("extendable:erc721:base");

    function _getState()
        internal 
        view
        returns (ERC721State storage erc721State) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            erc721State.slot := position
        }
    }
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

struct CallerState {
    // Stores a list of callers in the order they are received
    // The current caller context is always the last-most address
    address[] callerStack;
}

library CallerContextStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:caller-state");

    function _getStorage()
        internal 
        view
        returns (CallerState storage callerStorage) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            callerStorage.slot := position
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Storage struct used to hold state for Extendable contracts
 */
struct ExtendableState {
    // Array of interfaceIds extended by the Extendable contract instance
    bytes4[] interfaceIds;

    // Mapping of interfaceId to the extension address that implements it
    mapping(bytes4 => address) extensionContracts;
}

/**
 * @dev Storage library to access storage slot for the state struct
 */
library ExtendableStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:extendable-state");

    function _getStorage()
        internal 
        view
        returns (ExtendableState storage extendableStorage) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            extendableStorage.slot := position
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

    function _getStorage()
        internal 
        view
        returns (RoleState storage roleStorage) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            roleStorage.slot := position
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import "./IPermissioningLogic.sol";
import {RoleState, Permissions} from "../../storage/PermissionStorage.sol";

/**
 * @dev Reference implementation for PermissioningLogic which defines the logic to control
 *      and define ownership of contracts
 *
 * Records address as `owner` in the PermissionStorage module. Modifications and access to 
 * the module affect the state wherever it is accessed by Extensions and can be read/written
 * from/to by other attached extensions.
 *
 * Currently used by the ExtendLogic reference implementation to restrict extend permissions
 * to only `owner`. Uses a common function from the storage library `_onlyOwner()` as a
 * modifier replacement. Can be wrapped in a modifier if preferred.
*/
contract PermissioningLogic is IPermissioningLogic, Extension {
    /**
     * @dev see {Extension-constructor} for constructor
    */


    /**
     * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner`
    */
    modifier onlyOwner {
        address owner = Permissions._getStorage().owner;
        require(_lastCaller() == owner, "unauthorised");
        _;
    }

    /**
     * @dev see {IPermissioningLogic-init}
    */
    function init() override public {
        RoleState storage state = Permissions._getStorage();
        require(state.owner == address(0x0), "already initialised"); // make sure owner has yet to be set for delegator
        state.owner = _lastCaller();
    }

    /**
     * @dev see {IPermissioningLogic-updateOwner}
    */
    function updateOwner(address newOwner) override public onlyOwner {
        RoleState storage state = Permissions._getStorage();
        state.owner = newOwner;
    }

    /**
     * @dev see {IPermissioningLogic-getOwner}
    */
    function getOwner() override public view returns(address) {
        RoleState storage state = Permissions._getStorage();
        return(state.owner);
    }

    /**
     * @dev see {IExtension-getInterfaceId}
    */
    function getInterfaceId() override public pure returns(bytes4) {
        return(type(IPermissioningLogic).interfaceId);
    }

    /**
     * @dev see {IExtension-getInterface}
    */
    function getInterface() override public pure returns(string memory) {
        return  "function init() external;\n"
                "function updateOwner(address newOwner) external;\n"
                "function getOwner() external view returns(address);\n";
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import "./IExtendLogic.sol";
import {ExtendableState, ExtendableStorage} from "../../storage/ExtendableStorage.sol";
import {RoleState, Permissions} from "../../storage/PermissionStorage.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Reference implementation for ExtendLogic which defines the logic to extend
 *      Extendable contracts
 *
 * Uses PermissioningLogic owner pattern to control extensibility. Only the `owner`
 * can extend using this logic.
 *
 * Modify this ExtendLogic extension to change the way that your contract can be
 * extended: public extendability; DAO-based extendability; governance-vote-based etc.
*/
contract ExtendLogic is IExtendLogic, Extension {
    /**
     * @dev see {Extension-constructor} for constructor
    */

    /**
     * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner` or the current contract
    */
    modifier onlyOwnerOrSelf {
        initialise();
    
        address owner = Permissions._getStorage().owner;
        require(_lastCaller() == owner || _lastCaller() == address(this), "unauthorised");
        _;
    }

    /**
     * @dev see {IExtendLogic-extend}
     *
     * Uses PermissioningLogic implementation with `owner` checks.
     *
     * Restricts extend to `onlyOwner`.
     *
     * If `owner` has not been initialised, assume that this is the initial extend call
     * during constructor of Extendable and instantiate `owner` as the caller.
    */
    function extend(address extension) override public virtual onlyOwnerOrSelf {
        require(extension.code.length > 0, "Extend: address is not a contract");

        IERC165 erc165Extension = IERC165(payable(extension));
        require(erc165Extension.supportsInterface(bytes4(0x01ffc9a7)), "Extend: extension does not implement eip-165");

        IExtension ext = IExtension(payable(extension));
        ExtendableState storage state = ExtendableStorage._getStorage();
        require(state.extensionContracts[ext.getInterfaceId()] == address(0x0), "Extend: extension already exists for interfaceId");

        state.interfaceIds.push(ext.getInterfaceId());
        state.extensionContracts[ext.getInterfaceId()] = extension;
    }

    /**
     * @dev see {IExtendLogic-getCurrentInterface}
    */
    function getCurrentInterface() override public view returns(string memory fullInterface) {
        ExtendableState storage state = ExtendableStorage._getStorage();
        for (uint i = 0; i < state.interfaceIds.length; i++) {
            bytes4 interfaceId = state.interfaceIds[i];
            IExtension logic = IExtension(state.extensionContracts[interfaceId]);
            fullInterface = string(abi.encodePacked(fullInterface, logic.getInterface()));
        }

        // TO-DO optimise this return to a standardised format with comments for developers
        return string(abi.encodePacked("interface IExtended {\n", fullInterface, "}"));
    }

    /**
     * @dev see {IExtendLogic-getExtensions}
    */
    function getExtensions() override public view returns(bytes4[] memory) {
        ExtendableState storage state = ExtendableStorage._getStorage();
        return state.interfaceIds;
    }

    /**
     * @dev see {IExtendLogic-getExtensionAddresses}
    */
    function getExtensionAddresses() override public view returns(address[] memory) {
        ExtendableState storage state = ExtendableStorage._getStorage();
        address[] memory addresses = new address[](state.interfaceIds.length);
        
        for (uint i = 0; i < state.interfaceIds.length; i++) {
            bytes4 interfaceId = state.interfaceIds[i];
            addresses[i] = state.extensionContracts[interfaceId];
        }
        return addresses;
    }

    /**
     * @dev see {IExtension-getInterface}
    */
    function getInterface() override public pure returns(string memory) {
        return  "function extend(address extension) external;\n"
                "function getCurrentInterface() external view returns(string memory);\n"
                "function getExtensions() external view returns(bytes4[] memory);\n"
                "function getExtensionAddresses() external view returns(address[] memory);\n";
    }

    /**
     * @dev see {IExtension-getInterfaceId}
    */
    function getInterfaceId() override public pure returns(bytes4) {
        return(type(IExtendLogic).interfaceId);
    }


    /**
     * @dev Sets the owner of the contract to the tx origin if unset
     *
     * Used by Extendable during first extend to set deployer as the owner that can
     * extend the contract
    */
    function initialise() internal {
        RoleState storage state = Permissions._getStorage();

        // Set the owner to the transaction sender if owner has not been initialised
        if (state.owner == address(0x0)) {
            state.owner = _lastCaller();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IExtension.sol";
import "../errors/Errors.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "../utils/CallerContext.sol";

/**
 *  ______  __  __  ______  ______  __   __  _____   ______  ______  __      ______    
 * /\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  __-./\  __ \/\  == \/\ \    /\  ___\
 * \ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \ \/\ \ \  __ \ \  __<\ \ \___\ \  __\
 *  \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\ \____-\ \_\ \_\ \_____\ \_____\ \_____\
 *   \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/____/ \/_/\/_/\/_____/\/_____/\/_____/
 *
 *  Base contract for all Extensions in the Extendable Framework
 *  
 *  Inherit and implement this contract to create Extension contracts!
 *
 *  Implements the EIP-165 standard for interface detection of implementations during runtime.
 *
 *  Define your custom Extension interface and implement it whilst inheriting this contract:
 *      contract YourExtension is IYourExtension, Extension {...}
 *
 */
abstract contract Extension is ERC165Storage, CallerContext, IExtension {
    /**
     * @dev Constructor registers your custom Extension interface under EIP-165:
     *      https://eips.ethereum.org/EIPS/eip-165
    */
    constructor() {
        _registerInterface(getInterfaceId());
        _registerInterface(type(IExtension).interfaceId);
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
     * @dev Virtual override declaration of getInterfaceId() function
     *
     * Must be implemented in inherited contract.
    */
    function getInterfaceId() override public virtual pure returns(bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface for PermissioningLogic extension
*/
interface IPermissioningLogic {
    /**
     * @dev Initialises the `owner` of the contract as `msg.sender`
     *
     * Requirements:
     * - `owner` cannot already be assigned
    */
    function init() external;

    /**
     * @dev Updates the `owner` to `newOwner`
    */
    function updateOwner(address newOwner) external;

    /**
     * @dev Returns the current `owner`
    */
    function getOwner() external view returns(address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
     * See {ExtendLogic-getInterface} for an example.
    */
    function getInterface() external pure returns(string memory);

    /**
     * @dev Returns the interfaceId of current custom Extension interface
     * 
     * Provides a simple abstraction from the developer for any custom Extension to 
     * be EIP-165 compliant out-of-the-box simply by implementing this function.
     *
     * Excludes any functions either already described by other interface definitions
     * that are not developed on top of this backbone i.e. EIP-165, IExtension
    */
    function getInterfaceId() external pure returns(bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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
        CallerState storage state = CallerContextStorage._getStorage();

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
        CallerState storage state = CallerContextStorage._getStorage();
        if (state.callerStack.length > 0)
            return state.callerStack[state.callerStack.length - 1];
        else
            return msg.sender;
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