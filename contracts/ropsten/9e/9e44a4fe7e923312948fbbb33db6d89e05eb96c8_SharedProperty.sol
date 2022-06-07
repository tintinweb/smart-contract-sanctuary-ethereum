/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// File: contracts/interfaces/IMerchantProperty.sol

pragma solidity ^0.8.0;

interface IMerchantProperty {
    function viewFeeMaxPercent() external view returns (uint16);

    function viewFeeMinPercent() external view returns (uint16);

    function viewDonationFee() external view returns (uint16);

    function viewTransactionFee() external view returns (uint16);

    function viewWeb3BalanceForFreeTx() external view returns (uint256);

    function viewMinAmountToProcessFee() external view returns (uint256);

    function viewMarketingWallet() external view returns (address payable);

    function viewDonationWallet() external view returns (address payable);

    function viewWeb3Token() external view returns (address);

    function viewAffiliatePool() external view returns (address);

    function viewStakingPool() external view returns (address);

    function viewMainExchange() external view returns (address, uint256);

    function viewExchanges() external view returns (address[] memory, uint256[] memory);

    function viewReserved() external view returns (bytes memory);

    function isBlacklistedFromPayToken(address token_)
        external
        view
        returns (bool);

    function isWhitelistedForRecToken(address token_)
        external
        view
        returns (bool);

    function viewMerchantWallet() external view returns (address);

    function viewAffiliatorWallet() external view returns (address);

    function viewFeeProcessingMethod() external view returns (uint8);

    function viewReceiveToken() external view returns (address);

    function viewDonationFeeCollected() external view returns (uint256);

    /**
     * @dev Update fee max percentage
     * Only callable by owner
     */
    function updateFeeMaxPercent(uint16 maxPercent_) external;

    /**
     * @dev Update fee min percentage
     * Only callable by owner
     */
    function updateFeeMinPercent(uint16 minPercent_) external;

    /**
     * @dev Update donation fee
     * Only callable by owner
     */
    function updateDonationFee(uint16 fee_) external;

    /**
     * @dev Update the transaction fee
     * Can only be called by the owner
     */
    function updateTransactionFee(uint16 fee_) external;

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateWeb3BalanceForFreeTx(uint256 web3Balance_) external;

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateMinAmountToProcessFee(uint256 minAmount_) external;

    /**
     * @dev Update the marketing wallet address
     * Can only be called by the owner.
     */
    function updateMarketingWallet(address payable marketingWallet_) external;

    /**
     * @dev Update the donation wallet address
     * Can only be called by the owner.
     */
    function updateDonationWallet(address payable donationWallet_) external;

    /**
     * @dev Update web3 token address
     * Callable only by owner
     */
    function updateWeb3TokenAddress(address tokenAddress_) external;

    function updateaffiliatePool(address affiliatePool_) external;

    function updateStakingPool(address stakingPool_) external;

    /**
     * @dev Update the main exchange address.
     * Can only be called by the owner.
     */
    function updateMainExchange(address exchange_, uint256 flag_) external;

    /**
     * @dev Add new exchange.
     * @param flag_: exchange type
     * Can only be called by the owner.
     */
    function addExchange(address exchange_, uint256 flag_) external;

    /**
     * @dev Remove the exchange.
     * Can only be called by the owner.
     */
    function removeExchange(uint256 index_) external;

    /**
     * @dev Exclude a token from paying blacklist
     * Only callable by owner
     */
    function excludeFromPayTokenBlacklist(address token_) external;

    /**
     * @dev Include a token in paying blacklist
     * Only callable by owner
     */
    function includeInPayTokenBlacklist(address token_) external;

    /**
     * @dev Exclude a token from receiving whitelist
     * Only callable by owner
     */
    function excludeFromRecTokenWhitelist(address token_) external;

    /**
     * @dev Include a token in receiving whitelist
     * Only callable by owner
     */
    function includeInRecTokenWhitelist(address token_) external;

    /**
     * @dev Update the merchant wallet address
     * Can only be called by the owner.
     */
    function updateMerchantWallet(address merchantWallet_) external;

