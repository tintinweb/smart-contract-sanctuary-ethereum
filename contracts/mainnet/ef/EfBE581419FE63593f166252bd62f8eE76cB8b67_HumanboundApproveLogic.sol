// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/erc721extendable/contracts/extensions/base/approve/ApproveLogic.sol";

contract HumanboundApproveLogic is ApproveLogic {
    function approve(address to, uint256 tokenId) public pure override {
        revert("HumanboundApproveLogic: approvals disallowed");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("HumanboundApproveLogic: approvals disallowed");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721State, ERC721Storage } from "../../../storage/ERC721Storage.sol";
import "./IApproveLogic.sol";
import "../getter/IGetterLogic.sol";

// Functional logic extracted from openZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
// To follow Extension principles, maybe best to separate each function into a different Extension
contract ApproveLogic is ApproveExtension {
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = IGetterLogic(address(this)).ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _lastExternalCaller() == owner ||
                IGetterLogic(address(this)).isApprovedForAll(owner, _lastExternalCaller()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        // must use external call for _internal to resolve correctly
        IApproveLogic(address(this))._approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_lastExternalCaller(), operator, approved);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        ERC721State storage erc721State = ERC721Storage._getState();
        erc721State._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) public virtual override _internal {
        ERC721State storage erc721State = ERC721Storage._getState();
        erc721State._tokenApprovals[tokenId] = to;
        emit Approval(IGetterLogic(address(this)).ownerOf(tokenId), to, tokenId);
    }
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

    function _getState() internal view returns (ERC721State storage erc721State) {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            erc721State.slot := position
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/InternalExtension.sol";

interface IApproveLogic {
    /**
     * @dev See {IERC721-Approval}.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev See {IERC721-ApprovalForAll}.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev See {IERC721-approve}.
     */
    function _approve(address to, uint256 tokenId) external;
}

abstract contract ApproveExtension is IApproveLogic, InternalExtension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function approve(address to, uint256 tokenId) external;\n"
            "function setApprovalForAll(address operator, bool approved) external;\n"
            "function _approve(address to, uint256 tokenId) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](3);
        functions[0] = IApproveLogic.approve.selector;
        functions[1] = IApproveLogic.setApprovalForAll.selector;
        functions[2] = IApproveLogic._approve.selector;

        interfaces[0] = Interface(type(IApproveLogic).interfaceId, functions);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/InternalExtension.sol";

interface IGetterLogic {
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external returns (uint256);

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external returns (address);

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) external returns (address);

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) external returns (bool);

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     *
     * Requirements:
     *
     * - Must be modified with `public _internal`.
     */
    function _exists(uint256 tokenId) external returns (bool);

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - Must be modified with `public _internal`.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) external returns (bool);
}

abstract contract GetterExtension is IGetterLogic, InternalExtension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function balanceOf(address owner) external view returns (uint256);\n"
            "function ownerOf(uint256 tokenId) external view returns (address);\n"
            "function getApproved(uint256 tokenId) external view returns (address);\n"
            "function isApprovedForAll(address owner, address operator) external view returns (bool);\n"
            "function _exists(uint256 tokenId) external view returns (bool);\n"
            "function _isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](6);
        functions[0] = IGetterLogic.balanceOf.selector;
        functions[1] = IGetterLogic.ownerOf.selector;
        functions[2] = IGetterLogic.getApproved.selector;
        functions[3] = IGetterLogic.isApprovedForAll.selector;
        functions[4] = IGetterLogic._exists.selector;
        functions[5] = IGetterLogic._isApprovedOrOwner.selector;

        interfaces[0] = Interface(type(IGetterLogic).interfaceId, functions);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Extension.sol";
import "../utils/Internal.sol";
import "../errors/Errors.sol";

/**
 *  ______  __  __  ______  ______  __   __  _____   ______  ______  __      ______    
 * /\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  __-./\  __ \/\  == \/\ \    /\  ___\
 * \ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \ \/\ \ \  __ \ \  __<\ \ \___\ \  __\
 *  \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\ \____-\ \_\ \_\ \_____\ \_____\ \_____\
 *   \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/____/ \/_/\/_/\/_____/\/_____/\/_____/
 *
 *  Base contract for Internal Extensions in the Extendable Framework
 *  
 *  Internal Extensions are used to house common functions that are used by other contract extensions.
 *  This is used to make internal functions usable across all your extensions without exposing it
 *  to the external world.
 *
 *  Define your custom Extension interface and implement it whilst inheriting this contract:
 *      contract YourExtension is IYourExtension, InternalExtension {...}
 *
 *  Then define your function and simply modify it in the following way:
 *      contract YourExtension is IYourExtension, InternalExtension {
 *          function _someFunc() public _internal {}
 *      }
 *   
 *  Notice that your internal function carries both the `public` visibility modifier and the `_internal` 
 *  modifier. This is because cross-extension calls are resolved as external calls and `public` allows
 *  your other extensions to call them whilst `_internal` restricts callers to only extensions of the
 *  same contract.
 *
 *  Note:
 *  Use underscores `_` as internal function prefixes as general naming convention.
 */
abstract contract InternalExtension is Internal, Extension {}

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

/**
 * @dev Internal contract base inherited by InternalExtension to allow access
 *      to `_internal` modifier for functions that should only be callable by
 *      other Extensions of the current contract thus keeping the functions
 *      'internal' with respects to Extendable contract scope.
 *
 * Modify your functions with `_internal` to restrict callers to only originate
 * from the current Extendable contract.
 *
 * Note that due to the nature of cross-Extension calls, they are deemed as external
 * calls and thus your functions must counterintuitively be marked as both:
 *
 * `public _internal`
 *
 * function yourFunction() public _internal {}
*/

contract Internal {
    modifier _internal() {
        require(msg.sender == address(this), "external caller not allowed");
        _;
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