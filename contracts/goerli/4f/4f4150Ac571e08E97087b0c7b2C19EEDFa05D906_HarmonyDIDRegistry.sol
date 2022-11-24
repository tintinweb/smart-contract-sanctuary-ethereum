// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IDIDRegistry} from "./interfaces/IDIDRegistry.sol";

contract HarmonyDIDRegistry is ERC2771Context, IDIDRegistry, Ownable, Pausable {
    using Address for address;

    string private constant _didPrefix = "did:metablox:";

    string[] private _context;

    mapping(address => bool) private _didRevokeds;

    mapping(address => DIDMetadata) private _didMetadatas;

    mapping(address => address[]) private _didControllers;

    mapping(address => VMethod[]) private _didVMethods;

    mapping(address => mapping(VRType => string[])) private _didVRelationships;

    mapping(address => Service[]) private _didServices;

    mapping(address => mapping(bytes32 => bool)) private _invalidVCs;

    modifier whenDIDActivated(address did) {
        require(!_didMetadatas[did].deactivated, "DIDRegistry: already unactivated");
        _;
    }

    modifier whenDIDExist(address did) {
        require(did != address(0), "DIDRegistry: zero address");
        require(!_didRevokeds[did], "DIDRegistry: DID revoked");
        require(_didMetadatas[did].exist, "DIDRegistry: DID not exist");
        _;
    }

    modifier onlyController(address did) {
        address[] memory addrs = _didControllers[did];
        require(addrs.length > 0, "DIDRegistry: not found");
        bool exist = false;
        for (uint8 i = 0; i < addrs.length; i++) {
            if (addrs[i] == _msgSender()) {
                exist = true;
                break;
            }
        }
        require(exist, "DIDRegistry: only controller");
        _;
    }

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     */
    constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {
        _context = ["https://www.w3.org/ns/did/v1"];
    }

    function registerDID(address did) external override whenNotPaused {
        require(did != _msgSender(), "DIDRegistry: only controller");
        require(!_didRevokeds[did], "DIDRegistry: DID revoked");
        require(_didMetadatas[did].exist, "DIDRegistry: did already exist");

        _didMetadatas[did] = DIDMetadata({
            exist: true,
            created: block.timestamp,
            updated: 0,
            deactivated: false,
            versionId: 1
        });

        _didControllers[did] = [_msgSender()];

        emit DIDRegistered(did);
    }

    function updateDID(
        address did,
        DOCExtra calldata docExtra
    ) external override whenNotPaused whenDIDExist(did) whenDIDActivated(did) onlyController(did) {
        _verifyDOCExtra(docExtra);

        _didMetadatas[did].updated = block.timestamp;
        _didMetadatas[did].versionId++;

        if (docExtra.verificationMethod.length > 0) {
            delete _didVMethods[did];
            VMethod[] storage vmethods = _didVMethods[did];
            for (uint8 i = 0; i < docExtra.verificationMethod.length; i++) {
                vmethods.push(docExtra.verificationMethod[i]);
            }
        }

        if (docExtra.assertionMethod.length > 0) {
            delete _didVRelationships[did][VRType.AssertionMethod];
            string[] storage rs = _didVRelationships[did][VRType.AssertionMethod];
            for (uint8 i = 0; i < docExtra.assertionMethod.length; i++) {
                rs.push(docExtra.assertionMethod[i]);
            }
        }

        if (docExtra.keyAgreement.length > 0) {
            delete _didVRelationships[did][VRType.KeyAgreement];
            string[] storage rs = _didVRelationships[did][VRType.KeyAgreement];
            for (uint8 i = 0; i < docExtra.keyAgreement.length; i++) {
                rs.push(docExtra.keyAgreement[i]);
            }
        }

        if (docExtra.capabilityInvocation.length > 0) {
            delete _didVRelationships[did][VRType.CapabilityInvocation];
            string[] storage rs = _didVRelationships[did][VRType.CapabilityInvocation];
            for (uint8 i = 0; i < docExtra.capabilityInvocation.length; i++) {
                rs.push(docExtra.capabilityInvocation[i]);
            }
        }

        if (docExtra.capabilityDelegation.length > 0) {
            delete _didVRelationships[did][VRType.CapabilityDelegation];
            string[] storage rs = _didVRelationships[did][VRType.CapabilityDelegation];
            for (uint8 i = 0; i < docExtra.capabilityDelegation.length; i++) {
                rs.push(docExtra.capabilityDelegation[i]);
            }
        }

        if (docExtra.service.length > 0) {
            delete _didServices[did];
            Service[] storage services = _didServices[did];
            for (uint8 i = 0; i < docExtra.service.length; i++) {
                services.push(docExtra.service[i]);
            }
        }

        emit DIDUpdated(did, _msgSender(), _didMetadatas[did].versionId);
    }

    function revokeDID(
        address did
    ) external override whenDIDExist(did) whenDIDActivated(did) whenNotPaused onlyController(did) {
        _didRevokeds[did] = true;

        delete _didMetadatas[did];

        delete _didControllers[did];

        delete _didVMethods[did];

        delete _didVRelationships[did][VRType.AssertionMethod];
        delete _didVRelationships[did][VRType.CapabilityDelegation];
        delete _didVRelationships[did][VRType.CapabilityInvocation];
        delete _didVRelationships[did][VRType.KeyAgreement];

        delete _didServices[did];

        emit DIDRevoked(did, _msgSender());
    }

    function activateDID(
        address did,
        bool enabled
    ) external override whenNotPaused whenDIDExist(did) onlyController(did) {
        _didMetadatas[did].deactivated = enabled;
        if (enabled) {
            emit DIDActived(did, _msgSender());
        } else {
            emit DIDDeactived(did, _msgSender());
        }
    }

    function addController(
        address did,
        address controller
    ) external override whenNotPaused whenDIDExist(did) whenDIDActivated(did) onlyController(did) {
        address[] storage ctrs = _didControllers[did];
        require(ctrs.length < 5, "DIDRegistry: too many cotrollers");

        for (uint8 i = 0; i < ctrs.length; i++) {
            require(ctrs[i] != controller, "DIDRegistry: already exist");
        }
        ctrs.push(controller);

        emit DIDControllerAdded(did, controller);
    }

    function removeController(
        address did,
        address controller
    ) external override whenNotPaused whenDIDExist(did) whenDIDActivated(did) onlyController(did) {
        address[] storage ctrs = _didControllers[did];
        require(ctrs.length > 1, "DIDRegistry: at least 1");

        for (uint8 j = 0; j < ctrs.length; j++) {
            if (controller == ctrs[j]) {
                if (ctrs.length - 1 != j) {
                    ctrs[j] = ctrs[ctrs.length - 1];
                }
                ctrs.pop();
                break;
            }

            emit DIDControllerRemoved(did, controller);
        }
    }

    function revokeVC(address did, string memory vcType) external override whenNotPaused whenDIDExist(did) {
        _invalidVCs[_msgSender()][keccak256(abi.encodePacked(did, vcType))] = true;
        emit VCRevoked(_msgSender(), did, vcType);
    }

    /**
     * @dev Return did @context and context hash value.
     */
    function getDIDContext() external view override returns (string[] memory) {
        return _context;
    }

    function isVCRevoked(
        address vcIssuer,
        address vcHolder,
        string memory vcType
    ) external view override returns (bool) {
        return _invalidVCs[vcIssuer][keccak256(abi.encodePacked(vcHolder, vcType))];
    }

    function getDID(
        address did
    ) external view override whenDIDExist(did) returns (DIDMetadata memory, address[] memory, DOCExtra memory) {
        DIDMetadata memory metadata = _didMetadatas[did];

        address[] memory controller = _didControllers[did];

        DOCExtra memory docExtra = DOCExtra({
            verificationMethod: _didVMethods[did],
            assertionMethod: _didVRelationships[did][VRType.AssertionMethod],
            keyAgreement: _didVRelationships[did][VRType.KeyAgreement],
            capabilityInvocation: _didVRelationships[did][VRType.CapabilityInvocation],
            capabilityDelegation: _didVRelationships[did][VRType.CapabilityDelegation],
            service: _didServices[did]
        });
        return (metadata, controller, docExtra);
    }

    function getDIDPrefix() external pure override returns (string memory) {
        return _didPrefix;
    }

    function _msgSender() internal view override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _verifyDOCExtra(DOCExtra calldata docExtra) internal view virtual {}
}

