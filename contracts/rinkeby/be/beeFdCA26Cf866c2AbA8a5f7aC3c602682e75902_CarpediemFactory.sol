//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Created by Carpe Diem Savings and SFXDX

contract CarpeDiem {
    using SafeERC20 for IERC20;

    address constant DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant percentBase = 100;
    uint256 private constant MULTIPLIER = 1e18; // used for multiplying numerators in lambda and price calculations
    uint256 private constant WEEK = 7 days;

    uint256 public constant PENALTY_PERCENT_PER_WEEK = 2; // amount of penalty percents applied to reward every late week
    uint256 public constant MAX_PENALTY_DURATION =
        100 / PENALTY_PERCENT_PER_WEEK;
    uint256 public constant MAX_PRICE = 1e12 * MULTIPLIER; // max price (1 share for 1 trillion tokens) to prevent overflow

    Ownable public immutable factory;
    IERC20 public immutable token;
    uint256 public immutable bBonusMaxPercent; // maximum value of B bonus
    uint256 public immutable lBonusMaxPercent; // maximum value of L bonus
    uint256 public immutable lBonusPeriod; // period for maximum L bonus
    uint256 public immutable initialPrice; // initial shares price
    uint256 public immutable bBonusAmount; // amount for maximum B bonus
    uint256 public immutable burnPercent;
    uint256 public immutable stakersPercent;

    uint256 public totalShares; // total shares with the bonuses in the pool
    uint256 public currentPrice; // current shares price
    uint256 public lambda;
    uint16[3] public distributionPercents; // percents to distribute
    address[3] public distributionAddresses; // addresses for penalty distribution. wallet[0] corresponds to reward pool and can be equal any address != address(0)
    uint256 public commissionAccumulator;

    struct StakeInfo {
        uint256 amount;
        uint32 term;
        uint32 startTs;
        uint256 shares;
        uint256 lBonusShares;
        uint256 bBonusShares;
        uint256 lastLambda;
        uint256 assignedReward;
    }

    mapping(address => StakeInfo[]) public stakes; // user address => StakeInfo

    event Deposit(address depositor, uint256 id, uint256 amount, uint32 term);

    event UpgradedStake(
        address depositor,
        uint256 id,
        uint256 amount,
        uint32 term
    );

    event Withdraw(
        address who,
        uint256 id,
        uint256 deposit,
        uint256 reward,
        uint256 penalty
    );

    event StakeRemoval(
        address who,
        uint256 id,
        uint256 deposit
    );

    event NewPrice(uint256 oldPrice, uint256 newPrice);

    constructor(
        address _factory,
        address _token,
        uint256[5] memory _params,
        uint16[5] memory _distributionPercents,
        address[3] memory _distributionAddresses
    ) {
        factory = Ownable(_factory);
        token = IERC20(_token);
        lambda = 0;
        totalShares = 0;
        currentPrice = _params[0];
        initialPrice = _params[0];
        bBonusAmount = _params[1];
        lBonusPeriod = _params[2];
        bBonusMaxPercent = _params[3];
        lBonusMaxPercent = _params[4];
        distributionPercents[0] = _distributionPercents[0];
        distributionPercents[1] = _distributionPercents[1];
        distributionPercents[2] = _distributionPercents[2];
        burnPercent = _distributionPercents[3];
        stakersPercent = _distributionPercents[4];
        distributionAddresses = _distributionAddresses;
    }

    function owner() public view virtual returns (address) {
        return factory.owner();
    }

    function deposit(uint256 _amount, uint32 _term) external {
        require(_amount > 0, "deposit cannot be zero");
        require(_term > 0, "term cannot be zero");
        require(_term <= 5555 days, "huge term");
        uint256 shares = _buyShares(_amount);
        uint256 lBonusShares = _getBonusL(shares, _term);
        uint256 bBonusShares = _getBonusB(shares, _amount);
        totalShares = totalShares + shares + lBonusShares + bBonusShares;
        stakes[msg.sender].push(
            StakeInfo(
                _amount,
                _term,
                uint32(block.timestamp),
                shares,
                lBonusShares,
                bBonusShares,
                lambda,
                0
            )
        );

        emit Deposit(msg.sender, stakes[msg.sender].length - 1, _amount, _term);
    }

    function upgradeStake(uint256 _stakeId, uint256 _amount) external {
        require(_amount > 0, "deposit cannot be zero");
        require(_stakeId < stakes[msg.sender].length, "no such stake id");
        StakeInfo memory stakeInfo = stakes[msg.sender][_stakeId];
        require(stakeInfo.startTs > 0, "stake was deleted");
        require(
            block.timestamp < stakeInfo.term + stakeInfo.startTs,
            "stake matured"
        );
        uint256 extraShares = _buyShares(_amount);
        uint32 blockTimestamp = uint32(block.timestamp);

        uint256 lBonusShares = _getBonusL(
            extraShares,
            stakeInfo.startTs + stakeInfo.term - blockTimestamp
        );
        uint256 bBonusShares = _getBonusB(
            stakeInfo.shares + extraShares,
            stakeInfo.amount + _amount
        );

        totalShares =
            totalShares +
            extraShares +
            bBonusShares +
            lBonusShares -
            stakeInfo.bBonusShares;
        // update stake info
        stakes[msg.sender][_stakeId] = StakeInfo(
            stakeInfo.amount + _amount,
            stakeInfo.term,
            stakeInfo.startTs,
            stakeInfo.shares + extraShares,
            stakeInfo.lBonusShares + lBonusShares,
            bBonusShares,
            lambda,
            getReward(msg.sender, _stakeId)
        );

        emit UpgradedStake(
            msg.sender,
            _stakeId,
            _amount,
            stakeInfo.startTs + stakeInfo.term - blockTimestamp
        );
    }

    function withdraw(uint256 _stakeId) external {
        require(_stakeId < stakes[msg.sender].length, "no such stake id");
        StakeInfo memory stakeInfo = stakes[msg.sender][_stakeId];
        require(stakeInfo.amount > 0, "stake was deleted");
        uint256 reward = getReward(msg.sender, _stakeId);
        uint256 penalty = _getPenalty(msg.sender, reward, _stakeId);
        _changeSharesPrice(
            stakeInfo.amount + reward - penalty,
            stakeInfo.shares
        );
        commissionAccumulator +=
            (penalty * (percentBase - stakersPercent)) /
            percentBase;
        totalShares =
            totalShares -
            stakeInfo.shares -
            stakeInfo.bBonusShares -
            stakeInfo.lBonusShares;
        if (totalShares == 0) {
            lambda = 0;
        } else {
            lambda +=
                (penalty * MULTIPLIER * stakersPercent) /
                percentBase /
                totalShares;
        }
        delete stakes[msg.sender][_stakeId];
        token.safeTransfer(msg.sender, stakeInfo.amount + reward - penalty);
        emit Withdraw(msg.sender, _stakeId, stakeInfo.amount, reward, penalty);
    }

    function removeDeadStake(address _user, uint256 _stakeId) external {
        require(_stakeId < stakes[_user].length, "noSuchStake");
        StakeInfo memory stakeInfo = stakes[_user][_stakeId];
        require(stakeInfo.amount > 0, "stakeWithdrawn");
        require(
            uint32(block.timestamp) >= stakeInfo.startTs + stakeInfo.term + 365 days,
            "stakeAlive"
        );

        _changeSharesPrice(
            stakes[_user][_stakeId].amount,
            stakes[_user][_stakeId].shares
        );
        totalShares -= (
            stakeInfo.shares + stakeInfo.bBonusShares + stakeInfo.lBonusShares
        );
        if (totalShares == 0) {
            lambda = 0;
        }
        delete stakes[_user][_stakeId];
        token.safeTransfer(_user, stakeInfo.amount);
        emit StakeRemoval(_user, _stakeId, stakeInfo.amount);
    }

    function distributePenalty() external {
        address[3] memory addresses = distributionAddresses;
        uint16[3] memory poolPercents = distributionPercents;
        uint256 _commissionAccumulator = commissionAccumulator;
        IERC20 poolToken = token;
        for (uint256 i = 0; i < addresses.length; i++) {
            if (poolPercents[i] > 0)
                poolToken.safeTransfer(
                    addresses[i],
                    (_commissionAccumulator * poolPercents[i]) /
                        (percentBase - stakersPercent)
                );
        }
        if (burnPercent > 0)
            poolToken.safeTransfer(
                DEAD_WALLET,
                (_commissionAccumulator * burnPercent) /
                    (percentBase - stakersPercent)
            );

        commissionAccumulator = 0;
    }

    function getPenalty(address _user, uint256 _stakeId)
        external
        view
        returns (uint256)
    {
        uint256 reward = getReward(_user, _stakeId);
        return _getPenalty(_user, reward, _stakeId);
    }

    function getReward(address _user, uint256 _stakeId)
        public
        view
        returns (uint256)
    {
        StakeInfo memory stakeInfo = stakes[_user][_stakeId];
        uint256 poolLambda = lambda;
        if (poolLambda - stakeInfo.lastLambda > 0) {
            stakeInfo.assignedReward +=
                ((poolLambda - stakeInfo.lastLambda) *
                    (stakeInfo.shares +
                        stakeInfo.bBonusShares +
                        stakeInfo.lBonusShares)) /
                MULTIPLIER;
        }
        return stakeInfo.assignedReward;
    }

    // buys shares for user for current share price
    function _buyShares(uint256 _amount)
        internal
        returns (uint256 sharesToBuy)
    {
        token.safeTransferFrom(msg.sender, address(this), _amount); // take tokens
        sharesToBuy = (_amount * MULTIPLIER) / currentPrice; // calculate corresponding amount of shares
    }

    function _getBonusB(uint256 _shares, uint256 _deposit)
        internal
        view
        returns (uint256)
    {
        uint256 poolBBonus = bBonusAmount;
        if (_deposit < poolBBonus)
            return
                (_shares * bBonusMaxPercent * _deposit) /
                (poolBBonus * percentBase);
        return (bBonusMaxPercent * _shares) / percentBase;
    }

    function _getBonusL(uint256 _shares, uint32 _term)
        internal
        view
        returns (uint256)
    {
        uint256 poolLBonus = lBonusPeriod;
        if (_term < poolLBonus)
            return
                (_shares * lBonusMaxPercent * _term) /
                (poolLBonus * percentBase);
        return (lBonusMaxPercent * _shares) / percentBase;
    }

    function _getPenalty(
        address _user,
        uint256 _reward,
        uint256 _stakeId
    ) internal view returns (uint256) {
        uint256 depositAmount = stakes[_user][_stakeId].amount;
        uint32 term = stakes[_user][_stakeId].term;
        uint32 startTs = stakes[_user][_stakeId].startTs;
        uint32 blockTimestamp = uint32(block.timestamp);
        if (startTs + term <= blockTimestamp) {
            if (startTs + term + WEEK > blockTimestamp) return 0;
            uint256 lateWeeks = (blockTimestamp - (startTs + term)) / WEEK;
            if (lateWeeks >= MAX_PENALTY_DURATION) return _reward;
            return
                (_reward * PENALTY_PERCENT_PER_WEEK * lateWeeks) / percentBase;
        }
        return
            ((depositAmount + _reward) * (term - (blockTimestamp - startTs))) /
            term;
    }

    function _changeSharesPrice(uint256 _profit, uint256 _shares) private {
        uint256 oldPrice = currentPrice;
        if (_profit > (oldPrice * _shares) / (MULTIPLIER)) {
            // equivalent to _profit / shares > oldPrice
            uint256 newPrice = (_profit * MULTIPLIER) / _shares;
            if (newPrice > MAX_PRICE) newPrice = MAX_PRICE;
            currentPrice = newPrice;
            emit NewPrice(oldPrice, newPrice);
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Carpediem.sol";

// Created by Carpe Diem Savings and SFXDX

contract CarpediemFactory is Ownable {
    address[] public allPools;

    uint256 constant percentBase = 100;

    event NewPool(
        address token,
        address poolAddress,
        uint256 initialPrice,
        uint256 bBonusAmount,
        uint256 lBonusPeriod,
        uint256 bBonusMaxPercent,
        uint256 lBonusMaxPercent
    );

    function createPool(
        address _token,
        uint256 _initialPrice,
        uint256 _bBonusAmount,
        uint256 _lBonusPeriod,
        uint256 _bBonusMaxPercent,
        uint256 _lBonusMaxPercent,
        uint16[5] memory _distributionPercents,
        address[3] memory _distributionAddresses
    ) external onlyOwner {
        require(_token != address(0), "token cannot be zero");
        require(_initialPrice != 0, "price cannot be zero");
        require(_bBonusAmount != 0, "B bonus amount cannot be zero");
        require(_lBonusPeriod != 0, "L bonus period cannot be zero");
        uint256 sum;
        for (uint256 i = 0; i < _distributionPercents.length; i++) {
            sum += _distributionPercents[i];
        }
        require(sum == percentBase, "percent sum must be == 100");
        for (uint256 i = 0; i < _distributionAddresses.length; i++) {
            require(
                _distributionAddresses[i] != address(0),
                "wallet cannot be == 0"
            );
        }
        CarpeDiem pool = new CarpeDiem(
            address(this),
            _token,
            [
                _initialPrice,
                _bBonusAmount,
                _lBonusPeriod,
                _bBonusMaxPercent,
                _lBonusMaxPercent
            ],
            _distributionPercents,
            _distributionAddresses
        );
        allPools.push(address(pool));
        emit NewPool(
            _token,
            address(pool),
            _initialPrice,
            _bBonusAmount,
            _lBonusPeriod,
            _bBonusMaxPercent,
            _lBonusMaxPercent
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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
    function _mint(address account, uint256 amount) internal virtual {
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
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
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
        uint256 amount
    ) internal virtual {
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
        uint256 amount
    ) internal virtual {
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
        uint256 amount
    ) internal virtual {}

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
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(uint256 _amount) ERC20("Token", "TKN") {
        _mint(msg.sender, _amount);
    }
}