    /**
     * @dev Update affiliator wallet address
     * Only callable by owner
     */
    function updateAffiliatorWallet(address affiliatorWallet_) external;

    /**
     * @dev Update fee processing method
     * Only callable by owner
     */
    function updateFeeProcessingMethod(uint8 method_) external;

    /**
     * @dev Update donationFeeCollected
     * Only callable by owner
     */
    function updateDonationFeeCollected(uint256 fee_) external;

    /**
     * @dev Update reserve param
     * Only callable by owner
     */
    function updateReserve(bytes memory reserved_) external;
}

// File: contracts/libs/Context.sol

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/libs/Ownable.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/libs/Operatable.sol

pragma solidity ^0.8.0;

/**
 * @dev Allow multiple operators with same permission
 */
abstract contract Operatable is Ownable {
    mapping(address => bool) private _operators;

    event PermissionUpdated(address indexed operator_, bool permission_);

    /**
     * @dev Initializes the contract setting the deployer as the operator.
     */
    constructor() {
        address msgSender = _msgSender();
        _operators[msgSender] = true;
        emit PermissionUpdated(msgSender, true);
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require(
            _operators[_msgSender()],
            "Operators: caller is not the operator"
        );
        _;
    }

    /**
     * @dev View permission of account
     */
    function viewPermission(address account_) external view returns (bool) {
        return _operators[account_];
    }

    /**
     * @dev Update permission of account
     * Can only be called by the current owner.
     */
    function updatePermission(address account_, bool permission_)
        external
        onlyOwner
    {
        _operators[account_] = permission_;
        emit PermissionUpdated(account_, permission_);
    }
}

// File: contracts/libs/SafeMath.sol

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libs/Address.sol

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: contracts/libs/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/libs/SafeERC20.sol

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: BEP20 operation did not succeed"
            );
        }
    }
}

// File: contracts/SharedProperty.sol

pragma solidity ^0.8.0;



/**
 * @dev Shared property all over the Slash protocol
 */
