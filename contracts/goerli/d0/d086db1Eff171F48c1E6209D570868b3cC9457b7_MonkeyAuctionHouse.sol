/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// File: contracts/IMonkeySplitter.sol



/// @title Interface for Splitter Contract

pragma solidity ^0.8.17;

interface IMonkeySplitter {

    function splitEditorSale(address _editor, uint _auctionId) external returns (bool);

    function splitSimpleSale() external returns (bool);

    function approveEditorPay(uint _auctionId, address _editor) external;

    function denyEditorPay(uint _auctionId, address _editor) external;

}
// File: contracts/TnmtLibrary.sol



/// @title Structs for tnmt Auction House

pragma solidity ^0.8.17;

library ITnmtLibrary {

    struct Tnmt {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        mapping(uint8 => ColorStr) colors;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
    }

    struct Attributes {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
    }

    struct Edit {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 manyEdits;
        uint8 rotations;
        ColorDec[3] colors;
        address editor;
    }

    struct ColorDec {
        uint8 colorId;
        uint8 color_R;
        uint8 color_G;
        uint8 color_B;
        uint8 color_A;
    }

    struct ColorStr {
        uint8 colorId;
        bytes color;
    }


}
// File: contracts/IMonkeySvgGen.sol

//SPDX-License-Identifier: GPL-3.0

///@title MonkeySvgGen Interface


pragma solidity ^0.8.17;

interface IMonkeySvgGen {

    function min(uint256 a, uint256 b) external returns (uint256);

    function max(uint256 a, uint256 b) external returns (uint256);

    function colorDif(ITnmtLibrary.ColorDec memory _colorOne, ITnmtLibrary.ColorDec memory _colorTwo) external returns (uint256);

    function editColorsAreValid(uint256 minColorDifValue, uint8 _manyEdits, ITnmtLibrary.ColorDec[3] memory _colors, ITnmtLibrary.ColorDec[] memory _tnmtColors) external returns(bool);

    function ColorDecToColorString(ITnmtLibrary.ColorDec memory color) external returns (bytes memory);

    function svgCode(ITnmtLibrary.Attributes memory attrbts, ITnmtLibrary.ColorStr[] memory tokenColors, uint8[1024] memory pixls, ITnmtLibrary.Edit memory _edit ) external pure returns (bytes memory);

}
// File: contracts/ITnmtToken.sol



/// @title Interface for tnmt Auction House


pragma solidity ^0.8.17;

interface ITnmtToken {

    function exists(uint256 a) external returns (bool);

    function ownerOf(uint256 a) external returns (address);

