// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OwnPauseAuth.sol";

contract TimeLockStaking is OwnPauseAuth, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ERC20 token for staking
    IERC20 public token;

    // Campaign Name
    string public name;

    // Locking timelock (in second) after that possible to claim
    uint256 public timelock;

    // Annual Percentage Rate
    uint256 public apr;

    // Max allowable tokens for deposit
    uint256 public maxCap;

    // Campaign expiry time (in second) after that impossible to deposit
    uint256 public expiryTime;

    uint256 public minTokensPerDeposit;

    uint256 public maxTokensPerDeposit;

    // Total amount of deposited and reward tokens that have already been paid out
    uint256 public totalPayout;

    // Total amount of reward tokens
    uint256 public totalRewardTokens;

    uint256 public totalDepositedTokens;

    bool public isMaxCapReached = false;

    struct DepositInfo {
        uint256 seq;
        uint256 amount;
        uint256 reward;
        bool isPaidOut;
        uint256 unlockTime;
    }

    mapping(address => DepositInfo[]) public stakingList;

    event Deposited(
        address indexed sender,
        uint256 seq,
        uint256 amount,
        uint256 timestamp
    );

    event Claimed(
        address indexed sender,
        uint256 seq,
        uint256 amount,
        uint256 reward,
        uint256 timestamp
    );

    event OwnerClaimed(address indexed sender, uint256 _remainingReward, address _to);
    event OwnerWithdrawn(address indexed sender, uint256 _amount, address _to);
    event OwnerWithdrawnAll(address indexed sender, uint256 _amount, address _to);

    event EvtSetName(string _name);
    event EvtSetTimelock(uint256 _timelock);
    event EvtSetAPR(uint256 _apr);
    event EvtSetMaxCap(uint256 _maxCap);
    event EvtSetExpiryTime(uint256 _expiryTime);
    event EvtSetMinTokensPerDeposit(uint256 _minTokensPerDeposit);
    event EvtSetMaxTokensPerDeposit(uint256 _maxTokensPerDeposit);

    constructor(
        IERC20 _token,
        string memory _campaignName,
        uint256 _expiryTime, // set to zero to disable expiry
        uint256 _maxCap,
        uint256 _maxTokensPerDeposit,
        uint256 _minTokensPerDeposit,
        uint256 _timelock,
        uint256 _apr
    ) {
        token = _token;
        name = _campaignName;

        if (_expiryTime > 0) {
            expiryTime = block.timestamp + _expiryTime;
        }

        maxCap = _maxCap;
        maxTokensPerDeposit = _maxTokensPerDeposit;
        minTokensPerDeposit = _minTokensPerDeposit;
        timelock = _timelock;
        apr = _apr;
    }

    function deposit(uint256 _amountIn) external whenNotPaused nonReentrant {
        require(isMaxCapReached == false, "TimeLockStaking: Max cap reached");

        uint256 _amount;
        if (totalDepositedTokens + _amountIn <= maxCap) {
            _amount = _amountIn;
        } else {
            isMaxCapReached = true;
            _amount = maxCap - totalDepositedTokens;
        }

        require(
            _amount >= minTokensPerDeposit,
            "TimeLockStaking: Depositing amount smaller than minTokensPerDeposit"
        );
        require(
            _amount <= maxTokensPerDeposit,
            "TimeLockStaking: Depositing amount larger than maxTokensPerDeposit"
        );
        require(
            expiryTime == 0 || block.timestamp < expiryTime,
            "TimeLockStaking: Campaign over"
        );

        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 unlockTime = block.timestamp + timelock;
        uint256 seq = stakingList[msg.sender].length + 1;
        uint256 reward = (_amount * apr * timelock) /
            (365 * 24 * 60 * 60 * 100);

        DepositInfo memory staking = DepositInfo(
            seq,
            _amount,
            reward,
            false,
            unlockTime
        );
        stakingList[msg.sender].push(staking);

        totalDepositedTokens += _amount;
        totalRewardTokens += reward;

        emit Deposited(msg.sender, seq, _amount, block.timestamp);
    }

    function claim(uint256 _seq) external whenNotPaused nonReentrant {
        DepositInfo[] memory userStakings = stakingList[msg.sender];
        require(
            _seq > 0 && userStakings.length >= _seq,
            "TimeLockStaking: Invalid seq"
        );

        uint256 idx = _seq - 1;

        DepositInfo memory staking = userStakings[idx];

        require(!staking.isPaidOut, "TimeLockStaking: Already paid out");
        require(
            staking.unlockTime <= block.timestamp,
            "TimeLockStaking: Staking still locked"
        );

        uint256 payout = staking.amount + staking.reward;

        token.safeTransfer(msg.sender, payout);
        totalPayout += payout;

        stakingList[msg.sender][idx].isPaidOut = true;

        emit Claimed(
            msg.sender,
            _seq,
            staking.amount,
            staking.reward,
            block.timestamp
        );
    }

    // Get the total tokens that still need to be paid out (including deposited tokens and reward tokens)
    function getRemainingPayout() public view returns (uint256) {
        uint256 remainingPayoutAmount = totalDepositedTokens +
            totalRewardTokens -
            totalPayout;
        return remainingPayoutAmount;
    }

    // Get the token balance of this contract
    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Get the total tokens that still need to be rewarded
    function getRemainingReward() public view returns (uint256) {
        uint256 remainingPayoutAmount = getRemainingPayout();
        uint256 balance = getTokenBalance();
        return balance - remainingPayoutAmount;
    }

    // Owner can withdraw all remaining reward tokens
    function ownerClaimRemainingReward(address _to)
        external
        isOwner
        nonReentrant
    {
        require(
            block.timestamp > expiryTime,
            "TimeLockStaking: Campaign not yet expired"
        );

        uint256 remainingReward = getRemainingReward();
        token.safeTransfer(_to, remainingReward);

        emit OwnerClaimed(msg.sender, remainingReward, _to);
    }

    // Owner can withdraw a specified amount of tokens
    function ownerWithdraw(address _to, uint256 _amount)
        external
        isOwner
        nonReentrant
    {
        token.safeTransfer(_to, _amount);

        emit OwnerWithdrawn(msg.sender, _amount, _to);
    }

    // Owner can withdraw all tokens
    function ownerWithdrawAll(address _to) external isOwner nonReentrant {
        uint256 tokenBal = getTokenBalance();
        token.safeTransfer(_to, tokenBal);

        emit OwnerWithdrawnAll(msg.sender, tokenBal, _to);
    }

    function setName(string memory _name) external isAuthorized {
        name = _name;
        emit EvtSetName(_name);
    }

    function setTimelock(uint256 _timelock) external isAuthorized {
        timelock = _timelock;
        emit EvtSetTimelock(_timelock);
    }

    function setAPR(uint256 _apr) external isAuthorized {
        apr = _apr;
        emit EvtSetAPR(_apr);
    }

    function setMaxCap(uint256 _maxCap) external isAuthorized {
        maxCap = _maxCap;
        isMaxCapReached = false;
        emit EvtSetMaxCap(_maxCap);
    }

    function setExpiryTime(uint256 _expiryTime) external isAuthorized {
        expiryTime = _expiryTime;
        emit EvtSetExpiryTime(_expiryTime);
    }

    function setMinTokensPerDeposit(uint256 _minTokensPerDeposit)
        external
        isAuthorized
    {
        minTokensPerDeposit = _minTokensPerDeposit;
        emit EvtSetMinTokensPerDeposit(_minTokensPerDeposit);
    }

    function setMaxTokensPerDeposit(uint256 _maxTokensPerDeposit)
        external
        isAuthorized
    {
        maxTokensPerDeposit = _maxTokensPerDeposit;
        emit EvtSetMaxTokensPerDeposit(_maxTokensPerDeposit);
    }

    function getCampaignInfo()
        external
        view
        returns (
            IERC20 _token,
            string memory _campaignName,
            uint256 _expiryTime,
            uint256 _maxCap,
            uint256 _maxTokensPerDeposit,
            uint256 _minTokensPerDeposit,
            uint256 _timelock,
            uint256 _apr,
            uint256 _totalDepositedTokens,
            uint256 _totalPayout
        )
    {
        return (
            token,
            name,
            expiryTime,
            maxCap,
            maxTokensPerDeposit,
            minTokensPerDeposit,
            timelock,
            apr,
            totalDepositedTokens,
            totalPayout
        );
    }

    function getStakings(address _staker)
        external
        view
        returns (
            uint256[] memory _seqs,
            uint256[] memory _amounts,
            uint256[] memory _rewards,
            bool[] memory _isPaidOuts,
            uint256[] memory _timestamps
        )
    {
        DepositInfo[] memory userStakings = stakingList[_staker];

        uint256 length = userStakings.length;

        uint256[] memory seqList = new uint256[](length);
        uint256[] memory amountList = new uint256[](length);
        uint256[] memory rewardList = new uint256[](length);
        bool[] memory isPaidOutList = new bool[](length);
        uint256[] memory timeList = new uint256[](length);

        for (uint256 idx = 0; idx < length; idx++) {
            DepositInfo memory stakingInfo = userStakings[idx];

            seqList[idx] = stakingInfo.seq;
            amountList[idx] = stakingInfo.amount;
            rewardList[idx] = stakingInfo.reward;
            isPaidOutList[idx] = stakingInfo.isPaidOut;
            timeList[idx] = stakingInfo.unlockTime;
        }

        return (seqList, amountList, rewardList, isPaidOutList, timeList);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OwnPauseAuth is Ownable, Pausable {
    mapping(address => bool) internal _authorizedAddressList;

    event RevokeAuthorized(address auth_);
    event GrantAuthorized(address auth_);

    modifier isAuthorized() {
        require(
            msg.sender == owner() || _authorizedAddressList[msg.sender] == true,
            "OwnPauseAuth: unauthorized"
        );
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner(), "OwnPauseAuth: not owner");
        _;
    }

    function grantAuthorized(address auth_) external isOwner {
        require(auth_ != address(0), "OwnPauseAuth: invalid auth_ address ");

        _authorizedAddressList[auth_] = true;

        emit GrantAuthorized(auth_);
    }

    function revokeAuthorized(address auth_) external isOwner {
        require(auth_ != address(0), "OwnPauseAuth: invalid auth_ address ");

        _authorizedAddressList[auth_] = false;

        emit RevokeAuthorized(auth_);
    }

    function checkAuthorized(address auth_) public view returns (bool) {
        require(auth_ != address(0), "OwnPauseAuth: invalid auth_ address ");

        return auth_ == owner() || _authorizedAddressList[auth_] == true;
    }

    function pause() external isOwner {
        _pause();
    }

    function unpause() external isOwner {
        _unpause();
    }
}