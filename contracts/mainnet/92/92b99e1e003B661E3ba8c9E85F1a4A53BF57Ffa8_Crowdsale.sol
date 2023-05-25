/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
// File: contracts/libraries/Math.sol


pragma solidity >=0.4.22 <0.9.0;

/**
 * @title Math library
 * @notice The math library.
 * @author Alpha
 **/

 library Math {
  
   /** 
    * @notice a ceiling division
    * @return the ceiling result of division
    */
   function divCeil(uint256 a, uint256 b) internal pure returns(uint256) {
     require(b > 0, "divider must more than 0");
     uint256 c = a / b;
     if (a % b != 0) {
       c = c + 1;
     }
     return c;
   }
 }

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/PriceConsumerV3.sol


pragma solidity >=0.4.22 <0.9.0;


contract PriceConsumerV3 {

    AggregatorV3Interface internal ETHpriceFeed;

    /**
     * Network: Sepolia Testnet
     * Aggregator: ETH/USD
     * ETH: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     
     * Network: Ethereum Mainnet
     * Aggregator: ETH/USD
     * ETH: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {
        ETHpriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }
  
    /**
     * Returns the usdc latest price
     */
    function getETHLatestPrice() public view returns (uint256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ETHpriceFeed.latestRoundData();
        return uint256(price);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/libraries/WadMath.sol


pragma solidity >=0.4.22 <0.9.0;


/**
 * @title WadMath library
 * @notice The wad math library.
 * @author Alpha
 **/

library WadMath {
  using SafeMath for uint256;

  /**
   * @dev one WAD is equals to 10^18
   */
  uint256 internal constant WAD = 1e18;

  /**
   * @notice get wad
   */
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @notice a multiply by b in Wad unit
   * @return the result of multiplication
   */
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(b).div(WAD);
  }

  /**
   * @notice a divided by b in Wad unit
   * @return the result of division
   */
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(WAD).div(b);
  }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// File: contracts/PresaleToken.sol



pragma solidity >=0.4.22 <0.9.0;








// ERC20 token interface is implemented only partially.
// Token transfer is prohibited due to spec (see PRESALE-SPEC.md),
// hence some functions are left undefined:
//  - transfer, transferFrom,
//  - approve, allowance.

contract PresaleToken is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using WadMath for uint256;
    using Math for uint256;

    string public constant name = "Coin7 Presale Token";
    string public constant symbol = "7PT";
    uint public constant decimals = 18;
    uint public constant TOKEN_SUPPLY_LIMIT = 1000000000 * (1 ether / 1 wei);
    uint256 public constant START_PRICE_IN_USDT = 0.01 * 1e8; // 100 7PT per USDT;

    /*/
     *  Token state
    /*/

    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    Phase public currentPhase = Phase.Created;

    /**
     * @dev price oracle to get Real Eth Price.
     */
    PriceConsumerV3 priceOracle;

    uint128 public roundId;
    uint256 public lastTokenPrice;

    uint public totalSupply = 0; // amount of tokens already sold
    uint public totalUSDTLiquidity = 0; // amount of ETH already earn
    uint public totalEthLiqudity = 0; // amount of USDT already earn

    // Since the following variables express the number of percentages and cannot be more than 100,
    // we can put them in one slot
    uint64 public rewardForReffererInSale;

    // Token manager has exclusive priveleges to call administrative
    // functions on this contract.
    address public tokenManager;

    // Gathered funds can be withdrawn only to escrow's address.
    address public escrow;

    // Crowdsale manager has exclusive priveleges to burn presale tokens.
    address public crowdsaleManager;

    address public usdtAddress;

    mapping(address => uint256) private balance;

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "You are not Token Manager");
        _;
    }
    modifier onlyCrowdsaleManager() {
        require(
            msg.sender == crowdsaleManager,
            "You are not Crowdsale Manager"
        );
        _;
    }

    /*/
     *  Events
    /*/

    event TokensPurchased(
        address indexed buyer,
        uint128 indexed roundId,
        uint256 tokensAmount
    );
    event LogBurn(address indexed owner, uint256 value);
    event LogPhaseSwitch(Phase newPhase);

    event SaleRoundEnded(
        uint128 indexed roundId,
        uint256 tokenPrice,
        uint256 tokenSupply,
        uint256 tokensBuyed
    );

    /*/
     *  ReferralProgramming
    /*/

    event Registred(address indexed referral, address indexed referrer);

    /**
     * @dev emitted on set price oracle
     * @param priceOracleAddress the address of the price oracle
     */
    event PriceOracleUpdated(address indexed priceOracleAddress);

    struct ReferralProgram {
        bool isRegistred;
        address userReferrer;
    }

    /**
     * @dev the struct for storing the Referral data
     */
    struct ReferralInfo {
        address whoReferred;
        uint256 rewardETHAmount;
        uint256 rewardUSDTAmount;
        uint256 timeReferred;
    }

    struct SaleRound {
        // There is already a global variable of the current price,
        // but here it is additionally so that it can be tracked in history.
        uint256 tokenPrice;
        uint256 tokenSupply;
        uint256 endTime;
        uint256 tokensBuyed;
    }

    mapping(address => ReferralProgram) public referralProgram;

    /**
     * @dev the mapping from the user to the struct of that ReferralInfo
     * user address => pool
     */
    mapping(address => uint256) public userReferralCount;

    /**
     * @dev the mapping from user address to ReferralInfo to the user data of
     * that referrals
     */
    mapping(address => mapping(uint256 => ReferralInfo)) public referralData;

    mapping(uint128 => SaleRound) public saleRounds;

    /// @param _tokenManager Token manager address.
    /// @param _escrow Admin wallet address.
    /// @param _priceOracle Price Oracle Contract address.
    /// @param _rewardForRefferer Admin wallet address.
    /// @param _usdtAddress USDT address.
    /// @param _roundEndTime First Presale End time.
    /// @param _firstPresaleAmount First Presale Coin7 Amount.
    constructor(
        address _tokenManager,
        address _escrow,
        PriceConsumerV3 _priceOracle,
        uint256 _roundEndTime,
        uint64 _rewardForRefferer,
        address _usdtAddress,
        uint256 _firstPresaleAmount
    ) {
        tokenManager = _tokenManager;
        escrow = _escrow;
        rewardForReffererInSale = _rewardForRefferer;
        usdtAddress = _usdtAddress;
        priceOracle = _priceOracle;

        saleRounds[0] = SaleRound(
            START_PRICE_IN_USDT,
            _firstPresaleAmount * (1 ether / 1 wei),
            _roundEndTime,
            0
        );
        lastTokenPrice = START_PRICE_IN_USDT;
    }

    /**
     * @dev set price oracle of the lending pool. only owner can set the price oracle.
     * @param _oracle the price oracle which will get asset price to the lending pool contract
     */
    function setPriceOracle(PriceConsumerV3 _oracle) external onlyOwner {
        priceOracle = _oracle;
        emit PriceOracleUpdated(address(_oracle));
    }

    /**
     * @dev get the price of eth from chainlink
     */
    function getEthPriceInUSD() public view returns (uint256) {
        require(
            address(priceOracle) != address(0),
            "Platform : price oracle isn't initialized"
        );
        uint256 ethprice;
        ethprice = priceOracle.getETHLatestPrice();
        require(ethprice > 0, "Platform : Eth price isn't correct");
        return ethprice;
    }

    /**
     * @dev get the ether amount
     * @param buyAmount the coin7 amount
     */
    function getEthAmount(uint256 buyAmount) public view returns (uint256) {
        uint256 result;
        uint256 priceEth = getEthPriceInUSD();

        result = buyAmount.mul(lastTokenPrice).wadDiv(priceEth);
        return result;
    }

    /**
     * @dev get the coin7 amount
     * @param ethAmount the eth amount
     */
    function getCoin7Amount(uint256 ethAmount) public view returns (uint256) {
        uint256 result;
        uint256 priceEth = getEthPriceInUSD();
        result = ethAmount.mul(priceEth).wadDiv(lastTokenPrice);
        return result;
    }

    /**
     * @dev get the coin7 amount
     * @param usdtAmount the usdt amount
     */
    function getCoin7AmountWithUSDT(
        uint256 usdtAmount
    ) public view returns (uint256) {
        uint256 result;
        result = usdtAmount.div(lastTokenPrice) * 100000000;
        return result;
    }

    /// @dev Lets buy you some tokens with Eth.
    function buyTokensWithEth(address referrer) public payable {
        // Available only if presale is running.
        require(
            currentPhase == Phase.Running,
            "Platform : Available only if presale is running."
        );
        require(msg.value > 0, "Platform: Not enough Eth balance");
        uint newTokens = getCoin7Amount(msg.value).wadMul(1);
        require(
            totalSupply + newTokens <= TOKEN_SUPPLY_LIMIT,
            "Platform: request exceeds totalSupplyLimit"
        );

        SaleRound storage currentRound = saleRounds[roundId];

        require(
            newTokens <= currentRound.tokenSupply - currentRound.tokensBuyed,
            "Platform: There are not enough tokens left in this round for your transaction"
        );

        registerReferrer(referrer);

        balance[msg.sender] += newTokens;
        totalSupply += newTokens;

        currentRound.tokensBuyed = currentRound.tokensBuyed + newTokens;

        address Refferer = referralProgram[msg.sender].userReferrer;

        if (Refferer != address(0)) {
            // Pay to Referrers
            payable(Refferer).transfer(
                (msg.value / 100) * rewardForReffererInSale
            );

            payable(escrow).transfer(
                msg.value - ((msg.value / 100) * rewardForReffererInSale)
            );
            uint256 ethamount = msg.value -
                ((msg.value / 100) * rewardForReffererInSale);

            totalEthLiqudity += ethamount;

            ReferralInfo memory request;
            request.whoReferred = msg.sender;
            request.rewardETHAmount =
                (msg.value / 100) *
                rewardForReffererInSale;
            request.timeReferred = block.timestamp;
            referralData[Refferer][userReferralCount[Refferer]] = request;
            userReferralCount[Refferer]++;
        } else {
            payable(escrow).transfer(msg.value);
             totalEthLiqudity += msg.value;
        }
        emit TokensPurchased(msg.sender, roundId, newTokens);
    }

    /// @dev Lets buy you some tokens with USDT.
    function buyTokensWithUSDT(uint256 _usdtAmount, address referrer) public {
        // Available only if presale is running.
        require(
            currentPhase == Phase.Running,
            "Platform: Available only if presale is running."
        );
        require(_usdtAmount > 0, "Platform: Not enough usdt balance");
        uint newTokens = getCoin7AmountWithUSDT(_usdtAmount);
        require(
            totalSupply + newTokens <= TOKEN_SUPPLY_LIMIT,
            "Platform: request exceeds totalSupplyLimit"
        );

        SaleRound storage currentRound = saleRounds[roundId];

        require(
            newTokens <= currentRound.tokenSupply - currentRound.tokensBuyed,
            "Platform: There are not enough tokens left in this round for your transaction"
        );

        registerReferrer(referrer);

        balance[msg.sender] += newTokens;
        totalSupply += newTokens;

        currentRound.tokensBuyed = currentRound.tokensBuyed + newTokens;

        address Refferer = referralProgram[msg.sender].userReferrer;

        if (Refferer != address(0)) {
            // Pay to Referrers
            require(
                IERC20(usdtAddress).transferFrom(
                    msg.sender,
                    address(Refferer),
                    (_usdtAmount / 100) * rewardForReffererInSale
                ),
                "buyToken: Transfer token from user to Refferer failed"
            );
            require(
                IERC20(usdtAddress).transferFrom(
                    msg.sender,
                    address(escrow),
                    _usdtAmount - (_usdtAmount / 100) * rewardForReffererInSale
                ),
                "buyToken: Transfer token from user to Escrew failed"
            );
            uint256 usdtamount = _usdtAmount -
                (_usdtAmount / 100) *
                rewardForReffererInSale;

            totalUSDTLiquidity += usdtamount;

            ReferralInfo memory request;
            request.whoReferred = msg.sender;
            request.rewardUSDTAmount =
                (_usdtAmount / 100) *
                rewardForReffererInSale;
            request.timeReferred = block.timestamp;

            referralData[Refferer][userReferralCount[Refferer]] = request;
            userReferralCount[Refferer]++;
        } else {
            require(
                IERC20(usdtAddress).transferFrom(
                    msg.sender,
                    address(escrow),
                    _usdtAmount
                ),
                "buyToken: Transfer token from user to Escrew failed"
            );
            totalUSDTLiquidity += _usdtAmount;
        }
        emit TokensPurchased(msg.sender, roundId, newTokens);
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function burnTokens(address _owner) public onlyCrowdsaleManager {
        // Available only during migration phase
        require(
            currentPhase == Phase.Migrating,
            "Available only during migration phase."
        );

        uint tokens = balance[_owner];
        require(tokens > 0, "Not enough tokens");
        balance[_owner] = 0;
        totalSupply -= tokens;
        emit LogBurn(_owner, tokens);

        // Automatically switch phase when migration is done.
        if (totalSupply == 0) {
            currentPhase = Phase.Migrated;
            emit LogPhaseSwitch(Phase.Migrated);
        }
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) public view returns (uint256) {
        return balance[_owner];
    }

    /*/
     *  Administrative functions
    /*/

    function setPresalePhase(Phase _nextPhase) public onlyTokenManager {
        bool canSwitchPhase = (currentPhase == Phase.Created &&
            _nextPhase == Phase.Running) ||
            (currentPhase == Phase.Running && _nextPhase == Phase.Paused) ||
            // switch to migration phase only if crowdsale manager is set
            ((currentPhase == Phase.Running || currentPhase == Phase.Paused) &&
                _nextPhase == Phase.Migrating &&
                crowdsaleManager != address(0)) ||
            (currentPhase == Phase.Paused && _nextPhase == Phase.Running) ||
            // switch to migrated only if everyting is migrated
            (currentPhase == Phase.Migrating &&
                _nextPhase == Phase.Migrated &&
                totalSupply == 0);

        require(canSwitchPhase == true, "Can not switch phase");
        currentPhase = _nextPhase;
        emit LogPhaseSwitch(_nextPhase);
    }

    function withdrawEther(address to) external onlyTokenManager {
        uint amount = address(escrow).balance;
        require(amount >= 0, "Platform: No ether left to withdraw");
        payable(to).transfer(amount);
    }

    function setCrowdsaleManager(address _mgr) public onlyTokenManager {
        // You can't change crowdsale contract when migration is in progress.
        require(
            currentPhase != Phase.Migrating,
            "You can't change crowdsale contract when migration is in progress."
        );
        crowdsaleManager = _mgr;
    }

    // Private functions
    function startNextSaleRound(
        uint256 _nextPresaleAmount,
        uint256 _nextPresaleEndTime
    ) public onlyTokenManager {
        lastTokenPrice = calculateNewPrice();

        ++roundId;

        saleRounds[roundId] = SaleRound(
            lastTokenPrice,
            _nextPresaleAmount * (1 ether / 1 wei),
            _nextPresaleEndTime,
            0
        );
    }

    // Private functions
    function setEscrewAddress(address _escrew) public onlyTokenManager {
        escrow = _escrew;
    }

    function setTokenManager(address _escrew) public onlyOwner {
        tokenManager = _escrew;
    }

    // Utils functions for calculating new values
    function calculateNewPrice() public view returns (uint256) {
        return (lastTokenPrice + (roundId + 1) * 50000);
    }

    function registerReferrer(address referrer) private {
        address registering = _msgSender();
        if (!referralProgram[registering].isRegistred) {
            if (referrer != address(0)) {
                if (referralProgram[referrer].isRegistred) {
                    referralProgram[registering].userReferrer = referrer;
                }
            }
        }
        referralProgram[registering].isRegistred = true;

        emit Registred(registering, referrer);
    }
}

