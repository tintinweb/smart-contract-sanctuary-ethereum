/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

/*
       ...                                                                                          
     :^^^^^:.                                            
  .:^^^^::^^^:.       
 :~^^::.  .:::^:.     
  :^^::. ..::::.    
   .^^::.::::. 
     :^:::::  
      .:::.                                            
        .   
*/
//SPDX-License-Identifier: MIT
     
// File: NHistorian.sol


pragma solidity 0.8.17;

/**
 * @author  Hyper0x0 for NEON Protocol.
 * @title   NHistorian.
 * @dev     All internal must be used as an abstract contract.
 * @notice  This contract takes care of historicizing the data of past DCAs for each user.
 */
contract NHistorian {

    struct data{
        mapping (uint256 => histDetail) userData;
        uint8 totStored;
        uint8 bufferId;
    }

    struct histDetail{
        address srcToken;
        uint256 chainId;
        address destToken;
        address ibStrategy;
        uint40 closedDcaTime;
        uint8 reason; // (0 = Completed, 1 = User Close DCA, 2 = Strike Reached...)
    }

    mapping (address => data) private database;
    
    /* WRITE METHODS*/
    /* INTERNAL */
    /**
     * @notice  store DCA data to buffer database.
     * @param   _userAddress  reference address of the owner.
     * @param   _struct  data to be stored.
     */
    function _storeDCA(address _userAddress, histDetail memory _struct) internal {
        require(_userAddress != address(0), "NHistorian: Null address not allowed");
        //buffer
        database[_userAddress].bufferId = database[_userAddress].bufferId >= 200 ? 1 : database[_userAddress].bufferId +1;
        uint8 bufferId = database[_userAddress].bufferId;
        database[_userAddress].userData[bufferId].srcToken = _struct.srcToken;
        database[_userAddress].userData[bufferId].chainId = _struct.chainId;
        database[_userAddress].userData[bufferId].destToken = _struct.destToken;
        database[_userAddress].userData[bufferId].ibStrategy = _struct.ibStrategy;
        database[_userAddress].userData[bufferId].closedDcaTime = _struct.closedDcaTime;
        database[_userAddress].userData[bufferId].reason = _struct.reason;
        if(database[_userAddress].totStored < 200){
            unchecked {
                database[_userAddress].totStored ++;
            }
        }
    }
    /* VIEW METHODS*/
    /* INTERNAL */
    /**
     * @notice  Retrieve all data from a specific address.
     * @param   _userAddress  reference address.
     * @return  histDetail batch data for each nBatch.
     * @return  nBatch number of batch data retrieved.
     */
    function _getHistoryDataBatch(address _userAddress) internal view returns(histDetail[] memory, uint8 nBatch){
        uint8 totStored = database[_userAddress].totStored;
        histDetail[] memory dataOut = new histDetail[](totStored);
        for(uint8 i = 1; i <= totStored; i ++){
            dataOut[i - 1] = database[_userAddress].userData[i];
        }
        return (dataOut, totStored);
    }
}
// File: interfaces/INStrategyIb.sol

pragma solidity 0.8.17;

interface INStrategyIb {
    function depositAndStake(address _source, address _receiver, address _token, uint256 _amount) external;
    function available(address _token) external view returns (bool);
}
// File: utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// File: extensions/IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// File: utils/Context.sol


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
// File: access/Ownable.sol


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
// File: interfaces/IERC20.sol


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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
// File: utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// File: lib/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
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
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
// File: NDCA.sol


pragma solidity 0.8.17;



/**
 * @author  Hyper0x0 for NEON Protocol.
 * @title   NDCA.
 * @dev     External contract part of NCore protocol, calls are enable only from NCore.
 * @notice  This contract manages DCAs, from creation to execution.
 */
