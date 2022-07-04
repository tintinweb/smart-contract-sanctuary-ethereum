/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org
// SPDX-License-Identifier: MIT
// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

 
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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


// File @openzeppelin/contracts-upgradeable/security/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File @openzeppelin/contracts-upgradeable/security/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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


// File @openzeppelin/contracts/utils/cryptography/[email protected]

 
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


// File contracts/MetafameSale_MTv2.sol

 
pragma solidity ^0.8.0;








abstract contract Presalable is ContextUpgradeable {

    event Presaled(address account);
    event Unpresaled(address account);

    bool private _presaled;

    function __Presalable_init() internal {
         _presaled = false;
    }

    function presaled() public view virtual returns (bool) {
        return _presaled;
    }
    modifier whenNotPresaled() {
        require(!presaled(), "Presalable: presaled");
        _;
    }
    modifier whenPresaled() {
        require(presaled(), "Presalable: not presaled");
        _;
    }
    function _presale() internal virtual whenNotPresaled {
        _presaled = true;
        emit Presaled(_msgSender());
    }

    function _unpresale() internal virtual whenPresaled {
        _presaled = false;
        emit Unpresaled(_msgSender());
    }
}

interface IMF1155 {
    function mint(address to, uint256 tokenId, uint256 amount, uint256 gender, uint256 skin) external;
    function mintAndBurn(address account, uint256 tokenId,uint256 newTokenId) external;
    function getRemainingBoxQuantity() external view returns(uint256);
    function getAllocatedBoxQuantity() external view returns(uint256);
    function getMaxSupply() external view returns(uint256);
    function getStepOneIdCounter() external view returns (uint256);
    function getMakeOverLimitId() external view returns (uint256);
    function getBalanceOf(address account, uint256 id) external view returns (uint256);
    function pause() external;
    function unpause() external;
}

