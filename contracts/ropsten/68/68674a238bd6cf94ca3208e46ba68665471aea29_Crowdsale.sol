/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


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
abstract contract Pausable is Context {
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
    constructor() {
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
}

// File: @openzeppelin/contracts/access/Ownable.sol


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
}

// File: contracts/N-Crowdsale.sol

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//    NNNNNNNN        NNNNNNNN   ffffffffffffffff           tttt                                               iiii                       //
//    N:::::::N       N::::::N  f::::::::::::::::f       ttt:::t                                              i::::i                      //
//    N::::::::N      N::::::N f::::::::::::::::::f      t:::::t                                               iiii                       //
//    N:::::::::N     N::::::N f::::::fffffff:::::f      t:::::t                                                                          //
//    N::::::::::N    N::::::N f:::::f       ffffffttttttt:::::ttttttt      aaaaaaaaaaaaa  nnnn  nnnnnnnn    iiiiiii   aaaaaaaaaaaaa      //
//    N:::::::::::N   N::::::N f:::::f             t:::::::::::::::::t      a::::::::::::a n:::nn::::::::nn  i:::::i   a::::::::::::a     //
//    N:::::::N::::N  N::::::Nf:::::::ffffff       t:::::::::::::::::t      aaaaaaaaa:::::an::::::::::::::nn  i::::i   aaaaaaaaa:::::a    //
//    N::::::N N::::N N::::::Nf::::::::::::f       tttttt:::::::tttttt               a::::ann:::::::::::::::n i::::i            a::::a    //
//    N::::::N  N::::N:::::::Nf::::::::::::f             t:::::t              aaaaaaa:::::a  n:::::nnnn:::::n i::::i     aaaaaaa:::::a    //
//    N::::::N   N:::::::::::Nf:::::::ffffff             t:::::t            aa::::::::::::a  n::::n    n::::n i::::i   aa::::::::::::a    //
//    N::::::N    N::::::::::N f:::::f                   t:::::t           a::::aaaa::::::a  n::::n    n::::n i::::i  a::::aaaa::::::a    //
//    N::::::N     N:::::::::N f:::::f                   t:::::t    tttttta::::a    a:::::a  n::::n    n::::n i::::i a::::a    a:::::a    //
//    N::::::N      N::::::::Nf:::::::f                  t::::::tttt:::::ta::::a    a:::::a  n::::n    n::::ni::::::ia::::a    a:::::a    //
//    N::::::N       N:::::::Nf:::::::f                  tt::::::::::::::ta:::::aaaa::::::a  n::::n    n::::ni::::::ia:::::aaaa::::::a    //
//    N::::::N        N::::::Nf:::::::f                    tt:::::::::::tt a::::::::::aa:::a n::::n    n::::ni::::::i a::::::::::aa:::a   //
//    NNNNNNNN         NNNNNNNfffffffff                      ttttttttttt    aaaaaaaaaa  aaaa nnnnnn    nnnnnniiiiiiii  aaaaaaaaaa  aaaa   //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                      .^!7JY5PPP55J?!^.                                                 //
//                                                                  :!YG#&@@@@@@@@@@@@@@&B57^                                             //
//                                                               :?G&@@@@@@@@@@@@@@@@@@@@@@@@BJ^                                          //
//                                                             ^5&@@@@@@@&BPYJ?777?JYPB&@@@@@@@@G!                                        //
//                                                           :[email protected]@@@@@@#Y!:             :!Y#@@@@@@@G^                                      //
//                                                          !&@@@@@@P~                     [email protected]@@@@@@J                                     //
//                                                         [email protected]@@@@@G~             .:::.       [email protected]@@@@@5                                    //
//                      .^^^^^^^^^^^^^^^^^^               [email protected]@@@@@Y     7#BBBB~!PB&&&&#G?.      [email protected]@@@@@Y                                   //
//                     7#@@@@@@@@@@@@@@@@@@#~            :&@@@@@5      [email protected]@@@@&@@@@@@@@@@G.      [email protected]@@@@@!                                  //
//                     [email protected]@@@@@@@@@@@@@@@@@@@B            [email protected]@@@@#.      [email protected]@@@@@Y~^^7#@@@@@7      .#@@@@@G                                  //
//                     [email protected]@@@@~           [email protected]@@@@5       [email protected]@@@@Y     [email protected]@@@@J       [email protected]@@@@&.                                 //
//                                     [email protected]@@@@5           [email protected]@@@@Y       [email protected]@@@@?     [email protected]@@@@J       [email protected]@@@@&:                                 //
//                                     .#@@@@#.          [email protected]@@@@G       [email protected]@@@@?     [email protected]@@@@J       [email protected]@@@@#.                                 //
//                                      [email protected]@@@@7          [email protected]@@@@@!      [email protected]@@@@J     [email protected]@@@@J      [email protected]@@@@@Y                                  //
//               .................      [email protected]@@@@G           [email protected]@@@@#^     [email protected]@@@@J     [email protected]@@@@J     ^#@@@@@&:                                  //
//             7G##################5:    [email protected]@@@@#BBB#5     :#@@@@@&!    ~YYYYY~     ~YYYYY~    !&@@@@@@!     J#BBBP!                       //
//             &@@@@@@@@@@@@@@@@@@@@7    [email protected]@@@@@@@@@@Y     :[email protected]@@@@@P^                       ^[email protected]@@@@@&!     [email protected]@@@@@&                       //
//             ^YGGGGGGGGGGGGGGGGGP7     :&@@@@@@@@@@@Y     [email protected]@@@@@@G7:                 :[email protected]@@@@@@G^     [email protected]@@@@@@P                       //
//                                        [email protected]@@@@@@@@@@@P.     [email protected]@@@@@@&GY7~:..   ..:~7YG&@@@@@@@B7      [email protected]@@@@@@@^                       //
//                                        [email protected]@@@@@@@@@@@@#7      ~5&@@@@@@@@@&&#BBB#&&@@@@@@@@@@G!      [email protected]@@@@@@@P                        //
//                  ?GBBBBBBBBBBBBBBP!    .#@@@@@@@@@@@@@@G~      .75#@@@@@@@@@@@@@@@@@@@@@#P?:      ^[email protected]@@@@@@@@@!                        //
//                 [email protected]@@@@@@@@@@@@@@@@&.    [email protected]@@@@@@@@@@@@@@@G7.      .^7YPB#&@@@@@@@&&BG5?~.       [email protected]@@@@@@@@@@B                         //
//                  ?GBBBBBBBBBBBBBBP!     ^@@@@@@@@@@@@@@@@@@#5!.         .:^^~~~^^:.         .~Y#@@@@@@@@@@@@@7                         //
//                                          [email protected]@@@@@@@@@@@@@@@@@@@&GJ!:                     :~?P#@@@@@@@@@@@@@@@#.                         //
//                                          [email protected]@@@@@@@@@@@@@@@@@@@@@@@&#PY?7~^^:::::^^~!?YPB&@@@@@@@@@@@@@@@@@@@J                          //
//                      .?PGGGGGGGGGGGJ:    :&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&:                          //
//                      [email protected]@@@@@@@@@@@@@P     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y                           //
//                      :5############P~     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^                           //
//                        ............       .#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P                            //
//                                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~                            //
//                                            ^@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G                             //
//                                             [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7                             //
//                                           .:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.                             //
//                                         !P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?                              //
//                                       ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                              //
//                                      ^&@@@@@P?7777777777777777777777777777777777777777777777777777777!~                                //
//                                      [email protected]@@@@?                                                                                           //
//                                      [email protected]@@@@Y                                                                                           //
//                                      [email protected]@@@@#5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ~                                 //
//                                       .5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J                                //
//                                         :?P#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~                                //
//                                            .:^^^[email protected]@@@@@@@@@@@@@@@@J^^^^^^^^^[email protected]@@@@@@@@@@@@@@@@Y^^^^^^                                  //
//                                                 [email protected]@@@@@@@@@@@@@@@@5         [email protected]@@@@@@@@@@@@@@@@G                                        //
//                                                 [email protected]@@@@@@@@@@@@@@@@J         [email protected]@@@@@@@@@@@@@@@@5                                        //
//                                                 [email protected]@@@@@@@@@@@@@@G.          [email protected]@@@@@@@@@@@@@@B:                                        //
//                                                   ?#@@@@@@@@@@@#?             [email protected]@@@@@@@@@@#Y.                                         //
//                                                    .!5B&@@@&B5!.               .!YB&@@@&B57:                                           //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// @title: Nftania NFT2.0
// @author: Nftania.com
// @custom: security-contact [email protected]
// @Contract: Nftania Crowdsale