contract NDCA {
    using SafeERC20 for ERC20;

    struct dcaData{
        address owner;
        address reciever;
        address srcToken;
        uint256 chainId;
        address destToken;
        uint8 destDecimals;
        address ibStrategy;
        uint256 srcAmount;
        uint8 tau;
        uint40 nextExecution;//sec
        uint40 lastExecutionOk;
        uint256 averagePrice;//USD (precision 6 dec)
        uint256 destTokenEarned;
        uint40 reqExecution;//0 = Unlimited
        uint40 perfExecution;
        uint8 strike;
        uint16 code;
        bool initExecution;
    }

    struct dcaDetail{
        address reciever;
        address srcToken;
        uint256 chainId;
        address destToken;
        address ibStrategy;
        uint256 srcAmount;
        uint8 tau;
        uint40 nextExecution;
        uint40 lastExecutionOk;
        uint256 averagePrice;
        uint256 destTokenEarned;
        uint40 reqExecution;
        uint40 perfExecution;
        uint8 strike;
        uint16 code;
        bool allowOk;
        bool balanceOk;
    }

    mapping (uint40 => dcaData) private DCAs;
    mapping (bytes32 => uint40) private dcaPosition;
    mapping (address => mapping (address => uint256)) private userAllowance;
    uint40 public activeDCAs;
    uint40 public totalPositions;

    uint8 immutable private MIN_TAU;
    uint8 immutable private MAX_TAU;
    uint24 immutable private TIME_BASE;
    uint256 immutable public DEFAULT_APPROVAL;
    address immutable public RESOLVER;
    address immutable public NCORE;

    event DCACreated(uint40 positionId, address owner);
    event DCAClosed(uint40 positionId, address owner);
    event DCASkipExe(uint40 positionId, address owner, uint40 _nextExecution);
    event DCAExecuted(uint40 positionId, address indexed reciever, uint256 chainId, uint256 amount, bool ibEnable, uint16 code);
    event DCAError(uint40 positionId, address indexed owner, uint8 strike);

    modifier onlyCore() {
        require(msg.sender == NCORE, "NDCA: Only Core is allowed");
        _;
    }

    constructor(address _NCore, address _resolver, uint256 _defaultApproval, uint24 _timeBase, uint8 _minTau, uint8 _maxTau){
        NCORE = _NCore;
        RESOLVER = _resolver;
        DEFAULT_APPROVAL = _defaultApproval;
        TIME_BASE = _timeBase;
        MIN_TAU = _minTau;
        MAX_TAU = _maxTau;
    }

    /* WRITE METHODS*/
    /**
     * @notice  DCA creation.
     * @dev     startegies are available only in the current chain.
     * @param   _user  DCA owner.
     * @param   _reciever  Address where will recieve token / receipt.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @param   _destDecimals  Destination token decimals.
     * @param   _ibStrategy  Strategy address.
     * @param   _srcAmount  Amount to invest into the DCA.
     * @param   _tau  Frequency of invest.
     * @param   _reqExecution  Required execution, if 0 is unlimited.
     * @param   _nowFirstExecution  if true, the first execution is brought forward to the current day.
     */
    function createDCA(
        address _user,
        address _reciever,
        address _srcToken,
        uint256 _chainId,
        address _destToken,
        uint8 _destDecimals,
        address _ibStrategy,
        uint256 _srcAmount,
        uint8 _tau,
        uint40 _reqExecution,
        bool _nowFirstExecution
    ) external onlyCore {
        require(_user != address(0) && _reciever != address(0), "NDCA: Null address not allowed");
        //require not needed, in the Core they are already checked against NPairs
        require(_tau >= MIN_TAU && _tau <= MAX_TAU, "NDCA: Tau out of limits");
        bytes32 uniqueId = _getId(_user, _srcToken, _chainId, _destToken, _ibStrategy);
        require(DCAs[dcaPosition[uniqueId]].owner == address(0), "NDCA: Already created with this pair");
        uint256 allowanceToAdd = _reqExecution == 0 ? (DEFAULT_APPROVAL * 10 ** ERC20(_srcToken).decimals()) : (_srcAmount * _reqExecution);
        address owner = _user;//too avoid "Stack too Deep"
        userAllowance[owner][_srcToken] = (userAllowance[owner][_srcToken] + allowanceToAdd) < type(uint256).max ? (userAllowance[owner][_srcToken] + allowanceToAdd) : type(uint256).max;
        require(ERC20(_srcToken).allowance(owner, address(this)) >= userAllowance[owner][_srcToken],"NDCA: Insufficient approved token");
        require(ERC20(_srcToken).balanceOf(owner) >= _srcAmount,"NDCA: Insufficient balance");
        if(dcaPosition[uniqueId] == 0){
            require(totalPositions <= type(uint40).max, "NDCA: Reached max positions");
            unchecked {
                totalPositions ++;
            }
            dcaPosition[uniqueId] = totalPositions;
        }       
        DCAs[dcaPosition[uniqueId]].owner = _user;
        DCAs[dcaPosition[uniqueId]].reciever = _reciever;
        DCAs[dcaPosition[uniqueId]].srcToken = _srcToken;
        DCAs[dcaPosition[uniqueId]].chainId = _chainId;
        DCAs[dcaPosition[uniqueId]].destToken = _destToken;
        DCAs[dcaPosition[uniqueId]].destDecimals = _destDecimals;
        DCAs[dcaPosition[uniqueId]].ibStrategy = _ibStrategy;
        DCAs[dcaPosition[uniqueId]].srcAmount = _srcAmount;
        DCAs[dcaPosition[uniqueId]].tau = _tau;
        DCAs[dcaPosition[uniqueId]].nextExecution = _nowFirstExecution ? uint40(block.timestamp) : (uint40(block.timestamp)+(_tau*TIME_BASE));
        DCAs[dcaPosition[uniqueId]].lastExecutionOk = 0;
        DCAs[dcaPosition[uniqueId]].averagePrice = 0;
        DCAs[dcaPosition[uniqueId]].destTokenEarned = 0;
        DCAs[dcaPosition[uniqueId]].reqExecution = _reqExecution;
        DCAs[dcaPosition[uniqueId]].perfExecution = 0;
        DCAs[dcaPosition[uniqueId]].strike = 0;
        DCAs[dcaPosition[uniqueId]].code = 0;
        DCAs[dcaPosition[uniqueId]].initExecution = false;
        unchecked {
            activeDCAs ++;
        }
        emit DCACreated(dcaPosition[uniqueId], _user);
    }
    /**
     * @notice  Close DCA.
     * @param   _user  DCA owner.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @param   _ibStrategy  Strategy address.
     */
    function closeDCA(address _user, address _srcToken, uint256 _chainId, address _destToken, address _ibStrategy) public onlyCore {
        require(_user != address(0), "NDCA: Null address not allowed");
        bytes32 uniqueId = _getId(_user, _srcToken, _chainId, _destToken, _ibStrategy);
        require(DCAs[dcaPosition[uniqueId]].owner != address(0), "NDCA: Already closed");
        DCAs[dcaPosition[uniqueId]].owner = address(0);
        uint256 allowanceToRemove;
        if(DCAs[dcaPosition[uniqueId]].reqExecution == 0){
            allowanceToRemove = ((DEFAULT_APPROVAL * 10 ** ERC20(_srcToken).decimals()) - (DCAs[dcaPosition[uniqueId]].srcAmount * DCAs[dcaPosition[uniqueId]].perfExecution));
        }else{
            allowanceToRemove = (DCAs[dcaPosition[uniqueId]].srcAmount * (DCAs[dcaPosition[uniqueId]].reqExecution - DCAs[dcaPosition[uniqueId]].perfExecution));
        }
        userAllowance[_user][_srcToken] -= userAllowance[_user][_srcToken] >= allowanceToRemove ? allowanceToRemove : userAllowance[_user][_srcToken];
        unchecked {
            activeDCAs --;
        }
        emit DCAClosed(dcaPosition[uniqueId], _user);
    }
    /**
     * @notice  Skip next execution.
     * @param   _user  DCA owner.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @param   _ibStrategy  Strategy address.
     */
    function skipNextExecution(address _user, address _srcToken, uint256 _chainId, address _destToken, address _ibStrategy) external onlyCore {
        require(_user != address(0), "NDCA: Null address not allowed");
        bytes32 uniqueId = _getId(_user, _srcToken, _chainId, _destToken, _ibStrategy);
        require(DCAs[dcaPosition[uniqueId]].owner != address(0), "NDCA: Already closed");
        unchecked {
            DCAs[dcaPosition[uniqueId]].nextExecution += (DCAs[dcaPosition[uniqueId]].tau * TIME_BASE);
        }
        emit DCASkipExe(dcaPosition[uniqueId], _user, DCAs[dcaPosition[uniqueId]].nextExecution);
    }
    /**
     * @notice  Initialize DCA execution to collect funds.
     * @param   _dcaId  Id of the DCA.
     */
    function initExecution(uint40 _dcaId) external onlyCore {
        require(_dcaId != 0 && _dcaId <= totalPositions, "NDCA: Id out of range");
        require(block.timestamp >= DCAs[_dcaId].nextExecution, "NDCA: Execution not required");
        if(!DCAs[_dcaId].initExecution){
            DCAs[_dcaId].initExecution = true;
            ERC20(DCAs[_dcaId].srcToken).safeTransferFrom(DCAs[_dcaId].owner, RESOLVER, DCAs[_dcaId].srcAmount);
        }
    }
    /**
     * @notice  Complete DCA execution, update values, handle refund and auto close.
     * @param   _dcaId  Id of the DCA.
     * @param   _destTokenAmount  Token earned with the DCA.
     * @param   _code  Execution code.
     * @param   _averagePrice  Single token purchase price USD.
     * @return  toBeStored  True if need to store the DCA.
     * @return  reason  Reason for the closure of the DCA.
     */
    function updateDCA(uint40 _dcaId, uint256 _destTokenAmount, uint16 _code, uint256 _averagePrice) external onlyCore returns (bool toBeStored, uint8 reason){
        require(_dcaId != 0 && _dcaId <= totalPositions, "NDCA: Id out of range");
        require(block.timestamp >= DCAs[_dcaId].nextExecution, "NDCA: Execution not required");
        uint40 actualtime = (block.timestamp - DCAs[_dcaId].nextExecution) >= TIME_BASE ? (uint40(block.timestamp) - 3600) : DCAs[_dcaId].nextExecution;
        DCAs[_dcaId].nextExecution =  actualtime + (DCAs[_dcaId].tau * TIME_BASE);
        DCAs[_dcaId].code = _code;
        if(_code == 200){
            DCAs[_dcaId].initExecution = false;
            DCAs[_dcaId].lastExecutionOk = uint40(block.timestamp);
            DCAs[_dcaId].destTokenEarned += _destTokenAmount;
            unchecked {
                DCAs[_dcaId].perfExecution ++;
                DCAs[_dcaId].averagePrice = DCAs[_dcaId].averagePrice == 0 ? _averagePrice : ((DCAs[_dcaId].averagePrice + _averagePrice) / 2);
            }
            emit DCAExecuted(_dcaId, DCAs[_dcaId].reciever, DCAs[_dcaId].chainId, _destTokenAmount, (DCAs[_dcaId].ibStrategy != address(0)), _code);
        }else{
            if(DCAs[_dcaId].initExecution){
                DCAs[_dcaId].initExecution = false;
                _refund(_code, _dcaId, _destTokenAmount);
            }
            unchecked {
                DCAs[_dcaId].strike ++;
            }
            emit DCAError(_dcaId, DCAs[_dcaId].owner, DCAs[_dcaId].strike);
        }
        //Completed or Errors
        if((DCAs[_dcaId].reqExecution != 0 && DCAs[_dcaId].perfExecution >= DCAs[_dcaId].reqExecution) || DCAs[_dcaId].strike >= 2){
            closeDCA(DCAs[_dcaId].owner, DCAs[_dcaId].srcToken, DCAs[_dcaId].chainId, DCAs[_dcaId].destToken, DCAs[_dcaId].ibStrategy);
            toBeStored = true;
            if(DCAs[_dcaId].strike >= 2){reason = 2;}
        }
    }
    /* VIEW METHODS*/
    /**
     * @notice  Manages dynamic approval.
     * @param   _user  DCA owner.
     * @param   _srcToken  Source token address.
     * @param   _srcAmount  Amount to invest into the DCA.
     * @param   _reqExecution  Required execution, if 0 is unlimited.
     * @return  allowOk  True if allowance is OK.
     * @return  increase  True if need to increaseAllowance or false if need to approve.
     * @return  allowanceToAdd  Value to approve from ERC20 approval.
     * @return  allowanceDCA  Total value approved into the DCA contract.
     */
    function checkAllowance(address _user, address _srcToken, uint256 _srcAmount, uint40 _reqExecution) external view returns (bool allowOk, bool increase, uint256 allowanceToAdd, uint256 allowanceDCA){
        uint256 ERC20Allowance = ERC20(_srcToken).allowance(_user, address(this));
        uint256 totalAmount = _reqExecution == 0 ? (DEFAULT_APPROVAL * 10 ** ERC20(_srcToken).decimals()) : (_srcAmount * _reqExecution);
        if(ERC20Allowance >= userAllowance[_user][_srcToken] && (userAllowance[_user][_srcToken] + totalAmount) < type(uint256).max){
            if((ERC20Allowance - userAllowance[_user][_srcToken]) >= totalAmount){
                allowOk = true;
            }else{
                increase = true;
                allowanceToAdd = totalAmount;
            }
        }else{
            bool maxAllow = (userAllowance[_user][_srcToken] + totalAmount) >= type(uint256).max;
            allowanceToAdd = maxAllow ? type(uint256).max : (userAllowance[_user][_srcToken] + totalAmount);
        }
        allowanceDCA = userAllowance[_user][_srcToken];
    }
    /**
     * @notice  check if you have already created the DCA.
     * @param   _user  DCA owner.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @param   _ibStrategy  Strategy address.
     * @return  bool  true if is possible create a DCA.
     */
    function checkAvailability(address _user, address _srcToken, uint256 _chainId, address _destToken, address _ibStrategy) external view returns (bool){
        bytes32 uniqueId = _getId(_user, _srcToken, _chainId, _destToken, _ibStrategy);
        return (DCAs[dcaPosition[uniqueId]].owner == address(0));
    }
    /**
     * @notice  Check if a DCA should be executed.
     * @param   _dcaId  Id of the DCA.
     * @return  bool  True if need to be executed.
     */
    function preCheck(uint40 _dcaId) external view returns (bool){
        return (block.timestamp >= DCAs[_dcaId].nextExecution && DCAs[_dcaId].owner != address(0));
    }
    /**
     * @notice  Check requirements for performing the DCA.
     * @param   _dcaId  Id of the DCA.
     * @return  exe  True if need to be executed.
     * @return  allowOk  True if allowance is OK.
     * @return  balanceOk  True if balance is OK.
     */
    function check(uint40 _dcaId) external view onlyCore returns (bool exe, bool allowOk, bool balanceOk){
        exe = (block.timestamp >= DCAs[_dcaId].nextExecution && DCAs[_dcaId].owner != address(0));
        if(exe){
            allowOk = (ERC20(DCAs[_dcaId].srcToken).allowance(DCAs[_dcaId].owner, address(this)) >= DCAs[_dcaId].srcAmount);
            balanceOk = (ERC20(DCAs[_dcaId].srcToken).balanceOf(DCAs[_dcaId].owner) >= DCAs[_dcaId].srcAmount);
        }
    }
    /**
     * @notice  Return data to execute the swap.
     * @param   _dcaId  Id of the DCA.
     * @return  reciever  Address where will recieve token / receipt.
     * @return  srcToken  Source token address.
     * @return  srcDecimals  Source token decimals.
     * @return  chainId  Chain id for the destination token.
     * @return  destToken  Destination token address.
     * @return  destDecimals  Destination token decimals.
     * @return  ibStrategy  Strategy address.
     * @return  srcAmount  Amount to invest into the DCA.
     */
    function dataDCA(uint40 _dcaId) external view onlyCore returns (
        address reciever,
        address srcToken,
        uint8 srcDecimals,
        uint256 chainId,
        address destToken,
        uint8 destDecimals,
        address ibStrategy,
        uint256 srcAmount
    ){
        reciever = DCAs[_dcaId].reciever;
        srcToken = DCAs[_dcaId].srcToken;
        srcDecimals = ERC20(DCAs[_dcaId].srcToken).decimals();
        chainId = DCAs[_dcaId].chainId;
        destToken = DCAs[_dcaId].destToken;
        destDecimals = DCAs[_dcaId].destDecimals;
        ibStrategy = DCAs[_dcaId].ibStrategy;
        srcAmount = DCAs[_dcaId].srcAmount;
    }
    /**
     * @notice  Return data to display into the fronend.
     * @param   _dcaId  Id of the DCA.
     * @param   _user  DCA owner.
     * @return  dcaDetail  DCA info data.
     */
    function detailDCA(uint40 _dcaId, address _user) external view onlyCore returns (dcaDetail memory){
        dcaDetail memory data;
        if(DCAs[_dcaId].owner == _user){
            data.reciever = DCAs[_dcaId].reciever;
            data.srcToken = DCAs[_dcaId].srcToken;
            data.chainId = DCAs[_dcaId].chainId;
            data.destToken = DCAs[_dcaId].destToken;
            data.ibStrategy = DCAs[_dcaId].ibStrategy;
            data.srcAmount = DCAs[_dcaId].srcAmount;
            data.tau = DCAs[_dcaId].tau;
            data.nextExecution = DCAs[_dcaId].nextExecution;
            data.lastExecutionOk = DCAs[_dcaId].lastExecutionOk;
            data.averagePrice = DCAs[_dcaId].averagePrice;
            data.destTokenEarned = DCAs[_dcaId].destTokenEarned;
            data.reqExecution = DCAs[_dcaId].reqExecution;
            data.perfExecution = DCAs[_dcaId].perfExecution;
            data.strike = DCAs[_dcaId].strike;
            data.code = DCAs[_dcaId].code;
            data.allowOk = (ERC20(DCAs[_dcaId].srcToken).allowance(DCAs[_dcaId].owner, address(this)) >= DCAs[_dcaId].srcAmount);
            data.balanceOk = (ERC20(DCAs[_dcaId].srcToken).balanceOf(DCAs[_dcaId].owner) >= DCAs[_dcaId].srcAmount);
        }
        return data;
    }
    /* PRIVATE */
    /**
     * @notice  Generate unique Id.
     * @param   _user  DCA owner.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @param   _ibStrategy  Strategy address.
     * @return  bytes32  Unique Hash id.
     */
    function _getId(
        address _user,
        address _srcToken,
        uint256 _chainId,
        address _destToken,
        address _ibStrategy
    ) private pure returns (bytes32){
        return keccak256(abi.encodePacked(_user, _srcToken, _chainId, _destToken, _ibStrategy));
    }
    /**
     * @notice  Manage refund in case of error.
     * @dev     ibStartegy error from DCA contract return destToken, Swap error from Router return srcToken.
     * @param   _code  Error code of the execution.
     * @param   _dcaId  Id of the DCA.
     * @param   _destTokenAmount  Token earned with the DCA.
     */
    function _refund(uint16 _code, uint40 _dcaId, uint256 _destTokenAmount) private {
        if(_code == 402){
            ERC20(DCAs[_dcaId].destToken).safeTransfer(DCAs[_dcaId].owner, _destTokenAmount);
        }else{
            ERC20(DCAs[_dcaId].srcToken).safeTransferFrom(RESOLVER, DCAs[_dcaId].owner, DCAs[_dcaId].srcAmount);
        }
    }
}
// File: NPairs.sol


