/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/ExenoTokenIco.sol


pragma solidity 0.8.4;








contract ExenoTokenIco is
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    // Date when ICO starts
    uint256 public immutable startDate;

    // Token being sold
    IERC20 public immutable token;

    // Oracle for native currency market price 
    AggregatorV3Interface public immutable priceFeed;

    // Source of tokens and destination for cash
    address payable public immutable wallet;

    // How much cash has been raised so far
    uint256 public cashRaised;

    // How many tokens have been sold so far
    uint256 public totalTokensPurchased;

    // Total number of unique beneficiaries
    uint256 public totalBeneficiaries;
    
    // Map of token purchases made by beneficiaries
    mapping(address => uint256) public tokenPurchases;

    // Map of cash payments made by beneficiaries
    mapping(address => uint256) public cashPayments;

    // How many US dollars an investor needs to pay for 10**4 tokens in the PreICO stage, e.g. 3500 means $0.35
    uint256 public preIcoRate;

    // How many US dollars an investor needs to pay for 10**4 tokens in the ICO stage, e.g. 5000 means $0.50
    uint256 public icoRate;

    // Minimum cumulative amount of tokens an investor is allowed to purchase
    uint256 public immutable minCap;

    // Maximum cumulative amount of tokens an investor is allowed to purchase
    uint256 public immutable maxCap;

    // Limit triggering automatic transition to the ICO stage
    uint256 public constant PRE_ICO_LIMIT = 50 * 1000 * 1000 ether;

    // Limit triggering automatic transition to the PostICO stage
    uint256 public constant TOTAL_ICO_LIMIT = 75 * 1000 * 1000 ether;

    // The current stage of the ICO process
    Stage public currentStage;

    // Posssible values for `currentStage`
    enum Stage { PreICO, ICO, PostICO }
    
    /**
     * Event for token purchase logging
     * @param purchaser Who paid for the tokens
     * @param beneficiary Who got the tokens
     * @param saleCode Associated sale code
     * @param cashAmount Cash paid for the purchase
     * @param tokenAmount Amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint16 indexed saleCode,
        uint256 cashAmount,
        uint256 tokenAmount
    );

    /**
     * Event for stage change logging
     * @param previousStage Previous stage
     * @param currentStage Current stage
     */
    event NextStage(
        Stage previousStage,
        Stage currentStage
    );

    /**
     * Event for rates change logging
     * @param newPreIcoRate Previous stage
     * @param newIcoRate Current stage
     */
    event UpdateRates(
        uint256 newPreIcoRate,
        uint256 newIcoRate
    );

    /**
     * Event for cash forwarding logging
     * @param value Amount of cash transferred
     */
    event ForwardCash(
        uint256 value
    );

    modifier validAddress(address a) {
        require(a != address(0),
            "ExenoTokenIco: address cannot be zero");
        require(a != address(this),
            "ExenoTokenIco: invalid address");
        _;
    }

    constructor(
        IERC20 _token,
        AggregatorV3Interface _priceFeed,
        uint256 _preIcoRate,
        uint256 _icoRate,
        uint256 _minCap,
        uint256 _maxCap,
        address payable _wallet,
        uint256 _startDate
    )
        validAddress(_wallet)
    {
        assert(PRE_ICO_LIMIT < TOTAL_ICO_LIMIT);

        require(_preIcoRate > 0,
            "ExenoTokenIco: _preIcoRate needs to be above zero");
        
        require(_icoRate > _preIcoRate,
            "ExenoTokenIco: _icoRate needs to be above _preIcoRate");
        
        require(_minCap > 0,
            "ExenoTokenIco: _minCap needs to be above zero");

        require(_maxCap > _minCap,
            "ExenoTokenIco: _maxCap needs to be above _minCap");

        require(_startDate >= block.timestamp,
            "ExenoTokenIco: _startDate should be a date in the future");
        
        token = _token;
        priceFeed = _priceFeed;
        preIcoRate = _preIcoRate;
        icoRate = _icoRate;
        minCap = _minCap;
        maxCap = _maxCap;
        wallet = _wallet;
        startDate = _startDate;
        currentStage = Stage.PreICO;
    }

    /**
     * @notice Apply a new value for stage
     * @param newStage New stage
     */
    function _setStage(Stage newStage)
        internal
    {
        emit NextStage(currentStage, newStage);
        currentStage = newStage;
    }

    /**
     * @notice Allows investors to purchase tokens
     * @param beneficiary For whom the token is purchased
     * @param saleCode Sale code associated with the purchase
     */
    function _buyTokens(address beneficiary, uint16 saleCode)
        internal whenNotPaused nonReentrant
    {
        require(block.timestamp >= startDate,
            "ExenoTokenIco: sale has not started yet");
        
        require(currentStage == Stage.PreICO || currentStage == Stage.ICO,
            "ExenoTokenIco: buying tokens is only allowed in preICO and ICO");

        if (currentStage == Stage.PreICO) {
            assert(totalTokensPurchased < PRE_ICO_LIMIT);
        } else if (currentStage == Stage.ICO) {
            assert(totalTokensPurchased < TOTAL_ICO_LIMIT);
        }

        uint256 cashAmount = msg.value;
        require(cashAmount > 0,
            "ExenoTokenIco: invalid value");

        (uint256 tokenAmount,) = convertFromCashAmount(cashAmount);

        require(token.balanceOf(wallet) >= tokenAmount,
            "ExenoTokenIco: not enough balance on the wallet account");

        require(token.allowance(wallet, address(this)) >= tokenAmount,
            "ExenoTokenIco: not enough allowance from the wallet account");

        uint256 existingPayment = cashPayments[beneficiary];
        uint256 newPayment = existingPayment + cashAmount;

        uint256 existingPurchase = tokenPurchases[beneficiary];
        uint256 newPurchase = existingPurchase + tokenAmount;

        require(newPurchase >= minCap,
            "ExenoTokenIco: purchase is below min cap");

        require(newPurchase <= maxCap,
            "ExenoTokenIco: purchase is above max cap");

        cashRaised += cashAmount;
        totalTokensPurchased += tokenAmount;

        cashPayments[beneficiary] = newPayment;
        tokenPurchases[beneficiary] = newPurchase;

        if (existingPurchase == 0) {
            totalBeneficiaries += 1;
        }

        token.safeTransferFrom(wallet, beneficiary, tokenAmount);

        emit TokenPurchase(msg.sender, beneficiary, saleCode, cashAmount, tokenAmount);

        if (currentStage == Stage.PreICO
        && totalTokensPurchased >= PRE_ICO_LIMIT) {
            _setStage(Stage.ICO);
        } else if (currentStage == Stage.ICO
        && totalTokensPurchased >= TOTAL_ICO_LIMIT) {
            _setStage(Stage.PostICO);
        }
    }

    /**
     * @notice Allows token purchasing via a simple transfer
     */
    receive()
        external payable
    {
        _buyTokens(msg.sender, 0);
    }

    /**
     * @notice External access to `_buyTokens()`
     * @param beneficiary For whom the token is purchased
     * @param saleCode Sale code associated with the purchase
     */
    function buyTokens(address beneficiary, uint16 saleCode)
        external payable validAddress(beneficiary)
    {
        _buyTokens(beneficiary, saleCode);
    }

    /**
     * @notice Allows owner to pause further token purchases
     */
    function pause()
        external onlyOwner
    {
        _pause();
    }

    /**
     * @notice Allows owner to unpause further token purchases
     */
    function unpause()
        external onlyOwner
    {
        _unpause();
    }

    /**
     * @notice Allows owner to update the stage
     */
    function nextStage()
        external onlyOwner
    {
        require(currentStage == Stage.PreICO || currentStage == Stage.ICO,
            "ExenoTokenIco: changing stage is only allowed in preICO and ICO");

        if (currentStage == Stage.PreICO) {
            _setStage(Stage.ICO);
        } else if (currentStage == Stage.ICO) {
            _setStage(Stage.PostICO);
        }
    }

    /**
     * @notice Allows owner to update the rates
     * @param newPreIcoRate New preICO rate
     * @param newIcoRate New ICO rate
     */
    function updateRates(uint256 newPreIcoRate, uint256 newIcoRate)
        external onlyOwner
    {
        require(currentStage == Stage.PreICO || currentStage == Stage.ICO,
            "ExenoTokenIco: updating rates is only allowed in preICO and ICO");
        
        require(newPreIcoRate > 0 && newPreIcoRate < newIcoRate,
            "ExenoTokenIco: preICO rate needs to be lower than ICO rate");
        
        preIcoRate = newPreIcoRate;
        icoRate = newIcoRate;
        emit UpdateRates(newPreIcoRate, newIcoRate);
    }

    /**
     * @notice Allows owner to forward cash to the wallet
     */
    function forwardCash()
        external onlyOwner
    {
        uint256 balance = address(this).balance;
        require(balance > 0,
            "ExenoTokenIco: there no cash to forward");
        Address.sendValue(wallet, balance);
        emit ForwardCash(balance);
    }

    /**
     * @notice Figures out the current rate based on the current stage
     * @return the current rate
     */
    function currentRate()
        public view returns(uint256)
    {
        uint256 rate = 0;
        if (currentStage == Stage.PreICO) {
            rate = preIcoRate;
        } else if (currentStage == Stage.ICO) {
            rate = icoRate;
        }
        return rate;
    }

    /**
     * @notice Fetches the most recent market price of the native currency from an external oracle contract
     * @return price The most recent price and its decimals
     * @return decimals Decimals for the price
     */
    function getLatestPrice()
        public view returns(uint256 price, uint8 decimals)
    {
        (, int256 answer, , ,) = priceFeed.latestRoundData();
        price = uint256(answer);
        decimals = priceFeed.decimals();
    }

    /**
     * @notice Shows the current amount of tokens available for sale
     * @return Owner's balance and this contract's allowance
     */
    function checkAvailableFunds()
        external view returns(uint256, uint256)
    {
        return (token.balanceOf(wallet), token.allowance(wallet, address(this)));
    }

    /**
     * @notice Conversion calculation from cash amount (i.e. native currency)
     * @param cashAmount Amount of cash to be converted
     * @return tokenAmount Amount of tokens that can be purchased with the specified cashAmount
     * @return usdValue USD equivalent of cashAmount
     */
    function convertFromCashAmount(uint256 cashAmount)
        public view returns(uint256 tokenAmount, uint256 usdValue)
    {
        (uint256 price, uint8 decimals) = getLatestPrice();
        uint256 rate = currentRate();
        tokenAmount = cashAmount * price * 10**4 / rate / 10**decimals;
        usdValue = cashAmount * price / 10**decimals;
    }

    /**
     * @notice Conversion calculation from token amount
     * @param tokenAmount Amount of tokens to be converted
     * @return cashAmount Amount of cash (i.e. native currency) needed to purchase the specified tokenAmount
     * @return usdValue USD equivalent of tokenAmount
     */
    function convertFromTokenAmount(uint256 tokenAmount)
        external view returns(uint256 cashAmount, uint256 usdValue)
    {
        (uint256 price, uint8 decimals) = getLatestPrice();
        uint256 rate = currentRate();
        cashAmount = tokenAmount * 10**decimals * rate / price / 10**4;
        usdValue = tokenAmount * rate / 10**4;
    }

    /**
     * @notice Conversion calculation from USD value
     * @param usdValue Amount of USD to be converted
     * @return tokenAmount Amount of tokens that can be purchased with the specified usdValue
     * @return cashAmount Amount of cash (i.e. native currency) equivalent to the specified usdValue
     */
    function convertFromUSDValue(uint256 usdValue)
        external view returns(uint256 tokenAmount, uint256 cashAmount)
    {
        (uint256 price, uint8 decimals) = getLatestPrice();
        uint256 rate = currentRate();
        tokenAmount = usdValue * 10**4 / rate;
        cashAmount = usdValue * 10**decimals / price;
    }

}