pragma solidity 0.8.15;
   //////////////////////// Imports ////////////////////////////////////////





interface IAddLiquidity {
    function addLiquidityETH  (address _token, uint tokenAmount, uint EthAmount, address beneficiary ) external payable
    returns (uint amountToken, uint amountETH, uint amountliquidity, uint totalLiquidity, address pairAddress);
}

contract Crowdsale is Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

   //////////////////////// Main Variables /////////////////////////////////// 
        uint256 public totalTokensSold;                        // Total accumilative tokens purchased 
        uint256 private remainingTokens;                       // The cap of tokens available for purchase
        uint256 private tokenPresalePrice;                     // Token price fror presale (per one token in wei units) 
        uint256 private tokenPrice;                            // Token price before liquidty pool (per one nft2 token in wei units) 
        uint256 private purchaseOrderID;                       // Purcase order serial number
        uint256 private walletLimit;                           // Max total number of tokens allowed to be purchased per wallet (in complete units not decimals)
        uint256 private minPurchase;                           // Minimum number of tokens allowed per order (in complete units not decimals)
        uint256 private maxPurchase;                           // Maximum number of tokens allowed per order (in complete units not decimals)
        uint256 private weiRaised;                             // Total sales in wei
        uint256 private poolRaised;                            // Total Accumulative liquidity pool revenue share in wei
        uint256 private poolBalance;                           // Current contract balance allocated for liquidity pool in wei
        uint256 private freeBalance;                           // non liquidity pool eth balance inside the contract
        uint256 private revenueRaised;                         // Total revenue share in wei
        uint256 private startDate;                             // Sale starting date
        uint256 private endDate;                               // Sale ending date
        uint256 private poolPercent;                           // pool Percentage value in  per thousand value (1 per mili)
        uint256 private targetPool;                            // Minimum number of eth (in wei) needed to activate automatic liquity pool threshould
        uint256 private totalLiquidityTokens;                  // total number of liquidity tokens generated by manual and automaitc liquidity pool creation
        address private tokenAddress;                          // Address of the ERC-20 token to be sold
        address payable private AddLiquidityContract;          // Add Liquidity Contract (add liquidity to uniswap exchange)
        address payable private revenueWallet;                 // Wallet Receiving Sales in eth
        address private LiquidityPoolLocker;                   // Liquidity pool locker address
        bool private closed;                                   // Flag ("true" if crowdsale is closed)
        bool private soldOut;                                  // Flag ("true" if crowdsale token are sold out) 
        bool private timeEnded;                                // Flag ("true" if crowdsale end date achieved)
        mapping (address => uint256) public walletPurchases;   // Total Purchases for each purchasing wallet

   //////////////////////// Events /////////////////////////////////////////// 
    // Pause/unpause Smart Contract
        event ContractIsPaused(bool status);
    // Purchase Order                                          
        event PurchaseOrder(address indexed to, uint256 EthValue, uint256 tokensAmount, uint256 poolShare, uint256 revenueShare, uint256 totalWalletPurchases, uint256 walletTokenBalance, uint256 indexed purchaseOrderID, uint256 indexed date); 
    // Set New Price
        event NewPriceSet(uint256 indexed tokenPresalePrice, uint256 indexed tokenPrice, uint256 indexed date);
    // Status Update
        event StatusUpdate(uint256 weiRaised, uint256 poolRaised, uint256 revenueRaised, uint256 poolBalance, uint256 totalTokensSold, uint256 remainingTokens);
    // New Dates Set
        event NewDatesSet(uint startDate, uint endDate);
    // New Purchase Limits
        event NewPurchaseLimits(uint256 _minPurchase, uint256 _maxPurchase, uint256 _walletLimit);
    // Withdraw Tokens 
        event WithdrawTokens (address to, uint256  amount);
    // Liquidity Added
        event AutoLiquidity (uint tokenAmount, uint EthAmount);
        event ManualLiquidity (uint tokenAmount, uint EthAmount);
        event LiquidityAdded (uint amountToken, uint amountETH, uint amountliquidityTokens, uint totalLiquidityTokens, address pairAddress);
      
   //////////////////////// Constructor //////////////////////////////////////
    constructor(
        uint256 _tokenPresalePrice,   
        uint256 _tokenPrice,                 
        uint256 _walletLimit,  
        uint256 _minPurchase,  
        uint256 _maxPurchase,  
        uint256 _poolPercent,
        uint256 _targetPool,
        uint _startDate,
        uint _endDate){

        require(_tokenPresalePrice > 0,"NftaniaCrowdsale: token rate is 0 Wei");
        require(_tokenPrice > 0,"NftaniaCrowdsale: token rate is 0 Wei");
        require(_walletLimit != 0,"NftaniaCrowdsale: The wallet limit should not be zero");
        require(_minPurchase != 0,"NftaniaCrowdsale: The minimum purchase should not be zero");
        require(_maxPurchase >= _minPurchase,"NftaniaCrowdsale: The maximum purchase should be larger or equal to the minimum purchase");
        require(_poolPercent > 0,"NftaniaCrowdsale: Liquidity pool percent should not be zero");
        require(_targetPool > 0,"NftaniaCrowdsale: Target amount of tokens for liquidity pool should not be zero");
        require(_startDate >= block.timestamp,"NftaniaCrowdsale: opening time is before current time");
        require(_endDate > _startDate,"NftaniaCrowdsale: Closing time is  before openning time");

        tokenPresalePrice = _tokenPresalePrice;
        tokenPrice = _tokenPrice;    
        walletLimit = _walletLimit;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        poolPercent = _poolPercent;
        targetPool = _targetPool;
        startDate = _startDate;
        endDate = _endDate;
    }

   //////////////////////// intializeAddresses //////////////////////////////////////     
    function intilizeAddresses(
        address _tokenAddress, 
        address _LiquidityPoolLocker,
        address payable _AddLiquidityContract,
        address payable _revenueWallet) 
        public onlyOwner{
        require(_tokenAddress != address(0),"NftaniaCrowdsale: token is the zero address");
        require(_LiquidityPoolLocker != address(0),"NftaniaCrowdsale: Liquidity Locker is the zero address");
        require(_AddLiquidityContract != address(0),"NftaniaCrowdsale: Nftania Add Liquidity contract is the zero address");
        require(_revenueWallet != address(0),"NftaniaCrowdsale: wallet is the zero address");
        tokenAddress = _tokenAddress;  
        LiquidityPoolLocker =_LiquidityPoolLocker;
        AddLiquidityContract = _AddLiquidityContract;
        revenueWallet = _revenueWallet;        
        updateStatus();
    }

   //////////////////////// Fallback //////////////////////////////////////   
    fallback() external payable {} 
    receive()  external payable {} 
    
   ////////////////////////  get remaining tokens //////////////////////////////// 
    function getRemainingTokens() public view returns (uint256 _remainingTokens){
        _remainingTokens = remainingTokens;
        require(_remainingTokens > 10**18,"remaining tokens are fractions");
        return (_remainingTokens);
    }

   //////////////////////// Function update Remaining Tokens /////////////  
    function updateStatus() internal {
        uint256 tokenAllowance;
        uint256 tokenBallance;
        require(block.timestamp >= startDate,"Nftania Crowdsale: Sale has not started yet");
        tokenAllowance = IERC20(tokenAddress).allowance(owner(), address(this));
        tokenBallance = IERC20(tokenAddress).balanceOf(owner());
        remainingTokens = min (tokenAllowance, tokenBallance);
        soldOut = remainingTokens < minPurchase * 10**18;  // Checks if there is remaining tokens supply
        timeEnded = block.timestamp > endDate; // Checks if date Ended  
        closed = soldOut || timeEnded;   
        require(!soldOut,"Nftania Crowdsale: All tokens are sold out");  
        require(!timeEnded,"Nftania Crowdsale: Crowdsale time has ended"); 
    }

   //////////////////////// Function Reopen Corwdsale after close /////////////  
    //Owner must make sure of enough allowance and new date before reopen
    function reopenCrowdsale() public onlyOwner{
        closed = false;
    }

   //////////////////////// Function gets Minimum Value /////////////  
    function min (uint256 a, uint256 b) internal pure returns (uint minimum) {
        if (a>b) {
            return b;
        }
        else{
            return a;
        }
    }

   //////////////////////// get Details ////////////////////////////////
    function getDetails() public view returns (address _tokenAddress, address _revenueWallet, bool _soldOut, bool _timeEnded, bool _closed, uint _startDate, uint _endDate) {
        return (tokenAddress, revenueWallet, soldOut, timeEnded, closed, startDate, endDate) ;
    }

   //////////////////////// Get Purchase Limit ///////////////////////////////// 
    function getPurchaseLimits () public view returns (uint256 _minPurchase, uint256 _maxPurchase, uint256 _walletLimit){
        return (minPurchase, maxPurchase, walletLimit);
    }

   //////////////////////// Get Results //////////////////////// 
    function getEthInfo () external view returns (uint _balance, uint256 _weiRaised, uint256 _poolRaised, uint256 _poolBalance, uint256 _freeBalance, uint256 _revenueRaised) {
        _freeBalance = address(this).balance - poolBalance;
        return (address(this).balance, weiRaised, poolRaised, poolBalance, _freeBalance, revenueRaised);
    }

   //////////////////////// Get Token Price ////////////////////////////////// 
    function getPrices() public view returns (uint256 _tokenPresalePrice, uint256 _tokenPrice){
        return (tokenPresalePrice, tokenPrice);
    } 

   //////////////////////// Withdraw Funds ////////////////////////////////     
    function withdrawEth(uint amount, address payable receivingWallet) public onlyOwner returns (uint256 _contractBalance, uint256 _freeBalance, uint256 _poolBalance)  {
        freeBalance = address(this).balance - poolBalance;
        require(amount > 0, "NftaniaCrowdsale: amount cannot be zero");
        require(amount <= freeBalance, "NftaniaCrowdsale: Insufficient non-liquidity pool balance"); //owner cannot withdraw ETH allocated for liquidity pool
        (bool success, ) = receivingWallet.call{value: amount}("");
        require(success, "Error");
        _contractBalance = address(this).balance;
        return (_contractBalance, freeBalance, poolBalance);
    }

   //////////////////////// Withdraw Tokens ////////////////////////////////    
    function withdrawTokens (IERC20 token , address to , uint256 amount ) public onlyOwner {
        uint256 tokenBalance = token.balanceOf (address(this)) ;
        require (amount <= tokenBalance,"NftaniaCrowdsale: tokenBalance is low") ;
        token.safeTransfer(to,amount);
        emit WithdrawTokens (to, amount);
    }

   //////////////////////// update Purchase Limits ///////////////////////////////// 
    function updatePurchaseLimits (uint256 _minPurchase, uint256 _maxPurchase, uint256 _walletLimit) public onlyOwner whenNotClosed returns (bool status){
        require (_minPurchase > 0,"NftaniaCrowdsale: The minimum purchase should not be zero");
        require (_maxPurchase >= _minPurchase,"NftaniaCrowdsale: The max purchase should be larger or euqal to the minimum purchase");
        require (_walletLimit >= _maxPurchase,"NftaniaCrowdsale: The wallet limit should be larger or euqal to the maximum purchase");

        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        walletLimit = _walletLimit;
        emit NewPurchaseLimits(minPurchase, maxPurchase, walletLimit);
        return true;
    }

   //////////////////////// update Token Price ////////////////////////////////// 
    function updateTokenPrices(uint256 _tokenPresalePrice, uint256 _tokenPrice) public onlyOwner whenNotClosed returns (bool success){
        require (paused(),"NftaniaCrowdsale: contract should be paused to inform users about price change in advance");
        require (_tokenPresalePrice != 0,"NftaniaCrowdsale: The Price is zero"); 
        require (_tokenPrice != 0,"NftaniaCrowdsale: The Price is zero");
        tokenPresalePrice = _tokenPresalePrice;
        tokenPrice = _tokenPrice;
        emit NewPriceSet(tokenPresalePrice, tokenPrice, block.timestamp);
        return true;       
    } 

   //////////////////////// Update Dates //////////////////////////////////////// 
    function updateDates(uint _startDate, uint _endDate) public onlyOwner {
        require(_startDate >= block.timestamp,"NftaniaCrowdsale: opening time is before current time");
        require(_endDate > _startDate,"NftaniaCrowdsale: opening time is not before closing time");
        startDate = _startDate;
        endDate = _endDate;
        emit NewDatesSet(startDate, endDate);     
    } 

    bool public A;
