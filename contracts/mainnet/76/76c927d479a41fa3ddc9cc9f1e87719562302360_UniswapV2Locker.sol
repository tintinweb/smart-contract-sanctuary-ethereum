/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// File: contracts/interfaces/IUniswapV2Factory.sol



pragma solidity ^0.8.0;



interface IUniswapV2Factory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);



    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);



    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);



    function createPair(address tokenA, address tokenB) external returns (address pair);



    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

}


// File: contracts/interfaces/IUniswapV2Pair.sol



pragma solidity ^0.8.0;



interface IUniswapV2Pair {

    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);



    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);



    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);



    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);



    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;



    event Mint(address indexed sender, uint amount0, uint amount1);

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    event Swap(

        address indexed sender,

        uint amount0In,

        uint amount1In,

        uint amount0Out,

        uint amount1Out,

        address indexed to

    );

    event Sync(uint112 reserve0, uint112 reserve1);



    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);



    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;



    function initialize(address, address) external;

}


// File: contracts/interfaces/ISignataRight.sol



pragma solidity ^0.8.0;



interface ISignataRight {

    function holdsTokenOfSchema(address holder, uint256 schemaId) external view returns (bool);

}
// File: contracts/@openzeppelin/contracts/security/ReentrancyGuard.sol



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


// File: contracts/@openzeppelin/contracts/utils/Context.sol



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


// File: contracts/@openzeppelin/contracts/access/Ownable.sol



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


// File: contracts/@openzeppelin/contracts/utils/Address.sol



// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)



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

}


// File: contracts/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol



// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)



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


// File: contracts/@openzeppelin/contracts/token/ERC20/IERC20.sol



// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



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

    function transferFrom(

        address from,

        address to,

        uint256 amount

    ) external returns (bool);

}


// File: contracts/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)



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



    function safeTransfer(

        IERC20 token,

        address to,

        uint256 value

    ) internal {

        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));

    }



    function safeTransferFrom(

        IERC20 token,

        address from,

        address to,

        uint256 value

    ) internal {

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

        uint256 value

    ) internal {

        // safeApprove should only be called when setting an initial allowance,

        // or when resetting it to zero. To increase and decrease it, use

        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'

        require(

            (value == 0) || (token.allowance(address(this), spender) == 0),

            "SafeERC20: approve from non-zero to non-zero allowance"

        );

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));

    }



    function safeIncreaseAllowance(

        IERC20 token,

        address spender,

        uint256 value

    ) internal {

        uint256 newAllowance = token.allowance(address(this), spender) + value;

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));

    }



    function safeDecreaseAllowance(

        IERC20 token,

        address spender,

        uint256 value

    ) internal {

        unchecked {

            uint256 oldAllowance = token.allowance(address(this), spender);

            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");

            uint256 newAllowance = oldAllowance - value;

            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));

        }

    }



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

        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that

        // the target address contains contract code and also asserts for success in the low-level call.



        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            // Return data is optional

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");

        }

    }

}


// File: contracts/@openzeppelin/contracts/utils/math/SafeMath.sol



// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)



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


// File: contracts/@openzeppelin/contracts/utils/structs/EnumerableSet.sol



// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)



pragma solidity ^0.8.0;



/**

 * @dev Library for managing

 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive

 * types.

 *

 * Sets have the following properties:

 *

 * - Elements are added, removed, and checked for existence in constant time

 * (O(1)).

 * - Elements are enumerated in O(n). No guarantees are made on the ordering.

 *

 * ```

 * contract Example {

 *     // Add the library methods

 *     using EnumerableSet for EnumerableSet.AddressSet;

 *

 *     // Declare a set state variable

 *     EnumerableSet.AddressSet private mySet;

 * }

 * ```

 *

 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)

 * and `uint256` (`UintSet`) are supported.

 *

 * [WARNING]

 * ====

 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.

 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.

 *

 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.

 * ====

 */

