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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interface/IRental.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../interface/IRLand.sol";

abstract contract ARental is IRental {
    using Strings for uint256;

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter public rewardId;

    address public owner;

    address public landContract;
    address public lordContract;

    uint256[] public landWeight;
    uint256[] public lordWeight;
    uint256 public totalLandWeights;
    uint256 public availablePoolId;

    bytes32 public rootLand;
    bytes32 public rootLord;

    bool public paused;

    mapping(address => bool) public isBlacklisted;
    mapping(uint256 => LandLords) landLordsInfo;
    mapping(uint256 => Pool) poolInfo;
    mapping(address => uint256[]) rewardIdInfo;
    mapping(uint256 => uint256) index;
    mapping(uint256 => mapping(uint256 => uint256)) userClaimPerPool;

    modifier isBlacklist(address _user) {
        require(!isBlacklisted[_user], "Eth amount not enough");
        _;
    }

    modifier isContractApprove() {
        require(
            IERC721Upgradeable(landContract).isApprovedForAll(
                msg.sender,
                address(this)
            ) &&
                IERC721Upgradeable(lordContract).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
            "Nft not approved to contract"
        );
        _;
    }

    modifier isCatorgyValid(
        uint256[] memory _landCatorgy,
        uint256 _lordCatory
    ) {
        require(catorgyValid(_landCatorgy, _lordCatory), "not valid catory");
        _;
    }

    modifier isNonzero(
        uint256 _landId,
        uint256 _landCatorgy,
        uint256 _lordCatory
    ) {
        require(
            _landId != 0 && _landCatorgy != 0 && _lordCatory != 0,
            "not null"
        );
        _;
    }

    modifier isLandValid(uint256 length, uint256 _lordCatory) {
        require(lordWeight[_lordCatory - 1] >= length, "length mismatch");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier isOwnerOfId(uint256 _rewardId) {
        require(
            msg.sender == landLordsInfo[_rewardId].owner,
            "not rewardId owner"
        );
        _;
    }

    modifier isRewardIdExist(uint256 _rewardId) {
        require(
            rewardId.current() >= _rewardId && isRewardId(_rewardId),
            "rewardId not exist"
        );
        _;
    }

    modifier isMerkelProofValid(
        corrdinate memory cordinate,
        uint256[] memory _landId,
        uint256 _lordId,
        uint256[] memory _landCatorgy,
        uint256 _lordCatory,
        bytes32[] memory _merkleProofland1,
        bytes32[] memory _merkleProofland2,
        bytes32[] memory _merkleProofland3,
        bytes32[] memory _merkleProoflord
    ) {
        landProof(
            cordinate,
            _landId,
            _landCatorgy,
            _merkleProofland1,
            _merkleProofland2,
            _merkleProofland3
        );
        lordProof(_lordId, _lordCatory, _merkleProoflord);
        checkCoordinate(cordinate, _landId);
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "contract paused");
        _;
    }

    function checkCoordinate(
        corrdinate memory cordinate,
        uint256[] memory _landId
    ) internal view {
        if (_landId.length == 1) {
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land1[0],
                    cordinate.land1[1]
                ) == _landId[0],
                "not correct tokenId"
            );
        } else if (_landId.length == 2) {
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land1[0],
                    cordinate.land1[1]
                ) == _landId[0],
                "not correct tokenId"
            );
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land2[0],
                    cordinate.land2[1]
                ) == _landId[1],
                "not correct tokenId"
            );
        } else if (_landId.length == 3) {
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land1[0],
                    cordinate.land1[1]
                ) == _landId[0],
                "not correct tokenId"
            );
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land2[0],
                    cordinate.land2[1]
                ) == _landId[1],
                "not correct tokenId"
            );
            require(
                IRLand(landContract).getTokenId(
                    cordinate.land3[0],
                    cordinate.land3[1]
                ) == _landId[2],
                "not correct tokenId"
            );
        }
    }

    function claminingTime(
        uint256 preMonth,
        uint256 currentMonth,
        uint256 lastClaimTime,
        uint256 poolId
    ) internal view returns (uint256 claimableTime, uint256 lastClaim) {
        uint256 monthLasttime = poolInfo[poolId].poolStartTime +
            (poolInfo[poolId].poolTimeSlot * (preMonth + 1));

        if (currentMonth == (preMonth + 1) && block.timestamp < monthLasttime) {
            claimableTime = block.timestamp - lastClaimTime;
            lastClaim = block.timestamp;
        } else {
            claimableTime = monthLasttime - lastClaimTime;
            lastClaim = monthLasttime;
        }
    }

    function _currentMonth(uint256 _poolId) public view returns (uint256) {
        require(currentPoolId() == _poolId, "pass correct pool id");
        uint256 poolTime = poolInfo[_poolId].poolTimeSlot;
        uint256 poolMonth = poolInfo[_poolId].poolMonth;

        uint256 leftTime = block.timestamp - poolInfo[_poolId].poolStartTime;
        //require(leftTime < (poolTime * poolMonth), "Wrong pool id");

        if (leftTime > (poolTime * poolMonth)) {
            return poolMonth;
        }

        uint256 currentMonth = leftTime / poolTime;

        return currentMonth == poolMonth ? poolMonth : currentMonth + 1;
    }

    function currentPoolId() public view returns (uint256) {
        if (availablePoolId > 0) {
            return _calcuatePoolId();
        } else {
            return 0;
        }
    }

    function _calcuatePoolId() internal view returns (uint256 poolId) {
        for (uint256 i = 0; i < availablePoolId; i++) {
            if (
                poolInfo[i + 1].poolEndTime > block.timestamp &&
                poolInfo[i + 1].poolStartTime < block.timestamp
            ) {
                return i + 1;
            } else {
                if (i + 1 == availablePoolId) {
                    return availablePoolId;
                }
            }
        }
    }

    function catorgyValid(uint256[] memory _landCatorgy, uint256 _lordCatory)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _landCatorgy.length; i++) {
            if (_landCatorgy[i] >= 4 || _lordCatory >= 4) {
                return false;
            }
        }

        return true;
    }

    function _calculateRewards(uint256 _rewardId) internal returns (uint256) {
        uint256 _currentPoolId = currentPoolId();
        uint256 claimAmount;
        bool loop;

        while (!loop) {
            if (_currentPoolId == landLordsInfo[_rewardId].currentPoolId) {
                (
                    uint256 reward,
                    uint256 time,
                    uint256 claims
                ) = _rewardForCurrentPool(
                        _currentPoolId,
                        _rewardId,
                        landLordsInfo[_rewardId].lastClaimTime,
                        userClaimPerPool[_rewardId][_currentPoolId]
                    );
                claimAmount += reward;

                userClaimPerPool[_rewardId][_currentPoolId] = claims;
                landLordsInfo[_rewardId].lastClaimTime = time;
                loop = true;
            } else {
                uint256 poolId = landLordsInfo[_rewardId].currentPoolId;
                (uint256 reward, uint256 time) = _rewardsForPreviousPool(
                    poolId,
                    _rewardId,
                    landLordsInfo[_rewardId].lastClaimTime
                );
                claimAmount += reward;

                userClaimPerPool[_rewardId][poolId] = poolInfo[poolId]
                    .poolMonth;
                landLordsInfo[_rewardId].currentPoolId += 1;
                landLordsInfo[_rewardId].lastClaimTime = time;
            }
        }

        return claimAmount;
    }

    function _deposite(
        uint256[] memory _landId,
        uint256 _lordId,
        uint256[] memory _landCatorgy,
        uint256 _lordCatory,
        uint256 _currentPoolId
    ) internal {
        rewardId.increment();

        uint256 totalLandWeight;

        for (uint256 i = 0; i < _landCatorgy.length; i++) {
            totalLandWeight += landWeight[_landCatorgy[i] - 1];
        }

        landLordsInfo[rewardId.current()] = LandLords(
            msg.sender,
            _landId,
            _lordId,
            _landCatorgy,
            _lordCatory,
            block.timestamp,
            _currentPoolId,
            totalLandWeight,
            true
        );

        totalLandWeights += totalLandWeight;

        index[rewardId.current()] = rewardIdInfo[msg.sender].length;
        rewardIdInfo[msg.sender].push(rewardId.current());

        _monthTotalWeight(rewardId.current(), _currentPoolId, totalLandWeights);

        for (uint256 i = 0; i < _landId.length; i++) {
            _transfer(landContract, msg.sender, address(this), _landId[i]);
        }
        _transferA(lordContract, msg.sender, address(this), _lordId);

        emit DepositeLandLord(
            msg.sender,
            rewardId.current(),
            _landId,
            _lordId,
            _landCatorgy,
            _lordCatory
        );
    }

    function _getCurrentRewrdId() internal view returns (uint256) {
        return rewardId.current();
    }

    function isRewardId(uint256 _rewardId) internal view returns (bool) {
        for (uint256 i = 0; i < rewardIdInfo[msg.sender].length; i++) {
            if (rewardIdInfo[msg.sender][i] == _rewardId) {
                return true;
            }
        }
        return false;
    }

    function lordProof(
        uint256 _lordId,
        uint256 _lordCatory,
        bytes32[] memory _merkleProoflord
    ) internal view {
        bytes32 leafToCheck = keccak256(
            abi.encodePacked(_lordId.toString(), ",", _lordCatory.toString())
        );
        require(
            MerkleProofUpgradeable.verify(
                _merkleProoflord,
                rootLord,
                leafToCheck
            ),
            "Incorrect lord proof"
        );
    }

    function landProof(
        corrdinate memory cordinate,
        uint256[] memory _landId,
        uint256[] memory _landCatorgy,
        bytes32[] memory _merkleProofland1,
        bytes32[] memory _merkleProofland2,
        bytes32[] memory _merkleProofland3
    ) internal view {
        if (_landId.length == 1) {
            merkelProof(
                cordinate.land1[0],
                cordinate.land1[1],
                _landCatorgy[0],
                _merkleProofland1
            );
        } else if (_landId.length == 2) {
            merkelProof(
                cordinate.land1[0],
                cordinate.land1[1],
                _landCatorgy[0],
                _merkleProofland1
            );
            merkelProof(
                cordinate.land2[0],
                cordinate.land2[1],
                _landCatorgy[1],
                _merkleProofland2
            );
        } else if (_landId.length == 3) {
            merkelProof(
                cordinate.land1[0],
                cordinate.land1[1],
                _landCatorgy[0],
                _merkleProofland1
            );
            merkelProof(
                cordinate.land2[0],
                cordinate.land2[1],
                _landCatorgy[1],
                _merkleProofland2
            );
            merkelProof(
                cordinate.land3[0],
                cordinate.land3[1],
                _landCatorgy[2],
                _merkleProofland3
            );
        }
    }

    function _monthTotalWeight(
        uint256 _rewardId,
        uint256 _poolId,
        uint256 _totalLandWeight
    ) internal {
        uint256 currentMonth = _currentMonth(_poolId);
        poolInfo[_poolId].poolTotalWeight[currentMonth - 1] = _totalLandWeight;

        userClaimPerPool[_rewardId][_poolId] = currentMonth - 1;
    }

    function merkelProof(
        uint256 x,
        uint256 y,
        uint256 _landCatorgy,
        bytes32[] memory _merkleProofland
    ) internal view {
        bytes32 leafToCheck = keccak256(
            abi.encodePacked(
                x.toString(),
                ",",
                y.toString(),
                ",",
                _landCatorgy.toString()
            )
        );
        require(
            MerkleProofUpgradeable.verify(
                _merkleProofland,
                rootLand,
                leafToCheck
            ),
            "Incorrect land proof"
        );
    }

    function _poolMonthWeight(uint256 _poolId, uint256 _month)
        internal
        view
        returns (uint256)
    {
        uint256 month = _month;
        if (_poolId == 0) {
            return totalLandWeights;
        } else {
            for (uint256 i = 0; i < _month; i++) {
                if (poolInfo[_poolId].poolTotalWeight[month - 1] > 0) {
                    return poolInfo[_poolId].poolTotalWeight[month - 1];
                } else {
                    month -= 1;
                }
            }
        }

        return 0;
    }

    function _poolWeight(uint256 _poolId, uint256 _month)
        public
        view
        returns (uint256)
    {
        uint256 weight;
        uint256 poolId = _poolId;
        uint256 month = _month;
        for (uint256 i = 0; i < availablePoolId; i++) {
            weight = _poolMonthWeight(poolId, month);
            if (weight == 0) {
                poolId -= 1;
                month = poolInfo[poolId].poolMonth;
            } else {
                return weight;
            }
        }

        return totalLandWeights;
    }

    function _rewardsForPreviousPool(
        uint256 _poolId,
        uint256 _rewardId,
        uint256 _lastClaimTime
    ) internal view returns (uint256, uint256) {
        uint256 lastClaimTime = _lastClaimTime;
        uint256 totalRewards;
        uint256 poolId = _poolId;

        for (
            uint256 i = userClaimPerPool[_rewardId][poolId];
            i < poolInfo[poolId].poolMonth;
            i++
        ) {
            uint256 monthTime = poolInfo[poolId].poolStartTime +
                (poolInfo[poolId].poolTimeSlot * (i + 1));

            uint256 claimableTime = monthTime - lastClaimTime;

            uint256 weight = _poolWeight(poolId, i + 1);

            uint256 rewards = ((poolInfo[poolId].poolRoyalty * claimableTime) /
                (weight * poolInfo[poolId].poolTimeSlot)) *
                landLordsInfo[_rewardId].totalLandWeight;

            totalRewards += rewards;

            lastClaimTime = monthTime;
        }

        return (totalRewards, lastClaimTime);
    }

    function _rewardForCurrentPool(
        uint256 _poolId,
        uint256 rewardIds,
        uint256 _lastClaimTime,
        uint256 _userClaim
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _rewardId = rewardIds;
        uint256 lastClaimTime = _lastClaimTime;
        uint256 totalRewards;
        uint256 currentMonth = _currentMonth(_poolId);
        uint256 poolId = _poolId;
        uint256 claiming;
        uint256 weights;
        uint256 userClaim = _userClaim == currentMonth
            ? _userClaim - 1
            : _userClaim;

        if (currentMonth != 0) {
            for (uint256 i = userClaim; i < currentMonth; i++) {
                (uint256 claimableTime, uint256 monthTime) = claminingTime(
                    i,
                    currentMonth,
                    lastClaimTime,
                    poolId
                );

                claiming = claimableTime;

                uint256 weight = _poolWeight(poolId, i + 1);
                weights = weight;

                uint256 rewards = ((poolInfo[poolId].poolRoyalty *
                    claimableTime) / (weight * poolInfo[poolId].poolTimeSlot)) *
                    landLordsInfo[_rewardId].totalLandWeight;

                totalRewards += rewards;

                lastClaimTime = monthTime;
            }
        }
        return (totalRewards, lastClaimTime, currentMonth);
    }

    function stacklandlord(Deposite memory deposite)
        internal
        isNonzero(
            deposite._landId.length,
            deposite._landCatorgy.length,
            deposite._lordCatory
        )
        isCatorgyValid(deposite._landCatorgy, deposite._lordCatory)
        isContractApprove
        isLandValid(deposite._landId.length, deposite._lordCatory)
    {
        uint256 currentPoolIds = currentPoolId();
        require(currentPoolIds > 0, "deposite not allowed");

        _deposite(
            deposite._landId,
            deposite._lordId,
            deposite._landCatorgy,
            deposite._lordCatory,
            currentPoolIds
        );
    }

    function _transfer(
        address _contract,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721Upgradeable(_contract).transferFrom(_from, _to, _tokenId);
    }

    function _transferA(
        address _contract,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721AUpgradeable(_contract).safeTransferFrom(_from, _to, _tokenId);
    }

    function _transferETH(uint256 _amount) internal {
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "refund failed");
    }

    function _withdraw(uint256 _rewardId) internal {
        uint256 lastrewardId = rewardIdInfo[msg.sender][
            (rewardIdInfo[msg.sender].length - 1)
        ];
        index[lastrewardId] = index[_rewardId];
        rewardIdInfo[msg.sender][(index[_rewardId])] = lastrewardId;
        rewardIdInfo[msg.sender].pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRental {
    struct LandLords {
        address owner;
        uint256[] landId;
        uint256 lordId;
        uint256[] LandCatorgy;
        uint256 LordCatorgy;
        uint256 lastClaimTime;
        uint256 currentPoolId;
        uint256 totalLandWeight;
        bool status;
    }

    struct Pool {
        uint256 poolTimeSlot;
        uint256 poolRoyalty;
        uint256[] poolTotalWeight;
        uint256 poolMonth;
        uint256 poolStartTime;
        uint256 poolEndTime;
    }

    struct Deposite {
        uint256[] _landId;
        uint256 _lordId;
        uint256[] _landCatorgy;
        uint256 _lordCatory;
    }

    struct corrdinate {
        uint256[] land1;
        uint256[] land2;
        uint256[] land3;
    }

    event Blacklisted(address account, bool value);
    event DepositeLandLord(
        address owner,
        uint256 _rewardId,
        uint256[] landId,
        uint256 lordId,
        uint256[] landCatorgy,
        uint256 lordCatory
    );
    event Pausable(bool state);
    event UpdateOwner(address oldOwner, address newOwner);
    event UpdateLandContract(address newContract, address oldContract);
    event UpdateLordContract(address newContract, address oldContract);
    event WithdrawLandLord(
        address owner,
        uint256 _rewardId,
        uint256[] landId,
        uint256 lordId
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRLand
{
    function getTokenId(uint256 x, uint256 y)
      external
      view
      returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IRental.sol";
import "./Abstract/ARental.sol";

contract Rental is Initializable, ReentrancyGuardUpgradeable, IRental, ARental {
    function initialize(
        address _owner,
        address _landContract,
        address _lordContract,
        bytes32 _rootLand,
        bytes32 _rootLord,
        uint256[] calldata _landWeight,
        uint256[] calldata _lordWeight
    ) external initializer {
        owner = _owner;
        rootLand = _rootLand;
        rootLord = _rootLord;
        landContract = _landContract;
        lordContract = _lordContract;
        landWeight.push(_landWeight[0]);
        landWeight.push(_landWeight[1]);
        landWeight.push(_landWeight[2]);
        lordWeight.push(_lordWeight[0]);
        lordWeight.push(_lordWeight[1]);
        lordWeight.push(_lordWeight[2]);
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
        nonReentrant
    {
        isBlacklisted[account] = value;
        emit Blacklisted(account, value);
    }

    function setLandContract(address _landContract)
        external
        nonReentrant
        onlyOwner
    {
        address oldContract = landContract;
        landContract = _landContract;

        emit UpdateLandContract(_landContract, oldContract);
    }

    function setLordContract(address _lordContract)
        external
        nonReentrant
        onlyOwner
    {
        address oldContract = lordContract;
        lordContract = _lordContract;

        emit UpdateLandContract(_lordContract, oldContract);
    }

    function setOwner(address _owner) external nonReentrant onlyOwner {
        owner = _owner;
        emit UpdateOwner(msg.sender, owner);
    }

    function setRootLand(bytes32 _rootLand) external nonReentrant onlyOwner {
        rootLand = _rootLand;
    }

    function setRootLord(bytes32 _rootLord) external nonReentrant onlyOwner {
        rootLord = _rootLord;
    }

    function pause(bool _state) external nonReentrant onlyOwner {
        paused = _state;
        emit Pausable(_state);
    }

    function setLandWeight(
        uint256 _basicLandWeight,
        uint256 _platniumLandWeight,
        uint256 _primeLandWeight
    ) external nonReentrant onlyOwner {
        landWeight.push(_basicLandWeight);
        landWeight.push(_platniumLandWeight);
        landWeight.push(_primeLandWeight);
    }

    function setPool(
        uint256 _poolTimeSlot,
        uint256 _poolRoyalty,
        uint256[] calldata _poolTotalWeight,
        uint256 _poolMonth
    ) external payable onlyOwner {
        require(msg.value >= (_poolRoyalty * _poolMonth), "value not send");
        availablePoolId += 1;

        uint256 poolStartTime = availablePoolId == 1
            ? block.timestamp
            : poolInfo[availablePoolId - 1].poolEndTime;

        uint256 poolEndTime = poolStartTime + _poolTimeSlot * _poolMonth;

        poolInfo[availablePoolId] = Pool(
            _poolTimeSlot,
            _poolRoyalty,
            _poolTotalWeight,
            _poolMonth,
            poolStartTime,
            poolEndTime
        );
    }

    function emergencyWithdraw() external nonReentrant onlyOwner {
        _transferETH(address(this).balance);
    }

    function depositLandLords(
        Deposite memory deposite,
        corrdinate memory cordinate,
        bytes32[] memory _merkleProofland1,
        bytes32[] memory _merkleProofland2,
        bytes32[] memory _merkleProofland3,
        bytes32[] memory _merkleProoflord
    )
        external
        nonReentrant
        isMerkelProofValid(
            cordinate,
            deposite._landId,
            deposite._lordId,
            deposite._landCatorgy,
            deposite._lordCatory,
            _merkleProofland1,
            _merkleProofland2,
            _merkleProofland3,
            _merkleProoflord
        )
    {
        stacklandlord(deposite);
    }

    function withdrawLandLords(uint256 _rewardId)
        external
        nonReentrant
        whenNotPaused
        isRewardIdExist(_rewardId)
        isOwnerOfId(_rewardId)
    {
        require(_rewardId != 0, "not zero");
    
        for (uint256 i = 0; i < landLordsInfo[_rewardId].landId.length; i++) {
            _transfer(
                landContract,
                address(this),
                msg.sender,
                landLordsInfo[_rewardId].landId[i]
            );
        }
        _transferA(
            lordContract,
            address(this),
            msg.sender,
            landLordsInfo[_rewardId].lordId
        );

        totalLandWeights =
            totalLandWeights -
            landLordsInfo[_rewardId].totalLandWeight;

        landLordsInfo[_rewardId].status = false;

        uint256 poolId = currentPoolId();
        uint256 currentMonth = _currentMonth(poolId);
        poolInfo[poolId].poolTotalWeight[currentMonth - 1] = totalLandWeights;

        _withdraw(_rewardId);

        emit WithdrawLandLord(
            msg.sender,
            _rewardId,
            landLordsInfo[_rewardId].landId,
            landLordsInfo[_rewardId].lordId
        );
    }

    function claimRewards(uint256 _rewardId)
        external
        isRewardIdExist(_rewardId)
        isOwnerOfId(_rewardId)
        returns (uint256 rewards)
    {
        rewards = _calculateRewards(_rewardId);
        _transferETH(rewards);
    }

    function getPoolInfo(uint256 _poolId) external view returns (Pool memory) {
        return poolInfo[_poolId];
    }

    function getLandLordsInfo(uint256 _rewardId)
        external
        view
        returns (LandLords memory)
    {
        return landLordsInfo[_rewardId];
    }

    function getCurrentRewrdId() external view returns (uint256) {
        return _getCurrentRewrdId();
    }

    function getUserClaim(uint256 _rewardId, uint256 _poolId)
        external
        view
        returns (uint256)
    {
        return userClaimPerPool[_rewardId][_poolId];
    }

    function currrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function getcalculateRewards(uint256 _rewardId)
        external
        view
        isRewardIdExist(_rewardId)
        returns (uint256, uint256)
    {
        uint256 _currentPoolId = currentPoolId();
        uint256 claimAmount;
        uint256 userclaim = userClaimPerPool[_rewardId][_currentPoolId];
        uint256 lastClaimTime = landLordsInfo[_rewardId].lastClaimTime;
        uint256 userPoolId = landLordsInfo[_rewardId].currentPoolId;
        bool loop;

        while (!loop) {
            if (_currentPoolId == userPoolId) {
                (
                    uint256 reward,
                    uint256 time,
                    uint256 claims
                ) = _rewardForCurrentPool(
                        _currentPoolId,
                        _rewardId,
                        lastClaimTime,
                        userclaim
                    );
                claimAmount += reward;

                userclaim = claims;
                lastClaimTime = time;
                loop = true;
            } else {
                uint256 poolId = landLordsInfo[_rewardId].currentPoolId;
                (uint256 reward, uint256 time) = _rewardsForPreviousPool(
                    poolId,
                    _rewardId,
                    lastClaimTime
                );
                claimAmount += reward;
                userPoolId += 1;
                lastClaimTime = time;
            }
        }

        return (claimAmount, lastClaimTime);
    }

    function getUserRewardId(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return rewardIdInfo[_user];
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}