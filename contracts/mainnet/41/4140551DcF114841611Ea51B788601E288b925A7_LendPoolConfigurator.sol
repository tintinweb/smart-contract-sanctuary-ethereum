// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {IIncentivesController} from "./IIncentivesController.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title IDebtToken
 * @author Unlockd
 * @notice Defines the basic interface for a debt token.
 **/
interface IDebtToken is IScaledBalanceToken, IERC20Upgradeable, IERC20MetadataUpgradeable {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lend pool
   * @param incentivesController The address of the incentives controller
   * @param debtTokenDecimals the decimals of the debt token
   * @param debtTokenName the name of the debt token
   * @param debtTokenSymbol the symbol of the debt token
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol
  );

  /**
   * @dev Initializes the debt token.
   * @param addressProvider The address of the lend pool
   * @param underlyingAsset The address of the underlying asset
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address underlyingAsset,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol
  ) external;

  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount to be minted
   * @param index The last index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints debt token to the `user` address
   * @param user The address receiving the borrowed underlying
   * @param onBehalfOf The beneficiary of the mint
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return `true` if the the previous balance of the user is 0
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted when variable debt is burnt
   * @param user The user which debt has been burned
   * @param amount The amount of debt being burned
   * @param index The index of the user
   **/
  event Burn(address indexed user, uint256 amount, uint256 index);

  /**
   * @dev Burns user variable debt
   * @param user The user which debt is burnt
   * @param amount The amount to be burnt
   * @param index The variable debt index of the reserve
   **/
  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IIncentivesController);

  /**
   * @dev delegates borrowing power to a user on the specific debt token
   * @param delegatee the address receiving the delegated borrowing power
   * @param amount the maximum amount being delegated. Delegation will still
   * respect the liquidation constraints (even if delegated, a delegatee cannot
   * force a delegator HF to go below 1)
   **/
  function approveDelegation(address delegatee, uint256 amount) external;

  /**
   * @dev returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return the current allowance of toUser
   **/
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IIncentivesController {
  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param totalSupply The total supply of the asset in the lending pool
   * @param userBalance The balance of the user of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 totalSupply,
    uint256 userBalance
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {IUToken} from "./IUToken.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ILendPool {
  /**
   * @dev Emitted when _rescuer is modified in the LendPool
   * @param newRescuer The address of the new rescuer
   **/
  event RescuerChanged(address indexed newRescuer);

  /**
   * @dev Emitted on deposit()
   * @param user The address initiating the deposit
   * @param amount The amount deposited
   * @param reserve The address of the underlying asset of the reserve
   * @param onBehalfOf The beneficiary of the deposit, receiving the uTokens
   * @param referral The referral code used
   **/
  event Deposit(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed onBehalfOf,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param user The address initiating the withdrawal, owner of uTokens
   * @param reserve The address of the underlyng asset being withdrawn
   * @param amount The amount to be withdrawn
   * @param to Address that will receive the underlying
   **/
  event Withdraw(address indexed user, address indexed reserve, uint256 amount, address indexed to);

  /**
   * @dev Emitted on borrow() when loan needs to be opened
   * @param user The address of the user initiating the borrow(), receiving the funds
   * @param reserve The address of the underlying asset being borrowed
   * @param amount The amount borrowed out
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the loan
   * @param referral The referral code used
   * @param nftConfigFee an estimated gas cost fee for configuring the NFT
   **/
  event Borrow(
    address user,
    address indexed reserve,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address indexed onBehalfOf,
    uint256 borrowRate,
    uint256 loanId,
    uint16 indexed referral,
    uint256 nftConfigFee
  );

  /**
   * @dev Emitted on repay()
   * @param user The address of the user initiating the repay(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param amount The amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param borrower The beneficiary of the repayment, getting his debt reduced
   * @param loanId The loan ID of the NFT loans
   **/
  event Repay(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is auctioned.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param bidPrice The price of the underlying reserve given by the bidder
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Auction(
    address user,
    address indexed reserve,
    uint256 bidPrice,
    address indexed nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted on redeem()
   * @param user The address of the user initiating the redeem(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param borrowAmount The borrow amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param loanId The loan ID of the NFT loans
   **/
  event Redeem(
    address user,
    address indexed reserve,
    uint256 borrowAmount,
    uint256 fineAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event Liquidate(
    address user,
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated on NFTX.
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event LiquidateNFTX(
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );
  /**
   * @dev Emitted when an NFT configuration is triggered.
   * @param user The NFT holder
   * @param nftAsset The NFT collection address
   * @param nftTokenId The NFT token Id
   **/
  event ValuationApproved(address indexed user, address indexed nftAsset, uint256 indexed nftTokenId);
  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when the pause time is updated.
   */
  event PausedTimeUpdated(uint256 startTime, uint256 durationTime);

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendPool contract. The event is therefore replicated here so it
   * gets added to the LendPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
  @dev Emitted after the address of the interest rate strategy contract has been updated
  */
  event ReserveInterestRateAddressChanged(address indexed asset, address indexed rateAddress);

  /**
  @dev Emitted after setting the configuration bitmap of the reserve as a whole
  */
  event ReserveConfigurationChanged(address indexed asset, uint256 configuration);

  /**
  @dev Emitted after setting the configuration bitmap of the NFT collection as a whole
  */
  event NftConfigurationChanged(address indexed asset, uint256 configuration);

  /**
  @dev Emitted after setting the configuration bitmap of the NFT as a whole
  */
  event NftConfigurationByIdChanged(address indexed asset, uint256 indexed nftTokenId, uint256 configuration);

  /**
  @dev Emitted after setting the new safe health factor value for redeems
  */
  event SafeHealthFactorUpdated(uint256 indexed newSafeHealthFactor);

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying uTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 uusdc
   * @param reserve The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the uTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of uTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(address reserve, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent uTokens owned
   * E.g. User has 100 uusdc, calls withdraw() and receives 100 USDC, burning the 100 uusdc
   * @param reserve The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole uToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(address reserve, uint256 amount, address to) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral
   * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
   *   and lock collateral asset in contract
   * @param reserveAsset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrow(
    address reserveAsset,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function repay(address nftAsset, uint256 nftTokenId, uint256 amount) external returns (uint256, bool);

  /**
   * @dev Function to auction a non-healthy position collateral-wise
   * - The caller (liquidator) want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param bidPrice The bid price of the liquidator want to buy the underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function auction(address nftAsset, uint256 nftTokenId, uint256 bidPrice, address onBehalfOf) external;

  /**
   * @notice Redeem a NFT loan which state is in Auction
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(address nftAsset, uint256 nftTokenId, uint256 amount, uint256 bidFine) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
   *   the collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidate(address nftAsset, uint256 nftTokenId, uint256 amount) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The collateral asset is sold on NFTX & Sushiswap
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidateNFTX(address nftAsset, uint256 nftTokenId, uint256 amountOutMin) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The collateral asset is sold on NFTX & Sushiswap
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidateSudoSwap(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amountOutMin,
    address LSSVMPair,
    uint256 amountOutMinSudoswap
  ) external returns (uint256);

  /**
   * @dev Approves valuation of an NFT for a user
   * @dev Just the NFT holder can trigger the configuration
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function approveValuation(address nftAsset, uint256 nftTokenId) external payable;

  /**
   * @dev Validates and finalizes an uToken transfer
   * - Only callable by the overlying uToken of the `asset`
   * @param asset The address of the underlying asset of the uToken
   * @param from The user from which the uTokens are transferred
   * @param to The user receiving the uTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The uToken balance of the `from` user before the transfer
   * @param balanceToBefore The uToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external view;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getReserveConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the NFT
   * @param asset The address of the asset of the NFT
   * @return The configuration of the NFT
   **/
  function getNftConfiguration(address asset) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the configuration of the NFT
   * @param asset The address of the asset of the NFT
   * @param tokenId the Token Id of the NFT
   * @return The configuration of the NFT
   **/
  function getNftConfigByTokenId(
    address asset,
    uint256 tokenId
  ) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @dev Returns the list of the initialized reserves
   * @return the list of initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @dev Returns the state and configuration of the nft
   * @param asset The address of the underlying asset of the nft
   * @return The status of the nft
   **/
  function getNftData(address asset) external view returns (DataTypes.NftData memory);

  /**
   * @dev Returns the configuration of the nft asset
   * @param asset The address of the underlying asset of the nft
   * @param tokenId NFT asset ID
   * @return The configuration of the nft asset
   **/
  function getNftAssetConfig(
    address asset,
    uint256 tokenId
  ) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the loan data of the NFT
   * @param nftAsset The address of the NFT
   * @param reserveAsset The address of the Reserve
   * @return totalCollateralInETH the total collateral in ETH of the NFT
   * @return totalCollateralInReserve the total collateral in Reserve of the NFT
   * @return availableBorrowsInETH the borrowing power in ETH of the NFT
   * @return availableBorrowsInReserve the borrowing power in Reserve of the NFT
   * @return ltv the loan to value of the user
   * @return liquidationThreshold the liquidation threshold of the NFT
   * @return liquidationBonus the liquidation bonus of the NFT
   **/
  function getNftCollateralData(
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset
  )
    external
    view
    returns (
      uint256 totalCollateralInETH,
      uint256 totalCollateralInReserve,
      uint256 availableBorrowsInETH,
      uint256 availableBorrowsInReserve,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus
    );

  /**
   * @dev Returns the debt data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return reserveAsset the address of the Reserve
   * @return totalCollateral the total power of the NFT
   * @return totalDebt the total debt of the NFT
   * @return availableBorrows the borrowing power left of the NFT
   * @return healthFactor the current health factor of the NFT
   **/
  function getNftDebtData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    returns (
      uint256 loanId,
      address reserveAsset,
      uint256 totalCollateral,
      uint256 totalDebt,
      uint256 availableBorrows,
      uint256 healthFactor
    );

  /**
   * @dev Returns the auction data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return bidderAddress the highest bidder address of the loan
   * @return bidPrice the highest bid price in Reserve of the loan
   * @return bidBorrowAmount the borrow amount in Reserve of the loan
   * @return bidFine the penalty fine of the loan
   **/
  function getNftAuctionData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    returns (uint256 loanId, address bidderAddress, uint256 bidPrice, uint256 bidBorrowAmount, uint256 bidFine);

  /**
   * @dev Returns the state and configuration of the nft
   * @param nftAsset The address of the underlying asset of the nft
   * @param nftAsset The token ID of the asset
   **/
  function getNftLiquidatePrice(
    address nftAsset,
    uint256 nftTokenId
  ) external view returns (uint256 liquidatePrice, uint256 paybackAmount);

  /**
   * @dev Returns the list of nft addresses in the protocol
   **/
  function getNftsList() external view returns (address[] memory);

  /**
   * @dev Set the _pause state of a reserve
   * - Only callable by the LendPool contract
   * @param val `true` to pause the reserve, `false` to un-pause it
   */
  function setPause(bool val) external;

  function setPausedTime(uint256 startTime, uint256 durationTime) external;

  /**
   * @dev Returns if the LendPool is paused
   */
  function paused() external view returns (bool);

  function getPausedTime() external view returns (uint256, uint256);

  /**
   * @dev Returns the cached LendPoolAddressesProvider connected to this contract
   **/

  function getAddressesProvider() external view returns (ILendPoolAddressesProvider);

  /**
   * @dev Initializes a reserve, activating it, assigning an uToken and nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param uTokenAddress The address of the uToken that will be assigned to the reserve
   * @param debtTokenAddress The address of the debtToken that will be assigned to the reserve
   * @param interestRateAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address uTokenAddress,
    address debtTokenAddress,
    address interestRateAddress
  ) external;

  /**
   * @dev Initializes a nft, activating it, assigning nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the nft
   **/
  function initNft(address asset, address uNftAddress) external;

  /**
   * @dev Updates the address of the interest rate strategy contract
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateAddress(address asset, address rateAddress) external;

  /**
   * @dev Sets the configuration bitmap of the reserve as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setReserveConfiguration(address asset, uint256 configuration) external;

  /**
   * @dev Sets the configuration bitmap of the NFT as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the asset of the NFT
   * @param configuration The new configuration bitmap
   **/
  function setNftConfiguration(address asset, uint256 configuration) external;

  /**
   * @dev Sets the configuration bitmap of the NFT as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the asset of the NFT
   * @param nftTokenId the NFT tokenId
   * @param configuration The new configuration bitmap
   **/
  function setNftConfigByTokenId(address asset, uint256 nftTokenId, uint256 configuration) external;

  /**
   * @dev Sets the max supply and token ID for a given asset
   * @param asset The address to set the data
   * @param maxSupply The max supply value
   * @param maxTokenId The max token ID value
   **/
  function setNftMaxSupplyAndTokenId(address asset, uint256 maxSupply, uint256 maxTokenId) external;

  /**
   * @dev Sets the max number of reserves in the protocol
   * @param val the value to set the max number of reserves
   **/
  function setMaxNumberOfReserves(uint256 val) external;

  /**
   * @dev Sets the max number of NFTs in the protocol
   * @param val the value to set the max number of NFTs
   **/
  function setMaxNumberOfNfts(uint256 val) external;

  /**
   * @notice Assigns the rescuer role to a given address.
   * @param newRescuer New rescuer's address
   */
  function updateRescuer(address newRescuer) external;

  /**
   * @notice Update the safe health factor value for redeems
   * @param newSafeHealthFactor New safe health factor value
   */
  function updateSafeHealthFactor(uint256 newSafeHealthFactor) external;

  /**
   * @notice Rescue tokens or ETH locked up in this contract.
   * @param tokenContract ERC20 token contract address
   * @param to        Recipient address
   * @param amount    Amount to withdraw
   * @param rescueETH bool to know if we want to rescue ETH or other token
   */
  function rescue(IERC20 tokenContract, address to, uint256 amount, bool rescueETH) external;

  /**
   * @notice Rescue NFTs locked up in this contract.
   * @param nftAsset ERC721 asset contract address
   * @param tokenId ERC721 token id
   * @param to Recipient address
   */
  function rescueNFT(IERC721Upgradeable nftAsset, uint256 tokenId, address to) external;

  /**
   * @dev Sets the fee percentage for liquidations
   * @param percentage the fee percentage to be set
   **/
  function setLiquidateFeePercentage(uint256 percentage) external;

  /**
   * @dev Sets the max timeframe between NFT config triggers and borrows
   * @param timeframe the number of seconds for the timeframe
   **/
  function setTimeframe(uint256 timeframe) external;

  /**
   * @dev Adds and address to be allowed to sell on NFTX
   * @param nftAsset the nft address of the NFT to sell
   * @param val if true is allowed to sell if false is not
   **/
  function setIsMarketSupported(address nftAsset, uint8 market, bool val) external;

  /**
   * @dev sets the fee for configuringNFTAsCollateral
   * @param configFee the amount to charge to the user
   **/
  function setConfigFee(uint256 configFee) external;

  /**
   * @dev sets the fee to be charged on first bid on nft
   * @param auctionDurationConfigFee the amount to charge to the user
   **/
  function setAuctionDurationConfigFee(uint256 auctionDurationConfigFee) external;

  /**
   * @dev Returns the maximum number of reserves supported to be listed in this LendPool
   */
  function getMaxNumberOfReserves() external view returns (uint256);

  /**
   * @dev Returns the maximum number of nfts supported to be listed in this LendPool
   */
  function getMaxNumberOfNfts() external view returns (uint256);

  /**
   * @dev Returns the fee percentage for liquidations
   **/
  function getLiquidateFeePercentage() external view returns (uint256);

  /**
   * @notice Returns current rescuer
   * @return Rescuer's address
   */
  function rescuer() external view returns (address);

  /**
   * @notice Returns current safe health factor
   * @return The safe health factor value
   */
  function getSafeHealthFactor() external view returns (uint256);

  /**
   * @dev Returns the max timeframe between NFT config triggers and borrows
   **/
  function getTimeframe() external view returns (uint256);

  /**
   * @dev Returns the configFee amount
   **/
  function getConfigFee() external view returns (uint256);

  /**
   * @dev Returns the auctionDurationConfigFee amount
   **/
  function getAuctionDurationConfigFee() external view returns (uint256);

  /**
   * @dev Returns if the address is allowed to sell or not on NFTX
   */
  function getIsMarketSupported(address nftAsset, uint8 market) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Unlockd Governance
 * @author Unlockd
 **/
interface ILendPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendPoolUpdated(address indexed newAddress, bytes encodedCallData);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendPoolConfiguratorUpdated(address indexed newAddress, bytes encodedCallData);
  event ReserveOracleUpdated(address indexed newAddress);
  event NftOracleUpdated(address indexed newAddress);
  event LendPoolLoanUpdated(address indexed newAddress, bytes encodedCallData);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy, bytes encodedCallData);
  event UNFTRegistryUpdated(address indexed newAddress);
  event IncentivesControllerUpdated(address indexed newAddress);
  event UIDataProviderUpdated(address indexed newAddress);
  event UnlockdDataProviderUpdated(address indexed newAddress);
  event WalletBalanceProviderUpdated(address indexed newAddress);
  event NFTXVaultFactoryUpdated(address indexed newAddress);
  event SushiSwapRouterUpdated(address indexed newAddress);
  event LSSVMRouterUpdated(address indexed newAddress);
  event LendPoolLiquidatorUpdated(address indexed newAddress);
  event LtvManagerUpdated(address indexed newAddress);

  /**
   * @dev Returns the id of the Unlockd market to which this contracts points to
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @dev Allows to set the market which this LendPoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string calldata marketId) external;

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @dev General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `implementationAddress`
   * IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param impl The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address impl, bytes memory encodedCallData) external;

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @dev Returns the address of the LendPool proxy
   * @return The LendPool proxy address
   **/
  function getLendPool() external view returns (address);

  /**
   * @dev Updates the implementation of the LendPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new LendPool implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolImpl(address pool, bytes memory encodedCallData) external;

  /**
   * @dev Returns the address of the LendPoolConfigurator proxy
   * @return The LendPoolConfigurator proxy address
   **/
  function getLendPoolConfigurator() external view returns (address);

  /**
   * @dev Updates the implementation of the LendPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new LendPoolConfigurator implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolConfiguratorImpl(address configurator, bytes memory encodedCallData) external;

  /**
   * @dev returns the address of the LendPool admin
   * @return the LendPoolAdmin address
   **/
  function getPoolAdmin() external view returns (address);

  /**
   * @dev sets the address of the LendPool admin
   * @param admin the LendPoolAdmin address
   **/
  function setPoolAdmin(address admin) external;

  /**
   * @dev returns the address of the emergency admin
   * @return the EmergencyAdmin address
   **/
  function getEmergencyAdmin() external view returns (address);

  /**
   * @dev sets the address of the emergency admin
   * @param admin the EmergencyAdmin address
   **/
  function setEmergencyAdmin(address admin) external;

  /**
   * @dev returns the address of the reserve oracle
   * @return the ReserveOracle address
   **/
  function getReserveOracle() external view returns (address);

  /**
   * @dev sets the address of the reserve oracle
   * @param reserveOracle the ReserveOracle address
   **/
  function setReserveOracle(address reserveOracle) external;

  /**
   * @dev returns the address of the NFT oracle
   * @return the NFTOracle address
   **/
  function getNFTOracle() external view returns (address);

  /**
   * @dev sets the address of the NFT oracle
   * @param nftOracle the NFTOracle address
   **/
  function setNFTOracle(address nftOracle) external;

  /**
   * @dev returns the address of the lendpool loan
   * @return the LendPoolLoan address
   **/
  function getLendPoolLoan() external view returns (address);

  /**
   * @dev sets the address of the lendpool loan
   * @param loan the LendPoolLoan address
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolLoanImpl(address loan, bytes memory encodedCallData) external;

  /**
   * @dev returns the address of the UNFT Registry
   * @return the UNFTRegistry address
   **/
  function getUNFTRegistry() external view returns (address);

  /**
   * @dev sets the address of the UNFT registry
   * @param factory the UNFTRegistry address
   **/
  function setUNFTRegistry(address factory) external;

  /**
   * @dev returns the address of the incentives controller
   * @return the IncentivesController address
   **/
  function getIncentivesController() external view returns (address);

  /**
   * @dev sets the address of the incentives controller
   * @param controller the IncentivesController address
   **/
  function setIncentivesController(address controller) external;

  /**
   * @dev returns the address of the UI data provider
   * @return the UIDataProvider address
   **/
  function getUIDataProvider() external view returns (address);

  /**
   * @dev sets the address of the UI data provider
   * @param provider the UIDataProvider address
   **/
  function setUIDataProvider(address provider) external;

  /**
   * @dev returns the address of the Unlockd data provider
   * @return the UnlockdDataProvider address
   **/
  function getUnlockdDataProvider() external view returns (address);

  /**
   * @dev sets the address of the Unlockd data provider
   * @param provider the UnlockdDataProvider address
   **/
  function setUnlockdDataProvider(address provider) external;

  /**
   * @dev returns the address of the wallet balance provider
   * @return the WalletBalanceProvider address
   **/
  function getWalletBalanceProvider() external view returns (address);

  /**
   * @dev sets the address of the wallet balance provider
   * @param provider the WalletBalanceProvider address
   **/
  function setWalletBalanceProvider(address provider) external;

  function getNFTXVaultFactory() external view returns (address);

  /**
   * @dev sets the address of the NFTXVault Factory contract
   * @param factory the NFTXVault Factory address
   **/
  function setNFTXVaultFactory(address factory) external;

  /**
   * @dev returns the address of the SushiSwap router contract
   **/
  function getSushiSwapRouter() external view returns (address);

  /**
   * @dev sets the address of the LSSVM router contract
   * @param router the LSSVM router address
   **/
  function setSushiSwapRouter(address router) external;

  /**
   * @dev returns the address of the LSSVM router contract
   **/
  function getLSSVMRouter() external view returns (address);

  /**
   * @dev sets the address of the LSSVM router contract
   * @param router the SushiSwap router address
   **/
  function setLSSVMRouter(address router) external;

  /**
   * @dev returns the address of the LendPool liquidator contract
   **/
  function getLendPoolLiquidator() external view returns (address);

  /**
   * @dev sets the address of the LendPool liquidator contract
   * @param liquidator the LendPool liquidator address
   **/
  function setLendPoolLiquidator(address liquidator) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILendPoolConfigurator {
  struct ConfigReserveInput {
    address asset;
    uint256 reserveFactor;
  }

  struct ConfigNftInput {
    address asset;
    uint256 tokenId;
    uint256 baseLTV;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 redeemDuration;
    uint256 auctionDuration;
    uint256 redeemFine;
    uint256 redeemThreshold;
    uint256 minBidFine;
    uint256 maxSupply;
    uint256 maxTokenId;
  }

  struct ConfigNftAsCollateralInput {
    address asset;
    uint256 nftTokenId;
    uint256 newPrice;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 redeemThreshold;
    uint256 liquidationBonus;
    uint256 redeemDuration;
    uint256 auctionDuration;
    uint256 redeemFine;
    uint256 minBidFine;
  }

  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param uToken The address of the associated uToken contract
   * @param debtToken The address of the associated debtToken contract
   * @param interestRateAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed uToken,
    address debtToken,
    address interestRateAddress
  );

  /**
   * @dev Emitted when borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingEnabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when a reserve is activated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveActivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is deactivated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDeactivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is frozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveFrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve is unfrozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated
   * @param asset The address of the underlying asset of the reserve
   * @param factor The new reserve factor
   **/
  event ReserveFactorChanged(address indexed asset, uint256 factor);

  /**
   * @dev Emitted when the reserve decimals are updated
   * @param asset The address of the underlying asset of the reserve
   * @param decimals The new decimals
   **/
  event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

  /**
   * @dev Emitted when a reserve interest strategy contract is updated
   * @param asset The address of the underlying asset of the reserve
   * @param strategy The new address of the interest strategy contract
   **/
  event ReserveInterestRateChanged(address indexed asset, address strategy);

  /**
   * @dev Emitted when a nft is initialized.
   * @param asset The address of the underlying asset of the nft
   * @param uNft The address of the associated uNFT contract
   **/
  event NftInitialized(address indexed asset, address indexed uNft);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified NFT are updated.
   * @param asset The address of the underlying asset of the NFT
   * @param tokenId token ID
   * @param ltv The loan to value of the asset when used as NFT
   * @param liquidationThreshold The threshold at which loans using this asset as NFT will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event NftConfigurationChanged(
    address indexed asset,
    uint256 indexed tokenId,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when a NFT is activated
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftActivated(address indexed asset);

  /**
   * @dev Emitted when a NFT is deactivated
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftDeactivated(address indexed asset);

  /**
   * @dev Emitted when a NFT token is activated
   * @param asset The address of the underlying asset of the NFT
   * @param nftTokenId The token id of the underlying asset of the NFT
   **/
  event NftTokenActivated(address indexed asset, uint256 indexed nftTokenId);

  /**
   * @dev Emitted when a NFT token is deactivated
   * @param asset The address of the underlying asset of the NFT
   * @param nftTokenId The token id of the underlying asset of the NFT
   **/
  event NftTokenDeactivated(address indexed asset, uint256 indexed nftTokenId);

  /**
   * @dev Emitted when a NFT is frozen
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftFrozen(address indexed asset);

  /**
   * @dev Emitted when a NFT is unfrozen
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a NFT is frozen
   * @param asset The address of the underlying asset of the NFT
   * @param nftTokenId The token id of the underlying asset of the NFT
   **/
  event NftTokenFrozen(address indexed asset, uint256 indexed nftTokenId);

  /**
   * @dev Emitted when a NFT is unfrozen
   * @param asset The address of the underlying asset of the NFT
   * @param nftTokenId The token id of the underlying asset of the NFT
   **/
  event NftTokenUnfrozen(address indexed asset, uint256 indexed nftTokenId);

  /**
   * @dev Emitted when a redeem duration is updated
   * @param asset The address of the underlying asset of the NFT
   * @param tokenId token ID
   * @param redeemDuration The new redeem duration
   * @param auctionDuration The new redeem duration
   * @param redeemFine The new redeem fine
   **/
  event NftAuctionChanged(
    address indexed asset,
    uint256 indexed tokenId,
    uint256 redeemDuration,
    uint256 auctionDuration,
    uint256 redeemFine
  );
  /**
   * @dev Emitted when a redeem threshold is modified
   * @param asset The address of the underlying asset of the NFT
   * @param tokenId token ID
   * @param redeemThreshold The new redeem threshold
   **/
  event NftRedeemThresholdChanged(address indexed asset, uint256 indexed tokenId, uint256 redeemThreshold);
  /**
   * @dev Emitted when a min bid fine is modified
   * @param asset The address of the underlying asset of the NFT
   * @param tokenId token ID
   * @param minBidFine The new min bid fine
   **/
  event NftMinBidFineChanged(address indexed asset, uint256 indexed tokenId, uint256 minBidFine);
  /**
   * @dev Emitted when an asset's max supply and max token Id is modified
   * @param asset The address of the underlying asset of the NFT
   * @param maxSupply The new max supply
   * @param maxTokenId The new max token Id
   **/
  event NftMaxSupplyAndTokenIdChanged(address indexed asset, uint256 maxSupply, uint256 maxTokenId);

  /**
   * @dev Emitted when an uToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The uToken proxy address
   * @param implementation The new uToken implementation
   **/
  event UTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  /**
   * @dev Emitted when the implementation of a debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The debt token proxy address
   * @param implementation The new debtToken implementation
   **/
  event DebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  /**
   * @dev Emitted when the lend pool rescuer is updated
   * @param rescuer the new rescuer address
   **/
  event RescuerUpdated(address indexed rescuer);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface ILendPoolLoan {
  /**
   * @dev Emitted on initialization to share location of dependent notes
   * @param pool The address of the associated lend pool
   */
  event Initialized(address indexed pool);

  /**
   * @dev Emitted when a loan is created
   * @param user The address initiating the action
   */
  event LoanCreated(
    address indexed user,
    address indexed onBehalfOf,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is updated
   * @param user The address initiating the action
   */
  event LoanUpdated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is repaid by the borrower
   * @param user The address initiating the action
   */
  event LoanRepaid(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is auction by the liquidator
   * @param user The address initiating the action
   */
  event LoanAuctioned(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 borrowIndex,
    address bidder,
    uint256 price,
    address previousBidder,
    uint256 previousPrice
  );

  /**
   * @dev Emitted when a loan is redeemed
   * @param user The address initiating the action
   */
  event LoanRedeemed(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidate by the liquidator
   * @param user The address initiating the action
   */
  event LoanLiquidated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidate on NFTX
   */
  event LoanLiquidatedNFTX(
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex,
    uint256 sellPrice
  );

  /**
   * @dev Emitted when a loan is liquidate on SudoSwap
   */
  event LoanLiquidatedSudoSwap(
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex,
    uint256 sellPrice,
    address LSSVMPair
  );

  function initNft(address nftAsset, address uNftAddress) external;

  /**
   * @dev Create store a loan object with some params
   * @param initiator The address of the user initiating the borrow
   * @param onBehalfOf The address receiving the loan
   * @param nftAsset The address of the underlying NFT asset
   * @param nftTokenId The token Id of the underlying NFT asset
   * @param uNftAddress The address of the uNFT token
   * @param reserveAsset The address of the underlying reserve asset
   * @param amount The loan amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function createLoan(
    address initiator,
    address onBehalfOf,
    address nftAsset,
    uint256 nftTokenId,
    address uNftAddress,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  ) external returns (uint256);

  /**
   * @dev Update the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Active
   * @param initiator The address of the user updating the loan
   * @param loanId The loan ID
   * @param amountAdded The amount added to the loan
   * @param amountTaken The amount taken from the loan
   * @param borrowIndex The index to get the scaled loan amount
   */
  function updateLoan(
    address initiator,
    uint256 loanId,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Repay the given loan
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the repay
   * @param loanId The loan getting burned
   * @param uNftAddress The address of uNFT
   * @param amount The amount repaid
   * @param borrowIndex The index to get the scaled loan amount
   */
  function repayLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 amount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Auction the given loan
   *
   * Requirements:
   *  - The price must be greater than current highest price
   *  - The loan must be in state Active or Auction
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting auctioned
   * @param bidPrice The bid price of this auction
   */
  function auctionLoan(
    address initiator,
    uint256 loanId,
    address onBehalfOf,
    uint256 bidPrice,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Redeem the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Auction
   * @param initiator The address of the user initiating the borrow
   * @param loanId The loan getting redeemed
   * @param amountTaken The taken amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function redeemLoan(address initiator, uint256 loanId, uint256 amountTaken, uint256 borrowIndex) external;

  /**
   * @dev Liquidate the given loan
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting burned
   * @param uNftAddress The address of uNFT
   * @param borrowAmount The borrow amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function liquidateLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Liquidate the given loan on NFTX
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Auction
   *
   * @param loanId The loan getting burned
   */
  function liquidateLoanNFTX(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    uint256 amountOutMin
  ) external returns (uint256 sellPrice);

  /**
   * @dev Liquidate the given loan on SudoSwap
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Auction
   *
   * @param loanId The loan getting burned
   */
  function liquidateLoanSudoSwap(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    DataTypes.SudoSwapParams memory sudoswapParams
  ) external returns (uint256 sellPrice);

  /**
   *  @dev returns the borrower of a specific loan
   * param loanId the loan to get the borrower from
   */
  function borrowerOf(uint256 loanId) external view returns (address);

  /**
   *  @dev returns the loan corresponding to a specific NFT
   * param nftAsset the underlying NFT asset
   * param tokenId the underlying token ID for the NFT
   */
  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

  /**
   *  @dev returns the loan corresponding to a specific loan Id
   * param loanId the loan Id
   */
  function getLoan(uint256 loanId) external view returns (DataTypes.LoanData memory loanData);

  /**
   *  @dev returns the collateral and reserve corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanCollateralAndReserve(
    uint256 loanId
  ) external view returns (address nftAsset, uint256 nftTokenId, address reserveAsset, uint256 scaledAmount);

  /**
   *  @dev returns the reserve and borrow __scaled__ amount corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanReserveBorrowScaledAmount(uint256 loanId) external view returns (address, uint256);

  /**
   *  @dev returns the reserve and borrow  amount corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanReserveBorrowAmount(uint256 loanId) external view returns (address, uint256);

  function getLoanHighestBid(uint256 loanId) external view returns (address, uint256);

  /**
   *  @dev returns the collateral amount for a given NFT
   * param nftAsset the underlying NFT asset
   */
  function getNftCollateralAmount(address nftAsset) external view returns (uint256);

  /**
   *  @dev returns the collateral amount for a given NFT and a specific user
   * param user the user
   * param nftAsset the underlying NFT asset
   */
  function getUserNftCollateralAmount(address user, address nftAsset) external view returns (uint256);

  /**
   *  @dev returns the counter tracker for all the loan ID's in the protocol
   */
  function getLoanIdTracker() external view returns (CountersUpgradeable.Counter memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/************
@title INFTOracle interface
@notice Interface for NFT price oracle.*/
interface INFTOracle {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  /**
  @dev returns the NFT price for a given NFT
  @param _collection the NFT collection
  @param _tokenId the NFT token Id
   */
  function getNFTPrice(address _collection, uint256 _tokenId) external view returns (uint256);

  /**
  @dev returns the NFT price for a given array of NFTs
  @param _collections the array of NFT collections
  @param _tokenIds the array NFT token Id
   */
  function getMultipleNFTPrices(address[] calldata _collections, uint256[] calldata _tokenIds)
    external
    view
    returns (uint256[] memory);

  /**
  @dev sets the price for a given NFT 
  @param _collection the NFT collection
  @param _tokenId the NFT token Id
  @param _price the price to set to the token
  */
  function setNFTPrice(
    address _collection,
    uint256 _tokenId,
    uint256 _price
  ) external;

  /**
  @dev sets the price for a given NFT 
  @param _collections the array of NFT collections
  @param _tokenIds the array of  NFT token Ids
  @param _prices the array of prices to set to the given tokens
   */
  function setMultipleNFTPrices(
    address[] calldata _collections,
    uint256[] calldata _tokenIds,
    uint256[] calldata _prices
  ) external;

  /**
  @dev sets the pause status of the NFT oracle
  @param _nftContract the of NFT collection
  @param val the value to set the pausing status (true for paused, false for unpaused)
   */
  function setPause(address _nftContract, bool val) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface IUNFT is IERC721MetadataUpgradeable, IERC721ReceiverUpgradeable, IERC721EnumerableUpgradeable {
  /**
   * @dev Emitted when an uNFT is initialized
   * @param underlyingAsset The address of the underlying asset
   **/
  event Initialized(address indexed underlyingAsset);

  /**
   * @dev Emitted on mint
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address receive the uNFT token
   **/
  event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on burn
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address of the burned uNFT token
   **/
  event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Initializes the uNFT
   * @param underlyingAsset The address of the underlying asset of this uNFT (E.g. PUNK for bPUNK)
   */
  function initialize(address underlyingAsset, string calldata uNftName, string calldata uNftSymbol) external;

  /**
   * @dev Mints uNFT token to the user address
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `nftTokenId` must not exist.
   *
   * @param to The owner address receive the uNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Burns user uNFT token
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external;

  /**
   * @dev Returns the owner of the `nftTokenId` token.
   *
   * Requirements:
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   */
  function minterOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IUNFTRegistry {
  event Initialized(address genericImpl, string namePrefix, string symbolPrefix);
  event GenericImplementationUpdated(address genericImpl);
  event UNFTCreated(address indexed nftAsset, address uNftImpl, address uNftProxy, uint256 totals);
  event UNFTUpgraded(address indexed nftAsset, address uNftImpl, address uNftProxy, uint256 totals);

  /**
   * @dev gets the uNFT address
   * @param nftAsset The address of the underlying NFT asset
   **/
  function getUNFTAddresses(address nftAsset) external view returns (address uNftProxy, address uNftImpl);

  /**
   * @dev gets the uNFT address by index
   * @param index the uNFT index
   **/
  function getUNFTAddressesByIndex(uint16 index) external view returns (address uNftProxy, address uNftImpl);

  /**
   * @dev gets the list of uNFTs
   **/
  function getUNFTAssetList() external view returns (address[] memory);

  /**
   * @dev gets the length of the list of uNFTs
   **/
  function allUNFTAssetLength() external view returns (uint256);

  /**
   * @dev initializes the contract
   **/
  function initialize(
    address genericImpl,
    string memory namePrefix_,
    string memory symbolPrefix_
  ) external;

  /**
   * @dev sets the uNFT generic implementation
   * @dev genericImpl the implementation contract
   **/
  function setUNFTGenericImpl(address genericImpl) external;

  /**
   * @dev Create uNFT proxy and implement, then initialize it
   * @param nftAsset The address of the underlying asset of the UNFT
   **/
  function createUNFT(address nftAsset) external returns (address uNftProxy);

  /**
   * @dev Create uNFT proxy with already deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the UNFT
   * @param uNftImpl The address of the deployed implement of the UNFT
   **/
  function createUNFTWithImpl(address nftAsset, address uNftImpl) external returns (address uNftProxy);

  /**
   * @dev Update uNFT proxy to an new deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the UNFT
   * @param uNftImpl The address of the deployed implement of the UNFT
   * @param encodedCallData The encoded function call.
   **/
  function upgradeUNFTWithImpl(
    address nftAsset,
    address uNftImpl,
    bytes memory encodedCallData
  ) external;

  /**
   * @dev Adding custom symbol for some special NFTs like CryptoPunks
   * @param nftAssets_ The addresses of the NFTs
   * @param symbols_ The custom symbols of the NFTs
   **/
  function addCustomeSymbols(address[] memory nftAssets_, string[] memory symbols_) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {IIncentivesController} from "./IIncentivesController.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IUToken is IScaledBalanceToken, IERC20Upgradeable, IERC20MetadataUpgradeable {
  /**
   * @dev Emitted when an uToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this uToken
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController
  );

  /**
   * @dev Initializes the bToken
   * @param addressProvider The address of the address provider where this bToken will be used
   * @param treasury The address of the Unlockd treasury, receiving the fees on this bToken
   * @param underlyingAsset The address of the underlying asset of this bToken
   * @param uTokenDecimals The amount of token decimals
   * @param uTokenName The name of the token
   * @param uTokenSymbol The token symbol
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address treasury,
    address underlyingAsset,
    uint8 uTokenDecimals,
    string calldata uTokenName,
    string calldata uTokenSymbol
  ) external;

  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` uTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(address user, uint256 amount, uint256 index) external returns (bool);

  /**
   * @dev Emitted after uTokens are burned
   * @param from The owner of the uTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Emitted when treasury address is updated in utoken
   * @param _newTreasuryAddress The new treasury address
   **/
  event TreasuryAddressUpdated(address indexed _newTreasuryAddress);

  /**
    @dev Emitted after sweeping liquidity from the uToken to deposit it to external lending protocol
  * @param uToken The uToken swept
  * @param underlyingAsset The underlying asset from the uToken
  * @param amount The amount deposited to the lending protocol
  */
  event UTokenSwept(address indexed uToken, address indexed underlyingAsset, uint256 indexed amount);

  /**
   * @dev Takes reserve liquidity from uToken and deposits it to external lening protocol
   **/
  function sweepUToken() external;

  /**
   * @dev Burns uTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the uTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external;

  /**
   * @dev Mints uTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Deposits `amount` to the lending protocol currently active
   * @param amount The amount of tokens to deposit
   */
  function depositReserves(uint256 amount) external;

  /**
   * @dev Withdraws `amount` from the lending protocol currently active
   * @param amount The amount of tokens to withdraw
   */
  function withdrawReserves(uint256 amount) external returns (uint256);

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendPool to transfer
   * assets in borrow() and withdraw()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @return The available liquidity in reserve
   **/
  function getAvailableLiquidity() external view returns (uint256);

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IIncentivesController);

  /**
   * @dev Returns the address of the underlying asset of this uToken
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @dev Returns the address of the treasury set to this uToken
   **/
  function RESERVE_TREASURY_ADDRESS() external view returns (address);

  /**
   * @dev Sets the address of the treasury to this uToken
   **/
  function setTreasuryAddress(address treasury) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title NftConfiguration library
 * @author Unlockd
 * @notice Implements the bitmap logic to handle the NFT configuration
 */
library NftConfiguration {
  uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant REDEEM_DURATION_MASK =       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant AUCTION_DURATION_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant REDEEM_FINE_MASK =           0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant REDEEM_THRESHOLD_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant MIN_BIDFINE_MASK      =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant CONFIG_TIMESTAMP_MASK =      0xFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 constant REDEEM_DURATION_START_BIT_POSITION = 64;
  uint256 constant AUCTION_DURATION_START_BIT_POSITION = 80;
  uint256 constant REDEEM_FINE_START_BIT_POSITION = 96;
  uint256 constant REDEEM_THRESHOLD_START_BIT_POSITION = 112;
  uint256 constant MIN_BIDFINE_START_BIT_POSITION = 128;
  uint256 constant CONFIG_TIMESTAMP_START_BIT_POSITION = 144;

  uint256 constant MAX_VALID_LTV = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 constant MAX_VALID_REDEEM_DURATION = 65535;
  uint256 constant MAX_VALID_AUCTION_DURATION = 65535;
  uint256 constant MAX_VALID_REDEEM_FINE = 65535;
  uint256 constant MAX_VALID_REDEEM_THRESHOLD = 65535;
  uint256 constant MAX_VALID_MIN_BIDFINE = 65535;
  uint256 constant MAX_VALID_CONFIG_TIMESTAMP = 4294967295;

  /**
   * @dev Sets the Loan to Value of the NFT
   * @param self The NFT configuration
   * @param ltv the new ltv
   **/
  function setLtv(DataTypes.NftConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @dev Gets the Loan to Value of the NFT
   * @param self The NFT configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @dev Sets the liquidation threshold of the NFT
   * @param self The NFT configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.NftConfigurationMap memory self, uint256 threshold) internal pure {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

    self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation threshold of the NFT
   * @param self The NFT configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Sets the liquidation bonus of the NFT
   * @param self The NFT configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.NftConfigurationMap memory self, uint256 bonus) internal pure {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

    self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation bonus of the NFT
   * @param self The NFT configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the active state of the NFT
   * @param self The NFT configuration
   * @param active The active state
   **/
  function setActive(DataTypes.NftConfigurationMap memory self, bool active) internal pure {
    self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the active state of the NFT
   * @param self The NFT configuration
   * @return The active state
   **/
  function getActive(DataTypes.NftConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @dev Sets the frozen state of the NFT
   * @param self The NFT configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.NftConfigurationMap memory self, bool frozen) internal pure {
    self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @dev Gets the frozen state of the NFT
   * @param self The NFT configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.NftConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @dev Sets the redeem duration of the NFT
   * @param self The NFT configuration
   * @param redeemDuration The redeem duration
   **/
  function setRedeemDuration(DataTypes.NftConfigurationMap memory self, uint256 redeemDuration) internal pure {
    require(redeemDuration <= MAX_VALID_REDEEM_DURATION, Errors.RC_INVALID_REDEEM_DURATION);

    self.data = (self.data & REDEEM_DURATION_MASK) | (redeemDuration << REDEEM_DURATION_START_BIT_POSITION);
  }

  /**
   * @dev Gets the redeem duration of the NFT
   * @param self The NFT configuration
   * @return The redeem duration
   **/
  function getRedeemDuration(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~REDEEM_DURATION_MASK) >> REDEEM_DURATION_START_BIT_POSITION;
  }

  /**
   * @dev Sets the auction duration of the NFT
   * @param self The NFT configuration
   * @param auctionDuration The auction duration
   **/
  function setAuctionDuration(DataTypes.NftConfigurationMap memory self, uint256 auctionDuration) internal pure {
    require(auctionDuration <= MAX_VALID_AUCTION_DURATION, Errors.RC_INVALID_AUCTION_DURATION);

    self.data = (self.data & AUCTION_DURATION_MASK) | (auctionDuration << AUCTION_DURATION_START_BIT_POSITION);
  }

  /**
   * @dev Gets the auction duration of the NFT
   * @param self The NFT configuration
   * @return The auction duration
   **/
  function getAuctionDuration(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~AUCTION_DURATION_MASK) >> AUCTION_DURATION_START_BIT_POSITION;
  }

  /**
   * @dev Sets the redeem fine of the NFT
   * @param self The NFT configuration
   * @param redeemFine The redeem duration
   **/
  function setRedeemFine(DataTypes.NftConfigurationMap memory self, uint256 redeemFine) internal pure {
    require(redeemFine <= MAX_VALID_REDEEM_FINE, Errors.RC_INVALID_REDEEM_FINE);

    self.data = (self.data & REDEEM_FINE_MASK) | (redeemFine << REDEEM_FINE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the redeem fine of the NFT
   * @param self The NFT configuration
   * @return The redeem fine
   **/
  function getRedeemFine(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~REDEEM_FINE_MASK) >> REDEEM_FINE_START_BIT_POSITION;
  }

  /**
   * @dev Sets the redeem threshold of the NFT
   * @param self The NFT configuration
   * @param redeemThreshold The redeem duration
   **/
  function setRedeemThreshold(DataTypes.NftConfigurationMap memory self, uint256 redeemThreshold) internal pure {
    require(redeemThreshold <= MAX_VALID_REDEEM_THRESHOLD, Errors.RC_INVALID_REDEEM_THRESHOLD);

    self.data = (self.data & REDEEM_THRESHOLD_MASK) | (redeemThreshold << REDEEM_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the redeem threshold of the NFT
   * @param self The NFT configuration
   * @return The redeem threshold
   **/
  function getRedeemThreshold(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~REDEEM_THRESHOLD_MASK) >> REDEEM_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Sets the min & max threshold of the NFT
   * @param self The NFT configuration
   * @param minBidFine The min bid fine
   **/
  function setMinBidFine(DataTypes.NftConfigurationMap memory self, uint256 minBidFine) internal pure {
    require(minBidFine <= MAX_VALID_MIN_BIDFINE, Errors.RC_INVALID_MIN_BID_FINE);

    self.data = (self.data & MIN_BIDFINE_MASK) | (minBidFine << MIN_BIDFINE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the min bid fine of the NFT
   * @param self The NFT configuration
   * @return The min bid fine
   **/
  function getMinBidFine(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return ((self.data & ~MIN_BIDFINE_MASK) >> MIN_BIDFINE_START_BIT_POSITION);
  }

  /**
   * @dev Sets the timestamp when the NFTconfig was triggered
   * @param self The NFT configuration
   * @param configTimestamp The config timestamp
   **/
  function setConfigTimestamp(DataTypes.NftConfigurationMap memory self, uint256 configTimestamp) internal pure {
    require(configTimestamp <= MAX_VALID_CONFIG_TIMESTAMP, Errors.RC_INVALID_MAX_CONFIG_TIMESTAMP);

    self.data = (self.data & CONFIG_TIMESTAMP_MASK) | (configTimestamp << CONFIG_TIMESTAMP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the timestamp when the NFTconfig was triggered
   * @param self The NFT configuration
   * @return The config timestamp
   **/
  function getConfigTimestamp(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return ((self.data & ~CONFIG_TIMESTAMP_MASK) >> CONFIG_TIMESTAMP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the configuration flags of the NFT
   * @param self The NFT configuration
   * @return The state flags representing active, frozen
   **/
  function getFlags(DataTypes.NftConfigurationMap storage self) internal view returns (bool, bool) {
    uint256 dataLocal = self.data;

    return ((dataLocal & ~ACTIVE_MASK) != 0, (dataLocal & ~FROZEN_MASK) != 0);
  }

  /**
   * @dev Gets the configuration flags of the NFT from a memory object
   * @param self The NFT configuration
   * @return The state flags representing active, frozen
   **/
  function getFlagsMemory(DataTypes.NftConfigurationMap memory self) internal pure returns (bool, bool) {
    return ((self.data & ~ACTIVE_MASK) != 0, (self.data & ~FROZEN_MASK) != 0);
  }

  /**
   * @dev Gets the collateral configuration paramters of the NFT
   * @param self The NFT configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus
   **/
  function getCollateralParams(
    DataTypes.NftConfigurationMap storage self
  ) internal view returns (uint256, uint256, uint256) {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the auction configuration paramters of the NFT
   * @param self The NFT configuration
   * @return The state params representing redeem duration, auction duration, redeem fine
   **/
  function getAuctionParams(
    DataTypes.NftConfigurationMap storage self
  ) internal view returns (uint256, uint256, uint256, uint256) {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~REDEEM_DURATION_MASK) >> REDEEM_DURATION_START_BIT_POSITION,
      (dataLocal & ~AUCTION_DURATION_MASK) >> AUCTION_DURATION_START_BIT_POSITION,
      (dataLocal & ~REDEEM_FINE_MASK) >> REDEEM_FINE_START_BIT_POSITION,
      (dataLocal & ~REDEEM_THRESHOLD_MASK) >> REDEEM_THRESHOLD_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the collateral configuration paramters of the NFT from a memory object
   * @param self The NFT configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus
   **/
  function getCollateralParamsMemory(
    DataTypes.NftConfigurationMap memory self
  ) internal pure returns (uint256, uint256, uint256) {
    return (
      self.data & ~LTV_MASK,
      (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the auction configuration paramters of the NFT from a memory object
   * @param self The NFT configuration
   * @return The state params representing redeem duration, auction duration, redeem fine
   **/
  function getAuctionParamsMemory(
    DataTypes.NftConfigurationMap memory self
  ) internal pure returns (uint256, uint256, uint256, uint256) {
    return (
      (self.data & ~REDEEM_DURATION_MASK) >> REDEEM_DURATION_START_BIT_POSITION,
      (self.data & ~AUCTION_DURATION_MASK) >> AUCTION_DURATION_START_BIT_POSITION,
      (self.data & ~REDEEM_FINE_MASK) >> REDEEM_FINE_START_BIT_POSITION,
      (self.data & ~REDEEM_THRESHOLD_MASK) >> REDEEM_THRESHOLD_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the min & max bid fine of the NFT
   * @param self The NFT configuration
   * @return The min & max bid fine
   **/
  function getMinBidFineMemory(DataTypes.NftConfigurationMap memory self) internal pure returns (uint256) {
    return ((self.data & ~MIN_BIDFINE_MASK) >> MIN_BIDFINE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the timestamp the NFT was configured
   * @param self The NFT configuration
   * @return The timestamp value
   **/
  function getConfigTimestampMemory(DataTypes.NftConfigurationMap memory self) internal pure returns (uint256) {
    return ((self.data & ~CONFIG_TIMESTAMP_MASK) >> CONFIG_TIMESTAMP_START_BIT_POSITION);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Unlockd
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;

  uint256 constant MAX_VALID_LTV = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 constant MAX_VALID_DECIMALS = 255;
  uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;

  /**
   * @dev Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv the new ltv
   **/
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @dev Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @dev Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

    self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

    self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   **/
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
    require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   **/
  function getDecimals(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   **/
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   **/
  function getActive(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @dev Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @dev Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @dev Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   **/
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
    self.data = (self.data & BORROWING_MASK) | (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @dev Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @dev Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   **/
  function setStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @dev Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   **/
  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @dev Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   **/
  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor) internal pure {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

    self.data = (self.data & RESERVE_FACTOR_MASK) | (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @dev Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @dev Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
  function getFlags(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (
      bool,
      bool,
      bool,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0,
      (dataLocal & ~BORROWING_MASK) != 0,
      (dataLocal & ~STABLE_BORROWING_MASK) != 0
    );
  }

  /**
   * @dev Gets the configuration paramters of the reserve
   * @param self The reserve configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
  function getParams(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the configuration paramters of the reserve from a memory object
   * @param self The reserve configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
  function getParamsMemory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      self.data & ~LTV_MASK,
      (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the configuration flags of the reserve from a memory object
   * @param self The reserve configuration
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
  function getFlagsMemory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool,
      bool,
      bool
    )
  {
    return (
      (self.data & ~ACTIVE_MASK) != 0,
      (self.data & ~FROZEN_MASK) != 0,
      (self.data & ~BORROWING_MASK) != 0,
      (self.data & ~STABLE_BORROWING_MASK) != 0
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title Errors library
 * @author Unlockd
 * @notice Defines the error messages emitted by the different contracts of the Unlockd protocol
 */
library Errors {
  enum ReturnCode {
    SUCCESS,
    FAILED
  }

  string public constant SUCCESS = "0";

  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = "100"; // 'The caller must be the pool admin'
  string public constant CALLER_NOT_ADDRESS_PROVIDER = "101";
  string public constant INVALID_FROM_BALANCE_AFTER_TRANSFER = "102";
  string public constant INVALID_TO_BALANCE_AFTER_TRANSFER = "103";
  string public constant CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST = "104";
  string public constant CALLER_NOT_POOL_LIQUIDATOR = "105";
  string public constant INVALID_ZERO_ADDRESS = "106";
  string public constant CALLER_NOT_LTV_MANAGER = "107";
  string public constant CALLER_NOT_PRICE_MANAGER = "108";

  //math library errors
  string public constant MATH_MULTIPLICATION_OVERFLOW = "200";
  string public constant MATH_ADDITION_OVERFLOW = "201";
  string public constant MATH_DIVISION_BY_ZERO = "202";

  //validation & check errors
  string public constant VL_INVALID_AMOUNT = "301"; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = "302"; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = "303"; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "304"; // 'User cannot withdraw more than the available balance'
  string public constant VL_BORROWING_NOT_ENABLED = "305"; // 'Borrowing is not enabled'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = "306"; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "307"; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "308"; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "309"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_ACTIVE_NFT = "310";
  string public constant VL_NFT_FROZEN = "311";
  string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "312"; // 'User did not borrow the specified currency'
  string public constant VL_INVALID_HEALTH_FACTOR = "313";
  string public constant VL_INVALID_ONBEHALFOF_ADDRESS = "314";
  string public constant VL_INVALID_TARGET_ADDRESS = "315";
  string public constant VL_INVALID_RESERVE_ADDRESS = "316";
  string public constant VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER = "317";
  string public constant VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER = "318";
  string public constant VL_HEALTH_FACTOR_HIGHER_THAN_LIQUIDATION_THRESHOLD = "319";
  string public constant VL_TIMEFRAME_EXCEEDED = "320";
  string public constant VL_VALUE_EXCEED_TREASURY_BALANCE = "321";

  //lend pool errors
  string public constant LP_CALLER_NOT_LEND_POOL_CONFIGURATOR = "400"; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_IS_PAUSED = "401"; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = "402";
  string public constant LP_NOT_CONTRACT = "403";
  string public constant LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD = "404";
  string public constant LP_BORROW_IS_EXCEED_LIQUIDATION_PRICE = "405";
  string public constant LP_NO_MORE_NFTS_ALLOWED = "406";
  string public constant LP_INVALID_USER_NFT_AMOUNT = "407";
  string public constant LP_INCONSISTENT_PARAMS = "408";
  string public constant LP_NFT_IS_NOT_USED_AS_COLLATERAL = "409";
  string public constant LP_CALLER_MUST_BE_AN_UTOKEN = "410";
  string public constant LP_INVALID_NFT_AMOUNT = "411";
  string public constant LP_NFT_HAS_USED_AS_COLLATERAL = "412";
  string public constant LP_DELEGATE_CALL_FAILED = "413";
  string public constant LP_AMOUNT_LESS_THAN_EXTRA_DEBT = "414";
  string public constant LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD = "415";
  string public constant LP_AMOUNT_GREATER_THAN_MAX_REPAY = "416";
  string public constant LP_NFT_TOKEN_ID_EXCEED_MAX_LIMIT = "417";
  string public constant LP_NFT_SUPPLY_NUM_EXCEED_MAX_LIMIT = "418";
  string public constant LP_CALLER_NOT_LEND_POOL_LIQUIDATOR_NOR_GATEWAY = "419";
  string public constant LP_CONSECUTIVE_BIDS_NOT_ALLOWED = "420";
  string public constant LP_INVALID_OVERFLOW_VALUE = "421";
  string public constant LP_CALLER_NOT_NFT_HOLDER = "422";
  string public constant LP_NFT_NOT_ALLOWED_TO_SELL = "423";
  string public constant LP_RESERVES_WITHOUT_ENOUGH_LIQUIDITY = "424";
  string public constant LP_COLLECTION_NOT_SUPPORTED = "425";
  string public constant LP_MSG_VALUE_DIFFERENT_FROM_CONFIG_FEE = "426";
  string public constant LP_INVALID_SAFE_HEALTH_FACTOR = "427";

  //lend pool loan errors
  string public constant LPL_INVALID_LOAN_STATE = "480";
  string public constant LPL_INVALID_LOAN_AMOUNT = "481";
  string public constant LPL_INVALID_TAKEN_AMOUNT = "482";
  string public constant LPL_AMOUNT_OVERFLOW = "483";
  string public constant LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE = "484";
  string public constant LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE = "485";
  string public constant LPL_BID_REDEEM_DURATION_HAS_END = "486";
  string public constant LPL_BID_USER_NOT_SAME = "487";
  string public constant LPL_BID_REPAY_AMOUNT_NOT_ENOUGH = "488";
  string public constant LPL_BID_AUCTION_DURATION_HAS_END = "489";
  string public constant LPL_BID_AUCTION_DURATION_NOT_END = "490";
  string public constant LPL_BID_PRICE_LESS_THAN_BORROW = "491";
  string public constant LPL_INVALID_BIDDER_ADDRESS = "492";
  string public constant LPL_AMOUNT_LESS_THAN_BID_FINE = "493";
  string public constant LPL_INVALID_BID_FINE = "494";
  string public constant LPL_BID_PRICE_LESS_THAN_MIN_BID_REQUIRED = "495";

  //common token errors
  string public constant CT_CALLER_MUST_BE_LEND_POOL = "500"; // 'The caller of this function must be a lending pool'
  string public constant CT_INVALID_MINT_AMOUNT = "501"; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = "502"; //invalid amount to burn
  string public constant CT_BORROW_ALLOWANCE_NOT_ENOUGH = "503";

  //reserve logic errors
  string public constant RL_RESERVE_ALREADY_INITIALIZED = "601"; // 'Reserve has already been initialized'
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "602"; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "603"; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = "604"; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "605"; //  Variable borrow rate overflows uint128

  //configure errors
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "700"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_CONFIGURATION = "701"; // 'Invalid risk parameters for the reserve'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "702"; // 'The caller must be the emergency admin'
  string public constant LPC_INVALID_UNFT_ADDRESS = "703";
  string public constant LPC_INVALIED_LOAN_ADDRESS = "704";
  string public constant LPC_NFT_LIQUIDITY_NOT_0 = "705";
  string public constant LPC_PARAMS_MISMATCH = "706"; // NFT assets & token ids mismatch
  string public constant LPC_FEE_PERCENTAGE_TOO_HIGH = "707";
  string public constant LPC_INVALID_LTVMANAGER_ADDRESS = "708";
  string public constant LPC_INCONSISTENT_PARAMS = "709";
  string public constant LPC_INVALID_SAFE_HEALTH_FACTOR = "710";
  //reserve config errors
  string public constant RC_INVALID_LTV = "730";
  string public constant RC_INVALID_LIQ_THRESHOLD = "731";
  string public constant RC_INVALID_LIQ_BONUS = "732";
  string public constant RC_INVALID_DECIMALS = "733";
  string public constant RC_INVALID_RESERVE_FACTOR = "734";
  string public constant RC_INVALID_REDEEM_DURATION = "735";
  string public constant RC_INVALID_AUCTION_DURATION = "736";
  string public constant RC_INVALID_REDEEM_FINE = "737";
  string public constant RC_INVALID_REDEEM_THRESHOLD = "738";
  string public constant RC_INVALID_MIN_BID_FINE = "739";
  string public constant RC_INVALID_MAX_BID_FINE = "740";
  string public constant RC_INVALID_MAX_CONFIG_TIMESTAMP = "741";

  //address provider erros
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = "760"; // 'Provider is not registered'
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "761";

  //NFTXHelper
  string public constant NFTX_INVALID_VAULTS_LENGTH = "800";

  //NFTOracleErrors
  string public constant NFTO_INVALID_PRICEM_ADDRESS = "900";
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IUToken} from "../../interfaces/IUToken.sol";
import {IDebtToken} from "../../interfaces/IDebtToken.sol";
import {ILendPool} from "../../interfaces/ILendPool.sol";
import {ILendPoolAddressesProvider} from "../../interfaces/ILendPoolAddressesProvider.sol";

import {IUNFT} from "../../interfaces/IUNFT.sol";
import {IUNFTRegistry} from "../../interfaces/IUNFTRegistry.sol";

import {UnlockdUpgradeableProxy} from "../../libraries/proxy/UnlockdUpgradeableProxy.sol";
import {ReserveConfiguration} from "../../libraries/configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../../libraries/configuration/NftConfiguration.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {ConfigTypes} from "../../libraries/types/ConfigTypes.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

/**
 * @title ConfiguratorLogic library
 * @author Unlockd
 * @notice Implements the logic to configuration feature
 */
library ConfiguratorLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param uToken The address of the associated uToken contract
   * @param debtToken The address of the associated debtToken contract
   * @param interestRateAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed uToken,
    address debtToken,
    address interestRateAddress
  );

  /**
   * @dev Emitted when a nft is initialized.
   * @param asset The address of the underlying asset of the nft
   * @param uNft The address of the associated uNFT contract
   **/
  event NftInitialized(address indexed asset, address indexed uNft);

  /**
   * @dev Emitted when an uToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The uToken proxy address
   * @param implementation The new uToken implementation
   **/
  event UTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  /**
   * @dev Emitted when the implementation of a debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The debt token proxy address
   * @param implementation The new debtToken implementation
   **/
  event DebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  /**
   * @notice Initializes a reserve
   * @dev Emits the `ReserveInitialized()` event.
   * @param addressProvider The addresses provider
   * @param cachePool The lend pool
   * @param input The data to initialize the reserve
   */
  function executeInitReserve(
    ILendPoolAddressesProvider addressProvider,
    ILendPool cachePool,
    ConfigTypes.InitReserveInput calldata input
  ) external {
    address uTokenProxyAddress = _initTokenWithProxy(
      input.uTokenImpl,
      abi.encodeWithSelector(
        IUToken.initialize.selector,
        addressProvider,
        input.treasury,
        input.underlyingAsset,
        input.underlyingAssetDecimals,
        input.uTokenName,
        input.uTokenSymbol
      )
    );

    address debtTokenProxyAddress = _initTokenWithProxy(
      input.debtTokenImpl,
      abi.encodeWithSelector(
        IDebtToken.initialize.selector,
        addressProvider,
        input.underlyingAsset,
        input.underlyingAssetDecimals,
        input.debtTokenName,
        input.debtTokenSymbol
      )
    );

    cachePool.initReserve(input.underlyingAsset, uTokenProxyAddress, debtTokenProxyAddress, input.interestRateAddress);

    DataTypes.ReserveConfigurationMap memory currentConfig = cachePool.getReserveConfiguration(input.underlyingAsset);

    currentConfig.setDecimals(input.underlyingAssetDecimals);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    cachePool.setReserveConfiguration(input.underlyingAsset, currentConfig.data);

    emit ReserveInitialized(
      input.underlyingAsset,
      uTokenProxyAddress,
      debtTokenProxyAddress,
      input.interestRateAddress
    );
  }

  /**
   * @notice Initializes an NFT
   * @dev Emits the `NftInitialized()` event.
   * @param pool_ The lend pool
   * @param registry_ The UNFT Registry
   * @param input The data to initialize the NFT
   */
  function executeInitNft(ILendPool pool_, IUNFTRegistry registry_, ConfigTypes.InitNftInput calldata input) external {
    // UNFT proxy and implementation are created in UNFTRegistry
    (address uNftProxy, ) = registry_.getUNFTAddresses(input.underlyingAsset);
    require(uNftProxy != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);

    pool_.initNft(input.underlyingAsset, uNftProxy);

    DataTypes.NftConfigurationMap memory currentConfig = pool_.getNftConfiguration(input.underlyingAsset);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    pool_.setNftConfiguration(input.underlyingAsset, currentConfig.data);

    emit NftInitialized(input.underlyingAsset, uNftProxy);
  }

  /**
   * @notice Updates the uToken
   * @dev Emits the `UTokenUpgraded()` event.
   * @param cachedPool The lend pool
   * @param input The data to initialize the uToken
   */
  function executeUpdateUToken(ILendPool cachedPool, ConfigTypes.UpdateUTokenInput calldata input) external {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    _upgradeTokenImplementation(reserveData.uTokenAddress, input.implementation, input.encodedCallData);

    emit UTokenUpgraded(input.asset, reserveData.uTokenAddress, input.implementation);
  }

  /**
   * @notice Updates the debt token
   * @dev Emits the `DebtTokenUpgraded()` event.
   * @param cachedPool The lend pool
   * @param input The data to initialize the debt token
   */
  function executeUpdateDebtToken(ILendPool cachedPool, ConfigTypes.UpdateDebtTokenInput calldata input) external {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    _upgradeTokenImplementation(reserveData.debtTokenAddress, input.implementation, input.encodedCallData);

    emit DebtTokenUpgraded(input.asset, reserveData.debtTokenAddress, input.implementation);
  }

  /**
   * @notice Gets the token implementation contract
   * @param proxyAddress The proxy contract to fetch the implementation from
   */
  function getTokenImplementation(address proxyAddress) external view returns (address) {
    UnlockdUpgradeableProxy proxy = UnlockdUpgradeableProxy(payable(proxyAddress));
    return proxy.getImplementation();
  }

  /**
   * @notice Initializes the proxy contract
   * @param implementation The proxy contract
   * @param initParams The initial params to set in the initialization
   */
  function _initTokenWithProxy(address implementation, bytes memory initParams) internal returns (address) {
    UnlockdUpgradeableProxy proxy = new UnlockdUpgradeableProxy(implementation, address(this), initParams);

    return address(proxy);
  }

  /**
   * @notice Upgrades the implementation contract for the proxy
   * @param proxyAddress The proxy contract
   * @param implementation The new implementation contract
   * @param encodedCallData calldata to be executed
   */
  function _upgradeTokenImplementation(
    address proxyAddress,
    address implementation,
    bytes memory encodedCallData
  ) internal {
    UnlockdUpgradeableProxy proxy = UnlockdUpgradeableProxy(payable(proxyAddress));

    if (encodedCallData.length > 0) {
      proxy.upgradeToAndCall(implementation, encodedCallData);
    } else {
      proxy.upgradeTo(implementation);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Unlockd
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
  uint256 constant ONE_PERCENT = 1e2; //100, 1%
  uint256 constant TEN_PERCENT = 1e3; //1000, 10%
  uint256 constant ONE_THOUSANDTH_PERCENT = 1e1; //10, 0.1%
  uint256 constant ONE_TEN_THOUSANDTH_PERCENT = 1; //1, 0.01%

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(value <= (type(uint256).max - HALF_PERCENT) / percentage, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfPercentage = percentage / 2;

    require(value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../helpers/Errors.sol";

contract UnlockdUpgradeableProxy is TransparentUpgradeableProxy {
  constructor(
    address _logic,
    address admin_,
    bytes memory _data
  ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

  modifier OnlyAdmin() {
    require(msg.sender == _getAdmin(), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  /**
  @dev Returns the implementation contract for the proxy
   */
  function getImplementation() external view OnlyAdmin returns (address) {
    return _getImplementation();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

library ConfigTypes {
  struct InitReserveInput {
    address uTokenImpl;
    address debtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateAddress;
    address underlyingAsset;
    address treasury;
    string underlyingAssetName;
    string uTokenName;
    string uTokenSymbol;
    string debtTokenName;
    string debtTokenSymbol;
  }

  struct InitNftInput {
    address underlyingAsset;
  }

  struct UpdateUTokenInput {
    address asset;
    address implementation;
    bytes encodedCallData;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address implementation;
    bytes encodedCallData;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address uTokenAddress;
    address debtTokenAddress;
    //address of the interest rate strategy
    address interestRateAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct NftData {
    //stores the nft configuration
    NftConfigurationMap configuration;
    //address of the uNFT contract
    address uNftAddress;
    //the id of the nft. Represents the position in the list of the active nfts
    uint8 id;
    uint256 maxSupply;
    uint256 maxTokenId;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct NftConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 56: NFT is active
    //bit 57: NFT is frozen
    //bit 64-71: Redeem duration
    //bit 72-79: Auction duration
    //bit 80-95: Redeem fine
    //bit 96-111: Redeem threshold
    //bit 112-127: Min bid fine
    //bit 128-159: Timestamp Config
    uint256 data;
  }

  /**
   * @dev Enum describing the current state of a loan
   * State change flow:
   *  Created -> Active -> Repaid
   *                    -> Auction -> Defaulted
   */
  enum LoanState {
    // We need a default that is not 'Created' - this is the zero value
    None,
    // The loan data is stored, but not initiated yet.
    Created,
    // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
    Active,
    // The loan is in auction, higest price liquidator will got chance to claim it.
    Auction,
    // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
    Repaid,
    // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
    Defaulted
  }

  struct LoanData {
    //the id of the nft loan
    uint256 loanId;
    //the current state of the loan
    LoanState state;
    //address of borrower
    address borrower;
    //address of nft asset token
    address nftAsset;
    //the id of nft token
    uint256 nftTokenId;
    //address of reserve asset token
    address reserveAsset;
    //scaled borrow amount. Expressed in ray
    uint256 scaledAmount;
    //start time of first bid time
    uint256 bidStartTimestamp;
    //bidder address of higest bid
    address bidderAddress;
    //price of higest bid
    uint256 bidPrice;
    //borrow amount of loan
    uint256 bidBorrowAmount;
    //bidder address of first bid
    address firstBidderAddress;
  }

  struct ExecuteDepositParams {
    address initiator;
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteWithdrawParams {
    address initiator;
    address asset;
    uint256 amount;
    address to;
  }

  struct ExecuteBorrowParams {
    address initiator;
    address asset;
    uint256 amount;
    address nftAsset;
    uint256 nftTokenId;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteRepayParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteAuctionParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 bidPrice;
    address onBehalfOf;
    uint256 auctionDurationConfigFee;
  }

  struct ExecuteRedeemParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
    uint256 bidFine;
    uint256 safeHealthFactor;
  }

  struct ExecuteLiquidateParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteLiquidateMarketsParams {
    address nftAsset;
    uint256 nftTokenId;
    uint256 liquidateFeePercentage;
    uint256 amountOutMin;
  }

  struct SudoSwapParams {
    address LSSVMPair;
    uint256 amountOutMinSudoswap;
  }
  struct ExecuteLendPoolStates {
    uint256 pauseStartTime;
    uint256 pauseDurationTime;
  }

  struct ExecuteYearnParams {
    address underlyingAsset;
    uint256 amount;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {IUNFTRegistry} from "../interfaces/IUNFTRegistry.sol";
import {ILendPoolConfigurator} from "../interfaces/ILendPoolConfigurator.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {INFTOracle} from "../interfaces/INFTOracle.sol";
import {IUToken} from "../interfaces/IUToken.sol";

import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../libraries/configuration/NftConfiguration.sol";
import {ConfiguratorLogic} from "../libraries/logic/ConfiguratorLogic.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {ConfigTypes} from "../libraries/types/ConfigTypes.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title LendPoolConfigurator contract
 * @author Unlockd
 * @dev Implements the configuration methods for the Unlockd protocol
 **/

contract LendPoolConfigurator is Initializable, ILendPoolConfigurator {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;
  ILendPoolAddressesProvider internal _addressesProvider;

  mapping(address => bool) public isLtvManager;

  modifier onlyLtvManager() {
    require(isLtvManager[msg.sender], Errors.CALLER_NOT_LTV_MANAGER);
    _;
  }

  modifier onlyPoolAdmin() {
    require(_addressesProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  modifier onlyEmergencyAdmin() {
    require(_addressesProvider.getEmergencyAdmin() == msg.sender, Errors.LPC_CALLER_NOT_EMERGENCY_ADMIN);
    _;
  }

  /**
   * @dev Function is invoked by the proxy contract when the LendPoolConfigurator contract is added to the
   * LendPoolAddressesProvider of the market.
   * @param provider The address of the LendPoolAddressesProvider
   **/
  function initialize(ILendPoolAddressesProvider provider) public initializer {
    _addressesProvider = provider;
  }

  /**
   * @dev Initializes reserves in batch
   * @param input the input array with data to initialize each reserve
   **/
  function batchInitReserve(ConfigTypes.InitReserveInput[] calldata input) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    uint256 inputLength = input.length;
    for (uint256 i = 0; i < inputLength; ) {
      ConfiguratorLogic.executeInitReserve(_addressesProvider, cachedPool, input[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Initializes NFTs in batch
   * @param input the input array with data to initialize each NFT
   **/
  function batchInitNft(ConfigTypes.InitNftInput[] calldata input) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    IUNFTRegistry cachedRegistry = _getUNFTRegistry();
    uint256 inputLength = input.length;
    for (uint256 i = 0; i < inputLength; ) {
      ConfiguratorLogic.executeInitNft(cachedPool, cachedRegistry, input[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Updates the uToken implementation for the reserve
   * @param inputs the inputs array with data to update each UToken
   **/
  function updateUToken(ConfigTypes.UpdateUTokenInput[] calldata inputs) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    uint256 inputLength = inputs.length;
    for (uint256 i = 0; i < inputLength; ) {
      ConfiguratorLogic.executeUpdateUToken(cachedPool, inputs[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Updates the debt token implementation for the asset
   * @param inputs the inputs array with data to update each debt token
   **/
  function updateDebtToken(ConfigTypes.UpdateDebtTokenInput[] calldata inputs) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    uint256 inputLength = inputs.length;
    for (uint256 i = 0; i < inputLength; ) {
      ConfiguratorLogic.executeUpdateDebtToken(cachedPool, inputs[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Enables or disables borrowing on each reserve
   * @param asset the assets to update the flag to
   * @param flag the flag to set to the each reserve
   **/
  function setBorrowingFlagOnReserve(address asset, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    if (flag) {
      currentConfig.setBorrowingEnabled(true);
    } else {
      currentConfig.setBorrowingEnabled(false);
    }

    cachedPool.setReserveConfiguration(asset, currentConfig.data);

    if (flag) {
      emit BorrowingEnabledOnReserve(asset);
    } else {
      emit BorrowingDisabledOnReserve(asset);
    }
  }

  /**
   * @dev Activates or deactivates each reserve
   * @param asset the assets to update the flag to
   * @param flag the flag to set to the each reserve
   **/
  function setActiveFlagOnReserve(address asset, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    if (!flag) {
      _checkReserveNoLiquidity(asset);
    }
    currentConfig.setActive(flag);
    cachedPool.setReserveConfiguration(asset, currentConfig.data);
    if (flag) {
      emit ReserveActivated(asset);
    } else {
      emit ReserveDeactivated(asset);
    }
  }

  /**
   * @dev Freezes or unfreezes each reserve
   * @param asset the assets to update the flag to
   * @param flag the flag to set to the each reserve
   **/
  function setFreezeFlagOnReserve(address asset, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    currentConfig.setFrozen(flag);
    cachedPool.setReserveConfiguration(asset, currentConfig.data);

    if (flag) {
      emit ReserveFrozen(asset);
    } else {
      emit ReserveUnfrozen(asset);
    }
  }

  /**
   * @dev Updates the reserve factor of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 reserveFactor) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    currentConfig.setReserveFactor(reserveFactor);

    cachedPool.setReserveConfiguration(asset, currentConfig.data);

    emit ReserveFactorChanged(asset, reserveFactor);
  }

  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param assets The addresses of the underlying asset of the reserve
   * @param rateAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateAddress(address[] calldata assets, address rateAddress) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    uint256 assetsLength = assets.length;
    for (uint256 i = 0; i < assetsLength; ) {
      cachedPool.setReserveInterestRateAddress(assets[i], rateAddress);
      emit ReserveInterestRateChanged(assets[i], rateAddress);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Configures reserves in batch
   * @param inputs the input array with data to configure each reserve
   **/
  function batchConfigReserve(ConfigReserveInput[] calldata inputs) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    uint256 inputLength = inputs.length;
    for (uint256 i = 0; i < inputLength; ) {
      DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(inputs[i].asset);

      currentConfig.setReserveFactor(inputs[i].reserveFactor);

      cachedPool.setReserveConfiguration(inputs[i].asset, currentConfig.data);

      emit ReserveFactorChanged(inputs[i].asset, inputs[i].reserveFactor);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Activates or deactivates each NFT
   * @param asset the NFTs to update the flag to
   * @param flag the flag to set to the each NFT
   **/
  function setActiveFlagOnNft(address asset, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(asset);

    if (!flag) {
      _checkNftNoLiquidity(asset);
    }
    currentConfig.setActive(flag);
    cachedPool.setNftConfiguration(asset, currentConfig.data);

    if (flag) {
      emit NftActivated(asset);
    } else {
      emit NftDeactivated(asset);
    }
  }

  /**
   * @dev Activates or deactivates each NFT asset
   * @param assets the NFTs to update the flag to
   * @param tokenIds the NFT token ids to update the flag to
   * @param flag the flag to set to the each NFT
   **/
  function setActiveFlagOnNftByTokenId(
    address[] calldata assets,
    uint256[] calldata tokenIds,
    bool flag
  ) external onlyPoolAdmin {
    uint256 assetsLength = assets.length;
    require(assetsLength == tokenIds.length, Errors.LPC_PARAMS_MISMATCH);

    ILendPool cachedPool = _getLendPool();

    for (uint256 i = 0; i < assetsLength; ) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfigByTokenId(assets[i], tokenIds[i]);

      currentConfig.setActive(flag);
      cachedPool.setNftConfigByTokenId(assets[i], tokenIds[i], currentConfig.data);

      if (flag) {
        emit NftTokenActivated(assets[i], tokenIds[i]);
      } else {
        emit NftTokenDeactivated(assets[i], tokenIds[i]);
      }

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Freezes or unfreezes each NFT
   * @param asset the assets to update the flag to
   * @param flag the flag to set to the each NFT
   **/
  function setFreezeFlagOnNft(address asset, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(asset);
    currentConfig.setFrozen(flag);
    cachedPool.setNftConfiguration(asset, currentConfig.data);
    if (flag) {
      emit NftFrozen(asset);
    } else {
      emit NftUnfrozen(asset);
    }
  }

  /**
   * @dev Freezes or unfreezes each NFT token
   * @param assets the assets to update the flag to
   * @param tokenIds the NFT token ids to update the flag to
   * @param flag the flag to set to the each NFT
   **/
  function setFreezeFlagOnNftByTokenId(
    address[] calldata assets,
    uint256[] calldata tokenIds,
    bool flag
  ) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    uint256 assetsLength = assets.length;
    for (uint256 i = 0; i < assetsLength; ) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfigByTokenId(assets[i], tokenIds[i]);

      currentConfig.setFrozen(flag);
      cachedPool.setNftConfigByTokenId(assets[i], tokenIds[i], currentConfig.data);

      if (flag) {
        emit NftTokenFrozen(assets[i], tokenIds[i]);
      } else {
        emit NftTokenUnfrozen(assets[i], tokenIds[i]);
      }

      unchecked {
        ++i;
      }
    }
  }

  function configureNftsAsCollateral(ConfigNftAsCollateralInput[] calldata collateralData) external onlyLtvManager {
    uint256 cachedLength = collateralData.length;
    for (uint8 i; i < cachedLength; ) {
      _configureNftAsCollateral(collateralData[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Configures the NFT collateralization parameters
   * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means 100.00%
   * @param collateralData The NFT collateral configuration data
   **/
  function _configureNftAsCollateral(ConfigNftAsCollateralInput calldata collateralData) internal {
    {
      ILendPool cachedPool = _getLendPool();

      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfigByTokenId(
        collateralData.asset,
        collateralData.nftTokenId
      );

      //validation of the parameters: the LTV can
      //only be lower or equal than the liquidation threshold
      //(otherwise a loan against the asset would cause instantaneous liquidation)
      require(collateralData.ltv <= collateralData.liquidationThreshold, Errors.LPC_INVALID_CONFIGURATION);

      if (collateralData.liquidationThreshold != 0) {
        //liquidation bonus must be smaller than 100.00%
        require(collateralData.liquidationBonus < PercentageMath.PERCENTAGE_FACTOR, Errors.LPC_INVALID_CONFIGURATION);
      } else {
        require(collateralData.liquidationBonus == 0, Errors.LPC_INVALID_CONFIGURATION);
      }

      currentConfig.setLtv(collateralData.ltv);
      currentConfig.setLiquidationThreshold(collateralData.liquidationThreshold);
      currentConfig.setRedeemThreshold(collateralData.redeemThreshold);
      currentConfig.setLiquidationBonus(collateralData.liquidationBonus);
      currentConfig.setActive(true);
      currentConfig.setFrozen(false);

      //validation of the parameters: the redeem duration can
      //only be lower or equal than the auction duration
      require(collateralData.redeemDuration <= collateralData.auctionDuration, Errors.LPC_INVALID_CONFIGURATION);

      currentConfig.setRedeemDuration(collateralData.redeemDuration);
      currentConfig.setAuctionDuration(collateralData.auctionDuration);
      currentConfig.setRedeemFine(collateralData.redeemFine);
      currentConfig.setMinBidFine(collateralData.minBidFine);
      currentConfig.setConfigTimestamp(block.timestamp);

      cachedPool.setNftConfigByTokenId(collateralData.asset, collateralData.nftTokenId, currentConfig.data);

      INFTOracle(_addressesProvider.getNFTOracle()).setNFTPrice(
        collateralData.asset,
        collateralData.nftTokenId,
        collateralData.newPrice
      );
    }
    emit NftConfigurationChanged(
      collateralData.asset,
      collateralData.nftTokenId,
      collateralData.ltv,
      collateralData.liquidationThreshold,
      collateralData.liquidationBonus
    );
  }

  /**
   * @dev Configures the NFT auction parameters
   * @param asset The address of the underlying NFT asset
   * @param redeemDuration The max duration for the redeem
   * @param auctionDuration The auction duration
   * @param redeemFine The fine for the redeem
   **/
  function configureNftAsAuction(
    address asset,
    uint256 nftTokenId,
    uint256 redeemDuration,
    uint256 auctionDuration,
    uint256 redeemFine
  ) external onlyLtvManager {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfigByTokenId(asset, nftTokenId);

    //validation of the parameters: the redeem duration can
    //only be lower or equal than the auction duration
    require(redeemDuration <= auctionDuration, Errors.LPC_INVALID_CONFIGURATION);

    currentConfig.setRedeemDuration(redeemDuration);
    currentConfig.setAuctionDuration(auctionDuration);
    currentConfig.setRedeemFine(redeemFine);

    cachedPool.setNftConfigByTokenId(asset, nftTokenId, currentConfig.data);

    emit NftAuctionChanged(asset, nftTokenId, redeemDuration, auctionDuration, redeemFine);
  }

  /**
   * @dev Configures the redeem threshold
   * @param asset The address of the underlying NFT asset
   * @param nftTokenId the tokenId of the asset
   * @param redeemThreshold The threshold for the redeem
   **/
  function setNftRedeemThreshold(address asset, uint256 nftTokenId, uint256 redeemThreshold) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfigByTokenId(asset, nftTokenId);

    currentConfig.setRedeemThreshold(redeemThreshold);

    cachedPool.setNftConfigByTokenId(asset, nftTokenId, currentConfig.data);

    emit NftRedeemThresholdChanged(asset, nftTokenId, redeemThreshold);
  }

  /**
   * @dev Configures the minimum fine for the underlying asset
   * @param asset The address of the underlying NFT asset
   * @param nftTokenId the tokenId of the asset
   * @param minBidFine The minimum bid fine value
   **/
  function setNftMinBidFine(address asset, uint256 nftTokenId, uint256 minBidFine) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfigByTokenId(asset, nftTokenId);

    currentConfig.setMinBidFine(minBidFine);

    cachedPool.setNftConfigByTokenId(asset, nftTokenId, currentConfig.data);

    emit NftMinBidFineChanged(asset, nftTokenId, minBidFine);
  }

  /**
   * @dev Configures the maximum supply and token Id for the underlying NFT assets
   * @param assets The address of the underlying NFT assets
   * @param maxSupply The max supply value
   * @param maxTokenId The max token Id value
   **/
  function setNftMaxSupplyAndTokenId(
    address[] calldata assets,
    uint256 maxSupply,
    uint256 maxTokenId
  ) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    uint256 assetsLength = assets.length;
    for (uint256 i = 0; i < assetsLength; ) {
      cachedPool.setNftMaxSupplyAndTokenId(assets[i], maxSupply, maxTokenId);

      emit NftMaxSupplyAndTokenIdChanged(assets[i], maxSupply, maxTokenId);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Configures NFTs in batch
   * @param inputs the input array with data to configure each NFT asset
   **/

  function batchConfigNft(ConfigNftInput[] calldata inputs) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    uint256 inputsLength = inputs.length;
    for (uint256 i = 0; i < inputsLength; ) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfigByTokenId(
        inputs[i].asset,
        inputs[i].tokenId
      );

      //validation of the parameters: the LTV can
      //only be lower or equal than the liquidation threshold
      //(otherwise a loan against the asset would cause instantaneous liquidation)
      require(inputs[i].baseLTV <= inputs[i].liquidationThreshold, Errors.LPC_INVALID_CONFIGURATION);

      if (inputs[i].liquidationThreshold != 0) {
        //liquidation bonus must be smaller than 100.00%
        require(inputs[i].liquidationBonus < PercentageMath.PERCENTAGE_FACTOR, Errors.LPC_INVALID_CONFIGURATION);
      } else {
        require(inputs[i].liquidationBonus == 0, Errors.LPC_INVALID_CONFIGURATION);
      }

      // Active & Frozen Flag
      currentConfig.setActive(true);
      currentConfig.setFrozen(false);

      // collateral parameters
      currentConfig.setLtv(inputs[i].baseLTV);
      currentConfig.setLiquidationThreshold(inputs[i].liquidationThreshold);
      currentConfig.setLiquidationBonus(inputs[i].liquidationBonus);

      // auction parameters
      currentConfig.setRedeemDuration(inputs[i].redeemDuration);
      currentConfig.setAuctionDuration(inputs[i].auctionDuration);
      currentConfig.setRedeemFine(inputs[i].redeemFine);
      currentConfig.setRedeemThreshold(inputs[i].redeemThreshold);
      currentConfig.setMinBidFine(inputs[i].minBidFine);

      cachedPool.setNftConfigByTokenId(inputs[i].asset, inputs[i].tokenId, currentConfig.data);

      emit NftConfigurationChanged(
        inputs[i].asset,
        inputs[i].tokenId,
        inputs[i].baseLTV,
        inputs[i].liquidationThreshold,
        inputs[i].liquidationBonus
      );
      emit NftAuctionChanged(
        inputs[i].asset,
        inputs[i].tokenId,
        inputs[i].redeemDuration,
        inputs[i].auctionDuration,
        inputs[i].redeemFine
      );
      emit NftRedeemThresholdChanged(inputs[i].asset, inputs[i].tokenId, inputs[i].redeemThreshold);
      emit NftMinBidFineChanged(inputs[i].asset, inputs[i].tokenId, inputs[i].minBidFine);

      // max limit
      cachedPool.setNftMaxSupplyAndTokenId(inputs[i].asset, inputs[i].maxSupply, inputs[i].maxTokenId);
      emit NftMaxSupplyAndTokenIdChanged(inputs[i].asset, inputs[i].maxSupply, inputs[i].maxTokenId);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev sets the max amount of reserves
   * @param newVal the new value to set as the max reserves
   **/
  function setMaxNumberOfReserves(uint256 newVal) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    //default value is 32
    uint256 curVal = cachedPool.getMaxNumberOfReserves();
    require(newVal > curVal, Errors.LPC_INVALID_CONFIGURATION);
    cachedPool.setMaxNumberOfReserves(newVal);
  }

  /**
   * @dev sets the max amount of NFTs
   * @param newVal the new value to set as the max NFTs
   **/
  function setMaxNumberOfNfts(uint256 newVal) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    //default value is 256
    uint256 curVal = cachedPool.getMaxNumberOfNfts();
    require(newVal > curVal, Errors.LPC_INVALID_CONFIGURATION);
    cachedPool.setMaxNumberOfNfts(newVal);
  }

  /**
   * @dev sets the liquidation fee percentage
   * @param newVal the new value to set as the max fee percentage
   **/
  function setLiquidationFeePercentage(uint256 newVal) external onlyPoolAdmin {
    require(newVal < 1000, Errors.LPC_FEE_PERCENTAGE_TOO_HIGH); //prevent setting incorrect values and ensure fee is not too high (10% max)
    ILendPool cachedPool = _getLendPool();
    cachedPool.setLiquidateFeePercentage(newVal);
  }

  /**
   * @dev sets the max timeframe between an NFT config trigger and a borrow
   * @param newTimeframe the new value to set as the timeframe
   **/
  function setTimeframe(uint256 newTimeframe) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    cachedPool.setTimeframe(newTimeframe);
  }

  /**
   * @dev Allows and address to be sold on NFTX
   * @param nftAsset the address of the NFT
   * @param marketId the id of the market
   * @param val `true` if it is supported, `false`otherwise
   **/
  function setIsMarketSupported(address nftAsset, uint8 marketId, bool val) external onlyLtvManager {
    require(nftAsset != address(0), Errors.INVALID_ZERO_ADDRESS);
    ILendPool cachedPool = _getLendPool();
    cachedPool.setIsMarketSupported(nftAsset, marketId, val);
  }

  /**
   * @dev Sets configFee amount to be charged for ConfigureNFTAsColleteral
   * @param configFee the fee amount
   **/
  function setConfigFee(uint256 configFee) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    cachedPool.setConfigFee(configFee);
  }

  /**
   * @dev Sets auctionDurationConfigFee amount to be charged for first bids
   * @param auctionDurationConfigFee the fee amount
   **/
  function setAuctionDurationConfigFee(uint256 auctionDurationConfigFee) external onlyLtvManager {
    ILendPool cachedPool = _getLendPool();
    cachedPool.setAuctionDurationConfigFee(auctionDurationConfigFee);
  }

  /**
   * @dev pauses or unpauses all the actions of the protocol, including uToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool val) external onlyEmergencyAdmin {
    ILendPool cachedPool = _getLendPool();
    cachedPool.setPause(val);
  }

  function setLtvManagerStatus(address newLtvManager, bool val) external onlyPoolAdmin {
    require(newLtvManager != address(0), Errors.LPC_INVALID_LTVMANAGER_ADDRESS);
    isLtvManager[newLtvManager] = val;
  }

  /**
   * @dev Sets new pool rescuer
   * @param rescuer the new rescuer address
   **/
  function setPoolRescuer(address rescuer) external onlyPoolAdmin {
    require(rescuer != address(0), Errors.INVALID_ZERO_ADDRESS);
    ILendPool cachedPool = _getLendPool();
    cachedPool.updateRescuer(rescuer);
    emit RescuerUpdated(rescuer);
  }

  /**
   * @dev Returns the token implementation contract address
   * @param proxyAddress  The address of the proxy contract
   * @return The address of the token implementation contract
   **/
  function getTokenImplementation(address proxyAddress) external view onlyPoolAdmin returns (address) {
    return ConfiguratorLogic.getTokenImplementation(proxyAddress);
  }

  /**
   * @dev Checks the liquidity of reserves
   * @param asset  The address of the underlying reserve asset
   **/
  function _checkReserveNoLiquidity(address asset) internal view {
    DataTypes.ReserveData memory reserveData = _getLendPool().getReserveData(asset);

    uint256 availableLiquidity = IUToken(reserveData.uTokenAddress).getAvailableLiquidity();

    require(availableLiquidity == 0 && reserveData.currentLiquidityRate == 0, Errors.LPC_RESERVE_LIQUIDITY_NOT_0);
  }

  /**
   * @dev Checks the liquidity of NFTs
   * @param asset  The address of the underlying NFT asset
   **/
  function _checkNftNoLiquidity(address asset) internal view {
    uint256 collateralAmount = _getLendPoolLoan().getNftCollateralAmount(asset);

    require(collateralAmount == 0, Errors.LPC_NFT_LIQUIDITY_NOT_0);
  }

  /**
   * @dev Returns the LendPool address stored in the addresses provider
   **/
  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressesProvider.getLendPool());
  }

  /**
   * @dev Returns the LendPoolLoan address stored in the addresses provider
   **/
  function _getLendPoolLoan() internal view returns (ILendPoolLoan) {
    return ILendPoolLoan(_addressesProvider.getLendPoolLoan());
  }

  /**
   * @dev Returns the UNFTRegistry address stored in the addresses provider
   **/
  function _getUNFTRegistry() internal view returns (IUNFTRegistry) {
    return IUNFTRegistry(_addressesProvider.getUNFTRegistry());
  }
}