pragma solidity 0.8.17;


/**
 * @author  Hyper0x0 for NEON Protocol.
 * @title   NPairs.
 * @notice  This contract deals with listing and checking the validity of the tokens pairs set in the DCAs.
 */
contract NPairs {

    struct token{
        bool active;
        uint8 decimals;
    }

    //Token = Active
    mapping (address => bool) private srcToken;
    //ChainId => Token = Struct (Normal + CC)
    mapping (uint256 => mapping (address => token)) private destToken;
    //srcToken => chainId => destToken = Active
    mapping (address => mapping (uint256 => mapping (address => bool))) private NotAwailablePair;

    uint16 private totStrategy;
    uint16 private totDest;
    uint16 private totSrc;
    address immutable public OWNER;

    event SrcTokenListed(address indexed token, string symbol);
    event DestTokenListed(uint256 chainId, address indexed token, string symbol);

    modifier onlyOwner() {
        require(msg.sender == OWNER, "NPairs: Only Owner is allowed");
        _;
    }

    constructor(address _owner){
        OWNER = _owner;
    }

    /* WRITE METHODS*/
    /**
     * @notice  List source token that will be swapped.
     * @param   _token  Token address.
     */
    function listSrcToken(address _token) external onlyOwner {
        require(_token != address(0), "NPairs: Null address not allowed");
        require(!srcToken[_token], "NPairs: Token already listed");
        _listSrcToken(_token);
    }
    /**
     * @notice  List destination token that will be recieved.
     * @dev     _decimals & _symbol will be need if chain id is different from the current one.
     * @param   _chainId  Destination chain id.
     * @param   _token  Token address.
     * @param   _decimals  Token decimals.
     * @param   _symbol  Token symbol.
     */
    function listDestToken(uint256 _chainId, address _token, uint8 _decimals, string memory _symbol) external onlyOwner {
        require(_token != address(0), "NPairs: Null address not allowed");
        require(_chainId != 0, "NPairs: Chain ID must be > 0");
        require(!destToken[_chainId][_token].active, "NPairs: Token already listed");
        _listDestToken(_chainId, _token, _decimals, _symbol);
    }
    /**
     * @notice  Blacklist combination of tokens.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     */
    function blacklistPair(address _srcToken, uint256 _chainId, address _destToken) external onlyOwner {
        require(_srcToken != address(0) && _destToken != address(0), "NPairs: Null address not allowed");
        require(srcToken[_srcToken], "NPairs: Src.Token not listed");
        require(destToken[_chainId][_destToken].active, "NPairs: Dest.Token not listed");
        NotAwailablePair[_srcToken][_chainId][_destToken] = !NotAwailablePair[_srcToken][_chainId][_destToken];
    }
    /* VIEW METHODS */
    /**
     * @notice  Return total tokens and strategy listed.
     */
    function totalListed() external view returns(uint16 totSrcToken, uint16 totDestToken){
        return(totSrc, totDest);
    }
    /**
     * @notice  Return status of selected pair.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @return  true if pair is available.
     */
    function isPairAvailable(address _srcToken, uint256 _chainId, address _destToken) public view returns(bool){
        require(_srcToken != address(0) && _destToken != address(0), "NPairs: Null address not allowed");
        require(srcToken[_srcToken], "NPairs: Src.Token not listed");
        require(destToken[_chainId][_destToken].active, "NPairs: Dest.Token not listed");
        return !(NotAwailablePair[_srcToken][_chainId][_destToken]);
    }
    /* PRIVATE */
    function _listSrcToken(address _token) private {
        srcToken[_token] = true;
        unchecked {
            totSrc ++;
        }
        emit SrcTokenListed(_token, ERC20(_token).symbol());
    }
    function _listDestToken(uint256 _chainId, address _token, uint8 _decimals, string memory _symbol) private {
        string memory symbol;
        destToken[_chainId][_token].active = true;
        unchecked {
            totDest ++;
        }
        if(_chainId == block.chainid){
            symbol = ERC20(_token).symbol();
            destToken[_chainId][_token].decimals = ERC20(_token).decimals();
        }else{
            symbol = _symbol;
            destToken[_chainId][_token].decimals = _decimals;
        }
        emit DestTokenListed(_chainId, _token, symbol);
    }
}
// File: NCore.sol