    function mint(address _to,
        uint256 _auctionId,
        uint256 _monkeyId,
        uint8 _rotations,
        address _editor,
        uint8 _manyEdits,
        ITnmtLibrary.ColorDec[3] memory editColors) external returns (uint256);

}
// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts/utils/Counters.sol


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
library Counters {
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

// File: contracts/ITnmtAuctionHouse.sol



/// @title Interface for tnmt Auction House


pragma solidity ^0.8.17;

interface ItnmtAuctionHouse {


    struct Auction {

        // tnmt Auction Id
        uint256 auctionId;

        // tnmt Bidder bid for
        uint256 monkeyId;

        // edit Id for the bidded tnmt
        uint256 editId;

        // rotations for the bidded tnmt
        uint8 rotations;

        // The current highest bid amount
        uint256 amount;

        // The time that the auction started
        uint256 startTime;

        // The time that the auction is scheduled to end
        uint256 endTime;
        
        // The address of the current highest bid
        address payable bidder;

        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed auctionId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256  monkeyId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed auctionId, uint256 endTime);

    event AuctionTimeBufferUpdated(uint256 _timeBuffer);

    event AuctionMinColorDiffUpdated(uint256 _colorDif);

    event AuctionSettled(uint256 indexed auctionId,uint256 monkeyId, address winner, uint256 amount);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event SplitterUpdated(address splitter);

    event SvgGenUpdated(address svgGen);

    event SplitterLocked(address splitter);

    event SvgGenLocked(address svgGen);

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setColorDif(uint256 colorDif) external;
        
    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;

    function settleCurrentAndCreateNewAuction() external;

    function settleAuction() external;

    function createBid(uint256 monkeyId, uint8 rotations, uint256 editId) external payable;


}
// File: contracts/monkeyAuctionHouse.sol



/// @title tnmt auction House

pragma solidity ^0.8.17;










contract MonkeyAuctionHouse is
    ItnmtAuctionHouse,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    
    // Tnmt Auction Id tracker
    uint256 public currentTnmtAuctionId;
    
    // Edit ID tracker, resets each auction
    uint256 public currentEdit = 0;

    // Tracking edit ID's to edit struct, resets each auction
    mapping(uint256 => ITnmtLibrary.Edit) edits;

    // Refunding if bid return fails
    mapping(address => uint) refunds;
    
    // The tnmt ERC721 contract
    address public tnmt;

    // address of SvgGen contract
    address public svgGen;

    // address of splitter contract
    address payable public splitter;


    // Can the splitter be updated
    bool public isSplitterLocked;

    // Can the svgGen be updated
    bool public isSvgGenLocked;

    //Minimum accepted color value difference (Hopefully avoids copys)
    uint256 public minColorDifValue;

    // The minimum amoutn of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of an auction
    uint256 public duration;

    ItnmtAuctionHouse.Auction public auction;

    /**
     * Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     */
    function initialize(address payable _splitter, address _svgGen, address _tnmtToken, uint256 _timeBuffer, uint8 _minBidIncrementPercentage, uint256 _duration, uint256 _auctionId, uint256 _minColorDifValue) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        _pause();

        duration = _duration;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        timeBuffer = _timeBuffer;
        tnmt = _tnmtToken;
        svgGen = _svgGen;
        splitter = _splitter;
        currentTnmtAuctionId = _auctionId;
        minColorDifValue = _minColorDifValue;
    }

    /**
     * Sets the Splitter address. Only callable by the owner when Splitter is not locked
     */
    function setSplitter(address payable _splitter) external onlyOwner {
        require(!isSplitterLocked,"Splitter is locked");
        splitter = _splitter;
        emit SplitterUpdated(_splitter);
    }

    /**
     * Locks the splitter address.
     */
    function lockSplitter() external onlyOwner {
        isSplitterLocked = true;
        emit SplitterLocked(splitter);
    }  


    /**
     * Sets the svgGen address.
     * @dev Only callable by the owner when svgGen is not locked
     */
    function setSvgGen(address _svgGen) external onlyOwner {
        require(!isSvgGenLocked,"SvgGen is locked");
        svgGen = _svgGen;
        emit SvgGenUpdated(_svgGen);
    }

    /**
     * Locks the svgGen address.
     */
    function lockSvgGen() external onlyOwner {
        isSvgGenLocked = true;
        emit SvgGenLocked(splitter);
    }

    /**
     *   Pause the tnmt auction House
     *   This function can only be called by owner when contract is not paused
     *   No new auctions can be started when paused. Still anyone can settle an auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     *   Unause the tnmt auction House
     *   This function can only be called by owner when contract is paused.
     *   If required, this function will start a new auction
     */
    function unpause() external override onlyOwner {
        _unpause();
        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * Set the auction time buffer.
     * Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * Set the auction time buffer.
     * Only callable by the owner.
     */
    function setTnmtAddress(address _tnmtToken) external onlyOwner {
        tnmt = _tnmtToken;
    }

    /**
     * Set the min diff value between colors for edits.
     * Only callable by the owner.
     */
    function setColorDif(uint256 _colorDif) external override onlyOwner {
        minColorDifValue = _colorDif;

        emit AuctionMinColorDiffUpdated(_colorDif);
    }

    /**
     * Set the auction min bid increment percentage.
     * Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(
            _minBidIncrementPercentage
        );
    }

    /**
     * Settle de currrent auction and create new one
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    /**
     *   Settle de currrent auction
     *   This function can only be called when the contract is paused
     */
    function settleAuction() external override nonReentrant whenPaused {
        _settleAuction();
    }

    /**
     *   Current Edits Viewer function
     */
    function editsView(uint _editId) public view returns(ITnmtLibrary.Edit memory) {
        return edits[_editId];
    }

    /**
     * Settle an auction, finalizing the bid and paying out to the splitter contract.
     * If there are no bids no minting is done
     */
    function _settleAuction() internal {
        ItnmtAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction has not begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auction.settled = true;

        if (_auction.bidder != address(0)) {
            uint256 token = 0;
            if(_auction.editId != 0) {
                token = ITnmtToken(tnmt).mint(_auction.bidder, currentTnmtAuctionId, _auction.monkeyId, _auction.rotations, edits[_auction.editId].editor, edits[_auction.editId].manyEdits,edits[_auction.editId].colors);
            } else {
                ITnmtLibrary.ColorDec[3] memory emptyColors;
                token = ITnmtToken(tnmt).mint(_auction.bidder, currentTnmtAuctionId, _auction.monkeyId, _auction.rotations, address(0),0,emptyColors);
            }
            token = 0;
        }

        if (_auction.amount > 0 ) {
            
            _safeTransferETH(splitter, _auction.amount);
            bool succes = false;
            if(_auction.editId != 0) {
                succes = IMonkeySplitter(splitter).splitEditorSale(edits[_auction.editId].editor, currentTnmtAuctionId);
            } else {
                succes = IMonkeySplitter(splitter).splitSimpleSale();
            }
            require(succes,"Algo no salio muy bien");
        }

        
        emit AuctionSettled(
            _auction.auctionId,
            _auction.monkeyId,
            _auction.bidder,
            _auction.amount
        );
    }

    /**
     * Create a new auction.
     * Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     */
    function _createAuction() internal {
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        currentTnmtAuctionId++;
        edits[0].editor = payable(0);


        for (uint256 i = 1; i < currentEdit; i++) {
            delete edits[i];
        }

        currentEdit = 0;

        auction = Auction({
            auctionId: currentTnmtAuctionId,
            monkeyId: 2000,
            editId: 0,
            rotations: 0,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false
        });

        emit AuctionCreated(
            auction.auctionId,
            auction.startTime,
            auction.endTime
        );

    }


    /**
     * Transfer ETH and return the success status.
     * This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint value) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    /**
     * Transfer ETH and return the success status.
     * This function only forwards 30,000 gas to the callee.
     */
    function withdrawRefund() external nonReentrant {
        require(refunds[msg.sender] > 0, "No ETH to be refunded");
        uint amount = refunds[msg.sender];
        refunds[msg.sender] = 0;
        bool success = _safeTransferETH(msg.sender, amount);
        require(success);
    }

    /**
     * Checks callers refunds balance
     */
    function myBalance() public view returns (uint256) {
        return refunds[msg.sender];
    }

    /**
     *   Creates a bid for a tnmt
     */
    function createBid(uint256 _monkeyId, uint8 _rotations, uint256 _editId) external payable override nonReentrant whenNotPaused {
        ItnmtAuctionHouse.Auction memory _auction = auction;

        require(_monkeyId <= 1999, "monkeyId must be less than or equal to 1999");
        require(block.timestamp < _auction.endTime, "Auction ended");
        require(auction.startTime != 0, "Auction has not begun");
        require(!auction.settled, "Auction has already been settled");
        require(msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );
        require(_editId <= currentEdit,
            "Bidded for non Existant EditId"
        );

        if(_editId > 0){
            require(_monkeyId == edits[_editId].monkeyId, "Bid MonkeyId and Edit MonkeyId do not match");
        }
        
        require(_rotations < 4, "Rotations must be between 1 and 3");

        address payable lastBidder = _auction.bidder;

        if (lastBidder != address(0)) {
            uint256 refundAmount = _auction.amount;
            auction.amount = 0;
            refunds[lastBidder] += refundAmount;
        }

        auction.monkeyId = _monkeyId;
        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);
        auction.rotations = _rotations;
        auction.editId = _editId;

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.monkeyId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.auctionId, _auction.endTime);
        }
    }

    /**
     *   Checkes wether the color scheme is valid in the current auction or not for a given MonkeyID
     **/
    function editColorsAreValid(uint256 _monkeyId, uint8 _manyEdits, ITnmtLibrary.ColorDec[3] memory _colors) internal returns(bool) {

        bool valid = false;

        for (uint j = 0; j < currentEdit + 1; j++) {
            if (
                edits[j].monkeyId == _monkeyId &&
                edits[j].manyEdits == _manyEdits
            ) {
                valid = false;
                for (uint c = 0; c < _manyEdits; c++) {
                    if (
                        edits[j].colors[c].colorId !=
                        _colors[c].colorId
                    ) {
                        valid = true;
                    } else if (
                        IMonkeySvgGen(svgGen).colorDif(edits[j].colors[c], _colors[c]) >= minColorDifValue
                    ) {
                        valid = true;
                    }
                }

                if(!valid) {
                    return false;
                }
            }
        }

        return true;
    }

    /**
     *   Creates a new biddable edit, when proposing,three valid color arrays must be submited, for 
     *   simplicity purposes, even when just one color change is WANTED, unused color must be indexed as 10 and 
     *   11. Second parameter indicates how many of those colors are to be taken.
     **/
    function proposeEdit(uint256 _monkeyId, uint8 _manyEdits, uint8 _rotations, ITnmtLibrary.ColorDec[3] memory _colors) public whenNotPaused returns(uint256) {
        
        require(_monkeyId < 2000, "MonkeyId must be between 0 and 1999");
        require(_manyEdits < 4, "Edit lenght must be between 1 and 3");
        require(_rotations < 4, "Rotations must be between 1 and 3");
        require(_colors[0].colorId < _colors[1].colorId && _colors[1].colorId < _colors[2].colorId, "Color Indexes must be in ascending order");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(auction.startTime != 0, "Auction has not begun");
        require(!auction.settled, "Auction has already been settled");

        
        for (uint i = 0; i < _manyEdits; i++) {
            require(
                _colors[i].colorId >= 0 && _colors[i].colorId < 10 ,
                "Color Indexes must be between 0 and 9"
            );

            if (_colors[i].color_A > 100) {
                _colors[i].color_A = 100;
            }
        }

        require(editColorsAreValid(_monkeyId, _manyEdits, _colors), "Proposed color scheme is too similar to another existing Edit");

        currentEdit++;

        edits[currentEdit].auctionId = currentTnmtAuctionId;
        edits[currentEdit].monkeyId = _monkeyId;
        edits[currentEdit].rotations = _rotations;
        edits[currentEdit].manyEdits = _manyEdits;
        edits[currentEdit].editor = msg.sender;

        for (uint256 c = 0; c < _manyEdits; c++) {
            edits[currentEdit].colors[c].colorId = _colors[c].colorId;
            edits[currentEdit].colors[c].color_R = _colors[c].color_R;
            edits[currentEdit].colors[c].color_G = _colors[c].color_G;
            edits[currentEdit].colors[c].color_B = _colors[c].color_B;
            edits[currentEdit].colors[c].color_A = _colors[c].color_A;
        }
        
        return currentEdit;
    }
}