bool public B;
bool public C;
bool public D;
bool public E;
bool public F;

    function setTest1 (bool _A, bool _B, bool _C, bool _D,bool _E, bool _F) public {
        A=_A;
        B=_B;
        C=_C;
        D=_D;
        E=_E;
        F=_F;
    }
   //////////////////////// Purchase Tokens  /////////////  
    function buyTokens(uint amount) public payable whenNotPaused whenNotClosed nonReentrant returns
    (address userAddress, uint256 orderValue, uint256 _amount , uint256 poolShare, uint256 revenueShare, 
    uint256 _walletPurchases, uint256 walletTokenBalance, uint256 _purchaseOrderID, uint256 date){  

        // Qualify Order
        updateStatus();
        require(amount >= minPurchase,"Nftania Crowdsale: The tokens amount for this order is smaller than the minimum tokens amount allowed per order"); // checks if transaction value less than minimum allowed order value.
        require(amount * 10**18 <= remainingTokens,"Nftania Crowdsale: Amount requested is lager than remaining tokens");                            // Checks "Purchase supply" availability.
        require(amount <= maxPurchase,"Nftania Crowdsale: The tokens amount for this order is larger than the maximum tokens amount allowed per order");  // Checks is remaining tokens are below minimum order quantity
        require(amount + walletPurchases[msg.sender] <= walletLimit,"Nftania Crowdsale: The total cumulative tokens requested is more than max qouta per wallet"); // Checks "qouta amount" limit if allowed.
        require(msg.value == amount * tokenPresalePrice,"Nftania Crowdsale: Ether amount does not match tokens amount value");                                    // checks if paid value match qunatity total cost.
          
        // Update variables Status 
        (poolShare, revenueShare) = getShares(msg.value);
        weiRaised += msg.value;                    // UPDATE WEI RAISED STATE
        poolRaised += poolShare;                   // UPDATE TOTAL ACCUMULATIVE WEI POOL
        poolBalance += poolShare;                  // UPDATE CURRENT BALANCE IN CONTRACT FOR LIQUIDTY POOL WEI 
        revenueRaised += revenueShare;             // UPDATE WEI REVENUE STATE
        totalTokensSold += amount;                 // UPDATE TOTAL PURCHASED TOKENS 
        purchaseOrderID += 1;                      // GENERATE ORDER ID
        remainingTokens -= amount * 10**18;        // UPDATE REMAINING TOKENS
        walletPurchases[msg.sender] += amount;     // regiter total tokens purchasea by a wallet.
                
        // Collect & Deliver
        forwardFunds(revenueShare,poolShare);   
        deliverTokens(msg.sender, amount);
        walletTokenBalance = IERC20(tokenAddress).balanceOf(msg.sender); //get total wallet token balance after pruchase
        require(A,"A");

        autoAddLiquidity();          


        // Events
        emit PurchaseOrder(msg.sender, msg.value, amount * 10**18, poolShare, revenueShare, walletPurchases[msg.sender] * 10**18 , walletTokenBalance, purchaseOrderID, block.timestamp);
        emit StatusUpdate(weiRaised , poolRaised, revenueRaised , poolBalance , totalTokensSold, remainingTokens);
        return (msg.sender, msg.value, amount * 10**18, poolShare, revenueShare, walletPurchases[msg.sender] * 10**18 , walletTokenBalance, purchaseOrderID, block.timestamp);
    } 

   //////////////////////// function Deliver Tokens /////////////  
    function deliverTokens(address to, uint256 amount) internal {
        IERC20(tokenAddress).safeTransferFrom(owner(), to, amount * 10**18); 
    }     

   //////////////////////// function Forward Funds /////////////  
    function forwardFunds(uint256 _revenueShare, uint256 _poolShare) internal {  
        (bool successRevenueShare, ) = revenueWallet.call{value: _revenueShare}("");
        require(successRevenueShare, "Error revenueShare");  
        (bool successPoolShare, ) = payable (address(this)).call{value: _poolShare}("");
        require(successPoolShare, "Error PoolShare");  
    }  

   ////////////////// calculate shares for revenue and liquidity pool /////////////
    function getShares(uint256 paymentAmount) internal view returns (uint256 poolShare, uint256 revenueShare ) {
        require(paymentAmount * poolPercent  > 1000,"small transaction amount");
        poolShare = (paymentAmount * poolPercent) / 1000;
        revenueShare = paymentAmount - poolShare; 
        return (poolShare, revenueShare);
    }

   ////////////////////Automatic Add Liquidity /////////////  
    function autoAddLiquidity () internal returns (uint tokenAmount, uint EthAmount) {
        if (poolRaised >= targetPool) {
            EthAmount = poolBalance;
            tokenAmount = calclulateTokens(EthAmount);
            // callAddLiquidity (tokenAmount, EthAmount);  
            require(B,"B");
            (, uint amountETH,,,) = callAddLiquidity (tokenAmount, EthAmount);  
            require(E,"E"); 
            poolBalance -= amountETH;  
            // poolBalance -= EthAmount;              
        }
        emit AutoLiquidity (tokenAmount,EthAmount);
        return (tokenAmount, EthAmount);
    }

   ////////////////////Increase Target Pool  /////////////  
    function increaseTargetPool(uint256 newTargetPool) public onlyOwner{
        require (newTargetPool > targetPool, "Pool Target can be increased only");
        targetPool = newTargetPool;
    }

   ////////////////////get pool info /////////////  
    function getPoolInfo() public view returns (uint _poolRaised,uint _targetPool,uint _poolBalance,address _LiquidityPoolLocker, uint _totalLiquidityTokens) {
        return (poolRaised,targetPool,poolBalance,LiquidityPoolLocker,totalLiquidityTokens);
    }

   //////////////////// Manual Add Liquidity /////////////  
    function manualAddLiquidity (uint EthAmount)  public onlyOwner {
        require (EthAmount <= poolBalance, "Nftania Crowdsale: No Enough funds for liquidity");
        uint tokenAmount = calclulateTokens (EthAmount);
        require(D,"D");   
        callAddLiquidity (tokenAmount, EthAmount) ;
        (, uint amountETH,,,) = callAddLiquidity (tokenAmount, EthAmount) ;
        poolBalance -= amountETH;
        // poolBalance -= EthAmount;
        require(F,"F");
        emit ManualLiquidity (tokenAmount,EthAmount);
    }

    function calclulateTokens (uint EthAmount) internal view returns (uint tokenAmount){
        tokenAmount = (EthAmount / tokenPrice) * 10**18;
        return tokenAmount;
    }
        
   //////////////////// Add Liquidity /////////////  
    function callAddLiquidity (uint tokenAmount, uint EthAmount) internal
    returns (uint amountToken, uint amountETH,uint amountliquidityTokens, uint _totalLiquidityTokens, address pairAddress){
        IERC20(tokenAddress).safeTransferFrom(owner(), address(this), tokenAmount); 
        // get current liquidity contract allowance
        uint currentAllowance = IERC20(tokenAddress).allowance(address(this), AddLiquidityContract);
        // reset current liquidity contract allowance to zero
        IERC20(tokenAddress).safeDecreaseAllowance(AddLiquidityContract, currentAllowance);  
        // set the needed allowance
        IERC20(tokenAddress).safeIncreaseAllowance(AddLiquidityContract, tokenAmount);  
        (amountToken, amountETH, amountliquidityTokens, totalLiquidityTokens, pairAddress) = 
        IAddLiquidity(AddLiquidityContract).addLiquidityETH {value:EthAmount} (tokenAddress, tokenAmount, EthAmount, LiquidityPoolLocker);
        require(C,"C");
        emit LiquidityAdded (amountToken, amountETH, amountliquidityTokens, totalLiquidityTokens, pairAddress);
        return (amountToken, amountETH, amountliquidityTokens, totalLiquidityTokens, pairAddress);
    }   


   ////////////////// Modifier Checks if Not Closed  ///////////////////// 
    modifier whenNotClosed {
        require(!closed,"Nftania Crowdsale: Crowdsale is closed");
        _;
    }

   //////////////////////// Pause/UnPause Smart Contract ///////////////////// 
    function pause() public onlyOwner {
        _pause();
        emit ContractIsPaused(true);        
    }
    
    function unpause() public onlyOwner {
        _unpause();
        emit ContractIsPaused(false);
    }

   /////////////////////// Disable Renounce Ownership //////////////////////////////////// 
    function renounceOwnership() public view override onlyOwner {
        revert("Nftania Crowdsale: Ownership cannot be renounced");  
    }   
}