library EnumerableSet {

    // To implement this library for multiple types with as little code

    // repetition as possible, we write it in terms of a generic Set type with

    // bytes32 values.

    // The Set implementation uses private functions, and user-facing

    // implementations (such as AddressSet) are just wrappers around the

    // underlying Set.

    // This means that we can only create new EnumerableSets for types that fit

    // in bytes32.



    struct Set {

        // Storage of set values

        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0

        // means a value is not in the set.

        mapping(bytes32 => uint256) _indexes;

    }



    /**

     * @dev Add a value to a set. O(1).

     *

     * Returns true if the value was added to the set, that is if it was not

     * already present.

     */

    function _add(Set storage set, bytes32 value) private returns (bool) {

        if (!_contains(set, value)) {

            set._values.push(value);

            // The value is stored at length-1, but we add 1 to all indexes

            // and use 0 as a sentinel value

            set._indexes[value] = set._values.length;

            return true;

        } else {

            return false;

        }

    }



    /**

     * @dev Removes a value from a set. O(1).

     *

     * Returns true if the value was removed from the set, that is if it was

     * present.

     */

    function _remove(Set storage set, bytes32 value) private returns (bool) {

        // We read and store the value's index to prevent multiple reads from the same storage slot

        uint256 valueIndex = set._indexes[value];



        if (valueIndex != 0) {

            // Equivalent to contains(set, value)

            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in

            // the array, and then remove the last element (sometimes called as 'swap and pop').

            // This modifies the order of the array, as noted in {at}.



            uint256 toDeleteIndex = valueIndex - 1;

            uint256 lastIndex = set._values.length - 1;



            if (lastIndex != toDeleteIndex) {

                bytes32 lastValue = set._values[lastIndex];



                // Move the last value to the index where the value to delete is

                set._values[toDeleteIndex] = lastValue;

                // Update the index for the moved value

                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex

            }



            // Delete the slot where the moved value was stored

            set._values.pop();



            // Delete the index for the deleted slot

            delete set._indexes[value];



            return true;

        } else {

            return false;

        }

    }



    /**

     * @dev Returns true if the value is in the set. O(1).

     */

    function _contains(Set storage set, bytes32 value) private view returns (bool) {

        return set._indexes[value] != 0;

    }



    /**

     * @dev Returns the number of values on the set. O(1).

     */

    function _length(Set storage set) private view returns (uint256) {

        return set._values.length;

    }



    /**

     * @dev Returns the value stored at position `index` in the set. O(1).

     *

     * Note that there are no guarantees on the ordering of values inside the

     * array, and it may change when more values are added or removed.

     *

     * Requirements:

     *

     * - `index` must be strictly less than {length}.

     */

    function _at(Set storage set, uint256 index) private view returns (bytes32) {

        return set._values[index];

    }



    /**

     * @dev Return the entire set in an array

     *

     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed

     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that

     * this function has an unbounded cost, and using it as part of a state-changing function may render the function

     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.

     */

    function _values(Set storage set) private view returns (bytes32[] memory) {

        return set._values;

    }



    // Bytes32Set



    struct Bytes32Set {

        Set _inner;

    }



    /**

     * @dev Add a value to a set. O(1).

     *

     * Returns true if the value was added to the set, that is if it was not

     * already present.

     */

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {

        return _add(set._inner, value);

    }



    /**

     * @dev Removes a value from a set. O(1).

     *

     * Returns true if the value was removed from the set, that is if it was

     * present.

     */

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {

        return _remove(set._inner, value);

    }



    /**

     * @dev Returns true if the value is in the set. O(1).

     */

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {

        return _contains(set._inner, value);

    }



    /**

     * @dev Returns the number of values in the set. O(1).

     */

    function length(Bytes32Set storage set) internal view returns (uint256) {

        return _length(set._inner);

    }



    /**

     * @dev Returns the value stored at position `index` in the set. O(1).

     *

     * Note that there are no guarantees on the ordering of values inside the

     * array, and it may change when more values are added or removed.

     *

     * Requirements:

     *

     * - `index` must be strictly less than {length}.

     */

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {

        return _at(set._inner, index);

    }



    /**

     * @dev Return the entire set in an array

     *

     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed

     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that

     * this function has an unbounded cost, and using it as part of a state-changing function may render the function

     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.

     */

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {

        return _values(set._inner);

    }



    // AddressSet



    struct AddressSet {

        Set _inner;

    }



    /**

     * @dev Add a value to a set. O(1).

     *

     * Returns true if the value was added to the set, that is if it was not

     * already present.

     */

    function add(AddressSet storage set, address value) internal returns (bool) {

        return _add(set._inner, bytes32(uint256(uint160(value))));

    }



    /**

     * @dev Removes a value from a set. O(1).

     *

     * Returns true if the value was removed from the set, that is if it was

     * present.

     */

    function remove(AddressSet storage set, address value) internal returns (bool) {

        return _remove(set._inner, bytes32(uint256(uint160(value))));

    }



    /**

     * @dev Returns true if the value is in the set. O(1).

     */

    function contains(AddressSet storage set, address value) internal view returns (bool) {

        return _contains(set._inner, bytes32(uint256(uint160(value))));

    }



    /**

     * @dev Returns the number of values in the set. O(1).

     */

    function length(AddressSet storage set) internal view returns (uint256) {

        return _length(set._inner);

    }



    /**

     * @dev Returns the value stored at position `index` in the set. O(1).

     *

     * Note that there are no guarantees on the ordering of values inside the

     * array, and it may change when more values are added or removed.

     *

     * Requirements:

     *

     * - `index` must be strictly less than {length}.

     */

    function at(AddressSet storage set, uint256 index) internal view returns (address) {

        return address(uint160(uint256(_at(set._inner, index))));

    }



    /**

     * @dev Return the entire set in an array

     *

     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed

     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that

     * this function has an unbounded cost, and using it as part of a state-changing function may render the function

     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.

     */

    function values(AddressSet storage set) internal view returns (address[] memory) {

        bytes32[] memory store = _values(set._inner);

        address[] memory result;



        /// @solidity memory-safe-assembly

        assembly {

            result := store

        }



        return result;

    }



    // UintSet



    struct UintSet {

        Set _inner;

    }



    /**

     * @dev Add a value to a set. O(1).

     *

     * Returns true if the value was added to the set, that is if it was not

     * already present.

     */

    function add(UintSet storage set, uint256 value) internal returns (bool) {

        return _add(set._inner, bytes32(value));

    }



    /**

     * @dev Removes a value from a set. O(1).

     *

     * Returns true if the value was removed from the set, that is if it was

     * present.

     */

    function remove(UintSet storage set, uint256 value) internal returns (bool) {

        return _remove(set._inner, bytes32(value));

    }



    /**

     * @dev Returns true if the value is in the set. O(1).

     */

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {

        return _contains(set._inner, bytes32(value));

    }



    /**

     * @dev Returns the number of values on the set. O(1).

     */

    function length(UintSet storage set) internal view returns (uint256) {

        return _length(set._inner);

    }



    /**

     * @dev Returns the value stored at position `index` in the set. O(1).

     *

     * Note that there are no guarantees on the ordering of values inside the

     * array, and it may change when more values are added or removed.

     *

     * Requirements:

     *

     * - `index` must be strictly less than {length}.

     */

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {

        return uint256(_at(set._inner, index));

    }



    /**

     * @dev Return the entire set in an array

     *

     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed

     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that

     * this function has an unbounded cost, and using it as part of a state-changing function may render the function

     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.

     */

    function values(UintSet storage set) internal view returns (uint256[] memory) {

        bytes32[] memory store = _values(set._inner);

        uint256[] memory result;



        /// @solidity memory-safe-assembly

        assembly {

            result := store

        }



        return result;

    }

}


