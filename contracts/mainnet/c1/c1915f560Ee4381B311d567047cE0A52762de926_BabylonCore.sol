// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library MerkleProof {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IBabylonCore.sol";
import "./interfaces/IBabylonMintPass.sol";
import "./interfaces/ITokensController.sol";
import "./interfaces/IRandomProvider.sol";
import "./interfaces/IEditionsExtension.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract BabylonCore is Initializable, IBabylonCore, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    ITokensController internal _tokensController;
    IRandomProvider internal _randomProvider;
    IEditionsExtension internal _editionsExtension;
    string internal _mintPassBaseURI;
    //listing ids start from 1st, not 0
    uint256 internal _lastListingId;
    uint256 internal _maxListingDuration;

    address internal _treasury;

    // collection address -> tokenId -> id of a listing
    mapping(address => mapping(uint256 => uint256)) internal _ids;
    // id of a listing -> a listing info
    mapping(uint256 => ListingInfo) internal _listingInfos;
    // id of a listing -> a listing restrictions
    mapping(uint256 => ListingRestrictions) internal _listingRestrictions;
    // id of a listing -> participant address -> num of mint passes
    mapping(uint256 => mapping(address => uint256)) internal _participations;

    uint256 public constant BASIS_POINTS = 10000;

    event NewParticipant(uint256 listingId, address participant, uint256 ticketsAmount);
    event ListingStarted(uint256 listingId, address creator, address token, uint256 tokenId, address mintPass);
    event ListingResolving(uint256 listingId, uint256 randomRequestId);
    event ListingSuccessful(uint256 listingId, address claimer);
    event ListingCanceled(uint256 listingId);
    event ListingFinalized(uint256 listingId);
    event ListingRestrictionsUpdated(
        uint256 indexed listingId,
        bytes32 allowlistRoot,
        uint256 reserved,
        uint256 mintedFromReserve,
        uint256 maxPerAddress
    );

    function initialize(
        ITokensController tokensController,
        IRandomProvider randomProvider,
        IEditionsExtension editionsExtension,
        address treasury
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        _tokensController = tokensController;
        _randomProvider = randomProvider;
        _editionsExtension = editionsExtension;
        _maxListingDuration = 7 days;
        _treasury = treasury;
        transferOwnership(msg.sender);
    }

    function startListing(
        ListingItem calldata item,
        IEditionsExtension.EditionInfo calldata edition,
        ListingRestrictions calldata restrictions,
        uint256 timeStart,
        uint256 price,
        uint256 totalTickets,
        uint256 donationBps
    ) external {
        uint256 listingId = _ids[item.token][item.identifier];

        if (listingId != 0) {
            require(
                _listingInfos[listingId].state != ListingState.Active &&
                _listingInfos[listingId].state != ListingState.Resolving,
                "BabylonCore: Active listing for this token already exists"
            );
        }

        require(
            _tokensController.checkApproval(msg.sender, item),
            "BabylonCore: Token should be owned and approved to the controller"
        );

        require(totalTickets > 0, "BabylonCore: Number of tickets is too low");
        require(donationBps <= BASIS_POINTS, "BabylonCore: Donation out of range");

        require(
            restrictions.reserved <= totalTickets &&
            restrictions.maxPerAddress <= totalTickets,
            "BabylonCore: Incorrect restrictions"
        );

        listingId = _lastListingId + 1;
        address mintPass = _tokensController.createMintPass(listingId);
        _editionsExtension.registerEdition(edition, msg.sender, listingId);
        _ids[item.token][item.identifier] = listingId;
        ListingInfo storage listing = _listingInfos[listingId];
        listing.item = item;
        listing.state = ListingState.Active;
        listing.creator = msg.sender;
        listing.mintPass = mintPass;
        listing.price = price;
        listing.timeStart = timeStart > block.timestamp ? timeStart : block.timestamp;
        listing.totalTickets = totalTickets;
        listing.donationBps = donationBps;
        listing.creationTimestamp = block.timestamp;
        ListingRestrictions storage listingRestrictions = _listingRestrictions[listingId];
        listingRestrictions.allowlistRoot = restrictions.allowlistRoot;
        listingRestrictions.reserved = restrictions.reserved;
        listingRestrictions.maxPerAddress = restrictions.maxPerAddress;
        _lastListingId = listingId;

        emit ListingStarted(listingId, msg.sender, item.token, item.identifier, mintPass);
        emit ListingRestrictionsUpdated(
            listingId,
            restrictions.allowlistRoot,
            restrictions.reserved,
            0,
            restrictions.maxPerAddress
        );
    }

    function participate(
        uint256 id,
        uint256 tickets,
        bytes32[] calldata allowlistProof
    ) external payable nonReentrant {
        ListingInfo storage listing =  _listingInfos[id];
        require(
            _tokensController.checkApproval(listing.creator, listing.item),
            "BabylonCore: Token is no longer owned or approved to the controller"
        );
        require(listing.state == ListingState.Active, "BabylonCore: Listing state should be active");
        require(block.timestamp >= listing.timeStart, "BabylonCore: Too early to participate");
        uint256 current = listing.currentTickets;
        require(current + tickets <= listing.totalTickets, "BabylonCore: No available tickets");
        uint256 totalPrice = listing.price * tickets;
        require(msg.value == totalPrice, "BabylonCore: msg.value doesn't match price for tickets");

        ListingRestrictions storage restrictions = _listingRestrictions[id];

        uint256 participations = _participations[id][msg.sender] + tickets;
        require(participations <= restrictions.maxPerAddress, "BabylonCore: Tickets exceed maxPerAddress");
        _participations[id][msg.sender] = participations;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(allowlistProof, restrictions.allowlistRoot, leaf)) {
            uint256 allowlistLeft = restrictions.reserved - restrictions.mintedFromReserve;
            if (allowlistLeft > 0) {
                if (allowlistLeft <= tickets) {
                    restrictions.mintedFromReserve = restrictions.reserved;
                } else {
                    restrictions.mintedFromReserve += tickets;
                }

                emit ListingRestrictionsUpdated(
                    id,
                    restrictions.allowlistRoot,
                    restrictions.reserved,
                    restrictions.mintedFromReserve,
                    restrictions.maxPerAddress
                );
            }
        } else {
            uint256 available = (listing.totalTickets + restrictions.mintedFromReserve) - current - restrictions.reserved;
            require((available >= tickets), "BabylonCore: No available tickets outside the allowlist");
        }

        IBabylonMintPass(listing.mintPass).mint(msg.sender, tickets);

        listing.currentTickets = current + tickets;

        emit NewParticipant(id, msg.sender, tickets);

        if (listing.currentTickets == listing.totalTickets) {
            listing.randomRequestId = _randomProvider.requestRandom(id);
            listing.state = ListingState.Resolving;

            emit ListingResolving(id, listing.randomRequestId);
        }
    }

    function updateListingRestrictions(uint256 id, ListingRestrictions calldata newRestrictions) external {
        ListingInfo storage listing =  _listingInfos[id];
        require(listing.state == ListingState.Active, "BabylonCore: Listing state should be active");
        require(msg.sender == listing.creator, "BabylonCore: Only the creator can update the restrictions");

        ListingRestrictions storage restrictions = _listingRestrictions[id];
        uint256 totalTickets = listing.totalTickets;

        require(
            newRestrictions.maxPerAddress <= totalTickets &&
            newRestrictions.reserved >= restrictions.mintedFromReserve &&
            newRestrictions.reserved <= (totalTickets - listing.currentTickets + restrictions.mintedFromReserve),
            "BabylonCore: Incorrect restrictions"
        );

        restrictions.allowlistRoot = newRestrictions.allowlistRoot;
        restrictions.reserved = newRestrictions.reserved;
        restrictions.maxPerAddress = newRestrictions.maxPerAddress;

        emit ListingRestrictionsUpdated(
            id,
            restrictions.allowlistRoot,
            restrictions.reserved,
            restrictions.mintedFromReserve,
            restrictions.maxPerAddress
        );
    }

    function cancelListing(uint256 id) external {
        ListingInfo storage listing =  _listingInfos[id];
        if (listing.state == ListingState.Resolving) {
            require(_randomProvider.isRequestOverdue(listing.randomRequestId), "BabylonCore: Random is not overdue");
        } else {
            require(listing.state == ListingState.Active, "BabylonCore: Listing state should be active");
            require(msg.sender == listing.creator, "BabylonCore: Only listing creator can cancel active listing");
        }

        listing.state = ListingState.Canceled;

        emit ListingCanceled(id);
    }

    function transferETHToCreator(uint256 id) external nonReentrant {
        ListingInfo storage listing =  _listingInfos[id];
        require(listing.state == ListingState.Successful, "BabylonCore: Listing state should be successful");

        bool sent;
        uint256 creatorPayout = listing.totalTickets * listing.price;
        uint256 donation = creatorPayout * listing.donationBps / BASIS_POINTS;

        if (donation > 0) {
            creatorPayout -= donation;
            (sent, ) = payable(_treasury).call{value: donation}("");
            require(sent, "BabylonCore: Unable to send donation to the treasury");
        }

        if (creatorPayout > 0) {
            (sent, ) = payable(listing.creator).call{value: creatorPayout}("");
            require(sent, "BabylonCore: Unable to send ETH to the creator");
        }

        listing.state = ListingState.Finalized;
        emit ListingFinalized(id);
    }

    function refund(uint256 id) external nonReentrant {
        ListingInfo storage listing =  _listingInfos[id];

        if (
            (
                (listing.state == ListingState.Active || listing.state == ListingState.Resolving) &&
                !_tokensController.checkApproval(listing.creator, listing.item)
            ) ||
            (
                listing.state == ListingState.Active &&
                (listing.timeStart + _maxListingDuration <= block.timestamp)
            )
        ) {
            listing.state = ListingState.Canceled;

            emit ListingCanceled(id);
        }

        require(listing.state == ListingState.Canceled, "BabylonCore: Listing state should be canceled to refund");

        uint256 tickets = IBabylonMintPass(listing.mintPass).burn(msg.sender);

        uint256 amount = tickets * listing.price;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");

        require(sent, "BabylonCore: Unable to refund ETH");
    }

    function mintEdition(uint256 id) external {
        ListingInfo storage listing =  _listingInfos[id];
        require(
            listing.state == ListingState.Successful ||
            listing.state == ListingState.Finalized,
            "BabylonCore: Listing should be successful"
        );

        uint256 tickets = IBabylonMintPass(listing.mintPass).burn(msg.sender);
        _editionsExtension.mintEdition(id, msg.sender, tickets);
    }

    function resolveClaimer(
        uint256 id,
        uint256 random
    ) external override {
        require(msg.sender == address(_randomProvider), "BabylonCore: msg.sender is not the Random Provider");
        ListingInfo storage listing =  _listingInfos[id];
        require(listing.state == ListingState.Resolving, "BabylonCore: Listing state should be resolving");
        uint256 claimerIndex = random % listing.totalTickets;
        address claimer = IBabylonMintPass(listing.mintPass).ownerOf(claimerIndex);
        listing.claimer = claimer;
        listing.state = ListingState.Successful;
        _tokensController.sendItem(listing.item, listing.creator, claimer);

        emit ListingSuccessful(id, claimer);
    }

    function setMaxListingDuration(uint256 maxListingDuration) external onlyOwner {
        _maxListingDuration = maxListingDuration;
    }

    function setMintPassBaseURI(string calldata mintPassBaseURI) external onlyOwner {
        _mintPassBaseURI = mintPassBaseURI;
    }

    function setTreasury(address treasury) external onlyOwner {
        _treasury = treasury;
    }

    function getAvailableToParticipate(
        uint256 id,
        address user,
        bytes32[] calldata allowlistProof
    ) external view returns (uint256) {
        ListingInfo storage listing =  _listingInfos[id];
        ListingRestrictions storage restrictions = _listingRestrictions[id];
        uint256 current = listing.currentTickets;
        uint256 total = listing.totalTickets;
        uint256 available = total - current;

        if (
            (listing.state == ListingState.Active) &&
            _tokensController.checkApproval(listing.creator, listing.item) &&
            (block.timestamp >= listing.timeStart) &&
            (available > 0) &&
            (restrictions.maxPerAddress > _participations[id][user])
        ) {
            uint256 leftForAddress = restrictions.maxPerAddress - _participations[id][user];
            bytes32 leaf = keccak256(abi.encodePacked(user));
            if (!MerkleProof.verify(allowlistProof, restrictions.allowlistRoot, leaf)) {
                available = (total + restrictions.mintedFromReserve) - current - restrictions.reserved;
            }

            return available >= leftForAddress ? leftForAddress : available;
        }

        return 0;
    }

    function getLastListingId() external view returns (uint256) {
        return _lastListingId;
    }

    function getTreasury() external view returns (address) {
        return _treasury;
    }

    function getListingId(address token, uint256 tokenId) external view returns (uint256) {
        return _ids[token][tokenId];
    }

    function getListingInfo(uint256 id) external view returns (ListingInfo memory) {
        return _listingInfos[id];
    }

    function getListingParticipations(uint256 id, address user) external view returns (uint256) {
        return _participations[id][user];
    }

    function getListingRestrictions(uint256 id) external view returns (ListingRestrictions memory) {
        return _listingRestrictions[id];
    }

    function getTokensController() external view returns (ITokensController) {
        return _tokensController;
    }

    function getRandomProvider() external view returns (IRandomProvider) {
        return _randomProvider;
    }

    function getEditionsExtension() external view returns (IEditionsExtension) {
        return _editionsExtension;
    }

    function getMaxListingDuration() external view returns (uint256) {
        return _maxListingDuration;
    }

    function getMintPassBaseURI() external view returns (string memory) {
        return _mintPassBaseURI;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IBabylonCore {
    enum ItemType {
        ERC721,
        ERC1155
    }

    struct ListingItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
    }

    /**
     * @dev Indicates state of a listing.
    */
    enum ListingState {
        Active,
        Resolving,
        Successful,
        Finalized,
        Canceled
    }

    /**
     * @dev Contains all information for a specific listing.
    */
    struct ListingInfo {
        ListingItem item;
        ListingState state;
        address creator;
        address claimer;
        address mintPass;
        uint256 price;
        uint256 timeStart;
        uint256 totalTickets;
        uint256 currentTickets;
        uint256 donationBps;
        uint256 randomRequestId;
        uint256 creationTimestamp;
    }

    /**
     * @dev Contains all restriction for a specific listing such as allowlist and max per wallet.
    */
    struct ListingRestrictions {
        bytes32 allowlistRoot;
        uint256 reserved;
        uint256 mintedFromReserve;
        uint256 maxPerAddress;
    }

    function resolveClaimer(
        uint256 id,
        uint256 random
    ) external;

    function getListingInfo(uint256 id) external view returns (ListingInfo memory);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IBabylonMintPass {
    function initialize(
        uint256 listingId_,
        address core_
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from) external returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IEditionsExtension {
    struct EditionInfo {
        uint256 royaltiesBps;
        string name;
        string editionURI;
    }

    function registerEdition(
        EditionInfo calldata info,
        address creator,
        uint256 listingId
    ) external;

    function mintEdition(uint256 listingId, address receiver, uint256 amount) external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IRandomProvider {
    function isRequestOverdue(
        uint256 requestId
    ) external view returns (bool);

    function requestRandom(
        uint256 listingId
    ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "./IBabylonCore.sol";

interface ITokensController {
    function createMintPass(
        uint256 listingId
    ) external returns (address);

    function checkApproval(
        address creator,
        IBabylonCore.ListingItem calldata item
    ) external view returns (bool);

    function sendItem(IBabylonCore.ListingItem calldata item, address from, address to) external;
}