// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./YieldStrategyBase.sol";
import "../interfaces/ICurveSwapPool.sol";
import "../../concentrator/interfaces/IAladdinCRVConvexVault.sol";
import "../../concentrator/interfaces/IAladdinCRV.sol";
import "../../interfaces/IZap.sol";
import "../../misc/checker/IPriceChecker.sol";

// solhint-disable reason-string

/// @title Concentrator Strategy for CLever.
///
/// @dev The gas usage is very high when combining CLever and Concentrator, we need a batch deposit version.
contract ConcentratorStrategy is Ownable, YieldStrategyBase {
  using SafeERC20 for IERC20;

  event UpdatePercentage(uint256 _percentage);
  event UpdateChecker(address _checker);

  uint256 internal constant PRECISION = 1e9;

  /// @dev The address of aCRV on mainnet.
  // solhint-disable-next-line const-name-snakecase
  address internal constant aCRV = 0x2b95A1Dcc3D405535f9ed33c219ab38E8d7e0884;

  /// @dev The address of cvxCRV on mainnet.
  // solhint-disable-next-line const-name-snakecase
  address internal constant cvxCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;

  /// @notice The address of zap contract.
  address public immutable zap;

  /// @dev The address of Concentrator Vault on mainnet.
  address public immutable vault;

  /// @notice The address of curve pool for corresponding yield token.
  address public immutable curvePool;

  uint256 public immutable pid;

  uint256 public percentage;

  address public checker;

  constructor(
    address _zap,
    address _vault,
    uint256 _pid,
    uint256 _percentage,
    address _curvePool,
    address _yieldToken,
    address _underlyingToken,
    address _operator
  ) YieldStrategyBase(_yieldToken, _underlyingToken, _operator) {
    require(_curvePool != address(0), "ConcentratorStrategy: zero address");
    require(_percentage <= PRECISION, "ConcentratorStrategy: percentage too large");

    zap = _zap;
    vault = _vault;
    pid = _pid;
    percentage = _percentage;
    curvePool = _curvePool;

    // The Concentrator Vault is maintained by our team, it's safe to approve uint256.max.
    IERC20(_yieldToken).safeApprove(_vault, uint256(-1));
  }

  /// @inheritdoc IYieldStrategy
  function underlyingPrice() public view override returns (uint256) {
    return ICurveSwapPool(curvePool).get_virtual_price();
  }

  /// @inheritdoc IYieldStrategy
  ///
  /// @dev It is just an estimation, not accurate amount.
  function totalUnderlyingToken() external view override returns (uint256) {
    return (_totalYieldToken() * underlyingPrice()) / 1e18;
  }

  /// @inheritdoc IYieldStrategy
  function totalYieldToken() external view override returns (uint256) {
    return _totalYieldToken();
  }

  /// @inheritdoc IYieldStrategy
  function deposit(
    address,
    uint256 _amount,
    bool _isUnderlying
  ) external virtual override onlyOperator returns (uint256 _yieldAmount) {
    _yieldAmount = _zapBeforeDeposit(_amount, _isUnderlying);

    IAladdinCRVConvexVault(vault).deposit(pid, _yieldAmount);
  }

  /// @inheritdoc IYieldStrategy
  function withdraw(
    address _recipient,
    uint256 _amount,
    bool _asUnderlying
  ) external virtual override onlyOperator returns (uint256 _returnAmount) {
    _amount = _withdrawFromConcentrator(pid, _amount);

    _returnAmount = _zapAfterWithdraw(_recipient, _amount, _asUnderlying);
  }

  /// @inheritdoc IYieldStrategy
  function harvest()
    external
    virtual
    override
    onlyOperator
    returns (
      uint256 _underlyingAmount,
      address[] memory _rewardTokens,
      uint256[] memory _amounts
    )
  {
    // 1. claim aCRV from Concentrator Vault
    uint256 _aCRVAmount = IAladdinCRVConvexVault(vault).claim(pid, 0, IAladdinCRVConvexVault.ClaimOption.Claim);

    address _underlyingToken = underlyingToken;
    // 2. sell part of aCRV as underlying token
    if (percentage > 0) {
      uint256 _sellAmount = (_aCRVAmount * percentage) / PRECISION;
      _aCRVAmount -= _sellAmount;

      address _zap;
      uint256 _cvxCRVAmount = IAladdinCRV(aCRV).withdraw(_zap, _aCRVAmount, 0, IAladdinCRV.WithdrawOption.Withdraw);
      _underlyingAmount = IZap(_zap).zap(cvxCRV, _cvxCRVAmount, _underlyingToken, 0);
    }

    // 3. transfer rewards to operator
    if (_underlyingAmount > 0) {
      IERC20(_underlyingToken).safeTransfer(msg.sender, _underlyingAmount);
    }
    if (_aCRVAmount > 0) {
      IERC20(aCRV).safeTransfer(msg.sender, _aCRVAmount);
    }

    _rewardTokens = new address[](1);
    _rewardTokens[0] = aCRV;

    _amounts = new uint256[](1);
    _amounts[0] = _aCRVAmount;
  }

  /// @inheritdoc IYieldStrategy
  function migrate(address _strategy) external virtual override onlyOperator returns (uint256 _yieldAmount) {
    IAladdinCRVConvexVault(vault).withdrawAllAndClaim(pid, 0, IAladdinCRVConvexVault.ClaimOption.None);

    address _yieldToken = yieldToken;
    _yieldAmount = IERC20(_yieldToken).balanceOf(address(this));
    IERC20(_yieldToken).safeTransfer(_strategy, _yieldAmount);
  }

  /// @inheritdoc IYieldStrategy
  function onMigrateFinished(uint256 _yieldAmount) external virtual override onlyOperator {
    IAladdinCRVConvexVault(vault).deposit(pid, _yieldAmount);
  }

  function updatePercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= PRECISION, "ConcentratorStrategy: percentage too large");

    percentage = _percentage;

    emit UpdatePercentage(_percentage);
  }

  function updateChecker(address _checker) external onlyOwner {
    checker = _checker;

    emit UpdateChecker(_checker);
  }

  function _withdrawFromConcentrator(uint256 _pid, uint256 _amount) internal returns (uint256) {
    uint256 _totalShare = IAladdinCRVConvexVault(vault).getTotalShare(_pid);
    uint256 _totalUnderlying = IAladdinCRVConvexVault(vault).getTotalUnderlying(_pid);
    uint256 _shares = (_amount * _totalShare) / _totalUnderlying;

    // @note reuse variable `_amount` to indicate the amount of yield token withdrawn.
    (_amount, ) = IAladdinCRVConvexVault(vault).withdrawAndClaim(
      _pid,
      _shares,
      0,
      IAladdinCRVConvexVault.ClaimOption.None
    );
    return _amount;
  }

  function _zapBeforeDeposit(uint256 _amount, bool _isUnderlying) internal returns (uint256) {
    if (_isUnderlying) {
      address _checker = checker;
      if (_checker != address(0)) {
        require(IPriceChecker(_checker).check(yieldToken), "price is manipulated");
      }
      // @todo add reserve check for curve lp to avoid flashloan attack.
      address _zap = zap;
      address _underlyingToken = underlyingToken;
      IERC20(_underlyingToken).safeTransfer(_zap, _amount);
      return IZap(_zap).zap(_underlyingToken, _amount, yieldToken, 0);
    } else {
      return _amount;
    }
  }

  function _zapAfterWithdraw(
    address _recipient,
    uint256 _amount,
    bool _asUnderlying
  ) internal returns (uint256) {
    address _token = yieldToken;
    if (_asUnderlying) {
      address _checker = checker;
      if (_checker != address(0)) {
        require(IPriceChecker(_checker).check(yieldToken), "price is manipulated");
      }
      address _zap = zap;
      address _underlyingToken = underlyingToken;
      IERC20(_token).safeTransfer(_zap, _amount);
      _amount = IZap(_zap).zap(_token, _amount, _underlyingToken, 0);
      _token = _underlyingToken;
    }
    IERC20(_token).safeTransfer(_recipient, _amount);
    return _amount;
  }

  function _totalYieldTokenInConcentrator(uint256 _pid) internal view returns (uint256) {
    address _vault = vault;
    uint256 _totalShare = IAladdinCRVConvexVault(_vault).getTotalShare(_pid);
    uint256 _totalUnderlying = IAladdinCRVConvexVault(_vault).getTotalUnderlying(_pid);
    uint256 _userShare = IAladdinCRVConvexVault(_vault).getUserShare(_pid, address(this));
    if (_userShare == 0) return 0;
    return (uint256(_userShare) * _totalUnderlying) / _totalShare;
  }

  function _totalYieldToken() internal view virtual returns (uint256) {
    return _totalYieldTokenInConcentrator(pid);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase

interface ICurveSwapPool {
  function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IYieldStrategy.sol";

/// @title YieldStrategyBase for CLever and Furnace.
abstract contract YieldStrategyBase is IYieldStrategy {
  using SafeERC20 for IERC20;

  /// @inheritdoc IYieldStrategy
  address public immutable override yieldToken;

  /// @inheritdoc IYieldStrategy
  address public immutable override underlyingToken;

  /// @notice The address of operator.
  address public immutable operator;

  modifier onlyOperator() {
    require(msg.sender == operator, "YieldStrategy: only operator");
    _;
  }

  constructor(
    address _yieldToken,
    address _underlyingToken,
    address _operator
  ) {
    require(_yieldToken != address(0), "YieldStrategy: zero address");
    require(_underlyingToken != address(0), "YieldStrategy: zero address");
    require(_operator != address(0), "YieldStrategy: zero address");

    yieldToken = _yieldToken;
    underlyingToken = _underlyingToken;
    operator = _operator;
  }

  /// @inheritdoc IYieldStrategy
  function migrate(address _strategy) external virtual override onlyOperator returns (uint256 _yieldAmount) {
    address _yieldToken = yieldToken;
    _yieldAmount = IERC20(_yieldToken).balanceOf(address(this));
    IERC20(_yieldToken).safeTransfer(_strategy, _yieldAmount);
  }

  /// @inheritdoc IYieldStrategy
  // solhint-disable-next-line no-empty-blocks
  function onMigrateFinished(uint256 _yieldAmount) external virtual override onlyOperator {}

  /// @inheritdoc IYieldStrategy
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external payable override onlyOperator returns (bool, bytes memory) {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IAladdinCRV is IERC20Upgradeable {
  event Harvest(address indexed _caller, uint256 _amount);
  event Deposit(address indexed _sender, address indexed _recipient, uint256 _amount);
  event Withdraw(
    address indexed _sender,
    address indexed _recipient,
    uint256 _shares,
    IAladdinCRV.WithdrawOption _option
  );

  event UpdateWithdrawalFeePercentage(uint256 _feePercentage);
  event UpdatePlatformFeePercentage(uint256 _feePercentage);
  event UpdateHarvestBountyPercentage(uint256 _percentage);
  event UpdatePlatform(address indexed _platform);
  event UpdateZap(address indexed _zap);

  enum WithdrawOption {
    Withdraw,
    WithdrawAndStake,
    WithdrawAsCRV,
    WithdrawAsCVX,
    WithdrawAsETH
  }

  /// @dev return the total amount of cvxCRV staked.
  function totalUnderlying() external view returns (uint256);

  /// @dev return the amount of cvxCRV staked for user
  function balanceOfUnderlying(address _user) external view returns (uint256);

  function deposit(address _recipient, uint256 _amount) external returns (uint256);

  function depositAll(address _recipient) external returns (uint256);

  function depositWithCRV(address _recipient, uint256 _amount) external returns (uint256);

  function depositAllWithCRV(address _recipient) external returns (uint256);

  function withdraw(
    address _recipient,
    uint256 _shares,
    uint256 _minimumOut,
    WithdrawOption _option
  ) external returns (uint256);

  function withdrawAll(
    address _recipient,
    uint256 _minimumOut,
    WithdrawOption _option
  ) external returns (uint256);

  function harvest(address _recipient, uint256 _minimumOut) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IZap {
  function zap(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256 _minOut
  ) external payable returns (uint256);

  function zapWithRoutes(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256[] calldata _routes,
    uint256 _minOut
  ) external payable returns (uint256);

  function zapFrom(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256 _minOut
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IAladdinCRVConvexVault {
  enum ClaimOption {
    None,
    Claim,
    ClaimAsCvxCRV,
    ClaimAsCRV,
    ClaimAsCVX,
    ClaimAsETH
  }

  event Deposit(uint256 indexed _pid, address indexed _sender, uint256 _amount);
  event Withdraw(uint256 indexed _pid, address indexed _sender, uint256 _shares);
  event Claim(address indexed _sender, uint256 _reward, ClaimOption _option);
  event Harvest(address indexed _caller, uint256 _reward, uint256 _platformFee, uint256 _harvestBounty);

  event UpdateWithdrawalFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
  event UpdatePlatformFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
  event UpdateHarvestBountyPercentage(uint256 indexed _pid, uint256 _percentage);
  event UpdatePlatform(address indexed _platform);
  event UpdateZap(address indexed _zap);
  event UpdatePoolRewardTokens(uint256 indexed _pid, address[] _rewardTokens);
  event AddPool(uint256 indexed _pid, uint256 _convexPid, address[] _rewardTokens);
  event PausePoolDeposit(uint256 indexed _pid, bool _status);
  event PausePoolWithdraw(uint256 indexed _pid, bool _status);

  /// @notice Return the amount of pending AladdinCRV rewards for specific pool.
  /// @param _pid - The pool id.
  /// @param _account - The address of user.
  function pendingReward(uint256 _pid, address _account) external view returns (uint256);

  /// @notice Return the amount of pending AladdinCRV rewards for all pool.
  /// @param _account - The address of user.
  function pendingRewardAll(address _account) external view returns (uint256);

  /// @notice Return the user share for specific user.
  /// @param _pid The pool id to query.
  /// @param _account The address of user.
  function getUserShare(uint256 _pid, address _account) external view returns (uint256);

  /// @notice Return the total underlying token deposited.
  /// @param _pid The pool id to query.
  function getTotalUnderlying(uint256 _pid) external view returns (uint256);

  /// @notice Return the total pool share deposited.
  /// @param _pid The pool id to query.
  function getTotalShare(uint256 _pid) external view returns (uint256);

  /// @notice Deposit some token to specific pool.
  /// @dev This function is deprecated.
  /// @param _pid The pool id to query
  /// @param _amount The amount of token to deposit.
  /// @return share The amount of share after deposit.
  function deposit(uint256 _pid, uint256 _amount) external returns (uint256 share);

  /// @notice Deposit some token to specific pool for someone.
  /// @param _pid The pool id.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @param _amount The amount of token to deposit.
  /// @return share The amount of share after deposit.
  function deposit(
    uint256 _pid,
    address _recipient,
    uint256 _amount
  ) external returns (uint256 share);

  /// @notice Deposit all token of the caller to specific pool.
  /// @dev This function is deprecated.
  /// @param _pid The pool id.
  /// @return share The amount of share after deposit.
  function depositAll(uint256 _pid) external returns (uint256 share);

  /// @notice Deposit all token of the caller to specific pool for someone.
  /// @param _pid The pool id.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @return share The amount of share after deposit.
  function depositAll(uint256 _pid, address _recipient) external returns (uint256 share);

  /// @notice Deposit some token to specific pool with zap.
  /// @dev This function is deprecated.
  /// @param _pid The pool id.
  /// @param _token The address of token to deposit.
  /// @param _amount The amount of token to deposit.
  /// @param _minAmount The minimum amount of share to deposit.
  /// @return share The amount of share after deposit.
  function zapAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) external payable returns (uint256 share);

  /// @notice Deposit some token to specific pool with zap for someone.
  /// @param _pid The pool id.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @param _token The address of token to deposit.
  /// @param _amount The amount of token to deposit.
  /// @param _minAmount The minimum amount of share to deposit.
  /// @return share The amount of share after deposit.
  function zapAndDeposit(
    uint256 _pid,
    address _recipient,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) external payable returns (uint256 share);

  /// @notice Deposit all token to specific pool with zap.
  /// @dev This function is deprecated.
  /// @param _pid The pool id.
  /// @param _token The address of token to deposit.
  /// @param _minAmount The minimum amount of share to deposit.
  /// @return share The amount of share after deposit.
  function zapAllAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _minAmount
  ) external payable returns (uint256);

  /// @notice Deposit all token to specific pool with zap for someone.
  /// @param _pid The pool id.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @param _token The address of token to deposit.
  /// @param _minAmount The minimum amount of share to deposit.
  /// @return share The amount of share after deposit.
  function zapAllAndDeposit(
    uint256 _pid,
    address _recipient,
    address _token,
    uint256 _minAmount
  ) external payable returns (uint256);

  /// @notice Withdraw some token from specific pool and zap to token.
  /// @param _pid - The pool id.
  /// @param _shares - The share of token want to withdraw.
  /// @param _token - The address of token zapping to.
  /// @param _minOut - The minimum amount of token to receive.
  /// @return withdrawn - The amount of token sent to caller.
  function withdrawAndZap(
    uint256 _pid,
    uint256 _shares,
    address _token,
    uint256 _minOut
  ) external returns (uint256);

  /// @notice Withdraw all token from specific pool and zap to token.
  /// @param _pid - The pool id.
  /// @param _token - The address of token zapping to.
  /// @param _minOut - The minimum amount of token to receive.
  /// @return withdrawn - The amount of token sent to caller.
  function withdrawAllAndZap(
    uint256 _pid,
    address _token,
    uint256 _minOut
  ) external returns (uint256);

  /// @notice Withdraw some token from specific pool and claim pending rewards.
  /// @param _pid - The pool id.
  /// @param _shares - The share of token want to withdraw.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (don't claim, as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return withdrawn - The amount of token sent to caller.
  /// @return claimed - The amount of reward sent to caller.
  function withdrawAndClaim(
    uint256 _pid,
    uint256 _shares,
    uint256 _minOut,
    ClaimOption _option
  ) external returns (uint256, uint256);

  /// @notice Withdraw all share of token from specific pool and claim pending rewards.
  /// @param _pid - The pool id.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return withdrawn - The amount of token sent to caller.
  /// @return claimed - The amount of reward sent to caller.
  function withdrawAllAndClaim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) external returns (uint256, uint256);

  /// @notice claim pending rewards from specific pool.
  /// @param _pid - The pool id.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return claimed - The amount of reward sent to caller.
  function claim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) external returns (uint256);

  /// @notice claim pending rewards from all pools.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return claimed - The amount of reward sent to caller.
  function claimAll(uint256 _minOut, ClaimOption _option) external returns (uint256);

  /// @notice Harvest the pending reward and convert to aCRV.
  /// @param _pid - The pool id.
  /// @param _recipient - The address of account to receive harvest bounty.
  /// @param _minimumOut - The minimum amount of cvxCRV should get.
  /// @return harvested - The amount of cvxCRV harvested after zapping all other tokens to it.
  function harvest(
    uint256 _pid,
    address _recipient,
    uint256 _minimumOut
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IPriceChecker {
  function check(address lp) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IYieldStrategy {
  /// @notice Return the the address of the yield token.
  function yieldToken() external view returns (address);

  /// @notice Return the the address of the underlying token.
  /// @dev The underlying token maybe the same as the yield token.
  function underlyingToken() external view returns (address);

  /// @notice Return the number of underlying token for each yield token worth, multiplied by 1e18.
  function underlyingPrice() external view returns (uint256);

  /// @notice Return the total number of underlying token in the contract.
  function totalUnderlyingToken() external view returns (uint256);

  /// @notice Return the total number of yield token in the contract.
  function totalYieldToken() external view returns (uint256);

  /// @notice Deposit underlying token or yield token to corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the token is already transfered into the strategy contract.
  ///   + Caller should make sure the deposit amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the share.
  /// @param _amount The amount of token to deposit.
  /// @param _isUnderlying Whether the deposited token is underlying token.
  ///
  /// @return _yieldAmount The amount of yield token deposited.
  function deposit(
    address _recipient,
    uint256 _amount,
    bool _isUnderlying
  ) external returns (uint256 _yieldAmount);

  /// @notice Withdraw underlying token or yield token from corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the withdraw amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _amount The amount of yield token to withdraw.
  /// @param _asUnderlying Whether the withdraw as underlying token.
  ///
  /// @return _returnAmount The amount of token sent to `_recipient`.
  function withdraw(
    address _recipient,
    uint256 _amount,
    bool _asUnderlying
  ) external returns (uint256 _returnAmount);

  /// @notice Harvest possible rewards from strategy.
  /// @dev Part of the reward tokens will be sold to underlying token.
  ///
  /// @return _underlyingAmount The amount of underlying token harvested.
  /// @return _rewardTokens The address list of extra reward tokens.
  /// @return _amounts The list of amount of corresponding extra reward token.
  function harvest()
    external
    returns (
      uint256 _underlyingAmount,
      address[] memory _rewardTokens,
      uint256[] memory _amounts
    );

  /// @notice Migrate all yield token in current strategy to another strategy.
  /// @param _strategy The address of new yield strategy.
  function migrate(address _strategy) external returns (uint256 _yieldAmount);

  /// @notice Notify the target strategy that the migration is finished.
  /// @param _yieldAmount The amount of yield token migrated.
  function onMigrateFinished(uint256 _yieldAmount) external;

  /// @notice Emergency function to execute arbitrary call.
  /// @dev This function should be only used in case of emergency. It should never be called explicitly
  ///  in any contract in normal case.
  ///
  /// @param _to The address of target contract to call.
  /// @param _value The value passed to the target contract.
  /// @param _data The calldata pseed to the target contract.
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external payable returns (bool, bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}