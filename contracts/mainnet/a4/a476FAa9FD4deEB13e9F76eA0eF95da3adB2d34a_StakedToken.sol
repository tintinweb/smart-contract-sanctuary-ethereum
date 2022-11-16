// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./library/ExponentMath.sol";

import "./interfaces/IStakedToken.sol";
import "./interfaces/ITreasury.sol";

/// @title StakedToken
/// @author Bluejay Core Team
/// @notice StakedToken is the contract for sBLU token.
/// The token accumulates interest every second and maintains a
/// one-to-one ratio with the underlying BLU token.
contract StakedToken is Ownable, IStakedToken {
  using SafeERC20 for IERC20;

  uint256 private constant WAD = 10**18;
  uint256 private constant RAY = 10**27;

  /// @notice The name of the token
  string public constant name = "Staked BLU";

  /// @notice The symbol of the token
  string public constant symbol = "sBLU";

  /// @notice Contract address of the underlying BLU token
  IERC20 public immutable BLU;

  /// @notice Contract address of the treasury contract for minting BLU
  ITreasury public immutable treasury;

  /// @notice Interest rate per second, in RAY
  /// @dev To obtain the per second interest rate from APY:
  /// nthRoot(<APY-IN-RAY> + RAY, 365 * 24 * 60 * 60)
  uint256 public interestRate;

  /// @notice Accumulated interest rates, in RAY
  uint256 public accumulatedRates;

  /// @notice Last time the interest rate was updated, in unix epoch time
  uint256 public lastInterestRateUpdate;

  /// @notice Flag to pause staking
  bool public isStakePaused;

  /// @notice Flag to pause unstaking
  bool public isUnstakePaused;

  /// @notice Normalized total supply of token, in WAD
  uint256 public normalizedTotalSupply;

  /// @notice Minimum amount of normalized balance allowed for an address, in WAD
  /// Any account with balance lower than this number will be zeroed
  uint256 public minimumNormalizedBalance;

  /// @notice Mapping of addresses to their normalized token balances, in WAD
  mapping(address => uint256) public normalizedBalances;

  /// @notice Mapping of owners to spenders to spendable allowances, in WAD
  /// @dev Stored as allowances[owner][spender].
  /// Nore that the allowance is already denormalized
  mapping(address => mapping(address => uint256)) private allowances;

  /// @notice Constructor to initialize the contract
  /// @param _BLU Contract address of the underlying BLU token
  /// @param _treasury Contract address of the treasury contract for minting BLU
  /// @param _interestRate Interest rate per second, in RAY
  constructor(
    address _BLU,
    address _treasury,
    uint256 _interestRate
  ) {
    BLU = IERC20(_BLU);
    treasury = ITreasury(_treasury);

    lastInterestRateUpdate = block.timestamp;
    interestRate = _interestRate;
    accumulatedRates = RAY;
    minimumNormalizedBalance = WAD / 10**3; // 1/1000th of a BLU
    isStakePaused = true;

    emit UpdatedInterestRate(interestRate);
    emit UpdatedMinimumNormalizedBalance(minimumNormalizedBalance);
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function to transfer token from one address to another
  /// @param sender Address of token sender
  /// @param recipient Address of token recipient
  /// @param normalizedAmount Amount of tokens to transfer, in normalized form
  function _transfer(
    address sender,
    address recipient,
    uint256 normalizedAmount
  ) internal {
    require(sender != address(0), "Transfer from the zero address");
    require(recipient != address(0), "Transfer to the zero address");

    require(
      normalizedBalances[sender] >= normalizedAmount,
      "Transfer amount exceeds balance"
    );

    _beforeTokenTransfer(sender, recipient, normalizedAmount);

    unchecked {
      normalizedBalances[sender] -= normalizedAmount;
    }
    normalizedBalances[recipient] += normalizedAmount;

    emit Transfer(sender, recipient, denormalize(normalizedAmount));

    _afterTokenTransfer(sender, recipient, normalizedAmount);
  }

  /// @notice Internal function to mint sBLU token to an address
  /// @param account Address of account to credit tokens to
  /// @param normalizedAmount Amount of tokens to mint, in normalized form
  function _mint(address account, uint256 normalizedAmount) internal {
    require(account != address(0), "Minting to the zero address");

    _beforeTokenTransfer(address(0), account, normalizedAmount);

    normalizedTotalSupply += normalizedAmount;
    normalizedBalances[account] += normalizedAmount;
    emit Transfer(address(0), account, denormalize(normalizedAmount));

    _afterTokenTransfer(address(0), account, normalizedAmount);
  }

  /// @notice Internal function to burn sBLU token from an address
  /// @param account Address of account to burn tokens from
  /// @param normalizedAmount Amount of tokens to burn, in normalized form
  function _burn(address account, uint256 normalizedAmount) internal {
    require(account != address(0), "Burn from the zero address");

    _beforeTokenTransfer(account, address(0), normalizedAmount);

    require(
      normalizedBalances[account] >= normalizedAmount,
      "Burn amount exceeds balance"
    );
    unchecked {
      normalizedBalances[account] -= normalizedAmount;
    }
    normalizedTotalSupply -= normalizedAmount;

    emit Transfer(account, address(0), denormalize(normalizedAmount));

    _afterTokenTransfer(account, address(0), normalizedAmount);
  }

  /// @notice Internal function to approve a spender to spend a certain amount of tokens
  /// @param owner Address of owner who is approving the spending
  /// @param spender Address of spender who is allowed to spend
  /// @param denormalizedAmount Amount of tokens as allowance, in denormalized form
  function _approve(
    address owner,
    address spender,
    uint256 denormalizedAmount
  ) internal {
    require(owner != address(0), "Approve from the zero address");
    require(spender != address(0), "Approve to the zero address");

    allowances[owner][spender] = denormalizedAmount;
    emit Approval(owner, spender, denormalizedAmount);
  }

  /// @notice Internal function to zero out balance on an address if the balance is too low
  /// @param account Address to check for small balances
  function _zeroMinimumBalances(address account) internal {
    if (
      normalizedBalances[account] < minimumNormalizedBalance &&
      normalizedBalances[account] != 0
    ) {
      // Cannot use _burn here because it would be recursive
      normalizedTotalSupply -= normalizedBalances[account];
      normalizedBalances[account] = 0;
    }
  }

  /// @notice Internal function to run before a token transfer occurs
  function _beforeTokenTransfer(
    address,
    address,
    uint256
  ) internal {}

  /// @notice Internal function to run after a token transfer occurs
  /// @dev A cleanup is run after every token transfer to remove accounts with negligible amount of tokens
  /// @param sender Address of token sender
  function _afterTokenTransfer(
    address sender,
    address,
    uint256
  ) internal {
    _zeroMinimumBalances(sender);
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Staking function allowing users to convert BLU to sBLU at one-to-one ratio
  /// @dev The transfer may result in small rounding error due to normalization
  /// and denormalization. Dusty accounts will also be zeroed our after the process.
  /// @param amount Amount of BLU to stake, in WAD
  /// @param recipient Address of sBLU recipient
  /// @return success Whether the staking was successful
  function stake(uint256 amount, address recipient)
    public
    override
    returns (bool)
  {
    require(!isStakePaused, "Staking paused");
    require(recipient != address(0), "Staking to the zero address");
    BLU.safeTransferFrom(msg.sender, address(this), amount);
    _mint(recipient, normalize(amount));
    emit Stake(recipient, amount);
    return true;
  }

  /// @notice Unstaking function allowing users to convert sBLU to BLU at one-to-one ratio
  /// @dev The transfer may result in small rounding error due to normalization
  /// and denormalization. Dusty accounts will also be zeroed our after the process.
  /// Rebase is called each time to ensure this contact is sufficient funded with BLU
  /// tokens from the treasury.
  /// @param amount Amount of sBLU to unstake, in WAD
  /// @param recipient Address of BLU recipient
  /// @return success Whether the unstaking was successful
  function unstake(uint256 amount, address recipient)
    public
    override
    returns (bool)
  {
    require(!isUnstakePaused, "Unstaking paused");
    rebase();
    require(recipient != address(0), "Unstaking to the zero address");
    _burn(recipient, normalize(amount));
    BLU.safeTransfer(recipient, amount);
    emit Unstake(recipient, amount);
    return true;
  }

  /// @notice Transfer sBLU from one address to another
  /// @dev The transfer may result in small rounding error due to normalization
  /// and denormalization. Dusty accounts will also be zeroed our after the process.
  /// @param recipient Address of sBLU recipient
  /// @param amount Amount of sBLU to transfer, in WAD
  /// @return success Whether the transfer was successful
  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(msg.sender, recipient, normalize(amount));
    return true;
  }

  /// @notice Returns the remaining number of tokens that `spender` will be
  /// allowed to spend on behalf of `owner` through {transferFrom}. This is
  /// zero by default.
  /// @param owner Address of owner
  /// @param spender Address of spender
  /// @return allowance Amount of tokens that `spender` is allowed to spend from owner, in WAD
  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return allowances[owner][spender];
  }

  /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens
  /// @param spender Address of spender
  /// @param amount Amount of tokens that `spender` is allowed to spend, in WAD
  /// @return success Whether the allowance was set successfully
  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /// @notice Moves `amount` tokens from `from` to `to` using the
  /// allowance mechanism. `amount` is then deducted from the caller's
  /// allowance.
  /// @param sender Address of the sender of sBLU tokens
  /// @param recipient Address of the recipient of sBLU tokens
  /// @param amount Amount of sBLU tokens to transfer, in WAD
  /// @return success Whether the transfer was successful
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, normalize(amount));

    uint256 currentAllowance = allowances[sender][msg.sender];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    unchecked {
      _approve(sender, msg.sender, currentAllowance - amount);
    }

    return true;
  }

  /// @notice Atomically increases the allowance granted to `spender` by the caller
  /// @param spender Address of the spender to increase allowance for
  /// @param addedValue Amount of allowance to increment, in WAD
  /// @return success Whether the allowance increment was successful
  function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool)
  {
    _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
    return true;
  }

  /// @notice Atomically decreases the allowance granted to `spender` by the caller
  /// @param spender Address of the spender to decrease allowance for
  /// @param subtractedValue Amount of allowance to decrement, in WAD
  /// @return success Whether the allowance decrement was successful
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool)
  {
    uint256 currentAllowance = allowances[msg.sender][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    unchecked {
      _approve(msg.sender, spender, currentAllowance - subtractedValue);
    }
    return true;
  }

  /// @notice Update the accumulated rate and the last updated timestamp
  /// @return accumulatedRates Updated accumulated interest rate
  function updateAccumulatedRate() public override returns (uint256) {
    accumulatedRates = currentAccumulatedRate();
    lastInterestRateUpdate = block.timestamp;
    return accumulatedRates;
  }

  /// @notice Rebase function that ensures the contract is funded with sufficient
  /// BLU tokens from the treasury to ensure that all unstake can be fulfilled.
  /// @return mintedTokens Amount of BLU tokens minted to this contract
  function rebase() public override returns (uint256 mintedTokens) {
    updateAccumulatedRate();
    uint256 mappedTokens = denormalize(normalizedTotalSupply);
    uint256 tokenBalance = BLU.balanceOf(address(this));
    if (tokenBalance < mappedTokens) {
      mintedTokens = mappedTokens - tokenBalance;
      treasury.mint(address(this), mintedTokens);
    }
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Sets the interest rate for the staking contract
  /// @dev The interest rate compounds per second and cannot be less than RAY to ensure
  /// balance is monotonic increasing.
  /// @param _interestRate Interest rate per second, in RAY
  function setInterestRate(uint256 _interestRate) public override onlyOwner {
    require(_interestRate >= RAY, "Interest rate less than 1");
    updateAccumulatedRate();
    interestRate = _interestRate;
    emit UpdatedInterestRate(interestRate);
  }

  /// @notice Sets the minimum amount of normalized balance on an account to prevent
  /// accounts from having extremely small amount of sBLU.
  /// @param _minimumNormalizedBalance Minimum normalized balance, in WAD
  function setMinimumNormalizedBalance(uint256 _minimumNormalizedBalance)
    public
    override
    onlyOwner
  {
    require(_minimumNormalizedBalance <= WAD, "Minimum balance greater than 1");
    minimumNormalizedBalance = _minimumNormalizedBalance;
    emit UpdatedMinimumNormalizedBalance(_minimumNormalizedBalance);
  }

  /// @notice Pause or unpause staking
  /// @param pause True to pause staking, false to unpause staking
  function setIsStakePaused(bool pause) public override onlyOwner {
    isStakePaused = pause;
    emit StakePaused(pause);
  }

  /// @notice Pause or unpause unstaking
  /// @param pause True to pause unstaking, false to unpause unstaking
  function setIsUnstakePaused(bool pause) public override onlyOwner {
    isUnstakePaused = pause;
    emit UnstakePaused(pause);
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Number of decimals for sBLU token
  /// @return decimals Number of decimals for sBLU token
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /// @notice Total supply of sBLU token
  /// @return totalSupply Total supply of sBLU token
  function totalSupply() public view override returns (uint256) {
    return denormalize(normalizedTotalSupply);
  }

  /// @notice Token balance of `owner`
  /// @param account Address of account
  /// @return balance Token balance of `owner`
  function balanceOf(address account) public view override returns (uint256) {
    return denormalize(normalizedBalances[account]);
  }

  /// @notice Current compounded interest rate since the deployment of the contract
  /// @return accumulatedRates Current compounded interest rate, in RAY
  function currentAccumulatedRate() public view override returns (uint256) {
    require(block.timestamp >= lastInterestRateUpdate, "Invalid timestamp");
    return
      (compoundedInterest(block.timestamp - lastInterestRateUpdate) *
        accumulatedRates) / RAY;
  }

  /// @notice Denormalize a number by the accumulated interest rate
  /// @dev Use this to obtain the denormalized form used for presentation purposes
  /// @param amount Amount to denormalize
  /// @return denormalizedAmount Denormalized amount
  function denormalize(uint256 amount) public view override returns (uint256) {
    return (amount * currentAccumulatedRate()) / RAY;
  }

  /// @notice Normalize a number by the accumulated interest rate
  /// @dev Use this to obtain the normalized form used for storage purposes
  /// @param amount Amount to normalize
  /// @return normalizedAmount Normalized amount
  function normalize(uint256 amount) public view override returns (uint256) {
    return (amount * RAY) / currentAccumulatedRate();
  }

  /// @notice Current interest rate compounded by the timePeriod
  /// @dev Use this to obtain the interest rate over other periods of time like a year
  /// @param timePeriod Number of seconds to compound the interest rate by
  function compoundedInterest(uint256 timePeriod)
    public
    view
    override
    returns (uint256)
  {
    return ExponentMath.rpow(interestRate, timePeriod, RAY);
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

// SPDX-License-Identifier: AGPL-3.0-or-later
// https://github.com/makerdao/dss/blob/master/src/abaci.sol
pragma solidity ^0.8.4;

library ExponentMath {
  function rpow(
    uint256 x,
    uint256 n,
    uint256 b
  ) internal pure returns (uint256 z) {
    assembly {
      switch n
      case 0 {
        z := b
      }
      default {
        switch x
        case 0 {
          z := 0
        }
        default {
          switch mod(n, 2)
          case 0 {
            z := b
          }
          default {
            z := x
          }
          let half := div(b, 2) // for rounding.
          for {
            n := div(n, 2)
          } n {
            n := div(n, 2)
          } {
            let xx := mul(x, x)
            if shr(128, x) {
              revert(0, 0)
            }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) {
              revert(0, 0)
            }
            x := div(xxRound, b)
            if mod(n, 2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                revert(0, 0)
              }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) {
                revert(0, 0)
              }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStakedToken is IERC20 {
  function stake(uint256 amount, address recipient) external returns (bool);

  function unstake(uint256 amount, address recipient) external returns (bool);

  function updateAccumulatedRate() external returns (uint256);

  function rebase() external returns (uint256 mintedTokens);

  function currentAccumulatedRate() external view returns (uint256);

  function denormalize(uint256 amount) external view returns (uint256);

  function normalize(uint256 amount) external view returns (uint256);

  function compoundedInterest(uint256 timePeriod)
    external
    view
    returns (uint256);

  function setInterestRate(uint256 _interestRate) external;

  function setMinimumNormalizedBalance(uint256 _minimumNormalizedBalance)
    external;

  function setIsStakePaused(bool pause) external;

  function setIsUnstakePaused(bool pause) external;

  function decimals() external view returns (uint8);

  event Stake(address indexed recipient, uint256 amount);
  event Unstake(address indexed recipient, uint256 amount);
  event UpdatedInterestRate(uint256 interestRate);
  event UpdatedMinimumNormalizedBalance(uint256 minimumNormalizedBalance);
  event StakePaused(bool indexed isPaused);
  event UnstakePaused(bool indexed isPaused);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
  function mint(address to, uint256 amount) external;

  function withdraw(
    address token,
    address to,
    uint256 amount
  ) external;

  function increaseMintLimit(address minter, uint256 amount) external;

  function decreaseMintLimit(address minter, uint256 amount) external;

  function increaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  function decreaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  event Mint(address indexed to, uint256 amount);
  event Withdraw(address indexed token, address indexed to, uint256 amount);
  event MintLimitUpdate(address indexed minter, uint256 amount);
  event WithdrawLimitUpdate(
    address indexed token,
    address indexed minter,
    uint256 amount
  );
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";