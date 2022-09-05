/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IRcaController.sol";

// solhint-disable not-rely-on-time

contract BribePot {
    using SafeERC20Upgradeable for IERC20Permit;

    /* ========== structs ========== */
    struct BribeDetail {
        /// @notice Ease paid per week
        uint112 rate;
        /// @notice Bribe Start week (including)
        uint32 startWeek;
        /// @notice Bribe end week (upto)
        uint32 endWeek;
    }
    struct BribeRate {
        /// @notice amount of bribe to start
        uint128 startAmt;
        /// @notice amount of bribe to expire
        uint128 expireAmt;
    }
    struct PermitArgs {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /* ========== CONSTANTS ========== */
    uint256 private constant WEEK = 1 weeks;
    uint256 private constant MULTIPLIER = 1e18;

    /* ========== STATE ========== */
    string public name = "Ease Bribe Pot";
    IERC20Permit public immutable rewardsToken;
    IRcaController public immutable rcaController;
    address public gvToken;
    /// @notice Time upto which bribe rewards are active
    uint256 public periodFinish = 0;
    /// @notice Last updated timestamp
    uint256 public lastRewardUpdate;
    uint256 public rewardPerTokenStored;
    /// @notice week upto which bribes has been updated (aka expired)
    uint256 public lastBribeUpdate;
    /// @notice Nearest floor week in timestamp before deployment
    uint256 public immutable genesis = (block.timestamp / WEEK) * WEEK;

    /// @notice total gvEASE deposited to bribe pot
    uint256 private _totalSupply;
    /// @notice Bribe per week stored at last bribe update week
    uint256 private _bribeRateStored = 0;

    mapping(address => uint256) public userRewardPerTokenPaid;
    /// @notice Ease rewards stored for bribing gvEASE
    mapping(address => uint256) public rewards;
    /// @notice user => rca-vault => BribeDetail
    mapping(address => mapping(address => BribeDetail)) public bribes;

    /// @notice weekNumber => Bribes that activate and expire every week
    mapping(uint256 => BribeRate) private bribeRates;
    /// @notice user balance of gvEASE deposited to bribe pot
    mapping(address => uint256) private _balances;

    /* ========== EVENTS ========== */
    event Leased(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event BribeAdded(
        address indexed user,
        address indexed vault,
        uint256 bribePerWeek,
        uint256 startWeek,
        uint256 endWeek
    );
    event BribeCanceled(
        address indexed user,
        address indexed vault,
        uint256 bribePerWeek,
        uint256 expiryWeek, // this will always currentWeek + 1
        uint256 endWeek
    );

    /* ========== MODIFIERS ========== */
    modifier onlyGvToken(address caller) {
        require(caller == gvToken, "only gvToken");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _gvToken,
        address _rewardsToken,
        address _rcaController
    ) {
        rewardsToken = IERC20Permit(_rewardsToken);
        gvToken = _gvToken;
        lastRewardUpdate = genesis;
        periodFinish = genesis;
        rcaController = IRcaController(_rcaController);
    }

    /* ========== EXTERNAL FUNCTIONS ========== */
    ///@notice Deposit gvEase of a user
    ///@param from wallet address of a user
    ///@param amount amount of gvEase to deposit to venal pot
    function deposit(address from, uint256 amount)
        external
        onlyGvToken(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        // update reward rates and bribes
        _update(from);
        _totalSupply += amount;
        _balances[from] += amount;

        emit Leased(from, amount);
    }

    ///@notice Withdraw gvEase of user
    ///@param from wallet address of a user
    ///@param amount amount of gvEase to withdraw from venal pot
    function withdraw(address from, uint256 amount)
        external
        onlyGvToken(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        // update reward rates and bribes
        _update(from);
        _totalSupply -= amount;
        _balances[from] -= amount;

        emit Withdrawn(from, amount);
    }

    ///@notice Transfers rewards amount to the desired user
    ///@param user address of gvEase depositor
    ///@param toUser boolean to identify whom to transfer (gvEASE contract/user)
    function getReward(address user, bool toUser)
        external
        onlyGvToken(msg.sender)
        returns (uint256)
    {
        // update reward rates and bribes
        _update(user);
        uint256 reward = rewards[user];
        if (reward > 0) {
            rewards[user] = 0;

            // if user wants to reDeposit transfer to gvToken else
            // transfer to user's wallet
            address to = toUser ? user : gvToken;
            rewardsToken.safeTransfer(to, reward);

            emit RewardPaid(user, reward);
        }
        return reward;
    }

    ///@notice Adds bribes per week to venal pot and recieve percentage
    /// share of the venal pot depending on share of the bribe the briber
    /// is paying per week. Bribe will activate starting next week.
    ///@param bribeRate EASE per week for percentage share of bribe pot
    ///@param vault Rca-vault address to bribe gvEASE for
    ///@param numOfWeeks Number of weeks to bribe with the current rate
    function bribe(
        uint256 bribeRate,
        address vault,
        uint256 numOfWeeks, // Total weeks to bribe
        PermitArgs memory permit
    ) external {
        require(_totalSupply > 0, "nothing to bribe");

        require(rcaController.activeShields(vault), "inactive vault");

        uint256 startWeek = ((block.timestamp - genesis) / WEEK) + 1;
        uint256 endWeek = startWeek + numOfWeeks;
        address briber = msg.sender;
        // check if bribe already exists
        require(
            bribes[briber][vault].endWeek <= _getCurrWeek(),
            "bribe already exists"
        );

        // transfer amount to bribe pot
        uint256 amount = bribeRate * numOfWeeks;
        _transferRewardToken(briber, amount, permit);

        bribes[briber][vault] = BribeDetail(
            uint112(bribeRate),
            uint16(startWeek),
            uint16(endWeek)
        );

        bribeRates[startWeek].startAmt += uint112(bribeRate);
        bribeRates[endWeek].expireAmt += uint112(bribeRate);

        // update reward period finish
        uint256 bribeFinish = genesis + (endWeek * WEEK);
        if (bribeFinish > periodFinish) {
            periodFinish = bribeFinish;
        }

        emit BribeAdded(briber, vault, bribeRate, startWeek, endWeek);
    }

    /// @notice Allows user to cancel existing bribe if it seems unprofitable.
    /// Transfers remaining EASE amount to the briber by rounding to end of current week
    /// @param vault Rca-vault address to cancel bribe for
    function cancelBribe(address vault) external {
        address briber = msg.sender;
        BribeDetail memory userBribe = bribes[briber][vault];
        delete bribes[briber][vault];
        uint256 currWeek = _getCurrWeek();

        // if bribe starts at week 1 and ends at week 5 that
        // means number of week bribe will be active is 4 weeks

        // if bribe has expired or does not exist this line will error
        uint256 amountToRefund = (userBribe.endWeek - (currWeek + 1)) *
            userBribe.rate;

        // remove expire amt from end week
        bribeRates[userBribe.endWeek].expireAmt -= userBribe.rate;
        // add expire amt to next week
        bribeRates[currWeek + 1].expireAmt += userBribe.rate;

        // update reward end week if this is the last bribe of
        // the system
        uint256 endTime = (userBribe.endWeek * WEEK) + genesis;
        if (endTime == periodFinish) {
            uint256 lastBribeEndWeek = userBribe.endWeek;
            while (lastBribeEndWeek > currWeek) {
                if (bribeRates[lastBribeEndWeek].expireAmt != 0) {
                    periodFinish = genesis + (lastBribeEndWeek * WEEK);
                    break;
                }
                lastBribeEndWeek--;
            }
        }

        if (amountToRefund != 0) {
            rewardsToken.safeTransfer(briber, amountToRefund);
        }

        emit BribeCanceled(
            briber,
            vault,
            userBribe.rate,
            currWeek + 1,
            userBribe.endWeek
        );
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() external view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        // consider the bribes that has not been
        // added to rewardPerToken because of user inaction
        (
            uint256 additionalRewardPerToken,
            uint256 currBribePerWeek,

        ) = _getBribeUpdates();
        return _rewardPerToken(additionalRewardPerToken, currBribePerWeek);
    }

    /// @notice amount of EASE token earned for bribing gvEASE
    /// @param account address of a user to get earned rewards
    /// @return amount of reward owed to the user
    function earned(address account) public view returns (uint256) {
        (
            uint256 additionalRewardPerToken,
            uint256 currBribePerWeek,

        ) = _getBribeUpdates();
        uint256 currRewardPerToken = _rewardPerToken(
            additionalRewardPerToken,
            currBribePerWeek
        );
        return _earned(account, currRewardPerToken);
    }

    ///@notice Calculates total bribe per week for current week
    ///@return bribeRate Total bribe per week for entire venal pot
    function bribePerWeek() external view returns (uint256 bribeRate) {
        bribeRate = _getCurrWeekBribeRate();
    }

    ///@notice Calculates total reward user can earn current week
    ///@param user User address to calculate reward for
    ///@return rewardAmt Amount of ease user can get from current week
    function earnable(address user) external view returns (uint256 rewardAmt) {
        if (_totalSupply == 0) {
            return 0;
        }
        uint256 totalBribePerWeek = _getCurrWeekBribeRate();
        rewardAmt = (_balances[user] * totalBribePerWeek) / _totalSupply;
    }

    ///@notice Calculates amount of gvToken briber can get for bribing EASE
    ///@param bribeRate Bribe per week in EASE
    ///@return gvAmt Amount of gvEase briber will be given
    function expectedGvAmount(uint256 bribeRate)
        external
        view
        returns (uint256 gvAmt)
    {
        uint256 currBribePerWeek = _getCurrWeekBribeRate();
        if (currBribePerWeek == 0) {
            gvAmt = _totalSupply;
        } else {
            gvAmt = (bribeRate * _totalSupply) / (currBribePerWeek + bribeRate);
        }
    }

    function earningsPerWeek(uint256 gvAmt)
        external
        view
        returns (uint256 rewardAmt)
    {
        uint256 currBribeRate = _getCurrWeekBribeRate();
        if (currBribeRate == 0 || gvAmt == 0) {
            rewardAmt = 0;
        } else {
            rewardAmt = (currBribeRate * gvAmt) / (_totalSupply + gvAmt);
        }
    }

    /* ========== INTERNAL ========== */
    ///@notice Update rewards collected and rewards per token paid
    ///for the user's account
    function _update(address account) internal {
        (
            uint256 additionalRewardPerToken,
            uint256 currBribePerWeek,
            uint256 bribeUpdatedUpto
        ) = _getBribeUpdates();

        lastBribeUpdate = bribeUpdatedUpto;
        _bribeRateStored = currBribePerWeek;

        rewardPerTokenStored = _rewardPerToken(
            additionalRewardPerToken,
            currBribePerWeek
        );

        // should be updated after calculating _rewardPerToken()
        lastRewardUpdate = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = _earned(account, rewardPerTokenStored);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function _transferRewardToken(
        address from,
        uint256 amount,
        PermitArgs memory permit
    ) internal {
        // we only call permit if bribePot doesn't have enough allowance
        if (permit.r != "") {
            rewardsToken.permit(
                from,
                address(this),
                amount,
                permit.deadline,
                permit.v,
                permit.r,
                permit.s
            );
        }
        rewardsToken.safeTransferFrom(from, address(this), amount);
    }

    ///@notice Current week count from genesis starts at 0
    function _getCurrWeek() internal view returns (uint256) {
        return ((block.timestamp - genesis) / WEEK);
    }

    ///@notice calculates bribe rate for current week
    ///@return currBribePerWeek Current week total bribe amount for
    ///entire venal pot
    function _getCurrWeekBribeRate()
        internal
        view
        returns (uint256 currBribePerWeek)
    {
        uint256 _lastBribeUpdate = lastBribeUpdate;
        uint256 bribeUpdatedUpto = _lastBribeUpdate;
        uint256 currWeek = _getCurrWeek();
        currBribePerWeek = _bribeRateStored;
        BribeRate memory rates;
        if (currWeek != _lastBribeUpdate) {
            // if we are inside this conditional that means we
            // need to update bribeRate for current week
            while (currWeek >= bribeUpdatedUpto) {
                rates = bribeRates[bribeUpdatedUpto];
                currBribePerWeek -= rates.expireAmt;
                currBribePerWeek += rates.startAmt;
                bribeUpdatedUpto++;
            }
        }
    }

    /// @notice calculates additional reward per token and current bribe
    /// per week for view functions
    /// @return addRewardPerToken additional reward per token
    /// @return currentBribePerWeek bribe per week for current week
    /// @return bribeUpdatedUpto week number from genesis upto which bribes
    /// have been calculated for rewards
    function _getBribeUpdates()
        internal
        view
        returns (
            uint256 addRewardPerToken,
            uint256 currentBribePerWeek,
            uint256 bribeUpdatedUpto
        )
    {
        // keep backup of where we started
        uint256 _lastBribeUpdate = lastBribeUpdate;

        bribeUpdatedUpto = _lastBribeUpdate;
        uint256 currWeek = _getCurrWeek();
        uint256 rewardedUpto = (lastRewardUpdate - genesis) % WEEK;

        currentBribePerWeek = _bribeRateStored;
        BribeRate memory rates;
        while (currWeek > bribeUpdatedUpto) {
            if (_totalSupply != 0) {
                if (rewardedUpto != 0) {
                    // this means that user deposited or withdrew funds in between week
                    // we need to update ratePerTokenStored
                    addRewardPerToken +=
                        (((currentBribePerWeek * MULTIPLIER) / WEEK) *
                            (WEEK - rewardedUpto)) /
                        _totalSupply;
                } else {
                    // caclulate weeks bribe rate
                    rates = bribeRates[bribeUpdatedUpto];
                    // remove expired amount from bribeRate
                    currentBribePerWeek -= rates.expireAmt;
                    // additional active bribe
                    currentBribePerWeek += rates.startAmt;
                    addRewardPerToken += ((currentBribePerWeek * MULTIPLIER) /
                        _totalSupply);
                }
            }

            rewardedUpto = 0;
            bribeUpdatedUpto++;
        }
        // we update bribe per week only if we update bribes
        // else we may never enter the while loop and keep updating
        // currentBribePerWeek
        if (_lastBribeUpdate < bribeUpdatedUpto) {
            rates = bribeRates[bribeUpdatedUpto];
            currentBribePerWeek -= rates.expireAmt;
            currentBribePerWeek += rates.startAmt;
        }
    }

    function _earned(address account, uint256 currRewardPerToken)
        internal
        view
        returns (uint256)
    {
        return
            ((_balances[account] *
                (currRewardPerToken - (userRewardPerTokenPaid[account]))) /
                (MULTIPLIER)) + rewards[account];
    }

    function _rewardPerToken(
        uint256 additionalRewardPerToken,
        uint256 currBribePerWeek
    ) internal view returns (uint256 calcRewardPerToken) {
        uint256 lastUpdate = lastRewardUpdate;
        uint256 timestamp = block.timestamp;
        // if last reward update is before current week we need to
        // set it to end of last week as getBribeUpdates() has
        // taken care of additional rewards for that time
        if (lastUpdate < ((timestamp / WEEK) * WEEK)) {
            lastUpdate = (timestamp / WEEK) * WEEK;
        }

        uint256 bribeRate = (currBribePerWeek * MULTIPLIER) / WEEK;
        uint256 lastRewardApplicable = lastTimeRewardApplicable();

        calcRewardPerToken = rewardPerTokenStored + additionalRewardPerToken;

        if (lastRewardApplicable > lastUpdate) {
            calcRewardPerToken += (((lastRewardApplicable - lastUpdate) *
                bribeRate) / (_totalSupply));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Permit is IERC20Upgradeable {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IRcaController {
    function activeShields(address shield) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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