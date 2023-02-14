/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]



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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]



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
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/libs/UniversalERC20Upgradeable.sol


pragma solidity ^0.8.4;

// File: contracts/UniversalERC20Upgradeable.sol
library UniversalERC20Upgradeable {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private constant ZERO_ADDRESS =
        IERC20Upgradeable(0x0000000000000000000000000000000000000000);
    IERC20Upgradeable private constant ETH_ADDRESS =
        IERC20Upgradeable(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    error WrongUsage();

    function universalTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) return 0;

        if (isETH(token)) {
            payable(address(uint160(to))).sendValue(amount);
            return amount;
        } else {
            uint256 balanceBefore = token.balanceOf(to);
            token.safeTransfer(to, amount);
            return token.balanceOf(to) - balanceBefore;
        }
    }

    function universalTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) return 0;

        if (isETH(token)) {
            if (from != msg.sender || msg.value < amount) revert WrongUsage();
            if (to != address(this))
                payable(address(uint160(to))).sendValue(amount);
            // refund redundant amount
            if (msg.value > amount)
                payable(msg.sender).sendValue(msg.value - amount);
            return amount;
        } else {
            uint256 balanceBefore = token.balanceOf(to);
            token.safeTransferFrom(from, to, amount);
            return token.balanceOf(to) - balanceBefore;
        }
    }

    function universalTransferFromSenderToThis(
        IERC20Upgradeable token,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) return 0;

        if (isETH(token)) {
            if (msg.value < amount) revert WrongUsage();
            // Return remainder if exist
            if (msg.value > amount)
                payable(msg.sender).sendValue(msg.value - amount);
            return amount;
        } else {
            uint256 balanceBefore = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            return token.balanceOf(address(this)) - balanceBefore;
        }
    }

    function universalApprove(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0)
                token.safeApprove(to, 0);
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20Upgradeable token, address who)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) return who.balance;
        return token.balanceOf(who);
    }

    function universalDecimals(IERC20Upgradeable token)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) return 18;

        (bool success, bytes memory data) = address(token).staticcall{
            gas: 10000
        }(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20Upgradeable token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}


// File contracts/yasha/YashaLaunchpad.sol



pragma solidity ^0.8.4;
/**
 * @notice Yasha Launchpad contract with improved mode
 * @dev It aims to reduce gas costs as possible as it can be
 */