contract SharedProperty is IMerchantProperty, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) private _payTokenBlacklist; // List of tokens can not be used for paying
    mapping(address => bool) private _recTokenWhitelist; // list of tokens can be used for receiving

    uint16 private _feeMaxPercent; // FEE_MAX default 0.5%
    uint16 private _feeMinPercent; // FEE_MIN default 0.1%

    uint16 private _donationFee; // Donation fee default 0.15%
    uint16 public constant MAX_TRANSACTION_FEE = 1000; // Max transacton fee 10%
    uint16 private _transactionFee; // Transaction fee multiplied by 100, default 0.5%

    uint256 private _web3BalanceForFreeTx; // If any wallet has 1000 Web3 tokens, it will be exempted from the transaction fee
    uint256 private _minAmountToProcessFee; // When there is 1 BNB staked, fee will be processed

    address payable private _marketingWallet; // Marketing address
    address payable private _donationWallet; // Donation wallet

    address private _affiliatePool;
    address private _stakingPool;
    address private _web3Token;

    address private _mainExchange; // Main exchange
    uint256 private _mainExchangeFlag; // Main exchange type
    address[] private _exchanges; // Available exchanges
    uint256[] private _exchangeFlags; // Available exchanges' type

    bytes private _reserved;    // reserved param

    function viewFeeMaxPercent() external view override returns (uint16) {
        return _feeMaxPercent;
    }

    function viewFeeMinPercent() external view override returns (uint16) {
        return _feeMinPercent;
    }

    function viewDonationFee() external view override returns (uint16) {
        return _donationFee;
    }

    function viewTransactionFee() external view override returns (uint16) {
        return _transactionFee;
    }

    function viewWeb3BalanceForFreeTx()
        external
        view
        override
        returns (uint256)
    {
        return _web3BalanceForFreeTx;
    }

    function viewMinAmountToProcessFee()
        external
        view
        override
        returns (uint256)
    {
        return _minAmountToProcessFee;
    }

    function viewMarketingWallet()
        external
        view
        override
        returns (address payable)
    {
        return _marketingWallet;
    }

    function viewDonationWallet()
        external
        view
        override
        returns (address payable)
    {
        return _donationWallet;
    }

    function viewWeb3Token() external view override returns (address) {
        return _web3Token;
    }

    function viewAffiliatePool() external view override returns (address) {
        return _affiliatePool;
    }

    function viewStakingPool() external view override returns (address) {
        return _stakingPool;
    }

    function viewMainExchange()
        external
        view
        override
        returns (
            address, /** main exchange */
            uint256 /** exchange type */
        )
    {
        return (_mainExchange, _mainExchangeFlag);
    }

    function viewExchanges()
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        return (_exchanges, _exchangeFlags);
    }

    function viewReserved()
        external
        view
        override
        returns (bytes memory)
    {
        return _reserved;
    }

    function isBlacklistedFromPayToken(address token_)
        external
        view
        override
        returns (bool)
    {
        return _payTokenBlacklist[token_];
    }

    function isWhitelistedForRecToken(address token_)
        external
        view
        override
        returns (bool)
    {
        return _recTokenWhitelist[token_];
    }

    /**
     * @dev Merchant wallet property is only available in merchant-specific contract
     * Thats why it returns null address here
     */
    function viewMerchantWallet() external pure override returns (address) {
        return address(0);
    }

    /**
     * @dev Affiliator wallet property is only available in merchant-specific contract
     * Thats why it returns null address here
     */
    function viewAffiliatorWallet() external pure override returns (address) {
        return address(0);
    }

    /**
     * @dev Fee processing method property is only available in merchant-specific contract
     * Thats why it returns 0 here
     */
    function viewFeeProcessingMethod() external pure override returns (uint8) {
        return 0;
    }

    /**
     * @dev Receive token property is only available in merchant-specific contract
     * Thats why it returns null address here
     */
    function viewReceiveToken() external pure override returns (address) {
        return address(0);
    }

    /**
     * @dev donationFeeCollected property is only available in merchant-specific contract
     * Thats why it returns 0 here
     */
    function viewDonationFeeCollected()
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    /**
     * @dev Update fee max percentage
     * Only callable by owner
     */
    function updateFeeMaxPercent(uint16 maxPercent_)
        external
        override
        onlyOwner
    {
        require(
            maxPercent_ <= 10000 && maxPercent_ >= _feeMinPercent,
            "Invalid value"
        );

        _feeMaxPercent = maxPercent_;
    }

    /**
     * @dev Update fee min percentage
     * Only callable by owner
     */
    function updateFeeMinPercent(uint16 minPercent_)
        external
        override
        onlyOwner
    {
        require(
            minPercent_ <= 10000 && minPercent_ <= _feeMaxPercent,
            "Invalid value"
        );

        _feeMinPercent = minPercent_;
    }

    /**
     * @dev Update donation fee
     * Only callable by owner
     */
    function updateDonationFee(uint16 fee_) external override onlyOwner {
        require(fee_ <= 10000, "Invalid fee");

        _donationFee = fee_;
    }

    /**
     * @dev Update the transaction fee
     * Can only be called by the owner
     */
    function updateTransactionFee(uint16 fee_) external override onlyOwner {
        require(fee_ <= MAX_TRANSACTION_FEE, "Invalid fee");
        _transactionFee = fee_;
    }

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateWeb3BalanceForFreeTx(uint256 web3Balance_)
        external
        override
        onlyOwner
    {
        require(web3Balance_ > 0, "Invalid value");
        _web3BalanceForFreeTx = web3Balance_;
    }

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateMinAmountToProcessFee(uint256 minAmount_)
        external
        override
        onlyOwner
    {
        require(minAmount_ > 0, "Invalid value");
        _minAmountToProcessFee = minAmount_;
    }

    /**
     * @dev Update the marketing wallet address
     * Can only be called by the owner.
     */
    function updateMarketingWallet(address payable marketingWallet_)
        external
        override
        onlyOwner
    {
        require(marketingWallet_ != address(0), "Invalid address");
        _marketingWallet = marketingWallet_;
    }

    /**
     * @dev Update the donation wallet address
     * Can only be called by the owner.
     */
    function updateDonationWallet(address payable donationWallet_)
        external
        override
        onlyOwner
    {
        require(donationWallet_ != address(0), "Invalid address");
        _donationWallet = donationWallet_;
    }

    /**
     * @dev Update web3 token address
     * Callable only by owner
     */
    function updateWeb3TokenAddress(address tokenAddress_)
        external
        override
        onlyOwner
    {
        require(tokenAddress_ != address(0), "Invalid token");
        _web3Token = tokenAddress_;
    }

    function updateaffiliatePool(address affiliatePool_)
        external
        override
        onlyOwner
    {
        require(affiliatePool_ != address(0), "Invalid pool");
        _affiliatePool = affiliatePool_;
    }

    function updateStakingPool(address stakingPool_)
        external
        override
        onlyOwner
    {
        require(stakingPool_ != address(0), "Invalid pool");
        _stakingPool = stakingPool_;
    }

    /**
     * @dev Update the main exchange.
     * Can only be called by the owner.
     */
    function updateMainExchange(
        address exchange_,
        uint256 flag_ /** exchange type */
    ) external override onlyOwner {
        require(
            exchange_ != address(0) && flag_ > 0,
            "Invalid exchange config"
        );
        _mainExchange = exchange_;
        _mainExchangeFlag = flag_;
    }

    /**
     * @dev Add the exchange.
     * Can only be called by the owner.
     */
    function addExchange(address exchange_, uint256 flag_)
        external
        override
        onlyOwner
    {
        require(
            exchange_ != address(0) && flag_ > 0,
            "Invalid exchange config"
        );
        _exchanges.push(exchange_);
        _exchangeFlags.push(flag_);
    }

    /**
     * @dev Remove the swap router from avilable routers.
     * Can only be called by the owner.
     */
    function removeExchange(uint256 index_) external override onlyOwner {
        require(index_ < _exchanges.length, "Invalid index");

        if (index_ != _exchanges.length - 1) {
            _exchanges[index_] = _exchanges[_exchanges.length - 1];
            _exchangeFlags[index_] = _exchangeFlags[_exchangeFlags.length - 1];
        }

        delete _exchanges[_exchanges.length - 1];
        delete _exchangeFlags[_exchangeFlags.length - 1];
        _exchanges.pop();
        _exchangeFlags.pop();
    }

    /**
     * @dev Exclude a token from paying blacklist
     * Only callable by owner
     */
    function excludeFromPayTokenBlacklist(address token_)
        external
        override
        onlyOwner
    {
        require(token_ != address(0), "Invalid token");
        _payTokenBlacklist[token_] = false;
    }

    /**
     * @dev Include a token in paying blacklist
     * Only callable by owner
     */
    function includeInPayTokenBlacklist(address token_)
        external
        override
        onlyOwner
    {
        require(token_ != address(0), "Invalid token");
        _payTokenBlacklist[token_] = true;
    }

    /**
     * @dev Exclude a token from receiving whitelist
     * Only callable by owner
     */
    function excludeFromRecTokenWhitelist(address token_)
        external
        override
        onlyOwner
    {
        require(token_ != address(0), "Invalid token");
        _recTokenWhitelist[token_] = false;
    }

    /**
     * @dev Include a token in receiving whitelist
     * Only callable by owner
     */
    function includeInRecTokenWhitelist(address token_)
        external
        override
        onlyOwner
    {
        _recTokenWhitelist[token_] = true;
    }

    /**
     * @dev Update the merchant wallet address
     * Can only be called by the owner.
     */
    function updateMerchantWallet(address merchantWallet_) external override {}

    /**
     * @dev Update affiliator wallet address
     * Only callable by owner
     */
    function updateAffiliatorWallet(address affiliatorWallet_)
        external
        override
    {}

    /**
     * @dev Update fee processing method
     * Only callable by owner
     */
    function updateFeeProcessingMethod(uint8 method_) external override {}

    /**
     * @dev Update donationFeeCollected
     * Only callable by owner
     */
    function updateDonationFeeCollected(uint256 fee_) external override {}

    /**
     * @dev Update donationFeeCollected
     * Only callable by owner
     */
    function updateReserve(bytes memory reserved_) external override onlyOwner {
        _reserved = reserved_;
    }


    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).safeTransfer(_msgSender(), _tokenAmount);
    }
}