contract MetafameSaleMTv5_0704 is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable, Presalable{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    IMF1155 public metafame1155;

    bool private _endsaled;

    uint256 public _FOR_OWNER;
    
    uint256 public maxPurchaseLimit;
    uint256 public maxPurchaseLimitWL;

    uint256 public publicSaleStart;
    uint256 public publicSaleEnd;

    uint256 public ethPerBox;
    uint256 public ethPerBoxWL;
    uint256 public makeOverPrice;

    uint256 private _makeOver;

    uint256 public wlRoundNumber;
    struct RoundInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 limit;
        uint256 alreadySaled;
    }
    mapping(uint256 => RoundInfo) public wlRound;
    mapping(uint256 => address) public firstBuyerList;

    mapping(address => uint256) public whiteListAlreadyMinted;    // for pre sale
    mapping(address => uint256) public alreadyMinted;    // for public sale
    mapping(address => bool) public eliteClubMember;
    mapping(address => bool) public vipClubMember;

    bytes32 public merkleRoot;

    event BoxMinted(address indexed owner, uint256 indexed gender, uint256 indexed skin, uint256 tokenId);
    event Burned(address indexed owner, uint256 tokenId);
    event MakeOver(address indexed owner, uint256 newTokenId);
    event UnblindAccelerator(address indexed owner, uint256 tokenId, uint256 newTime);
    event UnblindBlindBox(address indexed owner, uint256 tokenId);

    event SetMaxPurchaseLimit(uint256 _maxPurchaseLimit);
    
    event PurchaseBox(address indexed user, uint256 price, uint256 number, uint256[] tokenIds);
    event OwnerMint(address indexed user, uint256 number, uint256[] tokenIds);
    
    function initialize(IMF1155 _metafame1155) initializer public {
        __Ownable_init();
        __Pausable_init();
        __Presalable_init();
        metafame1155 = _metafame1155;

        maxPurchaseLimit = 150;
        maxPurchaseLimitWL = 150;
        _FOR_OWNER = 1112;
        _makeOver = 200000;

        _endsaled = false;

        publicSaleStart = 1656132461;
        publicSaleEnd = 1687639628;

        wlRoundNumber =  1;
        wlRound[1] = RoundInfo({
            startTime: 1656132461,
            endTime: 1687639628,
            limit: 100,
            alreadySaled: 0
        });

        //測試用，價格都1; 0.01 ETH
        ethPerBox = 1 * 10**16;
        ethPerBoxWL = 1 * 10**16;
        makeOverPrice = 1 * 10**16;

        merkleRoot = 0x80a45046196cddc73fc55b60f8dbaace2cda8d9bc47cddbd48ca42a1dcf16b0b;

    }

    function withdraw() public onlyOwner {
        (bool succeed, ) = owner().call{value: address(this).balance}("");
        require(succeed, "Failed to withdraw");
    }

    function getRemainingPurchase(address user) external view returns(uint256) {
        return maxPurchaseLimit - alreadyMinted[user];
    }

    function getWLRemainingPurchase(address user, bytes32[] calldata _merkleProof) external view returns(uint256) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf) , "MetafameSale: The account is not in the whitelist");
        return maxPurchaseLimitWL - whiteListAlreadyMinted[user];
    }

    // For presale
    function purchaseBoxPresale(
        uint256 gender, 
        uint256 skin,
        uint256 number,
        bytes32[] calldata _merkleProof
        ) 
        whenNotPaused 
        whenPresaled 
        nonReentrant 
        public 
        payable
        {
        require(block.timestamp >= wlRound[wlRoundNumber].startTime, "MetafameSale: Not reach pre-sale time");
        require(block.timestamp <= wlRound[wlRoundNumber].endTime, "MetafameSale: End of sale");
        require(!endsaled(), "MetafameSale: End of sale");
        require(wlRound[wlRoundNumber].alreadySaled + number <= wlRound[wlRoundNumber].limit, "MetafameSale: Reach the sale limit of this round");
        require(metafame1155.getAllocatedBoxQuantity() <= metafame1155.getMaxSupply() - _FOR_OWNER, "Metafame1155: No more box can be minted");
        require(whiteListAlreadyMinted[_msgSender()] + number <= maxPurchaseLimitWL, "MetafameSale: Exceeds allowed mint number");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf) , "MetafameSale: The account is not in the whitelist");
        require(gender < 2, "MetafameSale: Wrong Gender Type");
        require(skin < 4, "MetafameSale: Wrong Skin Type");

        uint256[] memory tokenIDArray = new uint256[](number);
        uint256 price;

        require(msg.value == ethPerBoxWL * number, "Insufficient ETH");
        price = ethPerBoxWL  * number;

        eliteClubMember[_msgSender()] = true;
        whiteListAlreadyMinted[_msgSender()] += number;
        wlRound[wlRoundNumber].alreadySaled += number;
        
        uint256 tokenId;
        for(uint256 i=0; i<number ; i++){
            tokenId = _mintBox(_msgSender(), gender, skin);
            firstBuyerList[tokenId] = _msgSender();
            tokenIDArray[i] = tokenId;
        }

        emit PurchaseBox(msg.sender, price, number, tokenIDArray);

    }

    //For public sale
    function purchaseBoxPublicSale(
        uint256 gender,
        uint256 skin,
        uint256 number
        ) 
        whenNotPaused 
        whenNotPresaled 
        nonReentrant 
        external 
        payable
        {
        require(block.timestamp >= publicSaleStart, "MetafameSale: Not reach public sale time");
        require(block.timestamp <= publicSaleEnd, "Status: End of sale");
        require(!endsaled(), "Status: End of sale");
        require(metafame1155.getAllocatedBoxQuantity() <= metafame1155.getMaxSupply() - _FOR_OWNER, "Metafame1155: No more box can be minted");
        require(alreadyMinted[msg.sender] + number <= maxPurchaseLimit, "MetafameSale: Exceeds purchese limit");
        require(gender < 2, "MetafameSale: Wrong Gender Type");
        require(skin < 4, "MetafameSale: Wrong Skin Type");

        uint256[] memory tokenIDArray = new uint256[](number);
        uint256 price;

        require(msg.value == ethPerBox * number, "Insufficient ETH");
        price = ethPerBox  * number;
        
        alreadyMinted[address(msg.sender)] += number;
        eliteClubMember[_msgSender()] = true;

        uint256 tokenId;
        for(uint256 i=0; i<number ; i++){
            tokenId = _mintBox(_msgSender(), gender, skin);
            firstBuyerList[tokenId] = _msgSender();
            tokenIDArray[i] = tokenId;
        }

        emit PurchaseBox(msg.sender, price, number, tokenIDArray);

    }

    function _mintBox(
        address to,
        uint256 gender,
        uint256 skin
        ) 
        whenNotPaused
        private 
        returns (uint256)
        {
        uint256 tokenId = metafame1155.getStepOneIdCounter();

        metafame1155.mint(to, tokenId, 1, gender, skin);
        return tokenId;
    }

    function makeOver( 
        uint256 tokenId
        ) 
        whenNotPaused 
        nonReentrant
        existenceCheck(_msgSender(), tokenId) 
        public 
        payable
        returns(uint256)
        {
        require(tokenId <= metafame1155.getMaxSupply(), "MetafameSale: No more level to upgrade");
        require(msg.value == makeOverPrice, "Insufficient ETH");
        uint256 newTokenId = tokenId + _makeOver;
        
        metafame1155.mintAndBurn(_msgSender(), tokenId, newTokenId);
        vipClubMember[_msgSender()] = true;
        emit MakeOver(_msgSender(), newTokenId);
        return newTokenId;
    }

    // Presale
    function presale() public onlyOwner {
        _presale();
    }
    // Unpresale
    function unpresale() public onlyOwner{
        _unpresale();
    }

    // Pause
    function pause() onlyOwner public  {
        _pause();
        metafame1155.pause();
    }
    // Unpause
    function unpause() onlyOwner public {
        _unpause();
        metafame1155.unpause();
    }

    // Endsale
    function endsale() onlyOwner public  {
        _endsaled = true;
    }
    // Unendsale
    function unEndsale() onlyOwner public {
        _endsaled = false;
    }
    // get endsale status
    function endsaled() public view virtual returns (bool) {
        return _endsaled;
    }

    function getRemainingBoxQuantity() external view returns(uint256){
        return metafame1155.getRemainingBoxQuantity();
    }

    function getAllocatedBoxQuantity() external view returns(uint256) {
        return metafame1155.getAllocatedBoxQuantity();
    }

    function getMaxSupply() external view returns(uint256) {
        return metafame1155.getMaxSupply();
    }
    
    function getStepOneIdCounter() external view returns (uint256) {
        return metafame1155.getStepOneIdCounter();
    } 

    function getBalanceOf(address account, uint256 id) external view returns (uint256) {
        return metafame1155.getBalanceOf(account, id);
    }

    function getRoundStartTime(uint256 roundNumber) external view returns (uint256) {
        return wlRound[roundNumber].startTime;
    }

    function getRoundEndTime(uint256 roundNumber) external view returns (uint256) {
        return wlRound[roundNumber].endTime;
    }

    function getRoundSaleLimit(uint256 roundNumber) onlyOwner external view returns (uint256) {
        return wlRound[roundNumber].limit;
    }

    function getRoundSaled(uint256 roundNumber) onlyOwner external view returns (uint256) {
        return wlRound[roundNumber].alreadySaled;
    }

    function ownerMint(
        address to,
        uint256 gender, 
        uint256 skin,
        uint256 number
        ) 
        onlyOwner
        public 
        {
        require(metafame1155.getAllocatedBoxQuantity() <= metafame1155.getMaxSupply(), "Metafame1155: No more box can be minted");
        require(gender < 2, "MetafameSale: Wrong Gender Type");
        require(skin < 4, "MetafameSale: Wrong Skin Type");

        uint256[] memory tokenIDArray = new uint256[](number);

        uint256 tokenId;
        
        for(uint256 i=0; i<number ; i++){
            tokenId = _mintBox(to, gender, skin);
            tokenIDArray[i] = tokenId;
        }

        emit OwnerMint(msg.sender, number, tokenIDArray);
    }

    function setEthPerBox(uint256 saleType, uint256 weiPrice) onlyOwner whenPaused public {
        if(saleType == 0){
            ethPerBoxWL = weiPrice;
        }
        else{
            ethPerBox = weiPrice;
        }  
    }

    function setMakeOverPrice(uint256 weiPrice) onlyOwner whenPaused public {
        makeOverPrice = weiPrice;
    }

    function setMaxPurchaseLimit(uint256 limit) onlyOwner whenPaused public {
        maxPurchaseLimit = limit;
    }

    function setMaxPurchaseLimitWL(uint256 limit) onlyOwner whenPaused public {
        maxPurchaseLimitWL = limit;
    }

    function setOwnerMintAmount(uint256 limit) onlyOwner whenPaused public {
        _FOR_OWNER = limit;
    }

    function setWlRoundNumber(uint256 roundNumber) onlyOwner whenPaused public {
        wlRoundNumber = roundNumber;
    }

    function setWlRoundInfo(uint256 roundNumber, uint256 _startTime, uint256 _endTime, uint256 _limit) onlyOwner whenPaused public {
        wlRound[roundNumber] = RoundInfo({
            startTime: _startTime,
            endTime: _endTime,
            limit: _limit,
            alreadySaled: 0
        });
    }

    function setPublicSaleStart(uint256 _publicSaleStart) onlyOwner whenPaused public{
        publicSaleStart = _publicSaleStart;
    }
    function setPublicSaleEnd(uint256 _publicSaleEnd) onlyOwner whenPaused public{
        publicSaleEnd = _publicSaleEnd;
    }

    function set1155Address(IMF1155 _metafame1155) onlyOwner whenPaused public {
        metafame1155 = _metafame1155;
    }

    function setMerkleRoot(bytes32 root) onlyOwner whenPaused public {
        merkleRoot = root;
    }

    function getTokenBuyerByRange(uint256 from, uint256 to) onlyOwner public view returns(address[] memory){
        address[] memory addresses = new address[]((to+1) - from);
        uint256 j = 0;
        for (uint256 i = from; i <= to ; ++i) {
            addresses[j] = firstBuyerList[i];
            j++;
        }
        return addresses;
    }
   
    modifier existenceCheck(address account, uint256 tokenId) {
        require(metafame1155.getBalanceOf(account, tokenId) != 0, "ERC1155Metadata: query for nonexistent/not your token");
        _;
    }

}