/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.15;

interface IDIDRegistry {
    enum VRType {
        Authentication,
        AssertionMethod,
        KeyAgreement,
        CapabilityInvocation,
        CapabilityDelegation
    }

    struct DIDMetadata {
        bool exist;
        uint256 created;
        uint256 updated;
        bool deactivated;
        uint256 versionId;
    }

    struct VMethod {
        string id;
        string kind;
        address controller;
        string publicKeyData;
    }

    struct Service {
        string id;
        string kind;
        string serviceEndpoint;
    }

    struct DOCExtra {
        VMethod[] verificationMethod;
        string[] assertionMethod;
        string[] keyAgreement;
        string[] capabilityInvocation;
        string[] capabilityDelegation;
        Service[] service;
    }

    event DIDRegistered(address indexed did);
    event DIDUpdated(address indexed did, address indexed controller, uint256 indexed versionId);
    event DIDActived(address indexed did, address indexed controller);
    event DIDDeactived(address indexed did, address indexed controller);
    event DIDControllerRemoved(address indexed user, address indexed controller);
    event DIDControllerAdded(address indexed user, address indexed controller);
    event DIDRevoked(address indexed did, address indexed controller);
    event VCRevoked(address indexed issuer, address indexed holder, string vcType);

    /**
     * @dev Register DID
     * @param did standard address
     */
    function registerDID(address did) external;

    function updateDID(address did, DOCExtra memory docExtra) external;

    function revokeDID(address did) external;

    function activateDID(address did, bool enabled) external;

    function revokeVC(address did, string memory vcType) external;

    function removeController(address did, address controller) external;

    function addController(address did, address controller) external;

    function getDID(address did) external view returns (DIDMetadata memory, address[] memory, DOCExtra memory);

    function getDIDContext() external view returns (string[] memory);

    function getDIDPrefix() external view returns (string memory);

    function isVCRevoked(address vcIssuer, address vcHolder, string memory vcType) external view returns (bool);
}