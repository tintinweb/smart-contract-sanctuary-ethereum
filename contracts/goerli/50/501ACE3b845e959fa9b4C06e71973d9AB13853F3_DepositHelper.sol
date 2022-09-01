// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./../interfaces/native/IUnderwritingPool.sol";
import "./../interfaces/native/IUnderwritingEquity.sol";
import "./../interfaces/native/IUnderwritingLocker.sol";
import "./../interfaces/native/IDepositHelper.sol";


/**
 * @title DepositHelper
 * @author solace.fi
 * @notice The process of depositing into Solace Native requires multiple steps across multiple contracts. This helper contract allows users to deposit with a single transaction.
 *
 * These steps are
 * 1. Deposit governance token into [`UWP`](./UnderwritingPool).
 * 2. Deposit [`UWP`](./UnderwritingPool) into [`UWE`](./UnderwritingEquity).
 * 3. Deposit [`UWE`](./UnderwritingEquity) into an [`Underwriting Lock`](./UnderwritingLocker).
 *
 * These steps can be replaced with [`depositAndLock()`](#depositandlock) or [`depositIntoLock()`](#depositintolock).
 */
contract DepositHelper is IDepositHelper, ReentrancyGuard {

    /***************************************
    STATE VARIABLES
    ***************************************/

    address internal _uwe;
    address internal _locker;

    constructor(address uwe_, address locker_) {
        require(uwe_ != address(0x0), "zero address uwe");
        require(locker_ != address(0x0), "zero address locker");
        _uwe = uwe_;
        _locker = locker_;
        IERC20(uwe_).approve(locker_, type(uint256).max);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Address of the [underwriting pool](./UnderwritingPool).
     * @return uwp The underwriting pool.
     */
    function underwritingPool() external view override returns (address uwp) {
        return IUnderwritingEquity(_uwe).underwritingPool();
    }

    /**
     * @notice Address of [underwriting equity](./UnderwritingEquity).
     * @return uwe The underwriting equity.
     */
    function underwritingEquity() external view override returns (address uwe) {
        return _uwe;
    }

    /**
     * @notice Address of [underwriting locker](./UnderwritingLocker).
     * @return locker The underwriting locker.
     */
    function underwritingLocker() external view override returns (address locker) {
        return _locker;
    }

    /**
     * @notice Calculates the amount of [`UWE`](./UnderwritingEquity) minted for an amount of a token deposited.
     * The deposit token may be one of the tokens in [`UWP`](./UnderwritingPool), the [`UWP`](./UnderwritingPool) token, or the [`UWE`](./UnderwritingEquity) token.
     * @param depositToken The address of the token to deposit.
     * @param depositAmount The amount of the token to deposit.
     * @return uweAmount The amount of [`UWE`](./UnderwritingEquity) that will be minted to the receiver.
     */
    function calculateDeposit(address depositToken, uint256 depositAmount) external view override returns (uint256 uweAmount) {
        address uwe_ = _uwe;
        address uwp_ = IUnderwritingEquity(uwe_).underwritingPool();
        uint256 amount = depositAmount;
        // if deposit token is not uwp nor uwe
        // likely token is member of set
        if(depositToken != uwp_ && depositToken != uwe_) {
            // deposit token into set, receive uwp. reverts if token not in set
            address[] memory tokens = new address[](1);
            uint256[] memory amounts = new uint256[](1);
            tokens[0] = depositToken;
            amounts[0] = depositAmount;
            amount = IUnderwritingPool(uwp_).calculateIssue(tokens, amounts);
        }
        // if deposit token is not uwe
        if(depositToken != uwe_) {
            // deposit uwp into uwe
            amount = IUnderwritingEquity(uwe_).calculateDeposit(amount);
        }
        return amount;
    }

    /***************************************
    DEPOSIT FUNCTIONS
    ***************************************/

    /**
     * @notice Deposits tokens into [`UWE`](./UnderwritingEquity) and deposits [`UWE`](./UnderwritingEquity) into a new [`UWE Lock`](./UnderwritingLocker).
     * @param depositToken Address of the token to deposit.
     * @param depositAmount Amount of the token to deposit.
     * @param lockExpiry The timestamp the lock will unlock.
     * @return lockID The ID of the newly created [`UWE Lock`](./UnderwritingLocker).
     */
    function depositAndLock(
        address depositToken,
        uint256 depositAmount,
        uint256 lockExpiry
    ) external override nonReentrant returns (uint256 lockID) {
        // pull tokens from msg.sender, convert to uwe
        uint256 uweAmount = _tokenToUwe(depositToken, depositAmount);
        // deposit uwe into new lock
        lockID = IUnderwritingLocker(_locker).createLock(msg.sender, uweAmount, lockExpiry);
        return lockID;
    }

    /**
     * @notice Deposits tokens into [`UWE`](./UnderwritingEquity) and deposits [`UWE`](./UnderwritingEquity) into an existing [`UWE Lock`](./UnderwritingLocker).
     * @param depositToken Address of the token to deposit.
     * @param depositAmount Amount of the token to deposit.
     * @param lockID The ID of the [`UWE Lock`](./UnderwritingLocker) to deposit into.
     */
    function depositIntoLock(
        address depositToken,
        uint256 depositAmount,
        uint256 lockID
    ) external override nonReentrant {
        // pull tokens from msg.sender, convert to uwe
        uint256 uweAmount = _tokenToUwe(depositToken, depositAmount);
        // deposit uwe into existing lock
        IUnderwritingLocker(_locker).increaseAmount(lockID, uweAmount);
    }

    /***************************************
    INTERNAL FUNCTIONS
    ***************************************/

    /**
     * @notice Given a deposit token and amount, pulls the token from `msg.sender` and converts it to an amount of [`UWE`](./UnderwritingEquity).
     * @param depositToken Address of the token to deposit.
     * @param depositAmount Amount of the token to deposit.
     * @return uweAmount Amount of [`UWE`](./UnderwritingEquity) that was minted.
     */
    function _tokenToUwe(
        address depositToken,
        uint256 depositAmount
    ) internal returns (uint256 uweAmount) {
        address uwe_ = _uwe;
        address uwp_ = IUnderwritingEquity(uwe_).underwritingPool();
        uint256 amount = depositAmount;
        IERC20 tkn = IERC20(depositToken);
        // pull tokens from msg.sender
        SafeERC20.safeTransferFrom(tkn, msg.sender, address(this), amount);
        // if deposit token is not uwp nor uwe
        // likely token is member of set
        if(depositToken != uwp_ && depositToken != uwe_) {
            // deposit token into set, receive uwp. reverts if token not in set
            if(tkn.allowance(address(this), uwp_) < amount) tkn.approve(uwp_, type(uint256).max);
            address[] memory tokens = new address[](1);
            uint256[] memory amounts = new uint256[](1);
            tokens[0] = depositToken;
            amounts[0] = depositAmount;
            amount = IUnderwritingPool(uwp_).issue(tokens, amounts, address(this));
        }
        // if deposit token is not uwe
        if(depositToken != uwe_) {
            // deposit uwp into uwe
            IERC20 uwp2 = IERC20(uwp_);
            if(uwp2.allowance(address(this), uwe_) < amount) uwp2.approve(uwe_, type(uint256).max);
            amount = IUnderwritingEquity(uwe_).deposit(amount, address(this));
        }
        return amount;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/**
 * @title IUnderwritingPool
 * @author solace.fi
 * @notice The underwriting pool of Solace Native.
 *
 * In Solace Native risk is backed by a basket of assets known as the underwriting pool (UWP). Shares of the pool are known as `UWP` and are represented as an ERC20 token. [Governance](/docs/protocol/governance) can add or remove tokens from the basket and set their parameters (min and max in USD, price oracle) via [`addTokensToPool()`](#addtokenstopool) and [`removeTokensFromPool()`](#removetokensfrompool).
 *
 * Users can view tokens in the pool via [`tokensLength()`](#tokenslength), [`tokenData(address token)`](#tokendata), and [`tokenList(uint256 index)`](#tokenlist).
 *
 * Anyone can mint `UWP` by calling [`issue()`](#issue) and depositing any of the tokens in the pool. Note that
 * - You will not be credited `UWP` for raw transferring tokens to this contract. Use [`issue()`](#issue) instead.
 * - You do not need to deposit all of the tokens in the pool. Most users will deposit a single token.
 * - To manage risk, each token has a corresponding `min` and `max` measured in USD. Deposits must keep the pool within these bounds.
 * - Solace may charge a protocol fee as a fraction of the mint amount [`issueFee()`](#issuefee).
 *
 * Anyone can redeem their `UWP` for tokens in the pool by calling [`redeem()`](#redeem). You will receive a fair portion of all assets in the pool.
 *
 * [Governance](/docs/protocol/governance) can pause and unpause [`issue()`](#issue). The other functions cannot be paused.
 */
interface IUnderwritingPool is IERC20Metadata {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a token is added to the pool.
    event TokenAdded(address indexed token);
    /// @notice Emitted when a token is removed from the pool.
    event TokenRemoved(address indexed token);
    /// @notice Emitted when uwp is issued.
    event IssueMade(address user, uint256 amount);
    /// @notice Emitted when uwp is redeemed.
    event RedeemMade(address user, uint256 amount);
    /// @notice Emitted when issue fee is set.
    event IssueFeeSet(uint256 fee, address receiver);
    /// @notice Emitted when pause is set.
    event PauseSet(bool issueIsPaused);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    struct TokenData {
        address token;
        address oracle;
        uint256 min;
        uint256 max;
    }

    /**
     * @notice The number of tokens in the pool.
     * @return length The number of tokens in the pool.
     */
    function tokensLength() external view returns (uint256 length);

    /**
     * @notice Information about a token in the pool.
     * @param token The address of the token to query.
     * @return data Information about the token.
     */
    function tokenData(address token) external view returns (TokenData memory data);

    /**
     * @notice The list of tokens in the pool.
     * @dev Iterable `[0, tokensLength)`.
     * @param index The index of the list to query.
     * @return data Information about the token.
     */
    function tokenList(uint256 index) external view returns (TokenData memory data);

    /**
     * @notice The fraction of `UWP` that are charged as a protocol fee on mint.
     * @return fee The fee as a fraction with 18 decimals.
     */
    function issueFee() external view returns (uint256 fee);

    /**
     * @notice The receiver of issue fees.
     * @return receiver The receiver of the fee.
     */
    function issueFeeTo() external view returns (address receiver);

    /**
     * @notice Returns true if issue is paused.
     * @return paused Returns true if issue is paused.
     */
    function isPaused() external view returns (bool paused);

    /**
     * @notice Calculates the value of all assets in the pool in `USD`.
     * @return valueInUSD The value of the pool in `USD` with 18 decimals.
     */
    function valueOfPool() external view returns (uint256 valueInUSD);

    /**
     * @notice Calculates the value of an amount of `UWP` shares in `USD`.
     * @param shares The amount of shares to query.
     * @return valueInUSD The value of the shares in `USD` with 18 decimals.
     */
    function valueOfShares(uint256 shares) external view returns (uint256 valueInUSD);

    /**
     * @notice Calculates the value of a holders `UWP` shares in `USD`.
     * @param holder The holder to query.
     * @return valueInUSD The value of the users shares in `USD` with 18 decimals.
     */
    function valueOfHolder(address holder) external view returns (uint256 valueInUSD);

    /**
     * @notice Determines the amount of tokens that would be minted for a given deposit.
     * @param depositTokens The list of tokens to deposit.
     * @param depositAmounts The amount of each token to deposit.
     * @return amount The amount of `UWP` minted.
     */
    function calculateIssue(address[] memory depositTokens, uint256[] memory depositAmounts) external view returns (uint256 amount);

    /**
     * @notice Determines the amount of underlying tokens that would be received for an amount of `UWP`.
     * @param amount The amount of `UWP` to burn.
     * @return amounts The amount of each token received.
     */
    function calculateRedeem(uint256 amount) external view returns (uint256[] memory amounts);

    /***************************************
    MODIFIER FUNCTIONS
    ***************************************/

    /**
     * @notice Deposits one or more tokens into the pool.
     * @param depositTokens The list of tokens to deposit.
     * @param depositAmounts The amount of each token to deposit.
     * @param receiver The address to send newly minted `UWP` to.
     * @return amount The amount of `UWP` minted.
     */
    function issue(address[] memory depositTokens, uint256[] memory depositAmounts, address receiver) external returns (uint256 amount);

    /**
     * @notice Redeems some `UWP` for some of the tokens in the pool.
     * @param amount The amount of `UWP` to burn.
     * @param receiver The address to receive underlying tokens.
     * @return amounts The amount of each token received.
     */
    function redeem(uint256 amount, address receiver) external returns (uint256[] memory amounts);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds tokens to the pool. If the token is already in the pool, sets its oracle, min, and max.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokens The list of tokens to add.
     */
    function addTokensToPool(TokenData[] memory tokens) external;

    /**
     * @notice Removes tokens from the pool.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokens The list of tokens to remove.
     */
    function removeTokensFromPool(address[] memory tokens) external;

    /**
     * @notice Rescues misplaced tokens.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokens The list of tokens to rescue.
     * @param receiver The receiver of the tokens.
     */
    function rescueTokens(address[] memory tokens, address receiver) external;

    /**
     * @notice Sets the issue fee and receiver.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param fee The fee as a fraction with 18 decimals.
     * @param receiver The receiver of the fee.
     */
    function setIssueFee(uint256 fee, address receiver) external;

    /**
     * @notice Pauses or unpauses issue.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pause True to pause issue, false to unpause.
     */
    function setPause(bool pause) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/**
 * @title IUnderwritingEquity
 * @author solace.fi
 * @notice Equity of the [Underwriting Pool](./../../native/UnderwritingPool) that can be used in Solace Native.
 *
 * Users can deposit [`UWP`](./../../native/UnderwritingPool) via [`deposit()`](#deposit) which mints `UWE`. Users can redeem `UWE` for [`UWP`](./../../native/UnderwritingPool) via [`withdraw()`](#withdraw). Note that deposits must be made via [`deposit()`](#deposit). Simply transferring [`UWP`](./../../native/UnderwritingPool) to this contract will not mint `UWE`.
 *
 * Solace may charge a protocol fee as a fraction of the mint amount [`issueFee()`](#issuefee).
 *
 * Solace may lend some of the underlying [`UWP`](./../../native/UnderwritingPool) to a lending module and borrow stables against it to pay claims via [`lend()`](#lend).
 *
 * [Governance](/docs/protocol/governance) can pause and unpause [`deposit()`](#deposit), [`withdraw()`](#withdraw), and [`lend()`](#lend).
 */
interface IUnderwritingEquity is IERC20Metadata {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a deposit is made.
    event DepositMade(address indexed user, uint256 uwpAmount, uint256 uweAmount);
    /// @notice Emitted when a withdraw is made.
    event WithdrawMade(address indexed user, uint256 uwpAmount, uint256 uweAmount);
    /// @notice Emitted when uwp is loaned.
    event UwpLoaned(uint256 uwpAmount, address receiver);
    /// @notice Emitted when issue fee is set.
    event IssueFeeSet(uint256 fee, address receiver);
    /// @notice Emitted when pause is set.
    event PauseSet(bool depositIsPaused, bool withdrawIsPaused, bool lendIsPaused);
    /// @notice Emitted when the [`UWP`](./../../native/UnderwritingPool) contract is set.
    event UwpSet(address uwp);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Address of the [underwriting pool](./../../native/UnderwritingPool).
     * @return uwp The underwriting pool.
     */
    function underwritingPool() external view returns (address uwp);

    /**
     * @notice The fraction of `UWE` that are charged as a protocol fee on mint.
     * @return fee The fee as a fraction with 18 decimals.
     */
    function issueFee() external view returns (uint256 fee);

    /**
     * @notice The receiver of issue fees.
     * @return receiver The receiver of the fee.
     */
    function issueFeeTo() external view returns (address receiver);

    /**
     * @notice Returns true if functionality of the contract is paused.
     * @return depositIsPaused Returns true if depositing is paused.
     * @return withdrawIsPaused Returns true if withdrawing is paused.
     * @return lendIsPaused Returns true if lending is paused.
     */
    function isPaused() external view returns (bool depositIsPaused, bool withdrawIsPaused, bool lendIsPaused);

    /**
     * @notice Calculates the amount of `UWE` minted for an amount of [`UWP`](./../../native/UnderwritingPool) deposited.
     * @param uwpAmount The amount of [`UWP`](./../../native/UnderwritingPool) to deposit.
     * @return uweAmount The amount of `UWE` that will be minted to the receiver.
     */
    function calculateDeposit(uint256 uwpAmount) external view returns (uint256 uweAmount);

    /**
     * @notice Calculates the amount of [`UWP`](./../../native/UnderwritingPool) returned for an amount of `UWE` withdrawn.
     * @param uweAmount The amount of `UWE` to redeem.
     * @return uwpAmount The amount of [`UWP`](./../../native/UnderwritingPool) that will be returned to the receiver.
     */
    function calculateWithdraw(uint256 uweAmount) external view returns (uint256 uwpAmount);

    /***************************************
    MODIFIER FUNCTIONS
    ***************************************/

    /**
     * @notice Deposits [`UWP`](./../../native/UnderwritingPool) into `UWE`.
     * @param uwpAmount The amount of [`UWP`](./../../native/UnderwritingPool) to deposit.
     * @param receiver The address to send newly minted `UWE` to.
     * @return uweAmount The amount of `UWE` minted.
     */
    function deposit(uint256 uwpAmount, address receiver) external returns (uint256 uweAmount);

    /**
     * @notice Redeems some `UWE` for [`UWP`](./../../native/UnderwritingPool).
     * @param uweAmount The amount of `UWE` to burn.
     * @param receiver The address to receive [`UWP`](./../../native/UnderwritingPool).
     * @return uwpAmount The amount of [`UWP`](./../../native/UnderwritingPool) received.
     */
    function withdraw(uint256 uweAmount, address receiver) external returns (uint256 uwpAmount);

    /**
     * @notice Burns some `UWE` from `msg.sender`.
     * @param uweAmount The amount of `UWE` to burn.
     */
    function burn(uint256 uweAmount) external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Rescues misplaced tokens.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokens The list of tokens to rescue.
     * @param receiver The receiver of the tokens.
     */
    function rescueTokens(address[] memory tokens, address receiver) external;

    /**
     * @notice Lends out [`UWP`](./../../native/UnderwritingPool) to pay claims.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param uwpAmount The amount of [`UWP`](./../../native/UnderwritingPool) to lend.
     * @param receiver The receiver of [`UWP`](./../../native/UnderwritingPool).
     */
    function lend(uint256 uwpAmount, address receiver) external;

    /**
     * @notice Sets the issue fee and receiver.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param fee The fee as a fraction with 18 decimals.
     * @param receiver The receiver of the fee.
     */
    function setIssueFee(uint256 fee, address receiver) external;

    /**
     * @notice Pauses or unpauses contract functionality.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param depositIsPaused True to pause deposit, false to unpause.
     * @param withdrawIsPaused True to pause withdraw, false to unpause.
     * @param lendIsPaused True to pause lend, false to unpause.
     */
    function setPause(bool depositIsPaused, bool withdrawIsPaused, bool lendIsPaused) external;

    /**
     * @notice Upgrades the [`UWP`](./../../native/UnderwritingPool) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param uwp_ The address of the new [`UWP`](./../../native/UnderwritingPool).
     */
    function setUwp(address uwp_) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./../utils/IERC721Enhanced.sol";

/// @dev Defining Lock struct outside of the interface body causes this struct to be visible to contracts that import, but do not inherit, this file. If we otherwise define this struct in the interface body, it is only visible to contracts that both import and inherit this file.
struct Lock {
    uint256 amount;
    uint256 end;
}

/**
 * @title IUnderwritingLocker
 * @author solace.fi
 * @notice Having an underwriting lock is a requirement to vote on Solace Native insurance gauges.
 * To create an underwriting lock, $UWE must be locked for a minimum of 6 months.
 *
 * Locks are ERC721s and can be viewed with [`locks()`](#locks).
 * Each lock has an `amount` of locked $UWE, and an `end` timestamp.
 * Locks have a maximum duration of four years.
 *
 * Users can create locks via [`createLock()`](#createlock) or [`createLockSigned()`](#createlocksigned).
 * Users can deposit more $UWE into a lock via [`increaseAmount()`](#increaseamount), [`increaseAmountSigned()`] (#increaseamountsigned) or [`increaseAmountMultiple()`](#increaseamountmultiple).
 * Users can extend a lock via [`extendLock()`](#extendlock) or [`extendLockMultiple()`](#extendlockmultiple).
 * Users can withdraw from a lock via [`withdraw()`](#withdraw), [`withdrawInPart()`](#withdrawinpart), [`withdrawMultiple()`](#withdrawmultiple) or [`withdrawInPartMultiple()`](#withdrawinpartmultiple).
 *
 * Users and contracts may create a lock for another address.
 * Users and contracts may deposit into a lock that they do not own.
 * A portion (set by the funding rate) of withdraws will be burned. This is to incentivize longer staking periods - withdrawing later than other users will yield more tokens than withdrawing earlier.
 * Early withdrawls will incur an additional burn, which will increase with longer remaining lock duration.
 *
 * Any time a lock is minted, burned or otherwise modified it will notify the listener contracts.
 */
// solhint-disable-next-line contract-name-camelcase
interface IUnderwritingLocker is IERC721Enhanced {

    /***************************************
    CUSTOM ERRORS
    ***************************************/

    /// @notice Thrown when array arguments are mismatched in length (and need to have the same length);
    error ArrayArgumentsLengthMismatch();

    /// @notice Thrown when zero address is given as an argument.
    /// @param contractName Name of contract for which zero address was incorrectly provided.
    error ZeroAddressInput(string contractName);

    /// @notice Thrown when extend or withdraw is attempted by a party that is not the owner nor approved for a lock.
    error NotOwnerNorApproved();

    /// @notice Thrown when create lock is attempted with 0 deposit.
    error CannotCreateEmptyLock();

    /// @notice Thrown when a user attempts to create a new lock, when they already have MAX_NUM_LOCKS locks.
    error CreatedMaxLocks();

    /// @notice Thrown when createLock is attempted with lock duration < 6 months.
    error LockTimeTooShort();

    /// @notice Thrown when createLock or extendLock is attempted with lock duration > 4 years.
    error LockTimeTooLong();

    /// @notice Thrown when extendLock is attempted to shorten the lock duration.
    error LockTimeNotExtended();

    /// @notice Thrown when a withdraw is attempted for an `amount` that exceeds the lock balance.
    error ExcessWithdraw();

    /// @notice Thrown when funding rate is set above 100%
    error FundingRateAboveOne();

    /// @notice Emitted when chargePremium() is not called by the voting contract.
    error NotVotingContract();

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a lock is created.
    event LockCreated(uint256 indexed lockID);

    /// @notice Emitted when a new deposit is made into an existing lock.
    event LockIncreased(uint256 indexed lockID, uint256 newTotalAmount, uint256 depositAmount);

    /// @notice Emitted when a new deposit is made into an existing lock.
    event LockExtended(uint256 indexed lockID, uint256 newEndTimestamp);

    /// @notice Emitted when a lock is updated.
    event LockUpdated(uint256 indexed lockID, uint256 amount, uint256 end);

    /// @notice Emitted when a lock is withdrawn from.
    event Withdrawal(uint256 indexed lockID, uint256 requestedWithdrawAmount, uint256 actualWithdrawAmount, uint256 burnAmount);

    /// @notice Emitted when an early withdraw is made.
    event EarlyWithdrawal(uint256 indexed lockID, uint256 requestedWithdrawAmount, uint256 actualWithdrawAmount, uint256 burnAmount);

    /// @notice Emitted when a listener is added.
    event LockListenerAdded(address indexed listener);

    /// @notice Emitted when a listener is removed.
    event LockListenerRemoved(address indexed listener);

    /// @notice Emitted when the registry is set.
    event RegistrySet(address indexed registry);

    /// @notice Emitted when voting contract has been set
    event VotingContractSet(address indexed votingContract);

    /// @notice Emitted when funding rate is set.
    event FundingRateSet(uint256 indexed fundingRate);

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    /// @notice Token locked in the underwriting lock.
    function token() external view returns (address);

    /// @notice Registry address
    function registry() external view returns (address);

    /// @notice UnderwriterLockVoting.sol address.
    function votingContract() external view returns (address);

    /// @notice The total number of locks that have been created.
    function totalNumLocks() external view returns (uint256);

    /// @notice Funding rate - amount that will be charged and burned from a regular withdraw.
    /// @dev Value of 1e18 => 100%.
    function fundingRate() external view returns (uint256);

    /// @notice The minimum lock duration that a new lock must be created with.
    function MIN_LOCK_DURATION() external view returns (uint256);

    /// @notice The maximum time into the future that a lock can expire.
    function MAX_LOCK_DURATION() external view returns (uint256);

    /// @notice The maximum number of locks one user can create.
    function MAX_NUM_LOCKS() external view returns (uint256);

    /***************************************
    EXTERNAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Get `amount` and `end` values for a lockID.
     * @param lockID_ The ID of the lock to query.
     * @return lock_ Lock {uint256 amount, uint256 end}.
     */
    function locks(uint256 lockID_) external view returns (Lock memory lock_);


    /**
     * @notice Determines if the lock is currently locked.
     * @param lockID_ The ID of the lock to query.
     * @return locked True if the lock is locked, false if unlocked.
     */
    function isLocked(uint256 lockID_) external view returns (bool locked);

    /**
     * @notice Determines the time left until the lock unlocks.
     * @param lockID_ The ID of the lock to query.
     * @return time The time left in seconds, 0 if unlocked.
     */
    function timeLeft(uint256 lockID_) external view returns (uint256 time);

    /**
     * @notice Returns the total token amount that the user has staked in underwriting locks.
     * @param account_ The account to query.
     * @return balance The user's total staked token amount.
     */
    function totalStakedBalance(address account_) external view returns (uint256 balance);

    /**
     * @notice The list of contracts that are listening to lock updates.
     * @return listeners_ The list as an array.
     */
    function getLockListeners() external view returns (address[] memory listeners_);

    /**
     * @notice Computes amount of token that will be transferred to the user on full withdraw.
     * @param lockID_ The ID of the lock to query.
     * @return withdrawAmount Token amount that will be withdrawn.
     */
    function getWithdrawAmount(uint256 lockID_) external view returns (uint256 withdrawAmount);

    /**
     * @notice Computes amount of token that will be transferred to the user on partial withdraw.
     * @param lockID_ The ID of the lock to query.
     * @param amount_ The requested amount to withdraw.
     * @return withdrawAmount Token amount that will be withdrawn.
     */
    function getWithdrawInPartAmount(uint256 lockID_, uint256 amount_) external view returns (uint256 withdrawAmount);

    /**
     * @notice Computes amount of token that will be burned on full withdraw.
     * @param lockID_ The ID of the lock to query.
     * @return burnAmount Token amount that will be burned on withdraw.
     */
    function getBurnOnWithdrawAmount(uint256 lockID_) external view returns (uint256 burnAmount);

    /**
     * @notice Computes amount of token that will be burned on partial withdraw.
     * @param lockID_ The ID of the lock to query.
     * @param amount_ The requested amount to withdraw.
     * @return burnAmount Token amount that will be burned on withdraw.
     */
    function getBurnOnWithdrawInPartAmount(uint256 lockID_, uint256 amount_) external view returns (uint256 burnAmount);

    /**
     * @notice Gets multiplier (applied for voting boost, and for early withdrawals).
     * @param lockID_ The ID of the lock to query.
     * @return multiplier 1e18 => 1x multiplier, 2e18 => 2x multiplier.
     */
    function getLockMultiplier(uint256 lockID_) external view returns (uint256 multiplier);

    /**
     * @notice Gets all active lockIDs for a user.
     * @param user_ The address of user to query.
     * @return lockIDs Array of active lockIDs.
     */
    function getAllLockIDsOf(address user_) external view returns (uint256[] memory lockIDs);

    /***************************************
    EXTERNAL MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit token to create a new lock.
     * @dev Token is transferred from msg.sender, assumes its already approved.
     * @param recipient_ The account that will receive the lock.
     * @param amount_ The amount of token to deposit.
     * @param end_ The timestamp the lock will unlock.
     * @return lockID The ID of the newly created lock.
     */
    function createLock(address recipient_, uint256 amount_, uint256 end_) external returns (uint256 lockID);

    /**
     * @notice Deposit token to create a new lock.
     * @dev Token is transferred from msg.sender using ERC20Permit.
     * @dev recipient = msg.sender.
     * @param amount_ The amount of token to deposit.
     * @param end_ The timestamp the lock will unlock.
     * @param deadline_ Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     * @return lockID The ID of the newly created lock.
     */
    function createLockSigned(uint256 amount_, uint256 end_, uint256 deadline_, uint8 v, bytes32 r, bytes32 s) external returns (uint256 lockID);

    /**
     * @notice Deposit token to increase the value of an existing lock.
     * @dev Token is transferred from msg.sender, assumes its already approved.
     * @dev Anyone (not just the lock owner) can call increaseAmount() and deposit to an existing lock.
     * @param lockID_ The ID of the lock to update.
     * @param amount_ The amount of token to deposit.
     */
    function increaseAmount(uint256 lockID_, uint256 amount_) external;

    /**
     * @notice Deposit token to increase the value of multiple existing locks.
     * @dev Token is transferred from msg.sender, assumes its already approved.
     * @dev If a lockID does not exist, the corresponding amount will be refunded to msg.sender.
     * @dev Anyone (not just the lock owner) can call increaseAmountMultiple() and deposit to existing locks.
     * @param lockIDs_ Array of lock IDs to update.
     * @param amounts_ Array of token amounts to deposit.
     */
    function increaseAmountMultiple(uint256[] calldata lockIDs_, uint256[] calldata amounts_) external;

    /**
     * @notice Deposit token to increase the value of an existing lock.
     * @dev Token is transferred from msg.sender using ERC20Permit.
     * @dev Anyone (not just the lock owner) can call increaseAmount() and deposit to an existing lock.
     * @param lockID_ The ID of the lock to update.
     * @param amount_ The amount of token to deposit.
     * @param deadline_ Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function increaseAmountSigned(uint256 lockID_, uint256 amount_, uint256 deadline_, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @notice Extend a lock's duration.
     * @dev Can only be called by the lock owner or approved.
     * @param lockID_ The ID of the lock to update.
     * @param end_ The new time for the lock to unlock.
     */
    function extendLock(uint256 lockID_, uint256 end_) external;

    /**
     * @notice Extend multiple locks' duration.
     * @dev Can only be called by the lock owner or approved.
     * @dev If non-existing lockIDs are entered, these will be skipped.
     * @param lockIDs_ Array of lock IDs to update.
     * @param ends_ Array of new unlock times.
     */
    function extendLockMultiple(uint256[] calldata lockIDs_, uint256[] calldata ends_) external;

    /**
     * @notice Withdraw from a lock in full.
     * @dev Can only be called by the lock owner or approved.
     * @dev If called before `end` timestamp, will incur additional burn amount.
     * @param lockID_ The ID of the lock to withdraw from.
     * @param recipient_ The user to receive the lock's token.
     */
    function withdraw(uint256 lockID_, address recipient_) external;

    /**
     * @notice Withdraw from a lock in part.
     * @dev Can only be called by the lock owner or approved.
     * @dev If called before `end` timestamp, will incur additional burn amount.
     * @param lockID_ The ID of the lock to withdraw from.
     * @param amount_ The amount of token to withdraw.
     * @param recipient_ The user to receive the lock's token.
     */
    function withdrawInPart(uint256 lockID_, uint256 amount_, address recipient_) external;

    /**
     * @notice Withdraw from multiple locks in full.
     * @dev Can only be called by the lock owner or approved.
     * @dev If called before `end` timestamp, will incur additional burn amount.
     * @param lockIDs_ The ID of the locks to withdraw from.
     * @param recipient_ The user to receive the lock's token.
     */
    function withdrawMultiple(uint256[] calldata lockIDs_, address recipient_) external;

    /**
     * @notice Withdraw from multiple locks in part.
     * @dev Can only be called by the lock owner or approved.
     * @dev If called before `end` timestamp, will incur additional burn amount.
     * @param lockIDs_ The ID of the locks to withdraw from.
     * @param amounts_ Array of token amounts to withdraw
     * @param recipient_ The user to receive the lock's token.
     */
    function withdrawInPartMultiple(uint256[] calldata lockIDs_, uint256[] calldata amounts_ ,address recipient_) external;

    /***************************************
    VOTING CONTRACT FUNCTIONS
    ***************************************/

    /**
     * @notice Perform accounting for voting premiums to be charged by UnderwritingLockVoting.chargePremiums().
     * @dev Can only be called by votingContract set in the registry.
     * @param lockID_ The ID of the lock to charge premium.
     * @param premium_ Amount of tokens to charge as premium.
     */
    function chargePremium(uint256 lockID_, uint256 premium_) external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a listener.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param listener_ The listener to add.
     */
    function addLockListener(address listener_) external;

    /**
     * @notice Removes a listener.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param listener_ The listener to remove.
     */
    function removeLockListener(address listener_) external;

    /**
     * @notice Sets the base URI for computing `tokenURI`.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external;

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param registry_ The address of `Registry` contract.
     */
    function setRegistry(address registry_) external;

    /**
     * @notice Sets votingContract and enable safeTransferFrom call by `underwritingLockVoting` address stored in Registry.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function setVotingContract() external;

    /**
     * @notice Sets fundingRate.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param fundingRate_ Desired funding rate, 1e18 => 100%
     */
    function setFundingRate(uint256 fundingRate_) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IDepositHelper
 * @author solace.fi
 * @notice The process of depositing into Solace Native requires multiple steps across multiple contracts. This helper contract allows users to deposit with a single transaction.
 *
 * These steps are
 * 1. Deposit governance token into [`UWP`](./../../native/UnderwritingPool).
 * 2. Deposit [`UWP`](./../../native/UnderwritingPool) into [`UWE`](./../../native/UnderwritingEquity).
 * 3. Deposit [`UWE`](./../../native/UnderwritingEquity) into an [`Underwriting Lock`](./../../native/UnderwritingLocker).
 *
 * These steps can be replaced with [`depositAndLock()`](#depositandlock) or [`depositIntoLock()`](#depositintolock).
 */
interface IDepositHelper {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Address of the [underwriting pool](./../../native/UnderwritingPool).
     * @return uwp The underwriting pool.
     */
    function underwritingPool() external view returns (address uwp);

    /**
     * @notice Address of [underwriting equity](./../../native/UnderwritingEquity).
     * @return uwe The underwriting equity.
     */
    function underwritingEquity() external view returns (address uwe);

    /**
     * @notice Address of [underwriting locker](./../../native/UnderwritingLocker).
     * @return locker The underwriting locker.
     */
    function underwritingLocker() external view returns (address locker);

    /**
     * @notice Calculates the amount of [`UWE`](./../../native/UnderwritingEquity) minted for an amount of a token deposited.
     * The deposit token may be one of the tokens in [`UWP`](./../../native/UnderwritingPool), the [`UWP`](./../../native/UnderwritingPool) token, or the [`UWE`](./../../native/UnderwritingEquity) token.
     * @param depositToken The address of the token to deposit.
     * @param depositAmount The amount of the token to deposit.
     * @return uweAmount The amount of [`UWE`](./../../native/UnderwritingEquity) that will be minted to the receiver.
     */
    function calculateDeposit(address depositToken, uint256 depositAmount) external view returns (uint256 uweAmount);

    /***************************************
    DEPOSIT FUNCTIONS
    ***************************************/

    /**
     * @notice Deposits tokens into [`UWE`](./../../native/UnderwritingEquity) and deposits [`UWE`](./../../native/UnderwritingEquity) into a new [`UWE Lock`](./../../native/UnderwritingLocker).
     * @param depositToken Address of the token to deposit.
     * @param depositAmount Amount of the token to deposit.
     * @param lockExpiry The timestamp the lock will unlock.
     * @return lockID The ID of the newly created [`UWE Lock`](./../../native/UnderwritingLocker).
     */
    function depositAndLock(
        address depositToken,
        uint256 depositAmount,
        uint256 lockExpiry
    ) external returns (uint256 lockID);

    /**
     * @notice Deposits tokens into [`UWE`](./../../native/UnderwritingEquity) and deposits [`UWE`](./../../native/UnderwritingEquity) into an existing [`UWE Lock`](./../../native/UnderwritingLocker).
     * @param depositToken Address of the token to deposit.
     * @param depositAmount Amount of the token to deposit.
     * @param lockID The ID of the [`UWE Lock`](./../../native/UnderwritingLocker) to deposit into.
     */
    function depositIntoLock(
        address depositToken,
        uint256 depositAmount,
        uint256 lockID
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from OpenZeppelin and @uniswap/v3-periphery
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title ERC721Enhanced
 * @author solace.fi
 * @notice An extension of `ERC721`.
 *
 * The base is OpenZeppelin's `ERC721Enumerable` which also includes the `Metadata` extension. This extension includes simpler transfers, gasless approvals, and changeable URIs.
 */
interface IERC721Enhanced is IERC721Enumerable {

    /***************************************
    SIMPLER TRANSFERS
    ***************************************/

    /**
     * @notice Transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `transferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function transfer(address to, uint256 tokenID) external;

    /**
     * @notice Safely transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `safeTransferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function safeTransfer(address to, uint256 tokenID) external;

    /***************************************
    GASLESS APPROVALS
    ***************************************/

    /**
     * @notice Approve of a specific `tokenID` for spending by `spender` via signature.
     * @param spender The account that is being approved.
     * @param tokenID The ID of the token that is being approved for spending.
     * @param deadline The deadline timestamp by which the call must be mined for the approve to work.
     * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`.
     * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`.
     * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`.
     */
    function permit(
        address spender,
        uint256 tokenID,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Returns the current nonce for `tokenID`. This value must be
     * included whenever a signature is generated for `permit`.
     * Every successful call to `permit` increases ``tokenID``'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @param tokenID ID of the token to request nonce.
     * @return nonce Nonce of the token.
     */
    function nonces(uint256 tokenID) external view returns (uint256 nonce);

    /**
     * @notice The permit typehash used in the `permit` signature.
     * @return typehash The typehash for the `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external view returns (bytes32 typehash);

    /**
     * @notice The domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return seperator The domain seperator for `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 seperator);

    /***************************************
    CHANGEABLE URIS
    ***************************************/

    /// @notice Emitted when the base URI is set.
    event BaseURISet(string baseURI);

    /***************************************
    MISC
    ***************************************/

    /**
     * @notice Determines if a token exists or not.
     * @param tokenID The ID of the token to query.
     * @return status True if the token exists, false if it doesn't.
     */
    function exists(uint256 tokenID) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}