pragma solidity 0.8.17;









/**
 * @author  Hyper0x0 for NEON Protocol.
 * @title   NCore.
 * @dev     Automatically deploy all needed contract expect for the strategies.
 * @notice  This contract manage the protocol, call by the UI and resolve flow.
 */
contract NCore is NHistorian {
    using SafeERC20 for ERC20;
    
    struct resolverData{
        uint40 id;
        bool allowOk;
        bool balanceOk;
        address reciever;
        address srcToken;
        uint8 srcDecimals;
        uint256 chainId;
        address destToken;
        uint8 destDecimals;
        address ibStrategy;
        uint256 srcAmount;
    }

    struct update{
        uint40 id;
        uint256 destTokenAmount;
        uint256 averagePrice;
        uint16 code;
    }

    bool public resolverBusy;
    address immutable public DCA;
    address immutable public POOL;
    address immutable public RESOLVER;

    modifier onlyResolver() {
        require(msg.sender == RESOLVER, "NCore: Only Resolver is allowed");
        _;
    }

    modifier resolverFree() {
        require(!resolverBusy, "NCore: Resolver is computing, try later");
        _;
    }

    constructor(address _resolver, uint256 _defaultApproval, uint24 _timeBase, uint8 _minTau, uint8 _maxTau){
        DCA = address(
            new NDCA(address(this), _resolver, _defaultApproval, _timeBase, _minTau, _maxTau)
        );
        POOL = address(
            new NPairs(msg.sender)
        );
        RESOLVER = _resolver;
    }

    /* WRITE METHODS*/
    /**
     * @notice  DCA creation.
     * @param   _reciever  Address where will recieve token / receipt.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @param   _destDecimals  Destination token decimals.
     * @param   _ibStrategy  Strategy address.
     * @param   _srcAmount  Amount to invest into the DCA.
     * @param   _tau  Frequency of invest.
     * @param   _reqExecution  Required execution, if 0 is unlimited.
     * @param   _nowFirstExecution  if true, the first execution is brought forward to the current day.
     */
    function createDCA(
        address _reciever,
        address _srcToken,
        uint256 _chainId,
        address _destToken,
        uint8 _destDecimals,
        address _ibStrategy,
        uint256 _srcAmount,
        uint8 _tau,
        uint40 _reqExecution,
        bool _nowFirstExecution
    ) external resolverFree {  
        require(NPairs(POOL).isPairAvailable(_srcToken, _chainId, _destToken), "NCore: Selected pair not available");
        address strategy;
        if(_chainId == block.chainid && _ibStrategy != address(0)){
            require(INStrategyIb(_ibStrategy).available(_destToken), "NCore: Selected strategy not available");
            strategy = _ibStrategy;
        }
        NDCA(DCA).createDCA(msg.sender, _reciever, _srcToken, _chainId, _destToken, _destDecimals, strategy, _srcAmount, _tau, _reqExecution, _nowFirstExecution);
    }
    /**
     * @notice  Close DCA.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @param   _ibStrategy  Strategy address.
     */
    function closeDCA(address _srcToken, uint256 _chainId, address _destToken, address _ibStrategy) external resolverFree {
        NDCA(DCA).closeDCA(msg.sender, _srcToken, _chainId, _destToken, _ibStrategy);
        _storeDCA(msg.sender, histDetail(_srcToken, _chainId, _destToken, _ibStrategy, uint40(block.timestamp), 1));
    }
    /**
     * @notice  Skip next execution.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @param   _ibStrategy  Strategy address.
     */
    function skipNextExecution(address _srcToken, uint256 _chainId, address _destToken, address _ibStrategy) external resolverFree {
        NDCA(DCA).skipNextExecution(msg.sender, _srcToken, _chainId, _destToken, _ibStrategy);
    }
    /**
     * @notice  Trasfer residual token to resolver.
     * @dev     Available only when resolver isn't computing so there will be nothing left.
     * @param   _tokens  Array of tokens to be trasfered.
     */
    function getResidual(address[] memory _tokens) external resolverFree onlyResolver {
        uint40 length = uint40(_tokens.length);
        uint256 balance;
        for(uint40 i; i < length; i ++){
            balance = ERC20(_tokens[i]).balanceOf(address(this));
            ERC20(_tokens[i]).safeTransfer(RESOLVER, balance);
        }
    }
    /**
     * @notice  Initiate Resolver.
     */
    function startupResolver() external onlyResolver {
        _initResolver();
    }
    /**
     * @notice  Start DCA executions.
     * @param   _ids  Positions Ids to be executed.
     */
    function startExecution(uint40[] memory _ids) external onlyResolver {
        uint40 length = uint40(_ids.length);
        for(uint40 i; i < length; i ++){
            NDCA(DCA).initExecution(_ids[i]);
        }
    }
    /**
     * @notice  Close / Complete DCA execution.
     * @dev     Manage Ib strategy to Deposit&Stake.
     * @param   _data  Positions datas to be updated after execution.
     */
    function closureExecution(update[] memory _data) external onlyResolver {
        uint40 length = uint40(_data.length);
        for(uint40 i; i < length; i ++){
            update memory tempData = _data[i];
            uint16 code = tempData.code;
            (address reciever, address srcToken, , uint256 chainId, address destToken, , address ibStrategy, ) = NDCA(DCA).dataDCA(tempData.id);
            if(ibStrategy != address(0) && code == 200){
                ERC20(destToken).approve(ibStrategy, tempData.destTokenAmount);
                try INStrategyIb(ibStrategy).depositAndStake(address(this), reciever, destToken, tempData.destTokenAmount){   
                }catch{
                    ERC20(destToken).safeTransfer(DCA, tempData.destTokenAmount);
                    code = 402;
                }
            }
            (bool toBeStored, uint8 reason) = NDCA(DCA).updateDCA(tempData.id, tempData.destTokenAmount, code, tempData.averagePrice);
            if(toBeStored){
                _storeDCA(msg.sender, histDetail(srcToken, chainId, destToken, ibStrategy, uint40(block.timestamp), reason));
            }
        }
        _initResolver();
    }
    /* VIEW METHODS*/
    /**
     * @notice  Manages dynamic approval.
     * @param   _srcToken  Source token address.
     * @param   _srcAmount  Amount to invest into the DCA.
     * @param   _reqExecution  Required execution, if 0 is unlimited.
     * @return  allowOk  True if allowance is OK.
     * @return  increase  True if need to increaseAllowance or false if need to approve.
     * @return  allowanceToAdd  Value to approve from ERC20 approval.
     * @return  allowanceDCA  Total value approved into the DCA contract.
     */
    function checkAllowance(address _srcToken, uint256 _srcAmount, uint40 _reqExecution) external view returns (bool allowOk, bool increase, uint256 allowanceToAdd, uint256 allowanceDCA){
        return NDCA(DCA).checkAllowance(msg.sender, _srcToken, _srcAmount, _reqExecution);
    }
    /**
     * @notice  Verify if the user can create DCA.
     * @param   _srcToken  Source token address.
     * @param   _chainId  Chain id for the destination token.
     * @param   _destToken  Destination token address.
     * @param   _ibStrategy  Strategy address.
     * @return  bool  True if is possible to create DCA.
     */
    function checkAvailability(address _srcToken, uint256 _chainId, address _destToken, address _ibStrategy) external view returns (bool){
        return NDCA(DCA).checkAvailability(msg.sender, _srcToken, _chainId, _destToken, _ibStrategy);
    }
    /**
     * @notice  Retrieve data for UI of active DCAs.
     * @return  NDCA.dcaDetail[]  Array (Tuple) of data struct.
     * @return  nBatch  Number of DCAs retrieved (Current active DCAs).
     */
    function getDetail() external view returns (NDCA.dcaDetail[] memory, uint40 nBatch){
        NDCA.dcaDetail[] memory outData = new NDCA.dcaDetail[](_totalUserDCA(msg.sender));
        NDCA.dcaDetail memory tempData;
        uint40 id;
        uint40 totalpositions = NDCA(DCA).totalPositions();
        for(uint40 i = 1; i <= totalpositions; i ++){
            tempData = NDCA(DCA).detailDCA(i, msg.sender);
            if(tempData.reciever != address(0)){
                outData[id] = tempData;
                unchecked {
                    id ++;
                }
            }
        }
        return (outData, id);
    }
    /**
     * @notice  Retrieve data for UI of closed DCAs.
     * @return  histDetail[]  Array (Tuple) of data struct.
     * @return  nBatch  Number of History DCAs retrieved.
     */
    function getHistorian() external view returns (histDetail[] memory, uint40 nBatch){
        return _getHistoryDataBatch(msg.sender);
    }
    /**
     * @notice  Verify if one of DCAs need to be execute.
     * @return  bool  True is execution is needed.
     */
    function isExecutionNeeded() external view onlyResolver returns (bool){
        bool outData;
        uint40 totalpositions = NDCA(DCA).totalPositions();
        for(uint40 i = 1; i <= totalpositions; i ++){
            if(NDCA(DCA).preCheck(i)){
                outData = true;
                break;
            }
        }
        return outData;
    }
    /**
     * @notice  Retrieve data for resolver of DCAs that need execution.
     * @return  resolverData[]  Array (Tuple) of data struct.
     * @return  nBatch  Number DCAs retrieved.
     */
    function getDataDCA() external view onlyResolver returns (resolverData[] memory, uint40 nBatch){
        resolverData[] memory outData = new resolverData[](_totalExecutable());
        uint40 id;
        uint40 totalpositions = NDCA(DCA).totalPositions();
        for(uint40 i = 1; i <= totalpositions; i ++){
            (bool exe, bool allowOk, bool balanceOk) = NDCA(DCA).check(i);
            if(exe){
                (address reciever, address srcToken, uint8 srcDecimals, uint256 chainId, address destToken, uint8 destDecimals, address ibStrategy, uint256 srcAmount) = NDCA(DCA).dataDCA(i);
                outData[id].id = i;
                outData[id].allowOk = allowOk;
                outData[id].balanceOk = balanceOk;
                outData[id].reciever = reciever;
                outData[id].srcToken = srcToken;
                outData[id].srcDecimals = srcDecimals;
                outData[id].chainId = chainId;
                outData[id].destToken = destToken;
                outData[id].destDecimals = destDecimals;
                outData[id].ibStrategy = ibStrategy;
                outData[id].srcAmount = srcAmount;
                unchecked {
                    id ++;
                }
            }
        }
        return (outData, _totalExecutable());
    }
    /* PRIVATE */
    function _initResolver() private {
        resolverBusy = !resolverBusy;
    }
    /**
     * @notice  Retrieve total executable DCAs.
     * @return  uint40  Number of DCAs that need execution.
     */
    function _totalExecutable() private view returns (uint40) {
        uint40 totalpositions = NDCA(DCA).totalPositions();
        uint40 result;
        for(uint40 i = 1; i <= totalpositions; i ++){
            if(NDCA(DCA).preCheck(i)){
                unchecked {
                    result ++;
                }
            }
        }
        return result;
    }
    /**
     * @notice  Retrieve User total active DCAs.
     * @param   _user  DCA owner.
     * @return  uint40  Number of DCAs
     */
    function _totalUserDCA(address _user) private view returns (uint40) {
        uint40 totalpositions = NDCA(DCA).totalPositions();
        NDCA.dcaDetail memory tempData;
        uint40 result;
        for(uint40 i = 1; i <= totalpositions; i ++){
            tempData = NDCA(DCA).detailDCA(i, _user);
            if(tempData.reciever != address(0)){
                unchecked {
                    result ++;
                }
            }
        }
        return result;
    }
}