// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

pragma solidity ^0.8.15;

import { Errors } from "../../libraries/Errors.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title OwnableNFT
 * @author API3 Latam.
 *
 * @notice Logic for ACL trough token ownership.
 * The owner is determined by the holding of a token with an specific ID,
 * where the token ID converts to an on-chain address.
 */
abstract contract OwnableNFT {
    // ========== Storage ==========
    // The address of the token that the owner should have domain over.
    address public ownershipToken;

    // ========== Modifiers ==========
    /**
     * @notice Checks if the function is being called by the owner,
     * where the owner is defined by the token ID in the ownership token which
     * maps to the calling contract address.
     */
    modifier onlyOwner() {
        if (owner() != msg.sender) {
            revert Errors.CallerNotOwner(msg.sender);
        }
        _;
    }

    // ========== Helpers/Utilities Functions ==========
    /**
     * @notice Set the address for the token from whom ownership
     * the access control is derived.
     *
     * @param _ownershipToken The ERC721 address to use as controller.
     */
    function _setNFT (
        address _ownershipToken
    ) internal {
        ownershipToken = _ownershipToken;
    }

    // ========== Get/Set Function ==========
    /**
     * @notice Gets the owner of the underlying token ID, derived
     * from the contract address of the contract implementing.
     */
    function owner() 
     public view virtual returns (
        address
    ) {
        return IERC721(
            ownershipToken
        ).ownerOf(
            uint256(
                uint160(
                    address(this)
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { IAssetVault } from "../../../interfaces/IAssetVault.sol";
import { OwnableNFT } from "../../base/OwnableNFT.sol";  
import { Errors } from "../../../libraries/Errors.sol";
import { Events } from "../../../libraries/Events.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

/**
 * @title AssetVault
 * @author API3 Latam.
 *
 * The Asset Vault is a vault for the storage of ERC721 assets.
 * Designed for one-time use, like a piggy bank. Once withdrawals are enabled,
 * and the safe is broken, the vault can no longer be used.
 *
 * It starts in a deposit-only state. Assets cannot be withdrawn at this point. When
 * the owner is allow and actually calls `enableWithdraw()`, 
 * the state is set to a 'withdrawEnabled' state.
 * Withdraws cannot be disabled once enabled. This restriction protects the interactions
 * of the assets kept in the vault from unexpected withdrawal and frontrunning attacks.
 *
 * This contract is based from the arcadexyz repository `v2-contracts`.
 * You can found the original at the URL:
 * https://github.com/arcadexyz/v2-contracts/blob/main/contracts/vault/AssetVault.sol
 *
 * @dev AssetVault only supports arbitrary external calls by the current owner of the vault.
 */
contract AssetVault is
    IAssetVault,
    OwnableNFT,
    ERC721HolderUpgradeable
{
    // ========== Storage ==========
    /**
     * @notice True if withdrawals are allowed out of this vault.
     * @dev Once set to true, it cannot be reverted back to false.
    */
    bool public override withdrawEnabled;

    // ========== Modifiers ==========
    /**
     * @dev For methods only callable with withdraws enabled
     * (all withdrawal operations).
     */
    modifier onlyWithdrawEnabled () {
        if (!withdrawEnabled) {
            revert Errors.VaultWithdrawsDisabled();
        }
        _;
    }

    /**
     * @dev For methods only callable with withdraws disabled
     * (call operations and enabling withdraws).
     */
    modifier onlyWithdrawDisabled() {
        if (withdrawEnabled) {
            revert Errors.VaultWithdrawsEnabled();
        }
        _;
    }

    // ========== Initializer/Constructor ==========
    /**
     * @dev Disables initializers, so contract can only be used trough proxies.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev See { IAssetVault-initialize }.
     */
    function initialize ()
     external initializer {
        if (
            withdrawEnabled ||
            ownershipToken != address(0)
        ) {
            revert Errors.AlreadyInitialized();
        }

        _setNFT(msg.sender);
    }

    // ========== Core Functions ==========
    /**
     * @dev See { IAssetVault.enableWithdraw }.
     */
    function enableWithdraw ()
     external override onlyOwner onlyWithdrawDisabled {
        withdrawEnabled = true;
        emit Events.WithdrawEnabled(msg.sender);
    }

    /**
     * @dev See { IAssetVault.withdrawERC721 }.
     */
    function withdrawERC721 (
        address token,
        uint256 tokenId,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        IERC721(token).safeTransferFrom(
            address(this),
            to,
            tokenId
        );
        emit Events.WithdrawERC721(
            msg.sender,
            to,
            token,
            tokenId
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title IAssetVault
 * @author API3 Latam
 *
 * @notice This is the interface for the AssetVault contract,
 * which is utilized for safekeeping of assets during Hub
 * user flows, like 'Raffles'.
 *
 * This contract is based from the arcadexyz repository `v2-contracts`.
 * You can found it at this URL:
 * https://github.com/arcadexyz/v2-contracts/blob/main/contracts/interfaces/IAssetVault.sol
 */
interface IAssetVault {
    // ================ Initialize ================
    /**
     * @notice Initializer for the logic contract trough the minimal clone proxy.
     * @dev In practice, always called by the VaultFactory contract.
     */
    function initialize () external;

    // ========== Core Functions ==========
    /**
     * @notice Enables withdrawals on the vault.
     * @dev Any integration should be aware that a withdraw-enabled vault cannot
     * be transferred (will revert).
     */
    function enableWithdraw () 
     external;

    /**
     * @notice Withdraw entire balance of a given ERC721 token from the vault.
     * The vault must be in a "withdrawEnabled" state (non-transferrable).
     * The specified token must exist and be owned by this contract.
     *
     * @param token The token to withdraw.
     * @param tokenId The ID of the NFT to withdraw.
     * @param to The recipient of the withdrawn token.
     */
    function withdrawERC721 (
        address token,
        uint256 tokenId,
        address to
    ) external;

    // ========== Get/Set Functions ==========
    /**
     * 
     */
    function withdrawEnabled ()
     external view returns (
        bool
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title DataTypes
 * @author API3 Latam
 * 
 * @notice A standard library of data types used across the API3 LATAM
 * Fairness Platform.
 */
library DataTypes {
    
    // ========== Enums ==========
    /**
     * @notice An enum containing the different states a raffle can use.
     *
     * @param Unintialized - A raffle is created but yet to be open.
     * @param Canceled - A raffle that is invalidated.
     * @param Open - A raffle where participants can enter.
     * @param Close - A raffle which cannot recieve more participants.
     * @param Finish - A raffle that has been wrapped up.
     */
    enum RaffleStatus {
        Unintialized,
        Canceled,
        Open,
        Close,
        Finish
    }

    // ========== Structs ==========
    /**
     * @notice An enum containing the 
     */

    /**
     * @notice Structure to efficiently save IPFS hashes.
     * @dev To reconstruct full hash insert `hash_function` and `size` before the
     * the `hash` value. So you have `hash_function` + `size` + `hash`.
     * This gives you a hexadecimal representation of the CIDs. You need to parse
     * it to base58 from hex if you want to use it on a traditional IPFS gateway.
     *
     * @param hash - The hexadecimal representation of the CID payload from the hash.
     * @param hash_function - The hexadecimal representation of multihash identifier.
     * IPFS currently defaults to use `sha2` which equals to `0x12`.
     * @param size - The hexadecimal representation of `hash` bytes size.
     * Expecting value of `32` as default which equals to `0x20`. 
     */
    struct Multihash {
        bytes32 hash;
        uint8 hash_function;
        uint8 size;
    }

    /**
     * @notice Information for Airnode endpoints.
     *
     * @param endpointId - The unique identifier for the endpoint this
     * callbacks points to.
     * @param functionSelector - The function selector for this endpoint
     * callback.
     */
    struct Endpoint {
        bytes32 endpointId;
        bytes4 functionSelector;
    }

    /**
     * @notice Metadata information for WinnerAirnode request flow.
     * @dev This should be consume by used in addition to IndividualRaffle struct
     * to return actual winner addresses.
     *
     * @param totalEntries - The number of participants for this raffle.
     * @param totalWinners - The number of winners finally set for this raffle.
     * @param winnerIndexes - The indexes for the winners from raffle entries.
     * @param isFinished - Indicates wether the result has been retrieved or not.
     */
    struct WinnerReponse {
        uint256 totalEntries;
        uint256 totalWinners;
        uint256[] winnerIndexes;
        bool isFinished;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Errors
 * @author API3 Latam
 * 
 * @notice A standard library of error types used across the API3 LATAM
 * Raffle Platform.
 */
library Errors {

    // ========== Core Errors ==========
    error SameValueProvided ();
    error AlreadyInitialized ();
    error InvalidProxyAddress (
        address _proxy
    );
    error ZeroAddress();
    error WrongInitializationParams (
        string errorMessage
    );
    error InvalidParameter();
    error ParameterNotSet();
    error RaffleNotOpen ();             // Raffle
    error RaffleNotAvailable ();        // Raffle
    error RaffleNotClose ();            // Raffle
    error RaffleAlreadyOpen ();         // Raffle
    error EarlyClosing();               // Raffle

    // ========== Base Errors ==========
    error CallerNotOwner (               // Ownable ERC721
        address caller
    );
    error RequestIdNotKnown ();          // AirnodeLogic
    error NoEndpointAdded ();            // AirnodeLogic
    error InvalidEndpointId ();          // AirnodeLogic
    error IncorrectCallback ();          // AirnodeLogic

    // ========== Airnode Module Errors ==========
    error InvalidWinnerNumber ();        // WinnerAirnode
    error ResultRetrieved ();            // WinnerAirnode

    // ========== Vault Module Errors ==========
    error VaultWithdrawsDisabled ();     // AssetVault
    error VaultWithdrawsEnabled ();      // AssetVault
    error TokenIdOutOfBounds (           // VaultFactory
        uint256 tokenId
    );
    error NoTransferWithdrawEnabled (    // VaultFactory
        uint256 tokenId
    );
    error BatchLengthMismatch();         // VaultDepositRouter

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { DataTypes } from "./DataTypes.sol";

/**
 * @title Events
 * @author API3 Latam
 * 
 * @notice A standard library of Events used across the API3 LATAM
 * Raffle Platform.
 */
library Events {

    // ========== Core Events ==========
    /**
     * @dev Emitted when a Raffle is created.
     * 
     * @param _raffleId - The identifier for this specific raffle.
     */
    event RaffleCreated (
        uint256 indexed _raffleId
    );

    /**
     * @dev Emitted when the winners are set from the QRNG provided data.
     *
     * @param _raffleId - The identifier for this specific raffle.
     * @param raffleWinners - The winner address list for this raffle.
     */
    event WinnerPicked (
        uint256 indexed _raffleId,
        address[] raffleWinners
    );

        // ========== Base Events ==========
    /**
     * @dev Emitted when we set the parameters for the airnode.
     *
     * @param airnodeAddress - The Airnode address being use.
     * @param sponsorAddress - The address from sponsor.
     * @param sponsorWallet - The actual sponsored wallet address.
     */
    event SetRequestParameters (
        address airnodeAddress,
        address sponsorAddress,
        address sponsorWallet
    );

    /**
     * @dev Emitted when a new Endpoint is added to an AirnodeLogic instance.
     *
     * @param _index - The current index for the recently added endpoint in the array.
     * @param _newEndpointId - The given endpointId for the addition.
     * @param _newEndpointSelector - The selector for the given endpoint of this addition.
     */
    event SetAirnodeEndpoint (
        uint256 indexed _index,
        bytes32 indexed _newEndpointId,
        string _endpointFunction,
        bytes4 _newEndpointSelector
    );

    // ========== Airnode Module Events ==========
    /**
     * @dev Should be emitted when a request to WinnerAirnode is done.
     *
     * @param requestId - The request id which this event is related to.
     * @param airnodeAddress - The airnode address from which this request was originated.
     */
    event NewWinnerRequest (
        bytes32 indexed requestId,
        address indexed airnodeAddress
    );

    /**
     * @dev Same as `NewRequest` but, emitted at the callback time when
     * a request is successful for flow control.
     *
     * @param requestId - The request id from which this event was emitted.
     * @param airnodeAddress - The airnode address from which this request was originated.
     */
    event SuccessfulRequest (
        bytes32 indexed requestId,
        address indexed airnodeAddress
    );

    // ========== Vault Module Events ==========
    /**
     * @dev Should be emitted when withdrawals are enabled on a vault.
     *
     * @param emitter The address of the vault owner.
     */
    event WithdrawEnabled (
        address emitter
    );
    
    /**
     * @dev Should be emitted when the balance of ERC721s is withdraw
     * from a vault.
     *
     * @param emitter The address of the vault owner.
     * @param recipient The end user to recieve the assets.
     * @param tokenContract The addresses of the assets being transfered.
     * @param tokenId The id of the token being transfered.
     */
    event WithdrawERC721 (
        address indexed emitter,
        address indexed recipient,
        address indexed tokenContract,
        uint256 tokenId
    );

    /**
     * @dev Should be emitted when factory creates a new vault clone.
     *
     * @param vault The address of the new vault.
     * @param to The new owner of the vault.
     */
    event VaultCreated (
        address vault,
        address to
    );
}