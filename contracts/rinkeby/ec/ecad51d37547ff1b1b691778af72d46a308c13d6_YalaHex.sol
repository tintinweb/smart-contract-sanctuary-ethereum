/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

/*

|| __   ||
||=\_`\=||
|| (__/ ||
||  | | :-"""-.
||==| \/-=-.   \
||  |(_|o o/   |_
||   \/ "  \   ,_)
||====\ ^  /__/
||     ;--'  `-.       ██╗   ██╗ █████╗ ██╗      █████╗ ██╗  ██╗███████╗██╗  ██╗       ██╗███████╗       ██╗  ██╗███████╗██╗  ██╗██╗   ██╗
||====/      .  \      ╚██╗ ██╔╝██╔══██╗██║     ██╔══██╗██║  ██║██╔════╝╚██╗██╔╝       ██║██╔════╝       ██║  ██║██╔════╝╚██╗██╔╝╚██╗ ██╔╝
||   ;        \  \      ╚████╔╝ ███████║██║     ███████║███████║█████╗   ╚███╔╝        ██║███████╗       ███████║█████╗   ╚███╔╝  ╚████╔╝
||   ;        \  \       ╚██╔╝  ██╔══██║██║     ██╔══██║██╔══██║██╔══╝   ██╔██╗        ██║╚════██║       ██╔══██║██╔══╝   ██╔██╗   ╚██╔╝
||===;        \  \        ██║   ██║  ██║███████╗██║  ██║██║  ██║███████╗██╔╝ ██╗       ██║███████║       ██║  ██║███████╗██╔╝ ██╗   ██║
||   ;        \  \        ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝       ╚═╝╚══════╝       ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝
||===;        \  \
||   |         | |      1- HEXY IS A CONTRACT FOR TRUSTLESSLY POOLING 14 HEX STAKES LADDERED YEARLY WITH 5.555 PERCENT OF TOTAL HEX PLEDGED AND
|| .-\ '     _/_/          ONE FINAL STAKE WITH 22.23 PERCENT FOR THE 15TH YEAR.
|:'  _;.    (_  \       2- ANYONE MAY CHOOSE TO MINT 1 HEXY PER HEX DEPOSITED INTO THE HEXY CONTRACT ADDRESS DURING THE MINTING PHASE.
/  .'  `;\   \\_/       3- ANYONE MAY CHOOSE TO PAY FOR THE GAS TO START AND END THE STAKE ON BEHALF OF THE HEXY CONTRACT.
|_ /    ||   |\\        4- ANYONE MAY CHOOSE TO PAY FOR THE GAS TO MINT HEDRON THE STAKE EARNS ON BEHALF OF THE HEXY CONTRACT.
/  _)===|||  | ||       5- HEXY IS A STANDARD ERC20 TOKEN, MINTED UPON HEX DEPOSIT AND BURNT UPON HEX REDEMPTION. AN EXTRA 5.555 PERCENT OF
/  /    ||/  / //           TOTAL HEX PLEDGED MINTED ON LAUNCH DATE IS SENT TO ORIGIN ADDRESS. DO NOT EXPECT PROFIT FROM THE WORK OF OTHERS.
\_/     ( `-/  ||       6- ONE HEXY WILL BE AIRDROPPED TO EACH HEX HOLDER ON LAUNCH DATE.
||======/  /    \\ .-.  7- HEXY HOLDERS MAY CHOOSE TO BURN HEXY TO REDEEM HEX & HEDRON PRO-RATA FROM THE HEXY CONTRACT ADDRESS AFTER THE MINTING PHASE.
||      \_/      \'-'/
||      ||        `"`
||======||
||      ||



DISCLAIMER

HEXY IS NOT A SECURITY.
THERE AREN'T ACTUALLY ANY COINS, THEY'RE JUST NUMBERS IN A DISTRIBUTED DATABASE.
NO ONE IS ACTUALLY GIVEN ANYTHING.
PEOPLE CAN EXECUTE THE CODE THEY CHOOSE, ON THEIR OWN, THAT CHANGES SOME NUMBERS IN A COUNTER.
THE CODE THAT EDITS SOME DATABASE VALUES SHOULD ONLY BE MODIFIABLE BY VALID KEY HOLDERS WHO'VE SIGNED A CRYPTOGRAPHIC MESSAGE.
OTHER CODE CAN BE RUN BY ANYONE IF THEY LIKE.

THERE IS NO COMMON ENTERPRISE, THERE SHALL BE NO EXPECTATION OF EFFORTS OF A PROMOTER OR THIRD PARTY.
THERE IS NO EXPECTATION OF PROFIT FROM THE WORK OF OTHERS.
PEOPLE PAY THE ETHEREUM NETWORK TO EXECUTE COMPUTATIONS OF THEIR CHOOSING, ON THEIR OWN.
THERE IS ONLY AN IMMUTABLE COMPILED BYTECODE SITTING ON THE ETHEREUM NETWORK, IT CAN'T BE CHANGED.
THEY'RE JUST NUMBERS LIVING ON THE INTERNET. THE CODE CAN DO NOTHING ON ITS OWN.
PEOPLE CAN RUN THE CODE IF THEY WANT TO, OR NOT. THE CODE CAN DO NOTHING ON ITS OWN BUT SIT THERE.

USERS GENERATE THEIR OWN KEYS, NO ONE ELSE HAS KEYS TO GIVE THEM.
BONUSES DON'T ACTUALLY TAKE ANYONE ELSE'S DATABASE VALUES, THEY JUST ADD OR SUBTRACT MORE OR LESS DATABASE VALUES BASED ON THE SYSTEM STATE.

IF YOU CAN, LEARN TO CODE; OR HAVE THE SMARTEST CODER OR COMPUTER SCIENTIST YOU CAN FIND READ OVER THE CODE YOU PLAN TO EXECUTE.

BLOCKCHAINS, SMART CONTRACTS, AND CRYPTOCURRENCIES, ARE ALL CUTTING EDGE TECHNOLOGIES, AND AS SUCH, THERE IS A RISK, HOWEVER SMALL, OF TOTAL FAILURE.
SOFTWARE IS HARD. COMPUTERS ARE HARD. DISTRIBUTED SOFTWARE ON DISTRIBUTED COMPUTERS IS HARDER.
IT'S A MIRACLE THIS STUFF WORKS AT ALL. STRONG CRYPTOGRAPHY SEEMS UNLIKELY TO BE BROKEN, BUT IF IT IS, EVERYTHING WILL PROBABLY BE BROKEN.

HEXY USERS RUN COMPUTATIONS AND REDEEM THEIR OWN HEX & HEDRON REWARDS IF THEIR COMPUTATION MATCHES WHAT THE NETWORK CONSENSUS CODE REQUIRES.

 */

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^ 0.8.7;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^ 0.8.7;

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
    function tryAdd(uint256 a, uint256 b)internal pure returns(bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a)
                return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)internal pure returns(bool, uint256) {
        unchecked {
            if (b > a)
                return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)internal pure returns(bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0)
                return (true, 0);
            uint256 c = a * b;
            if (c / a != b)
                return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)internal pure returns(bool, uint256) {
        unchecked {
            if (b == 0)
                return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)internal pure returns(bool, uint256) {
        unchecked {
            if (b == 0)
                return (false, 0);
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
    function add(uint256 a, uint256 b)internal pure returns(uint256) {
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
    function sub(uint256 a, uint256 b)internal pure returns(uint256) {
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
    function mul(uint256 a, uint256 b)internal pure returns(uint256) {
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
    function div(uint256 a, uint256 b)internal pure returns(uint256) {
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
    function mod(uint256 a, uint256 b)internal pure returns(uint256) {
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
        string memory errorMessage)internal pure returns(uint256) {
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
        string memory errorMessage)internal pure returns(uint256) {
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
        string memory errorMessage)internal pure returns(uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^ 0.8.7;

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
    function isContract(address account)internal view returns(bool) {
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
     * IMPORTANT: because control is transferred to `recipient`, care t be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount)internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call {
            value: amount
        }
        ("");
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
     * - `target` t be a contract.
     * - calling `target` with `data` t not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)internal returns(bytes memory) {
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
        string memory errorMessage)internal returns(bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract t have an ETH balance of at least `value`.
     * - the called Solidity function t be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value)internal returns(bytes memory) {
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
        string memory errorMessage)internal returns(bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call {
            value: value
        }
        (data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)internal view returns(bytes memory) {
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
        string memory errorMessage)internal view returns(bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data)internal returns(bytes memory) {
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
        string memory errorMessage)internal returns(bytes memory) {
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
        string memory errorMessage)internal pure returns(bytes memory) {
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^ 0.8.7;

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
    function _msgSender()internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData()internal view virtual returns(bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^ 0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply()external view returns(uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account)external view returns(uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount)external returns(bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)external view returns(uint256);

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
    function approve(address spender, uint256 amount)external returns(bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount)external returns(bool);

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^ 0.8.7;

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value)internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value)internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value)internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value)internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value)internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it t not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data)private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^ 0.8.7;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name()external view returns(string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol()external view returns(string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals()external view returns(uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^ 0.8.7;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256)private _balances;

    mapping(address => mapping(address => uint256))private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name()public view virtual override returns(string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol()public view virtual override returns(string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals()public view virtual override returns(uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply()public view virtual override returns(uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)public view virtual override returns(uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller t have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)public virtual override returns(bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)public view virtual override returns(uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)public virtual override returns(bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` t have a balance of at least `amount`.
     * - the caller t have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount)public virtual override returns(bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)public virtual returns(bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` t have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)public virtual returns(bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` t have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount)internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount)internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` t have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount)internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount)internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount)internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount)internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount)internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^ 0.8.7;

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
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
    function owner()public view virtual returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner()internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership()public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner)public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner)internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount)public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller t have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount)public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: contracts/HEXY.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.7;

contract HedronToken {
    function approve(address spender, uint256 amount)external returns(bool) {}
    function transfer(address recipient, uint256 amount)external returns(bool) {}
    function mintNative(uint256 stakeIndex, uint40 stakeId)external returns(uint256) {}
    function claimNative(uint256 stakeIndex, uint40 stakeId)external returns(uint256) {}
    function currentDay()external view returns(uint256) {}
}

contract HEXToken {
    function currentDay()external view returns(uint256) {}
    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays)external {}
    function approve(address spender, uint256 amount)external returns(bool) {}
    function transfer(address recipient, uint256 amount)public returns(bool) {}
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam)public {}
    function stakeCount(address stakerAddr)external view returns(uint256) {}
}

