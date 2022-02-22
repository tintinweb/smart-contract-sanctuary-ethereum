// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./CompoundVaultBase.sol";

contract CompoundUSDTVault is CompoundVaultBase {
  constructor()
    CompoundVaultBase(
      address(0x07de306FF27a2B630B1141956844eB1552B956B5), // USDT
      msg.sender,
      msg.sender,
      address(0x61460874a7196d6a22D1eE4922473664b3E95270), // COMP
      address(0x5eAe89DC1C671724A672ff0630122ee834098657), // Comptroller
      address(0x3f0A0EA2f86baE6362CF9799B523BA06647Da018) // cUSDT
    )
  {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../SingleRewardVaultBase.sol";

interface cERC20 {
    function mint(uint256 mintAmount) external returns ( uint256 );
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function exchangeRateStored() external view returns (uint);
}

interface Comptroller {
    function claimComp(address holder) external;
}

abstract contract CompoundVaultBase is SingleRewardVaultBase {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  Comptroller public comptroller;
  cERC20 public cToken;

  constructor(
    address _baseToken,
    address _feeRecipient,
    address _governor,
    address _rewardToken,
    address _comptroller,
    address _cToken
  ) SingleRewardVaultBase(_baseToken, _feeRecipient, _governor, _rewardToken) {
    comptroller = Comptroller(_comptroller);
    cToken = cERC20(_cToken);
  }

  // Deposit token into strategy. Deposits entire vault balance
  function _deposit() internal override {
    uint256 amount = IERC20(baseToken).balanceOf(address(this));
    if (amount > 0) {
      IERC20(baseToken).safeApprove(address(cToken), amount);
      cToken.mint(amount);
    }
  }

  // Withdraw token from strategy. _amount is the amount of deposit tokens
  function _withdraw(uint256 _amount) internal override {
    cERC20(cToken).redeemUnderlying(_amount);
  }

  // Harvest rewards from strategy into vault
  function _harvest() internal override {
    comptroller.claimComp(address(this));
  }

  // Balance of deposit token in underlying strategy
  function _strategyBalance() internal view override returns (uint256) {
    return IERC20(address(cToken)).balanceOf(address(this)).mul(getExchangeRate()).div(1e18);
  }

  function getExchangeRate() public view returns (uint) {
    return cToken.exchangeRateStored();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../common/ReentrancyGuard.sol";

import "../interfaces/IVault.sol";

abstract contract VaultBase is ReentrancyGuard, IVault {

  /* ========== CONSTANTS ========== */

  uint256 public constant PRECISION = 1e18;
  uint256 public constant SEC_PER_YEAR = 31556952; // 365.2425 days

  /* ========== STATE VARIABLES ========== */

  // The address of staked token.
  address public immutable baseToken;

  // The address of governor.
  address public governor;

  // The fee percentage take from harvested reward.
  uint256 public performanceFee;

  // The fee percentage take from AUM per year.
  uint256 public managementFee;

  // The address of fee recipient.
  address public feeRecipient;

  // The total share of vault.
  uint256 public override balance;
  // Mapping from user address to vault share.
  mapping(address => uint256) public override balanceOf;

  /* ========== MODIFIERS ========== */

  modifier onlyGovernor() {
    require(msg.sender == governor, "VaultBase: only governor");
    _;
  }

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _baseToken,
    address _feeRecipient,
    address _governor
  ) {
    baseToken = _baseToken;
    feeRecipient = _feeRecipient;
    governor = _governor;

    performanceFee = 3e17; // 30%
    managementFee = 2e16; // 2%
  }

  /* ========== ADMIN FUNCTIONS ========== */

  function setGovernor(address _governor) external onlyGovernor {
    governor = _governor;
  }

  function setPerformanceFee(uint256 _performanceFee) external onlyGovernor {
    require(_performanceFee <= PRECISION, "VaultBase: percentage too large");

    performanceFee = _performanceFee;
  }

  function setManagementFee(uint256 _managementFee) external onlyGovernor {
    require(_managementFee <= PRECISION, "VaultBase: percentage too large");

    managementFee = _managementFee;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/SafeERC20.sol";

import "./VaultBase.sol";

abstract contract SingleRewardVaultBase is VaultBase {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /* ========== STATE VARIABLES ========== */

  // The address of reward token.
  address private rewardToken;

  // The last harvest block number.
  uint256 public lastUpdateTime;
  // The reward per share.
  uint256 public rewardsPerShareStored;
  // Mapping from user address to reward per share paid.
  mapping(address => uint256) public userRewardPerSharePaid;
  // Mapping from user address to reward amount.
  mapping(address => uint256) public rewards;

  /* ========== EVENTS ========== */

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);
  event Harvest(address indexed keeper, uint256 feeAmount, uint256 rewardAmount);

  /* ========== CONSTRUCTOR ========== */

  /// @param _baseToken The address of staked token.
  /// @param _feeRecipient The address of fee recipient.
  /// @param _governor The address of governor.
  /// @param _rewardToken The address of reward token.
  constructor(
    address _baseToken,
    address _feeRecipient,
    address _governor,
    address _rewardToken
  ) VaultBase(_baseToken, _feeRecipient, _governor) {
    rewardToken = _rewardToken;
  }

  /* ========== VIEWS ========== */

  /// @dev return the reward tokens in current vault.
  function getRewardTokens() external view override returns (address[] memory) {
    address[] memory result = new address[](1);
    result[0] = rewardToken;
    return result;
  }

  /// @dev return the reward token earned in current vault.
  /// @param _account The address of account.
  function earned(address _account) public view returns (uint256) {
    uint256 _balance = balanceOf[_account];
    return
      _balance.mul(rewardsPerShareStored.sub(userRewardPerSharePaid[_account])).div(1e18).add(rewards[_account]);
  }

  /// @dev Amount of deposit token per vault share
  function getPricePerFullShare() public view returns (uint256) {
    if (balance == 0) return 0;
    return _strategyBalance().mul(PRECISION).div(balance);
  }

  /* ========== USER FUNCTIONS ========== */

  /// @dev Deposit baseToken to vault.
  /// @param _amount The amount of token to deposit.
  function deposit(uint256 _amount) external override nonReentrant {
    _updateReward(msg.sender);

    address _token = baseToken; // gas saving
    uint256 _pool = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    _amount = IERC20(_token).balanceOf(address(this)).sub(_pool);

    uint256 _share;
    if (balance == 0) {
      _share = _amount;
    } else {
      _share = _amount.mul(balance).div(_strategyBalance());
    }

    balance = balance.add(_share);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_share);

    _deposit();

    emit Deposit(msg.sender, _amount);
  }

  /// @dev Withdraw baseToken from vault.
  /// @param _share The share of vault to withdraw.
  function withdraw(uint256 _share) public override nonReentrant {
    require(_share <= balanceOf[msg.sender], "Vault: not enough share");
    _updateReward(msg.sender);

    uint256 _amount = _share.mul(_strategyBalance()).div(balance);

    // sub will not overflow here.
    balanceOf[msg.sender] = balanceOf[msg.sender] - _share;
    balance = balance - _share;

    address _token = baseToken; // gas saving
    uint256 _pool = IERC20(_token).balanceOf(address(this));
    if (_pool < _amount) {
      uint256 _withdrawAmount = _amount - _pool;
      // Withdraw from strategy
      _withdraw(_withdrawAmount);
      uint256 _poolAfter = IERC20(_token).balanceOf(address(this));
      uint256 _diff = _poolAfter.sub(_pool);
      if (_diff < _withdrawAmount) {
        _amount = _pool.add(_diff);
      }
    }

    IERC20(_token).safeTransfer(msg.sender, _amount);

    emit Withdraw(msg.sender, _amount);
  }

  /// @dev Claim pending reward from vault.
  function claim() public override {
    _updateReward(msg.sender);

    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      IERC20(rewardToken).safeTransfer(msg.sender, reward);
    }

    emit Claim(msg.sender, reward);
  }

  /// @dev Withdraw and claim pending reward from vault.
  function exit() external override {
    withdraw(balanceOf[msg.sender]);
    claim();
  }

  /// @dev harvest pending reward from strategy.
  function harvest() public override {
    uint256 harvested = IERC20(rewardToken).balanceOf(address(this));
    // Harvest rewards from strategy
    _harvest();
    harvested = IERC20(rewardToken).balanceOf(address(this)).sub(harvested);

    uint256 feeAmount = harvested.mul(performanceFee).div(PRECISION);
    IERC20(rewardToken).safeTransfer(feeRecipient, feeAmount);

    uint256 rewardAmount = harvested.sub(feeAmount);
    // distribute new rewards to current shares evenly
    rewardsPerShareStored = rewardsPerShareStored.add(rewardAmount.mul(1e18).div(balance));

    emit Harvest(msg.sender, feeAmount, rewardAmount);
  }

  /* ========== STRATEGY FUNCTIONS ========== */

  /// @dev Deposit token into strategy. Deposits entire vault balance
  function _deposit() internal virtual;

  /// @dev Withdraw token from strategy. _amount is the amount of deposit tokens
  function _withdraw(uint256 _amount) internal virtual;

  /// @dev Harvest rewards from strategy into vault
  function _harvest() internal virtual;

  /// @dev Return the amount of baseToken in strategy.
  function _strategyBalance() internal view virtual returns (uint256);

  /* ========== INTERNAL FUNCTIONS ========== */

  /// @dev Update pending reward for user.
  /// @param _account The address of account.
  function _updateReward(address _account) internal {
    _assessFee();
    harvest();

    rewards[_account] = earned(_account);
    userRewardPerSharePaid[_account] = rewardsPerShareStored;
    lastUpdateTime = block.timestamp;
  }

  function _assessFee() internal {
    if (balance == 0) {
      return;
    }
    uint256 duration = block.timestamp - lastUpdateTime;
    uint256 managmentFeeAmount = balance.mul(managementFee).div(PRECISION).mul(duration).div(SEC_PER_YEAR);

    if (managmentFeeAmount > 0) {
      // issue new shares to receive managementFee
      balance = balance.add(managmentFeeAmount);
      balanceOf[feeRecipient] = balanceOf[feeRecipient].add(managmentFeeAmount);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IVault {
  function getRewardTokens() external view returns (address[] memory);

  function balance() external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  function claim() external;

  function exit() external;

  function harvest() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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