// File: contracts/Crowdsale.sol


pragma solidity >=0.4.22 <0.9.0;





contract Crowdsale is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public coin7;
    address public presaleToken;
    address public tokenManager;

    event TokensMigrated(address indexed buyer, uint256 tokensAmount);
    event TokensWithDrawed(address indexed buyer, uint256 tokensAmount);

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager);
        _;
    }

    constructor(address _coin7, address _presaletoken, address _tokenManager) {
        coin7 = _coin7;
        presaleToken = _presaletoken;
        tokenManager = _tokenManager;
    }

    function migratePresaleToken() external nonReentrant {
        address buyer = _msgSender();
        uint256 tokensAmount = PresaleToken(presaleToken).balanceOf(buyer);
        require(
            tokensAmount > 0,
            "Platform: ERROR There is no PresaleToken to migrate"
        );
        IERC20(coin7).transfer(buyer, tokensAmount);
        PresaleToken(presaleToken).burnTokens(buyer);

        emit TokensMigrated(buyer, tokensAmount);
    }

    function withdrawCoin7() external nonReentrant onlyTokenManager {
        address buyer = _msgSender();
        uint256 tokensAmount = IERC20(coin7).balanceOf(address(this));
        require(
            tokensAmount > 0,
            "Platform: ERROR There is no Coin7 to withDraw"
        );
        IERC20(coin7).transfer(buyer, tokensAmount);

        emit TokensWithDrawed(buyer, tokensAmount);
    }

    function setTokenAddress(address _coin7) public onlyTokenManager {
        coin7 = _coin7;
    }

    function setPresaleTokenAddress(address _presaleToken) public onlyTokenManager {
        presaleToken = _presaleToken;
    }
}