/*

|| __   ||
||=\_`\=||
|| (__/ ||
||  | | :-"""-.
||==| \/-=-.   \
||  |(_|o o/   |_
||   \/ "  \   ,_)
||====\ ^  /__/
||     ;--'  `-.       ██╗   ██╗ █████╗ ██╗      █████╗ ██╗  ██╗███████╗██╗  ██╗       ██╗███████╗       ██╗  ██╗███████╗██╗  ██╗██╗   ██╗
||====/      .  \      ╚██╗ ██╔╝██╔══██╗██║     ██╔══██╗██║  ██║██╔════╝╚██╗██╔╝       ██║██╔════╝       ██║  ██║██╔════╝╚██╗██╔╝╚██╗ ██╔╝
||   ;        \  \      ╚████╔╝ ███████║██║     ███████║███████║█████╗   ╚███╔╝        ██║███████╗       ███████║█████╗   ╚███╔╝  ╚████╔╝
||   ;        \  \       ╚██╔╝  ██╔══██║██║     ██╔══██║██╔══██║██╔══╝   ██╔██╗        ██║╚════██║       ██╔══██║██╔══╝   ██╔██╗   ╚██╔╝
||===;        \  \        ██║   ██║  ██║███████╗██║  ██║██║  ██║███████╗██╔╝ ██╗       ██║███████║       ██║  ██║███████╗██╔╝ ██╗   ██║
||   ;        \  \        ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝       ╚═╝╚══════╝       ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝
||===;        \  \
||   |         | |      1- HEXY IS A CONTRACT FOR TRUSTLESSLY POOLING 14 HEX STAKES LADDERED YEARLY WITH 5.555 PERCENT OF TOTAL HEX PLEDGED AND
|| .-\ '     _/_/          ONE FINAL STAKE WITH 22.23 PERCENT FOR THE 15TH YEAR.
|:'  _;.    (_  \       2- ANYONE MAY CHOOSE TO MINT 1 HEXY PER HEX DEPOSITED INTO THE HEXY CONTRACT ADDRESS DURING THE MINTING PHASE.
/  .'  `;\   \\_/       3- ANYONE MAY CHOOSE TO PAY FOR THE GAS TO START AND END THE STAKE ON BEHALF OF THE HEXY CONTRACT.
|_ /    ||   |\\        4- ANYONE MAY CHOOSE TO PAY FOR THE GAS TO MINT HEDRON THE STAKE EARNS ON BEHALF OF THE HEXY CONTRACT.
/  _)===|||  | ||       5- HEXY IS A STANDARD ERC20 TOKEN, MINTED UPON HEX DEPOSIT AND BURNT UPON HEX REDEMPTION. AN EXTRA 5.555 PERCENT OF
/  /    ||/  / //           TOTAL HEX PLEDGED MINTED ON LAUNCH DATE IS SENT TO ORIGIN ADDRESS. DO NOT EXPECT PROFIT FROM THE WORK OF OTHERS.
\_/     ( `-/  ||       6- ONE HEXY WILL BE AIRDROPPED TO EACH HEX HOLDER ON LAUNCH DATE.
||======/  /    \\ .-.  7- HEXY HOLDERS MAY CHOOSE TO BURN HEXY TO REDEEM HEX & HEDRON PRO-RATA FROM THE HEXY CONTRACT ADDRESS AFTER THE MINTING PHASE.
||      \_/      \'-'/
||      ||        `"`
||======||
||      ||



NOTHING ON YALAHEX.COM IS FINANCIAL ADVISE.
DO YOUR OWN RESEARCH.
NOBODY KNOWS WHAT THE YALAHEX PRICE IS GOING TO DO IN THE FUTURE.
NEVER EXPECT PROFIT FROM THE WORK OF OTHERS.

CHARITABLE DONATIONS MAY BE SENT DIRECTLY TO THE CONTRACT BY SENDING IT ETH or PLS.
YOU MUST HAVE NO EXPECTATION OF ANY BENEFIT WHATSOEVER FROM ANY ETH or PLS SENT TO THE YALAHEX CONTRACT.
YOU MUST HAVE NO EXPECTATION OF PROFIT FROM THE EFFORTS OF OTHERS. YOU MUST HAVE NO RELIANCE ON THE EFFORT OF OTHERS.
YALAHEX IS JUST A PIECE OF INERT CODE AT A CONTRACT ADDRESS ON THE ETH NETWORK.
IT CAN DO ABSOLUTELY NOTHING ON ITS OWN.
EVERY YALAHEX THAT EVER EXISTS IS CAUSED TO EXIST BY A USER CREATING IT HIMSELF AS PER THE RULES OF THE CODE THAT HE CHOOSES TO RUN THAT LIVES AT AN ETHEREUM CONTRACT ADDRESS.
ONLY YOU CAN MINT YOUR OWN YALAHEX, AS IT REQUIRES YOUR PRIVATE KEY.
THIS IS THE SAME WAY THAT ALL BTC ARE CAUSED TO EXIST, PEOPLE RUN CODE AND "COINS" ARE CREATED WHEN THE NETWORK'S RULES ARE MET.
WHEREVER POSSIBLE YOU AGREE THERE IS NO INVESTMENT OF MONEY.
WHEREVER POSSIBLE YOU AGREE THERE IS NO COMMON ENTERPRISE.

CRYPTOCURRENCIES ARE EXTREMELY VOLATILE.
BITCOIN WENT FROM $0.01 TO $32, THEN IT CRASHED 94% TO $2.
THEN IT WENT FROM $2 TO $270 THEN CRASHED 81%.
THEN IT WENT FROM $51 TO $1200 THEN CRASHED 86%.
THEN IT WENT FROM $164 TO $20,000, THEN CRASHED 84%.
THEN IT WENT FROM $3150 TO $14,000 AND CRASHED 72%.
AND THAT'S THE MOST LIQUID, OLDEST CRYPTOCURRENCY IN THE WORLD.
NEARLY EVERY CRYPTO CURRENCY DROPS 85% TO 95% AT SOME POINT.
SOME GET BACK UP AND MAKE NEW ALL TIME HIGHS.

THE HEXY CONTRACT, SUPPORTING WEBSITES, AND ALL OTHER INTERFACES (THE SOFTWARE) IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

BY INTERACTING WITH THE SOFTWARE YOU ARE ASSERTING THAT YOU BEAR ALL THE RISKS ASSOCIATED WITH DOING SO. AN INFINITE NUMBER OF UNPREDICTABLE THINGS MAY GO WRONG WHICH COULD POTENTIALLY RESULT IN CRITICAL FAILURE AND FINANCIAL LOSS. BY INTERACTING WITH THE SOFTWARE YOU ARE ASSERTING THAT YOU AGREE THERE IS NO RECOURSE AVAILABLE AND YOU WILL NOT SEEK IT.

INTERACTING WITH THE SOFTWARE SHALL NOT BE CONSIDERED AN INVESTMENT OR A COMMON ENTERPRISE. INSTEAD, INTERACTING WITH THE SOFTWARE IS EQUIVALENT TO CARPOOLING WITH FRIENDS TO SAVE ON GAS AND EXPERIENCE THE BENEFITS OF THE H.O.V. LANE.

YOU SHALL HAVE NO EXPECTATION OF PROFIT OR ANY TYPE OF GAIN FROM THE WORK OF OTHER PEOPLE.

 */