// File: contracts/UniswapV2Locker.sol



pragma solidity ^0.8.0;











contract UniswapV2Locker is Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;



    IUniswapV2Factory public uniswapFactory;



    struct UserInfo {

        EnumerableSet.AddressSet lockedTokens; // records all tokens the user has locked

        mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token

    }



    struct Lock {

        uint256 lockDate; // the date the token was locked

        uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)

        uint256 initialAmount; // the initial lock amount

        uint256 unlockDate; // the date the token can be withdrawn

        uint256 lockID; // lockID nonce per uni pair

        address owner;

        uint256 schemaId;

    }



    mapping(address => UserInfo) private users;



    EnumerableSet.AddressSet private lockedTokens;

    mapping(address => Lock[]) public locks; // map univ2 pair to all its locks



    uint256 public nativeFee; // eth fee for creating a lock



    address payable feeAddress;



    // Signata Integration

    ISignataRight public signataRight;



    event Deposited(

        address lpToken,

        address user,

        uint256 amount,

        uint256 lockDate,

        uint256 unlockDate,

        uint256 schemaId

    );

    event Withdrawn(address lpToken, uint256 amount);

    event SignataRightUpdated(address newSignataRight);

    event LockTransferred(address previousOwner, address newOwner);

    event Relocked(uint256 lockId, uint256 unlockDate);

    event LockSplit(uint256 lockId, uint256 amount);



    constructor(IUniswapV2Factory _uniswapFactory, ISignataRight _signataRight) {

        feeAddress = payable(msg.sender);

        nativeFee = 1e18;

        uniswapFactory = _uniswapFactory;

        signataRight = _signataRight;

    }



    function setFeeAddress(address payable _feeAddress) public onlyOwner {

        feeAddress = _feeAddress;

    }



    function setFee(uint256 _nativeFee) public onlyOwner {

        nativeFee = _nativeFee;

    }



    /**

     * @notice Creates a new lock

     * @param _lpToken the univ2 token address

     * @param _amount amount of LP tokens to lock

     * @param _unlock_date the unix timestamp (in seconds) until unlock

     * @param _withdrawer the user who can withdraw liquidity once the lock expires.

     */

    function lockTokens(

        address _lpToken,

        uint256 _amount,

        uint256 _unlock_date,

        address payable _withdrawer,

        uint256 _schemaId

    ) external payable nonReentrant {

        require(_unlock_date < 10000000000, "lockTokens::Invalid timestamp"); // prevents errors when timestamp entered in milliseconds

        require(_amount > 0, "lockTokens::Amount needs to be greater than 0");



        // ensure this pair is a univ2 pair by querying the factory

        IUniswapV2Pair lpair = IUniswapV2Pair(address(_lpToken));

        address factoryPairAddress = uniswapFactory.getPair(

            lpair.token0(),

            lpair.token1()

        );

        require(factoryPairAddress == address(_lpToken), "lockTokens::Invalid LP pair");



        // check holding NFT of schema

        if (_schemaId > 0) {

            require(

                signataRight.holdsTokenOfSchema(msg.sender, _schemaId),

                "lockTokens::Sender does not hold NFT of schema"

            );

        }



        SafeERC20.safeTransferFrom(

            IERC20(_lpToken),

            address(msg.sender),

            address(this),

            _amount

        );



        require(msg.value == nativeFee, "lockTokens::Fee not paid");

        feeAddress.transfer(nativeFee);



        Lock memory lock;

        lock.lockDate = block.timestamp;

        lock.amount = _amount;

        lock.initialAmount = _amount;

        lock.unlockDate = _unlock_date;

        lock.lockID = locks[_lpToken].length;

        lock.owner = _withdrawer;

        lock.schemaId = _schemaId;



        // record the lock for the univ2pair

        locks[_lpToken].push(lock);

        lockedTokens.add(_lpToken);



        // record the lock for the user

        UserInfo storage user = users[_withdrawer];

        user.lockedTokens.add(_lpToken);

        uint256[] storage user_locks = user.locksForToken[_lpToken];

        user_locks.push(lock.lockID);



        emit Deposited(

            _lpToken,

            msg.sender,

            lock.amount,

            lock.lockDate,

            lock.unlockDate,

            lock.schemaId

        );

    }



    /**

     * @notice extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed

     * this prevents errors when a user performs multiple tx per block possibly with varying gas prices

     */

    function relock(

        address _lpToken,

        uint256 _index,

        uint256 _lockID,

        uint256 _unlock_date

    ) external nonReentrant {

        require(_unlock_date < 10000000000, "relock::Invalid timestamp"); // prevents errors when timestamp entered in milliseconds

        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];

        Lock storage userLock = locks[_lpToken][lockID];

        require(

            lockID == _lockID && userLock.owner == msg.sender,

            "relock::Lock mismatch"

        ); // ensures correct lock is affected

        require(userLock.unlockDate < _unlock_date, "relock::Invalid date");



        // check holding NFT of schema

        if (userLock.schemaId > 0) {

            require(

                signataRight.holdsTokenOfSchema(msg.sender, userLock.schemaId),

                "relock::Sender does not hold NFT of schema"

            );

        }



        userLock.amount = userLock.amount;

        userLock.unlockDate = _unlock_date;



        emit Relocked(_lockID, _unlock_date);

    }



    /**

     * @notice withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed

     * this prevents errors when a user performs multiple tx per block possibly with varying gas prices

     */

    function withdraw(

        address _lpToken,

        uint256 _index,

        uint256 _lockID,

        uint256 _amount

    ) external nonReentrant {

        require(_amount > 0, "withdraw::Amount needs to be greater than 0");

        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];

        Lock storage userLock = locks[_lpToken][lockID];

        require(

            lockID == _lockID && userLock.owner == msg.sender,

            "withdraw::Lock mismatch"

        ); // ensures correct lock is affected

        require(userLock.unlockDate < block.timestamp, "withdraw::Lock not expired");

        userLock.amount = userLock.amount.sub(_amount);



        // check holding NFT of schema

        if (userLock.schemaId > 0) {

            require(

                signataRight.holdsTokenOfSchema(msg.sender, userLock.schemaId),

                "withdraw::Sender does not hold NFT of schema"

            );

        }



        // clean user storage

        if (userLock.amount == 0) {

            uint256[] storage userLocks = users[msg.sender].locksForToken[

                _lpToken

            ];

            userLocks[_index] = userLocks[userLocks.length - 1];

            userLocks.pop();

            if (userLocks.length == 0) {

                users[msg.sender].lockedTokens.remove(_lpToken);

            }

        }



        SafeERC20.safeTransfer(IERC20(_lpToken), msg.sender, _amount);

        emit Withdrawn(_lpToken, _amount);

    }



    /**

     * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees, and faster loading on our live block explorer

     */

    function incrementLock(

        address _lpToken,

        uint256 _index,

        uint256 _lockID,

        uint256 _amount

    ) external nonReentrant {

        require(_amount > 0, "incrementLock::Amount needs to be greater than 0");

        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];

        Lock storage userLock = locks[_lpToken][lockID];

        require(

            lockID == _lockID && userLock.owner == msg.sender,

            "incrementLock::Lock mismatch"

        ); // ensures correct lock is affected



        // check holding NFT of schema

        if (userLock.schemaId > 0) {

            require(

                signataRight.holdsTokenOfSchema(msg.sender, userLock.schemaId),

                "incrementLock::Sender does not hold NFT of schema"

            );

        }



        SafeERC20.safeTransferFrom(

            IERC20(_lpToken),

            address(msg.sender),

            address(this),

            _amount

        );



        userLock.amount = userLock.amount.add(_amount);

        emit Deposited(

            _lpToken,

            msg.sender,

            _amount,

            userLock.lockDate,

            userLock.unlockDate,

            userLock.schemaId

        );

    }



    /**

     * @notice split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion

     * and withdraw a smaller portion

     */

    function splitLock(

        address _lpToken,

        uint256 _index,

        uint256 _lockID,

        uint256 _amount

    ) external payable nonReentrant {

        require(_amount > 0, "splitLock::Amount needs to be greater than 0");

        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];

        Lock storage userLock = locks[_lpToken][lockID];

        require(

            lockID == _lockID && userLock.owner == msg.sender,

            "splitLock::Lock Mismatch"

        ); // ensures correct lock is affected



        // check holding NFT of schema

        if (userLock.schemaId > 0) {

            require(

                signataRight.holdsTokenOfSchema(msg.sender, userLock.schemaId),

                "splitLock::Sender does not hold NFT of schema"

            );

        }



        userLock.amount = userLock.amount.sub(_amount);



        Lock memory lock;

        lock.lockDate = userLock.lockDate;

        lock.amount = _amount;

        lock.initialAmount = _amount;

        lock.unlockDate = userLock.unlockDate;

        lock.lockID = locks[_lpToken].length;

        lock.owner = msg.sender;



        // record the lock for the univ2pair

        locks[_lpToken].push(lock);



        // record the lock for the user

        UserInfo storage user = users[msg.sender];

        uint256[] storage user_locks = user.locksForToken[_lpToken];

        user_locks.push(lock.lockID);



        emit LockSplit(_lockID, _amount);

    }



    /**

     * @notice transfer a lock to a new owner

     */

    function transferLockOwnership(

        address _lpToken,

        uint256 _index,

        uint256 _lockID,

        address payable _newOwner

    ) external {

        require(msg.sender != _newOwner, "transferLockOwnership::Cannot transfer to self");

        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];

        Lock storage lock = locks[_lpToken][lockID];

        require(

            lockID == _lockID && lock.owner == msg.sender,

            "transferLockOwnership::Lock Mismatch"

        ); // ensures correct lock is affected



        // check holding NFT of schema

        if (lock.schemaId > 0) {

            require(

                signataRight.holdsTokenOfSchema(

                    _newOwner,

                    lock.schemaId

                ),

                "transferLockOwnership::New owner does not hold NFT of schema"

            );

        }



        // record the lock for the new Owner

        UserInfo storage user = users[_newOwner];

        user.lockedTokens.add(_lpToken);

        uint256[] storage user_locks = user.locksForToken[_lpToken];

        user_locks.push(lock.lockID);



        // remove the lock from the old owner

        uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];

        userLocks[_index] = userLocks[userLocks.length - 1];

        userLocks.pop();

        if (userLocks.length == 0) {

            users[msg.sender].lockedTokens.remove(_lpToken);

        }

        lock.owner = _newOwner;



        emit LockTransferred(msg.sender, _newOwner);

    }



    function getNumLocksForToken(address _lpToken)

        external

        view

        returns (uint256)

    {

        return locks[_lpToken].length;

    }



    function getNumLockedTokens() external view returns (uint256) {

        return lockedTokens.length();

    }



    function getLockedTokenAtIndex(uint256 _index)

        external

        view

        returns (address)

    {

        return lockedTokens.at(_index);

    }



    // user functions

    function getUserNumLockedTokens(address _user)

        external

        view

        returns (uint256)

    {

        UserInfo storage user = users[_user];

        return user.lockedTokens.length();

    }



    function getUserLockedTokenAtIndex(address _user, uint256 _index)

        external

        view

        returns (address)

    {

        UserInfo storage user = users[_user];

        return user.lockedTokens.at(_index);

    }



    function getUserNumLocksForToken(address _user, address _lpToken)

        external

        view

        returns (uint256)

    {

        UserInfo storage user = users[_user];

        return user.locksForToken[_lpToken].length;

    }



    function getUserLockForTokenAtIndex(

        address _user,

        address _lpToken,

        uint256 _index

    )

        external

        view

        returns (

            uint256,

            uint256,

            uint256,

            uint256,

            uint256,

            uint256,

            address

        )

    {

        uint256 lockID = users[_user].locksForToken[_lpToken][_index];

        Lock storage lock = locks[_lpToken][lockID];

        return (

            lock.lockDate,

            lock.amount,

            lock.initialAmount,

            lock.unlockDate,

            lock.lockID,

            lock.schemaId,

            lock.owner

        );

    }



    function updateSignataRight(address _signataRight) public onlyOwner {

        signataRight = ISignataRight(_signataRight);

        emit SignataRightUpdated(_signataRight);

    }

}