contract YashaLaunchpad is OwnableUpgradeable {
    using UniversalERC20Upgradeable for IERC20Upgradeable;

    enum ActionCode {
        DEPOSIT_ICO_TOKEN,
        COMPLETE_ICO,
        CANCEL_ICO,
        CLAIM_FUND_TOKEN,
        USER_CONTRIBUTE,
        USER_REFUND,
        USER_CLAIM
    }

    uint16 private constant MAX_TREASURY_FEE = 3000;

    /// @notice Yasha treasury fee (1000 means 10%)
    uint16 private _treasuryFee;

    /// @notice Yasha treasury wallet to receive fee when claim funded tokens
    address payable private _treasuryWallet;

    /// @notice Yasha signer address to be used for the request verification
    address private _signer;

    /// @notice User contribution fund amount per project (key is hash of user address & project id)
    mapping(bytes32 => uint256) private _userContributes;
    /// @notice Project token amount in the contract per project (key is project id)
    mapping(bytes16 => uint256) private _icoTokens;
    /// @notice Project funds amount collected in the contract per project (key is project id)
    mapping(bytes16 => uint256) private _fundedTokens;

    event IcoTokenDeposited(bytes16 icoId, uint256 amount);
    event IcoCompleted(bytes16 icoId, uint256 redundantAmount);
    event IcoCancelled(bytes16 icoId);
    event FundTokenClaimed(bytes16 icoId, uint256 amount, uint256 feeAmount);
    event UserContributed(bytes16 icoId, address account, uint256 amount);
    event UserRefunded(bytes16 icoId, address account, uint256 amount);
    event UserClaimed(bytes16 icoId, address account, uint256 amount);

    error AlreadyFinished(uint64 endAt);
    error InsufficientIcoTokens(uint256 amount, uint256 expected);
    error InvalidAmount();
    error InvalidSignature();
    error InvalidSignatureLength();
    error InvalidZeroAddress();
    error NothingContributed();
    error OverHardcap(uint256 value, uint256 limit);
    error OverLimitation(uint16 value, uint16 limit);
    error OverMaxContributes(uint256 value, uint256 limit);
    error UnderMinContributes(uint256 value, uint256 limit);

    function initialize(
        address signer_,
        address payable treasuryWallet_,
        uint16 treasuryFee_
    ) public initializer {
        __Ownable_init();

        _signer = signer_;
        _treasuryWallet = treasuryWallet_;
        _treasuryFee = treasuryFee_;
    }

    /// @notice Deposit project token so that users can claim after ICO endds
    /// @dev Project tokens are transferred to this contract
    function depositIcoToken(
        bytes16 icoId_,
        address icoToken_,
        uint256 amount_,
        bytes calldata signature_
    ) external payable {
        // Validate signature with params
        validateParams1(
            ActionCode.DEPOSIT_ICO_TOKEN,
            icoId_,
            icoToken_,
            amount_,
            signature_
        );

        amount_ = IERC20Upgradeable(icoToken_)
            .universalTransferFromSenderToThis(amount_);

        if (amount_ == 0) revert InvalidAmount();

        _icoTokens[icoId_] += amount_;
        emit IcoTokenDeposited(icoId_, amount_);
    }

    /// @notice Complete ICO
    /// @dev There should be enough amount of ICO tokens deposited in the contract prior
    /// @dev Redundant ICO tokens are transferred back to the ICO owner
    function completeIco(
        bytes16 icoId_,
        address icoToken_,
        uint256 price_,
        bytes calldata signature_
    ) external {
        // Validate signature with params
        validateParams1(
            ActionCode.COMPLETE_ICO,
            icoId_,
            icoToken_,
            price_,
            signature_
        );

        // Calculate required amount from the ico token price and the users' contributed funds amount
        uint256 requiredAmount = (_fundedTokens[icoId_] *
            10 ** IERC20Upgradeable(icoToken_).universalDecimals()) / price_;
        uint256 depositedAmount = _icoTokens[icoId_];

        // Project can be completed when there are enough ico tokens deposited
        if (depositedAmount < requiredAmount)
            revert InsufficientIcoTokens(depositedAmount, requiredAmount);

        _icoTokens[icoId_] = requiredAmount;

        IERC20Upgradeable(icoToken_).universalTransfer(
            _msgSender(),
            depositedAmount - requiredAmount
        );

        emit IcoCompleted(icoId_, depositedAmount - requiredAmount);
    }

    /// @notice Cancel ICO
    /// @dev Deposited ICO tokens are transferred back to the ICO owner
    function cancelIco(
        bytes16 icoId_,
        address icoToken_,
        bytes calldata signature_
    ) external {
        // Validate signature with params
        validateParams2(ActionCode.CANCEL_ICO, icoId_, icoToken_, signature_);

        uint256 depositedAmount = _icoTokens[icoId_];
        if (depositedAmount > 0) {
            _icoTokens[icoId_] = 0;
            IERC20Upgradeable(icoToken_).universalTransfer(
                _msgSender(),
                depositedAmount
            );
        }

        emit IcoCancelled(icoId_);
    }

    /// @notice Claim contributed funds after ICO ends
    /// @dev Fee is transferred to the Yasha treasury account
    function claimFundToken(
        bytes16 icoId_,
        address fundToken_,
        bytes calldata signature_
    ) external {
        // Validate signature with params
        validateParams2(
            ActionCode.CLAIM_FUND_TOKEN,
            icoId_,
            fundToken_,
            signature_
        );

        uint256 fundedAmount = _fundedTokens[icoId_];
        if (fundedAmount == 0) revert NothingContributed();

        _fundedTokens[icoId_] = 0;

        uint256 feeAmount = (fundedAmount * _treasuryFee) / 10000;
        fundedAmount -= feeAmount;

        IERC20Upgradeable(fundToken_).universalTransfer(
            _treasuryWallet,
            feeAmount
        );
        IERC20Upgradeable(fundToken_).universalTransfer(
            _msgSender(),
            fundedAmount
        );

        emit FundTokenClaimed(icoId_, fundedAmount, feeAmount);
    }

    /// @notice Contribute into the project ICO
    /// @param amountArgs_ We pass contribute amount, softcap, hardcap, minPerUser, maxPerUser into abi encoded param
    function contribute(
        bytes16 icoId_,
        address fundToken_,
        bytes calldata amountArgs_,
        bytes calldata signature_
    ) external payable {
        // Validate signature with params
        validateParams3(
            ActionCode.USER_CONTRIBUTE,
            icoId_,
            fundToken_,
            amountArgs_,
            signature_
        );

        _contribute(icoId_, fundToken_, amountArgs_);
    }

    /// @notice Internal function for the contribute
    function _contribute(
        bytes16 icoId_,
        address fundToken_,
        bytes memory amountArgs_
    ) internal {
        (
            uint64 endAt_,
            uint256 amount_,
            uint256 hardcap,
            uint256 minPerUser,
            uint256 maxPerUser
        ) = abi.decode(
                amountArgs_,
                (uint64, uint256, uint256, uint256, uint256)
            );

        if (block.timestamp > endAt_) revert AlreadyFinished(endAt_);

        amount_ = IERC20Upgradeable(fundToken_)
            .universalTransferFromSenderToThis(amount_);
        if (amount_ == 0) revert InvalidAmount();

        bytes32 userKey = simpleHash(_msgSender(), icoId_);
        uint256 userContributedAmt = _userContributes[userKey] + amount_;
        uint256 icoFilledAmt = _fundedTokens[icoId_] + amount_;

        if (maxPerUser > 0 && userContributedAmt > maxPerUser)
            revert OverMaxContributes(userContributedAmt, maxPerUser);
        if (userContributedAmt < minPerUser)
            revert UnderMinContributes(userContributedAmt, minPerUser);
        if (icoFilledAmt > hardcap) revert OverHardcap(icoFilledAmt, hardcap);

        _userContributes[userKey] = userContributedAmt;
        _fundedTokens[icoId_] += icoFilledAmt;

        emit UserContributed(icoId_, _msgSender(), amount_);
    }

    /// @notice Refund his contributed funds from the ICO
    /// @dev Only when the ICO is cancelled
    function refund(
        bytes16 icoId_,
        address fundToken_,
        bytes calldata signature_
    ) external {
        // Verify params with signature
        validateParams2(ActionCode.USER_REFUND, icoId_, fundToken_, signature_);

        bytes32 key = simpleHash(_msgSender(), icoId_);
        uint256 fundedAmount = _userContributes[key];

        if (fundedAmount == 0) revert NothingContributed();

        _userContributes[key] = 0;
        IERC20Upgradeable(fundToken_).universalTransfer(
            _msgSender(),
            fundedAmount
        );

        emit UserRefunded(icoId_, _msgSender(), fundedAmount);
    }

    /// @notice Claim ico token after the ICO ends
    /// @dev Claim amount is calculated from the user contributed funds amount and ico price
    function claim(
        bytes16 icoId_,
        address icoToken_,
        uint256 price_,
        bytes calldata signature_
    ) external {
        // Verify signature with params
        validateParams1(
            ActionCode.USER_CLAIM,
            icoId_,
            icoToken_,
            price_,
            signature_
        );
        bytes32 key = simpleHash(_msgSender(), icoId_);
        uint256 fundedAmount = _userContributes[key];

        if (fundedAmount == 0) revert NothingContributed();

        uint256 amountToClaim = (fundedAmount *
            10 ** IERC20Upgradeable(icoToken_).universalDecimals()) / price_;

        _icoTokens[icoId_] -= amountToClaim;
        _userContributes[key] = 0;

        IERC20Upgradeable(icoToken_).universalTransfer(
            _msgSender(),
            amountToClaim
        );

        emit UserClaimed(icoId_, _msgSender(), amountToClaim);
    }

    /// @notice Generate simple hash message from (address, bytes16)
    function simpleHash(
        address param1_,
        bytes16 param2_
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(param1_, param2_));
    }

    /// @notice Validate parameters of (ActionCode, bytes16, address, uint256) with signature
    /// @dev It generates hash message with chainId & _msgSender() before param1
    function validateParams1(
        ActionCode param1_,
        bytes16 param2_,
        address param3_,
        uint256 param4_,
        bytes memory signature_
    ) private view {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        bytes32 hashMessage = getEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    chainId,
                    _msgSender(),
                    param1_,
                    param2_,
                    param3_,
                    param4_
                )
            )
        );
        if (recoverSigner(hashMessage, signature_) != _signer)
            revert InvalidSignature();
    }

    /// @notice Validate parameters of (ActionCode, bytes16, address) with signature
    /// @dev It generates hash message with chainId & _msgSender() before param1
    function validateParams2(
        ActionCode param1_,
        bytes16 param2_,
        address param3_,
        bytes memory signature_
    ) private view {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        bytes32 hashMessage = getEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    chainId,
                    _msgSender(),
                    param1_,
                    param2_,
                    param3_
                )
            )
        );
        if (recoverSigner(hashMessage, signature_) != _signer)
            revert InvalidSignature();
    }

    /// @notice Validate parameters of (ActionCode, bytes16, address, bytes) with signature
    /// @dev It generates hash message with chainId & _msgSender() before param1
    function validateParams3(
        ActionCode param1_,
        bytes16 param2_,
        address param3_,
        bytes memory param4_,
        bytes memory signature_
    ) private view {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        bytes32 hashMessage = getEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    chainId,
                    _msgSender(),
                    param1_,
                    param2_,
                    param3_,
                    param4_
                )
            )
        );
        if (recoverSigner(hashMessage, signature_) != _signer)
            revert InvalidSignature();
    }

    function recoverSigner(
        bytes32 ethSignedMessageHash_,
        bytes memory signature_
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature_);
        return ecrecover(ethSignedMessageHash_, v, r, s);
    }

    function getEthSignedMessageHash(
        bytes32 messageHash_
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash_
                )
            );
    }

    function splitSignature(
        bytes memory sig_
    ) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig_.length != 65) revert InvalidSignatureLength();

        assembly {
            r := mload(add(sig_, 32))
            s := mload(add(sig_, 64))
            v := byte(0, mload(add(sig_, 96)))
        }
    }

    /// @notice Update Yasha signer address
    function updateSigner(address signer_) external onlyOwner {
        if (signer_ == address(0)) revert InvalidZeroAddress();
        _signer = signer_;
    }

    function signer() external view returns (address) {
        return _signer;
    }

    /// @notice Update Yasha treasury wallet address
    function updateTreasuryWallet(
        address payable treasuryWallet_
    ) external onlyOwner {
        if (treasuryWallet_ == address(0)) revert InvalidZeroAddress();
        _treasuryWallet = treasuryWallet_;
    }

    function treasuryWallet() external view returns (address payable) {
        return _treasuryWallet;
    }

    /// @notice Update treasury fee value
    function updateTreasuryFee(uint16 treasuryFee_) external onlyOwner {
        if (treasuryFee_ > MAX_TREASURY_FEE)
            revert OverLimitation(treasuryFee_, MAX_TREASURY_FEE);
        _treasuryFee = treasuryFee_;
    }

    function treasuryFee() external view returns (uint16) {
        return _treasuryFee;
    }

    /// @notice It allows the admin to recover wrong tokens sent to the contract
    /// @dev This function is only callable by admin.
    function recoverTokens(address token_, uint256 amount_) external onlyOwner {
        IERC20Upgradeable(token_).universalTransfer(_msgSender(), amount_);
    }

    /// @notice To recieve ETH
    receive() external payable {}
}