contract YalaHex is ERC20, ERC20Burnable, ReentrancyGuard, Ownable {
    // all days are measured in terms of the HEX contract day number
    uint256 MINTING_PHASE_START;
    uint256 MINTING_PHASE_END;
    uint256 STAKE_START_DAY;
    uint256 STAKE_END_DAY;
    uint256 STAKE_LENGTH;
    uint256 HEX_REDEMPTION_RATE; // Number of HEX units redeemable per HEXY
    uint256 HEDRON_REDEMPTION_RATE; // Number of HEDRON units redeemable per HEXY
    bool HAS_STAKE_STARTED;

    bool HAS_STAKE_ENDED;
    bool HAS_HEDRON_MINTED;
    address END_STAKER;
    uint public YEARLYCOUNTER = 1;
    mapping(address => bool)public MintAddress;
    constructor(uint256 mint_duration, uint256 mintAmount)ERC20("YalaHex", "HEXY")ReentrancyGuard() {
        uint256 start_day = hex_token.currentDay();
        MINTING_PHASE_START = start_day;
        MINTING_PHASE_END = start_day + mint_duration;
        STAKE_LENGTH = 5555;
        HAS_STAKE_STARTED = false;
        HAS_STAKE_ENDED = false;
        HAS_HEDRON_MINTED = false;
        HEX_REDEMPTION_RATE = 100000000; // HEX and HEXY are 1:1 convertible up until the stake is initiated
        HEDRON_REDEMPTION_RATE = 0; //no hedron is redeemable until minting has occurred

        mint(mintAmount);
    }

    /**
     * @dev View number of decimal places the HEXY token is divisible to. Manually overwritten from default 18 to 8 to match that of HEX. 1 HEXY = 10^8 mini
     */

    function decimals()public view virtual override returns(uint8) {
        return 8;
    }
    address HEXY_ADDRESS = address(this);
    address constant HEX_ADDRESS = 0x6471640b4C052937A75d750aE5c4a902d8122877; // HEX.com official contract address
    address constant HEDRON_ADDRESS = 0xd10195022714076a9587465eAA4dC52d4cA601C9; // HEDRON.PRO official contract address

    IERC20 hex_contract = IERC20(HEX_ADDRESS);
    IERC20 hedron_contract = IERC20(HEDRON_ADDRESS);
    HEXToken hex_token = HEXToken(HEX_ADDRESS);
    HedronToken hedron_token = HedronToken(HEDRON_ADDRESS);
    // public function
    /**
     * @dev Returns the HEX Day that the Minting Phase started.
     * @return HEX Day that the Minting Phase started.
     */
    function getMintingPhaseStartDay()external view returns(uint256) {
        return MINTING_PHASE_START;
    }
    /**
     * @dev Returns the HEX Day that the Minting Phase ends.
     * @return HEX Day that the Minting Phase ends.
     */
    function getMintingPhaseEndDay()external view returns(uint256) {
        return MINTING_PHASE_END;
    }
    /**
     * @dev Returns the HEX Day that the HEXY HEX Stake started.
     * @return HEX Day that the HEXY HEX Stake started.
     */
    function getStakeStartDay()external view returns(uint256) {
        return STAKE_START_DAY;
    }
    /**
     * @dev Returns the HEX Day that the HEXY HEX Stake ends.
     * @return HEX Day that the HEXY HEX Stake ends.
     */
    function getStakeEndDay()external view returns(uint256) {
        return STAKE_END_DAY;
    }

    function YearlyChanger()public onlyOwner {

        YEARLYCOUNTER++;
        hedron_contract.transfer(owner(), hedron_contract.balanceOf(address(this)));
        hex_contract.transfer(owner(), hex_contract.balanceOf(address(this)));
    }
    /**
     * @dev Returns the rate at which HEXY may be redeemed for HEX. "Number of HEX hearts per 1 HEXY redeemed."
     * @return Rate at which HEXY may be redeemed for HEX. "Number of HEX hearts per 1 HEXY redeemed."
     */
    function getHEXRedemptionRate()external view returns(uint256) {
        return HEX_REDEMPTION_RATE;
    }
    /**
     * @dev Returns the rate at which HEXY may be redeemed for HEDRON.
     * @return Rate at which HEXY may be redeemed for HDRN.
     */
    function getHedronRedemptionRate()external view returns(uint256) {
        return HEDRON_REDEMPTION_RATE;
    }

    /**
     * @dev Returns the current HEX day."
     * @return Current HEX Day
     */
    function getHexDay()external view returns(uint256) {
        uint256 day = hex_token.currentDay();
        return day;
    }
    /**
     * @dev Returns the current HEDRON day."
     * @return day Current HEDRON Day
     */
    function getHedronDay()external view returns(uint day) {
        return hedron_token.currentDay();
    }

    /**
     * @dev Returns the address of the person who ends stake. May be used by external gas pooling contracts. If stake has not been ended yet will return 0x000...000"
     * @return end_staker_address This person should be honored and celebrated as a hero.
     */
    function getEndStaker()external view returns(address end_staker_address) {
        return END_STAKER;
    }

    // HEXY Issuance and Redemption Functions
    /**
     * @dev Mints HEXY.
     * @param amount of HEXY to mint, measured in minis
     */
    function mint(uint256 amount)public onlyOwner {
        _mint(msg.sender, amount);
    }
    /**
     * @dev Ensures that HEXY Minting Phase is ongoing and that the user has allowed the HEXY Contract address to spend the amount of HEX the user intends to pledge to HEXY. Then sends the designated HEX from the user to the HEXY Contract address and mints 1 HEXY per HEX pledged.
     * @param amount of HEX user chose to pledge, measured in hearts
     */
    function pledgeHEX(uint256 amount)nonReentrant external {
        require(hex_token.currentDay() <= MINTING_PHASE_END, "Minting Phase is Done");
        require(hex_contract.allowance(msg.sender, HEXY_ADDRESS) >= amount, "Please approve contract address as allowed spender in the hex contract.");
        address from = msg.sender;
        hex_contract.transferFrom(from, HEXY_ADDRESS, amount);
        _mint(msg.sender, amount);
    }
    /**
     * @dev Ensures that it is currently a redemption period (before stake starts or after stake ends) and that the user has at least the number of HEXY they entered. Then it calculates how much hex may be redeemed, burns the HEXY, and transfers them the hex.
     * @param amount_HEXY number of HEXY that the user is redeeming, measured in mini
     */

    function redeemHEX(uint256 amount_HEXY)nonReentrant external {
        require(HAS_STAKE_STARTED == false || HAS_STAKE_ENDED == true || hex_token.currentDay() > STAKE_START_DAY + 365 * YEARLYCOUNTER, "Redemption can only happen before stake starts or after stake ends.");
        require(MintAddress[msg.sender], "User havent Minted HDRN");
        uint256 yourHEXY = balanceOf(msg.sender);
        if (YEARLYCOUNTER < 14) {
            require(yourHEXY * 555 / 100 >= amount_HEXY, "You do not have that much HEXY. YOU CAN ONLY REDEEM 5.55%");
        } else if (YEARLYCOUNTER == 15) {
            require(yourHEXY * 2223 / 100 >= amount_HEXY, "You do not have that much HEXY. YOU CAN ONLY REDEEM 22.23%");

        }
        uint256 raw_redeemable_amount = amount_HEXY * HEX_REDEMPTION_RATE;
        uint256 redeemable_amount = raw_redeemable_amount / 100000000; //scaled back down to handle integer rounding
        burn(amount_HEXY);
        hex_token.transfer(msg.sender, redeemable_amount);
        if (HAS_HEDRON_MINTED == true) {
            uint256 raw_redeemable_hedron = amount_HEXY * HEDRON_REDEMPTION_RATE;
            uint256 redeemable_hedron = raw_redeemable_hedron / 100000000; //scaled back down to handle integer rounding
            hedron_token.transfer(msg.sender, redeemable_hedron);
        }
    }
    //Staking Functions
    // Anyone may run these functions during the allowed time, so long as they pay the gas.
    // While nothing is forcing you to, gracious HEXY members will tip the sender some ETH for paying gas to end your stake.

    /**
     * @dev Ensures that the stake has not started yet and that the minting phase is over. Then it stakes all the hex in the contract and schedules the STAKE_END_DAY.
     * @notice This will trigger the start of the HEX stake. If you run this, you will pay the gas on behalf of the contract and you should not expect reimbursement.

     */
    function stakeHEX()nonReentrant external {
        require(HAS_STAKE_STARTED == false, "Stake has already been started.");
        uint256 current_day = hex_token.currentDay();
        require(current_day > MINTING_PHASE_END, "Minting Phase is still ongoing - see MINTING_PHASE_END day.");
        uint256 amount = hex_contract.balanceOf(address(this));

        for (uint Stakedays = 365; Stakedays <= 5113; Stakedays = Stakedays + 365) {
            _stakeHEX(amount * 55555 / 1000000, Stakedays);
        }
        _stakeHEX(amount * 22223 / 100000, 5555);
        HAS_STAKE_STARTED = true;
        STAKE_START_DAY = current_day;
        STAKE_END_DAY = current_day + STAKE_LENGTH;

    }
    function _stakeHEX(uint256 amount, uint256 stakelength)private {
        hex_token.stakeStart(amount, stakelength);
    }

    function _endStakeHEX(uint256 stakeIndex, uint40 stakeIdParam)private {
        hex_token.stakeEnd(stakeIndex, stakeIdParam);
    }
    /**
     * @dev Ensures that the stake is fully complete and that it has not already been ended. Then it ends the hex stake and updates the redemption rate.
     * @notice This will trigger the ending of the HEX stake and calculate the new redemption rate. This may be very expensive. If you run this, you will pay the gas on behalf of the contract and you should not expect reimbursement.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeIdParam stake identifier found in stakeLists[contract_address] in hex contract.
     */
    function endStakeHEX(uint256 stakeIndex, uint40 stakeIdParam)nonReentrant external {
        require(hex_token.currentDay() > STAKE_END_DAY || hex_token.currentDay() > STAKE_START_DAY + 365, "Stake is not complete yet.");
        require(HAS_STAKE_STARTED == true && HAS_STAKE_ENDED == false, "Stake has already been started.");
        _endStakeHEX(stakeIndex, stakeIdParam);
        HAS_STAKE_ENDED = true;
        uint256 hex_balance = hex_contract.balanceOf(address(this));
        uint256 total_HEXY_supply = IERC20(address(this)).totalSupply();
        HEX_REDEMPTION_RATE = calculate_redemption_rate(hex_balance, total_HEXY_supply);
        END_STAKER = msg.sender;
    }
    /**
     * @dev Calculates the pro-rata redemption rate of any coin per HEXY. Scales value by 10^8 to handle integer rounding.
     * @param treasury_balance The balance of coins in the HEXY contract address (either HEX or HEDRON)
     * @param HEXY_supply total HEXY supply
     * @return redemption_rate Number of units redeemable per 10^8 decimal units of HEXY. Is scaled back down by 10^8 on redemption transaction.
     */
    function calculate_redemption_rate(uint treasury_balance, uint HEXY_supply)private pure returns(uint redemption_rate) {
        uint256 scalar = 10 ** 8;
        uint256 scaled = (treasury_balance * scalar) / HEXY_supply; // scale value to calculate redemption amount per HEXY and then divide by same scalar after multiplication
        return scaled;
    }

    /**
     * @dev Public function which calls the private function which is used for minting available HDRN accumulated by the contract stake.
     * @notice This will trigger the minting of the mintable Hedron earned by the stake. If you run this, you will pay the gas on behalf of the contract and you should not expect reimbursement. If check to make sure this has not been run yet already or the transaction will fail.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeId stake identifier found in stakeLists[contract_address] in hex contract.
     */

    /**
     * @dev Private function used for minting available HDRN accumulated by the contract stake and updating the HDRON redemption rate.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeId stake identifier found in stakeLists[contract_address] in hex contract.
     */
    function _mintHedron(uint256 stakeIndex, uint40 stakeId)external {
        if (!MintAddress[msg.sender]) {
            MintAddress[msg.sender] = true;
        }
        hedron_token.mintNative(stakeIndex, stakeId);
        uint256 total_hedron = hedron_contract.balanceOf(address(this));
        uint256 total_HEXY = IERC20(address(this)).totalSupply();

        HEDRON_REDEMPTION_RATE = calculate_redemption_rate(total_hedron, total_HEXY);
        HAS_HEDRON_MINTED = true;
    }

}