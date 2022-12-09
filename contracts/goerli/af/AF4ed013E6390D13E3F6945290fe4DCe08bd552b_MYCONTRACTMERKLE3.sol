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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library MathUpgradeable {
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

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable diamond facet contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */

import {ERC721A__InitializableStorage} from './ERC721A__InitializableStorage.sol';

abstract contract ERC721A__Initializable {
    using ERC721A__InitializableStorage for ERC721A__InitializableStorage.Layout;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializerERC721A() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            ERC721A__InitializableStorage.layout()._initializing
                ? _isConstructor()
                : !ERC721A__InitializableStorage.layout()._initialized,
            'ERC721A__Initializable: contract is already initialized'
        );

        bool isTopLevelCall = !ERC721A__InitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = true;
            ERC721A__InitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializingERC721A() {
        require(
            ERC721A__InitializableStorage.layout()._initializing,
            'ERC721A__Initializable: contract is not initializing'
        );
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base storage for the  initialization function for upgradeable diamond facet contracts
 **/

library ERC721A__InitializableStorage {
    struct Layout {
        /*
         * Indicates that the contract has been initialized.
         */
        bool _initialized;
        /*
         * Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.initializable.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721AStorage {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // The next token ID to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned.
        // See {_packedOwnershipOf} implementation for details.
        //
        // Bits Layout:
        // - [0..159]   `addr`
        // - [160..223] `startTimestamp`
        // - [224]      `burned`
        // - [225]      `nextInitialized`
        // - [232..255] `extraData`
        mapping(uint256 => uint256) _packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) _packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => ERC721AStorage.TokenApprovalRef) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.ERC721A');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AUpgradeable.sol';
import {ERC721AStorage} from './ERC721AStorage.sol';
import './ERC721A__Initializable.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721ReceiverUpgradeable {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is ERC721A__Initializable, IERC721AUpgradeable {
    using ERC721AStorage for ERC721AStorage.Layout;

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
        ERC721AStorage.layout()._currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return ERC721AStorage.layout()._currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - ERC721AStorage.layout()._burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return ERC721AStorage.layout()._burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return ERC721AStorage.layout()._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        ERC721AStorage.layout()._packedAddressData[owner] = packed;
    }

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(ERC721AStorage.layout()._packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (ERC721AStorage.layout()._packedOwnerships[index] == 0) {
            ERC721AStorage.layout()._packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < ERC721AStorage.layout()._currentIndex) {
                    uint256 packed = ERC721AStorage.layout()._packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = ERC721AStorage.layout()._packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

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
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        ERC721AStorage.layout()._tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return ERC721AStorage.layout()._tokenApprovals[tokenId].value;
    }

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
    function setApprovalForAll(address operator, bool approved) public virtual override {
        ERC721AStorage.layout()._operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return ERC721AStorage.layout()._operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < ERC721AStorage.layout()._currentIndex && // If within bounds,
            ERC721AStorage.layout()._packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        ERC721AStorage.TokenApprovalRef storage tokenApproval = ERC721AStorage.layout()._tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --ERC721AStorage.layout()._packedAddressData[from]; // Updates: `balance -= 1`.
            ++ERC721AStorage.layout()._packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data)
        returns (bytes4 retval) {
            return retval == ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            ERC721AStorage.layout()._currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            ERC721AStorage.layout()._currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = ERC721AStorage.layout()._currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (ERC721AStorage.layout()._currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            ERC721AStorage.layout()._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            ERC721AStorage.layout()._burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        ERC721AStorage.layout()._packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Errors {
    error CallerIsAnotherContract();
    error NonexistentToken();
    error PresaleIsActive();
    error MintAmountOver();
    error PresaleIsNotActive();
    error InvalidMerkleProof();
    error OverMintLimit();
    error MintAmountCannotBeZero();
    error MaxSupplyOver();
    error NotEnoughFunds();
    error CallerIsNotTeam();
    error NowPaused();
    error FailedWithdraw();
    // error ThisTokenIsLocked();

    error BurnMintNotPaused();
    error BurnMintMaxSupply();
    error BurnMintCallerNotOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import './erc721a/contracts/ERC721AUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

import "./opensea/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
// import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";

contract MYCONTRACTMERKLE3 is 
    ERC721AUpgradeable,
    OwnableUpgradeable, 
    ERC2981Upgradeable, 
    ReentrancyGuardUpgradeable, 
    DefaultOperatorFiltererUpgradeable
{
    using StringsUpgradeable for uint256;  //toString()でuint256を対応

    string private baseURI;
    string internal revealUri;
    // string internal lockedUri;
    // string internal extension;
    uint256 public preCost;
    uint256 public publicCost;
    uint256 public burnMintCost;
    bool public burnMintPaused;
    bool internal isRevealed;
    bool public isPause;
    uint64 public salePhase;
    uint64 private mintedCountPhase;
    uint64 public maxSupply;
    bytes32 private merkleRoot1;
    bytes32 private merkleRoot2;
    bytes32 private merkleRoot3;
    // bytes32 private merkleRoot4;
    mapping(uint64 => mapping(address => uint256)) public mintedLists;
    // mapping(string => bool) internal lockLists;   //2,7     trueでロックされる
    mapping(address => bool) private teamMember;
    
    function initialize() public initializerERC721A initializer {
        __Ownable_init();
        __ERC2981_init();
        // __ERC721AQueryable_init();
        // __ERC721ABurnable_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        __ERC721A_init("MY CONTRACT MERKLE TREE 3", "TEST");

        setMember(_msgSender(), true);

        baseURI = "";
        revealUri = "ar://g84agNL0vN3nUwlfe1AoghLqHHK-OKs-cui7v1nqAZs";
        // lockedUri = "";
        // extension = ".json";

        preCost = 0.02 ether;
        publicCost = 0.1 ether;

        burnMintCost = 0.001 ether;
        burnMintPaused = false;

        isRevealed = false;  //before　-> false　, after　-> true
        isPause = false;    //ポーズ中　-> true, セール中　-> false

        // フェーズ0：セール前
        // フェーズ１：フリーミント
        // フェーズ２：ALミント（確実にMINT可能数のみ） 0.02
        // フェーズ３：ALミント（配布数オーバーAL） 0.02
        // フェーズ５：パブリックセール（誰でもOK） 0.1
        salePhase = 0;

        mintedCountPhase = 1;   //カウントアップでミント済みをリセット
        maxSupply = 1000;

        //_feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
        setRoyaltyInfo(0x9e81fd993203113AebD886707D8E8c21dDe939c6, 1000);
    }

    modifier onlyTeam() {
        if(!teamMember[msg.sender]) revert Errors.CallerIsNotTeam();
        _;
    }
    event SetMember(address member, bool enable);
    function setMember(address member ,bool enable) public onlyOwner {
        teamMember[member] = enable;
        emit SetMember(member, enable);
    }

    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert Errors.CallerIsAnotherContract();
        _;
    }

    // internal override
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if(!_exists(_tokenId)) revert Errors.NonexistentToken();
        // if(lockLists[StringsUpgradeable.toString(_tokenId)] == true) {
        //     return lockedUri;
        // }
        if(isRevealed == false) {
            return revealUri;
        }
        return string(abi.encodePacked(baseURI, StringsUpgradeable.toString(_tokenId), ".json"));
    }
    // start from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // public mint
    function publicMint(uint256 _mintAmount) external payable callerIsUser nonReentrant {
        mintCheck(_mintAmount, publicCost * _mintAmount);
        if(!(salePhase == 5)) revert Errors.PresaleIsActive();
        if(_mintAmount > 10) revert Errors.MintAmountOver();
        _safeMint(msg.sender, _mintAmount);
    }

    // pre Mint
    function preMint(
        uint256 _mintAmount,
        uint256 _maxCount,
        bytes32[] calldata _proof
    ) external payable callerIsUser nonReentrant {
        mintCheck(_mintAmount,  getCurrentCost() * _mintAmount);
        if(!(salePhase >= 1 && salePhase <= 3)) revert Errors.PresaleIsNotActive();      //フェーズ１−４の間のみ許可
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _maxCount));
        bytes32 _merkleRoot;
        if(salePhase == 1){
            _merkleRoot = merkleRoot1;  //フェーズ1
        }else if(salePhase == 2){
            _merkleRoot = merkleRoot2;  //フェーズ2
        }else if(salePhase == 3){
            _merkleRoot = merkleRoot3;  //フェーズ3
        }
        // else if(salePhase == 4){
        //     _merkleRoot = merkleRoot4;  //フェーズ4
        // }
        if(!MerkleProofUpgradeable.verify(_proof, _merkleRoot, _leaf)) revert Errors.InvalidMerkleProof();     
        if(mintedLists[mintedCountPhase][msg.sender] + _mintAmount > _maxCount) revert Errors.OverMintLimit();    // 登録数は超えてないか？
        mintedLists[mintedCountPhase][msg.sender] += _mintAmount;   //ミント済みListをカウントアップ（フェーズ２へのカウントアップ時に自動でリセットさせるので、ここでは固定でOK）
        _safeMint(msg.sender, _mintAmount);
    }

    function mintCheck(
        uint256 _mintAmount,
        uint256 _cost
    ) private view {
        if(isPause) revert Errors.NowPaused();
        if(_mintAmount < 1) revert Errors.MintAmountCannotBeZero();
        if(totalSupply() + _mintAmount > maxSupply) revert Errors.MaxSupplyOver();
        if(msg.value < _cost) revert Errors.NotEnoughFunds();
    }

    function ownerMint(address _address, uint256 count) external onlyTeam {
       _safeMint(_address, count);
    }

    function setSalePhase(uint64 _phase) external onlyTeam {
        salePhase = _phase;
    }

    function setPreCost(uint256 _preCost) external onlyTeam {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) external onlyTeam {
        publicCost = _publicCost;
    }

    function getCurrentCost() public view returns (uint256) {
        if (salePhase == 1){
            return 0;
        } else if (salePhase == 2 || salePhase == 3 || salePhase == 4) {
            return preCost;
        } {
            return publicCost;
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyTeam {
        baseURI = _newBaseURI;
    }

    // function setExtension(string memory _value) external onlyTeam {
    //     extension = _value;
    // }

    function setPause(bool _bool) external onlyTeam {
        isPause = _bool;
    }

    function withdraw() external onlyTeam {
        bool success;
        (success, ) = payable(0x9e81fd993203113AebD886707D8E8c21dDe939c6).call{value: (address(this).balance)}("");
        if(!success) revert Errors.FailedWithdraw();

        // uint256 sendAmount = address(this).balance;
        // bool success;
        // (success, ) = payable(0x9e81fd993203113AebD886707D8E8c21dDe939c6).call{value: (sendAmount * 600/1000)}("");
        // if(!success) revert FailedWithdraw();
        // (success, ) = payable(0x9e81fd993203113AebD886707D8E8c21dDe939c6).call{value: (sendAmount * 400/1000)}("");
        // if(!success) revert FailedWithdraw();
    }

    function setMerkleRoot(bytes32 _merkleRoot1, bytes32 _merkleRoot2, bytes32 _merkleRoot3) external onlyTeam {
        merkleRoot1 = _merkleRoot1;
        merkleRoot2 = _merkleRoot2;
        merkleRoot3 = _merkleRoot3;
        // merkleRoot4 = _merkleRoot4;
    }

    function setMintedCountPhase() external onlyTeam {
        mintedCountPhase = mintedCountPhase + 1;
    }

    function getMintedCount(address _address) external view returns (uint256) {
        return mintedLists[mintedCountPhase][_address];
    }

    function setMaxSupply(uint64 _maxSupply) external onlyTeam {
        maxSupply = _maxSupply;
    }

    function setHiddenBaseURI(string memory _uri) external virtual onlyTeam {
        revealUri = _uri;
    }

    function setReveal(bool _bool) external virtual onlyTeam {
        isRevealed = _bool;
    }

    function burn(uint256 _tokenId) external virtual {
        _burn(_tokenId, true);
    }

    function setBurnMintPaused(bool _bool) external onlyTeam {
        burnMintPaused = _bool;
    }

    function burnMint(uint256[] memory _burnTokenIds) external payable nonReentrant {
        if (!burnMintPaused) revert Errors.BurnMintNotPaused();
        if (_nextTokenId() + _burnTokenIds.length > maxSupply) revert Errors.BurnMintMaxSupply();
        if (msg.sender != owner()) {
            require(msg.value >= burnMintCost * _burnTokenIds.length);
        }
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            if (_msgSender() != ownerOf(tokenId)) revert Errors.BurnMintCallerNotOwner();
            _burn(tokenId);
        }
        _safeMint(_msgSender(), _burnTokenIds.length);
    }

    // function setLockedURI(string memory _uri) external virtual onlyTeam {
    //     lockedUri = _uri;
    // }

    // function setLockList(string memory _tokenId, bool _bool) external virtual onlyTeam {
    //     lockLists[_tokenId] = _bool;
    // }

    // function getLockList(string memory _tokenId) external view virtual returns (bool) {
    //     return lockLists[_tokenId];
    // }

    // function _beforeTokenTransfers(
    //     address from,
    //     address to,
    //     uint256 startTokenId,
    //     uint256 quantity
    // ) internal view override {
    //     if(to != address(0)){
    //         for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
    //             if(lockLists[StringsUpgradeable.toString(i)] == true) revert ThisTokenIsLocked();
    //         }
    //     }
    // }


    /// @notice Function for changing royalty information
    /// @dev Can only be called by project owner
    /// @dev Owner can prevent any sale by setting the address to any address that can't receive native network token
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    function setRoyaltyInfo(address _royaltyReceiver, uint96 _feePercent)
        public
        onlyTeam
    {
        _setDefaultRoyalty(_royaltyReceiver, _feePercent);
        // emit Events.RoyaltyInfoChanged(_royaltyReceiver, _feePercent);
    }

    /// @notice Returns true if this contract implements the interface defined by `interfaceId`
    /// @dev Needs to be overridden cause two base contracts implement it
    /// @param _interfaceId InterfaceId to consider. Comes from type(InterfaceContract).interfaceId
    /// @return bool True if the considered interface is supported
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(_interfaceId) ||
            ERC2981Upgradeable.supportsInterface(_interfaceId) ||
            super.supportsInterface(_interfaceId);
    }


    // ========================
    // Opensea library
    // ========================
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";

abstract contract DefaultOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function __DefaultOperatorFilterer_init() internal onlyInitializing {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(DEFAULT_SUBSCRIPTION, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IOperatorFilterRegistry} from "../IOperatorFilterRegistry.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract OperatorFiltererUpgradeable is Initializable {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    function __OperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        onlyInitializing
    {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isRegistered(address(this))) {
                if (subscribe) {
                    operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        operatorFilterRegistry.register(address(this));
                    }
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }
}