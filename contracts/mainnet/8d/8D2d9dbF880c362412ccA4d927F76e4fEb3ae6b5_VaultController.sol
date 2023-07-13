/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
  uint256 public constant EXP_SCALE = 1e18;
  uint256 public constant DOUBLE_SCALE = 1e36;
  uint256 public constant HALF_EXP_SCALE = EXP_SCALE / 2;
  uint256 public constant MANTISSA_ONE = EXP_SCALE;
  uint256 public constant UINT192_MAX = 2 ** 192 - 1;
  uint256 public constant UINT128_MAX = 2 ** 128 - 1;

  struct Exp {
    uint256 mantissa;
  }

  struct Double {
    uint256 mantissa;
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * EXP_SCALE}) = 15
   */
  function _truncate(Exp memory _exp) internal pure returns (uint256 _result) {
    return _exp.mantissa / EXP_SCALE;
  }

  function _truncate(uint256 _u) internal pure returns (uint256 _result) {
    return _u / EXP_SCALE;
  }

  function _safeu192(uint256 _u) internal pure returns (uint192 _result) {
    require(_u < UINT192_MAX, 'overflow');
    return uint192(_u);
  }

  function _safeu128(uint256 _u) internal pure returns (uint128 _result) {
    require(_u < UINT128_MAX, 'overflow');
    return uint128(_u);
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function _mulScalarTruncate(Exp memory _a, uint256 _scalar) internal pure returns (uint256 _result) {
    Exp memory _product = _mul(_a, _scalar);
    return _truncate(_product);
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then _add an to an unsigned integer, returning an unsigned integer.
   */
  function _mulScalarTruncateAddUInt(
    Exp memory _a,
    uint256 _scalar,
    uint256 _addend
  ) internal pure returns (uint256 _result) {
    Exp memory _product = _mul(_a, _scalar);
    return _add(_truncate(_product), _addend);
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function _lessThanExp(Exp memory _left, Exp memory _right) internal pure returns (bool _result) {
    return _left.mantissa < _right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function _lessThanOrEqualExp(Exp memory _left, Exp memory _right) internal pure returns (bool _result) {
    return _left.mantissa <= _right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function _greaterThanExp(Exp memory _left, Exp memory _right) internal pure returns (bool _result) {
    return _left.mantissa > _right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function _isZeroExp(Exp memory _value) internal pure returns (bool _result) {
    return _value.mantissa == 0;
  }

  function _safe224(uint256 _n, string memory _errorMessage) internal pure returns (uint224 _result) {
    require(_n < 2 ** 224, _errorMessage);
    return uint224(_n);
  }

  function _safe32(uint256 _n, string memory _errorMessage) internal pure returns (uint32 _result) {
    require(_n < 2 ** 32, _errorMessage);
    return uint32(_n);
  }

  function _add(Exp memory _a, Exp memory _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _add(_a.mantissa, _b.mantissa)});
  }

  function _add(Double memory _a, Double memory _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _add(_a.mantissa, _b.mantissa)});
  }

  function _add(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
    return _add(_a, _b, 'addition overflow');
  }

  function _add(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256 _result) {
    uint256 _c = _a + _b;
    require(_c >= _a, _errorMessage);
    return _c;
  }

  function _sub(Exp memory _a, Exp memory _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _sub(_a.mantissa, _b.mantissa)});
  }

  function _sub(Double memory _a, Double memory _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _sub(_a.mantissa, _b.mantissa)});
  }

  function _sub(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
    return _sub(_a, _b, 'subtraction underflow');
  }

  function _sub(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256 _result) {
    require(_b <= _a, _errorMessage);
    return _a - _b;
  }

  function _mul(Exp memory _a, Exp memory _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _mul(_a.mantissa, _b.mantissa) / EXP_SCALE});
  }

  function _mul(Exp memory _a, uint256 _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _mul(_a.mantissa, _b)});
  }

  function _mul(uint256 _a, Exp memory _b) internal pure returns (uint256 _result) {
    return _mul(_a, _b.mantissa) / EXP_SCALE;
  }

  function _mul(Double memory _a, Double memory _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _mul(_a.mantissa, _b.mantissa) / DOUBLE_SCALE});
  }

  function _mul(Double memory _a, uint256 _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _mul(_a.mantissa, _b)});
  }

  function _mul(uint256 _a, Double memory _b) internal pure returns (uint256 _result) {
    return _mul(_a, _b.mantissa) / DOUBLE_SCALE;
  }

  function _mul(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
    return _mul(_a, _b, 'multiplication overflow');
  }

  function _mul(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256 _result) {
    if (_a == 0 || _b == 0) return 0;
    uint256 _c = _a * _b;
    require(_c / _a == _b, _errorMessage);
    return _c;
  }

  function _div(Exp memory _a, Exp memory _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _div(_mul(_a.mantissa, EXP_SCALE), _b.mantissa)});
  }

  function _div(Exp memory _a, uint256 _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _div(_a.mantissa, _b)});
  }

  function _div(uint256 _a, Exp memory _b) internal pure returns (uint256 _result) {
    return _div(_mul(_a, EXP_SCALE), _b.mantissa);
  }

  function _div(Double memory _a, Double memory _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _div(_mul(_a.mantissa, DOUBLE_SCALE), _b.mantissa)});
  }

  function _div(Double memory _a, uint256 _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _div(_a.mantissa, _b)});
  }

  function _div(uint256 _a, Double memory _b) internal pure returns (uint256 _result) {
    return _div(_mul(_a, DOUBLE_SCALE), _b.mantissa);
  }

  function _div(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
    return _div(_a, _b, 'divide by zero');
  }

  function _div(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256 _result) {
    require(_b > 0, _errorMessage);
    return _a / _b;
  }

  function _fraction(uint256 _a, uint256 _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _div(_mul(_a, DOUBLE_SCALE), _b)});
  }
}

/// @title CurveMaster Interface
/// @notice Interface for interacting with CurveMaster
interface ICurveMaster {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emited when the owner changes the vault controller address
   * @param _oldVaultControllerAddress The old address of the vault controller
   * @param _newVaultControllerAddress The new address of the vault controller
   */
  event VaultControllerSet(address _oldVaultControllerAddress, address _newVaultControllerAddress);

  /**
   * @notice Emited when the owner changes the curve address
   * @param _oldCurveAddress The old address of the curve
   * @param _token The token to set
   * @param _newCurveAddress The new address of the curve
   */
  event CurveSet(address _oldCurveAddress, address _token, address _newCurveAddress);

  /**
   * @notice Emited when the owner changes the curve address skipping the checks
   * @param _oldCurveAddress The old address of the curve
   * @param _token The token to set
   * @param _newCurveAddress The new address of the curve
   */
  event CurveForceSet(address _oldCurveAddress, address _token, address _newCurveAddress);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @notice Thrown when the token is not enabled
  error CurveMaster_TokenNotEnabled();

  /// @notice Thrown when result is zero
  error CurveMaster_ZeroResult();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /// @notice The vault controller address
  function vaultControllerAddress() external view returns (address _vaultController);

  /// @notice Returns the value of curve labled _tokenAddress at _xValue
  /// @param _tokenAddress The key to lookup the curve with in the mapping
  /// @param _xValue The x value to pass to the slave
  /// @return _value The y value of the curve
  function getValueAt(address _tokenAddress, int256 _xValue) external view returns (int256 _value);

  /// @notice Mapping of token to address
  function curves(address _tokenAddress) external view returns (address _curve);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Set the VaultController addr in order to pay interest on curve setting
  /// @param _vaultMasterAddress The address of vault master
  function setVaultController(address _vaultMasterAddress) external;

  /// @notice Setting a new curve should pay interest
  /// @param _tokenAddress The address of the token
  /// @param _curveAddress The address of the curve for the contract
  function setCurve(address _tokenAddress, address _curveAddress) external;

  /// @notice Special function that does not calculate interest, used for deployment
  /// @param _tokenAddress The address of the token
  /// @param _curveAddress The address of the curve for the contract
  function forceSetCurve(address _tokenAddress, address _curveAddress) external;
}

/// @title CurveSlave Interface
/// @notice Interface for interacting with CurveSlaves
interface ICurveSlave {
  function valueAt(int256 _xValue) external view returns (int256 _value);
}

/// @title OracleRelay Interface
/// @notice Interface for interacting with OracleRelay
interface IOracleRelay {
  /// @notice Emited when the underlyings are different in the anchored view
  error OracleRelay_DifferentUnderlyings();

  enum OracleType {
    Chainlink,
    Uniswap,
    Price
  }

  /// @notice returns the price with 18 decimals
  /// @return _currentValue the current price
  function currentValue() external returns (uint256 _currentValue);

  /// @notice returns the price with 18 decimals without any state changes
  /// @dev some oracles require a state change to get the exact current price.
  ///      This is updated when calling other state changing functions that query the price
  /// @return _price the current price
  function peekValue() external view returns (uint256 _price);

  /// @notice returns the type of the oracle
  /// @return _type the type (Chainlink/Uniswap/Price)
  function oracleType() external view returns (OracleType _type);

  /// @notice returns the underlying asset the oracle is pricing
  /// @return _underlying the address of the underlying asset
  function underlying() external view returns (address _underlying);
}

interface IBooster {
  function owner() external view returns (address _owner);
  function setVoteDelegate(address _voteDelegate) external;
  function vote(uint256 _voteId, address _votingAddress, bool _support) external returns (bool _success);
  function voteGaugeWeight(address[] calldata _gauge, uint256[] calldata _weight) external returns (bool _success);
  function poolInfo(uint256 _pid)
    external
    view
    returns (address _lptoken, address _token, address _gauge, address _crvRewards, address _stash, bool _shutdown);
  function earmarkRewards(uint256 _pid) external returns (bool _claimed);
  function earmarkFees() external returns (bool _claimed);
  function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool _success);
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

interface IVirtualBalanceRewardPool {
  function rewardToken() external view returns (IERC20 _rewardToken);
  function earned(address _ad) external view returns (uint256 _reward);
  function getReward() external;
  function queueNewRewards(uint256 _rewards) external;
}

interface IBaseRewardPool {
  function stake(uint256 _amount) external returns (bool _staked);
  function stakeFor(address _for, uint256 _amount) external returns (bool _staked);
  function withdraw(uint256 _amount, bool _claim) external returns (bool _success);
  function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool _success);
  function getReward(address _account, bool _claimExtras) external returns (bool _success);
  function rewardToken() external view returns (IERC20 _rewardToken);
  function earned(address _ad) external view returns (uint256 _reward);
  function extraRewardsLength() external view returns (uint256 _extraRewardsLength);
  function extraRewards(uint256 _position) external view returns (IVirtualBalanceRewardPool _virtualReward);
  function queueNewRewards(uint256 _rewards) external returns (bool _success);
}

/**
 * @title The interface for the CVX token
 */
interface ICVX is IERC20 {
  function totalCliffs() external view returns (uint256 _totalCliffs);
  function reductionPerCliff() external view returns (uint256 _reduction);
  function maxSupply() external view returns (uint256 _maxSupply);
}

/// @title Vault Interface
interface IVault {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
  /**
   * @notice Emited after depositing a token
   * @param _token The address of the token to deposit
   * @param _amount The amount to deposit
   */

  event Deposit(address _token, uint256 _amount);

  /**
   * @notice Emited after withdrawing a token
   * @param _token The address of the token to withdraw
   * @param _amount The amount to withdraw
   */
  event Withdraw(address _token, uint256 _amount);

  /**
   * @notice Emited when claiming a reward
   * @param _token The address of the token that was claimed
   * @param _amount The amount that was claimed
   */
  event ClaimedReward(address _token, uint256 _amount);

  /**
   * Emited when staking a crvLP token on convex manually
   * @param _token The address of the token to stake
   * @param _amount The amount to stake
   */
  event Staked(address _token, uint256 _amount);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/
  /**
   * @notice Thrown when trying to deposit a token that is not registered
   */
  error Vault_TokenNotRegistered();

  /**
   * @notice Thrown when trying to deposit 0 amount
   */
  error Vault_AmountZero();

  /// @notice Thrown when trying to withdraw more than it's possible
  error Vault_OverWithdrawal();

  /// @notice Thrown when trying to repay more than is needed
  error Vault_RepayTooMuch();

  /// @notice Thrown when _msgSender is not the minter of the vault
  error Vault_NotMinter();

  /// @notice Thrown when _msgSender is not the controller of the vault
  error Vault_NotVaultController();

  /// @notice Thrown when depositing and staking on convex fails
  error Vault_DepositAndStakeOnConvexFailed();

  /// @notice Thrown when trying to withdraw and unstake from convex
  error Vault_WithdrawAndUnstakeOnConvexFailed();

  /// @notice Thrown when trying to claim rewards with a non CurveLPStakedOnConvex token
  error Vault_TokenNotCurveLP();

  /// @notice Thrown when trying to stake with 0 balance
  error Vault_TokenZeroBalance();

  /// @notice Thrown when a crvLP token can not be staked
  error Vault_TokenCanNotBeStaked();

  /// @notice Thrown when a token is already staked and trying to stake again
  error Vault_TokenAlreadyStaked();

  /*///////////////////////////////////////////////////////////////
                              STRUCTS
    //////////////////////////////////////////////////////////////*/
  /// @title VaultInfo struct
  /// @notice this struct is used to store the vault metadata
  /// this should reduce the cost of minting by ~15,000
  /// by limiting us to max 2**96-1 vaults
  struct VaultInfo {
    uint96 id;
    address minter;
  }

  struct Reward {
    IERC20 token;
    uint256 amount;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the struct containing the vault information
   * @return _id Id of the vault
   * @return _minter Minter of the vault
   */
  function vaultInfo() external view returns (uint96 _id, address _minter);

  /**
   * @notice Returns the vault's balance of a token
   * @param _token The address of the token
   * @return _balance The token's balance of the vault
   */
  function balances(address _token) external view returns (uint256 _balance);

  /**
   * @notice Returns if the token in staked
   * @param _token The address of the token
   * @return _isStaked True if the token is staked
   */
  function isTokenStaked(address _token) external view returns (bool _isStaked);

  /**
   * @notice Returns the current vault base liability
   * @return _liability The current vault base liability of the vault
   */
  function baseLiability() external view returns (uint256 _liability);

  /**
   * @notice Returns the minter's address of the vault
   * @return _minter The minter's address
   */
  function minter() external view returns (address _minter);

  /**
   * @notice Returns the id of the vault
   * @return _id The id of the vault
   */
  function id() external view returns (uint96 _id);

  /**
   * @notice Returns the vault controller
   * @return _vaultController The vault controller
   */
  function CONTROLLER() external view returns (IVaultController _vaultController);

  /// @notice Returns the CRV token address
  /// @return _crv The CRV token address
  function CRV() external view returns (IERC20 _crv);

  /// @notice Returns the CVX token address
  /// @return _cvx The CVX token address
  function CVX() external view returns (ICVX _cvx);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Used to deposit a token to the vault
   * @param _token The address of the token to deposit
   * @param _amount The amount of the token to deposit
   */
  function depositERC20(address _token, uint256 _amount) external;

  /**
   * @notice Used to withdraw a token from the vault. This can only be called by the minter
   * @dev The withdraw will be denied if ones vault would become insolvent
   * @param _token The address of the token
   * @param _amount The amount of the token to withdraw
   */
  function withdrawERC20(address _token, uint256 _amount) external;

  /// @notice Let's the user manually stake their crvLP
  /// @dev    This can be called if the convex pool didn't exist when the token was registered
  ///         and was later updated
  /// @param _tokenAddress The address of erc20 crvLP token
  function stakeCrvLPCollateral(address _tokenAddress) external;

  /// @notice Returns true when user can manually stake their token balance
  /// @param _token The address of the token to check
  /// @return _canStake Returns true if the token can be staked manually
  function canStake(address _token) external view returns (bool _canStake);

  /// @notice Claims available rewards from multiple tokens
  /// @dev    Transfers a percentage of the crv and cvx rewards to claim AMPH tokens
  /// @param _tokenAddresses The addresses of the erc20 tokens
  function claimRewards(address[] memory _tokenAddresses) external;

  /// @notice Returns an array of tokens and amounts available for claim
  /// @param _tokenAddress The address of erc20 token
  /// @return _rewards The array of tokens and amount available for claim
  function claimableRewards(address _tokenAddress) external view returns (Reward[] memory _rewards);

  /**
   * @notice Function used by the VaultController to transfer tokens
   * @param _token The address of the token to transfer
   * @param _to The address of the person to send the coins to
   * @param _amount The amount of coins to move
   */
  function controllerTransfer(address _token, address _to, uint256 _amount) external;

  /**
   * @notice function used by the VaultController to withdraw from convex
   * callable by the VaultController only
   * @param _rewardPool pool to withdraw
   * @param _amount amount of coins to withdraw
   */
  function controllerWithdrawAndUnwrap(IBaseRewardPool _rewardPool, uint256 _amount) external;

  /**
   * @notice Modifies a vault's liability. Can only be called by VaultController
   * @param _increase True to increase liability, false to decrease
   * @param _baseAmount The change amount in base liability
   * @return _liability The new base liability
   */
  function modifyLiability(bool _increase, uint256 _baseAmount) external returns (uint256 _liability);
}

/**
 * @notice Deployer of Vaults
 * @dev    This contract is needed to reduce the size of the VaultController contract
 */
interface IVaultDeployer {
  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when someone other than the vault controller tries to call the method
   */
  error VaultDeployer_OnlyVaultController();

  /*///////////////////////////////////////////////////////////////
                              VARIABLES
  //////////////////////////////////////////////////////////////*/

  /// @notice The address of the CVX token
  /// @return _cvx The address of the CVX token
  function CVX() external view returns (IERC20 _cvx);

  /// @notice The address of the CRV token
  /// @return _crv The address of the CRV token
  function CRV() external view returns (IERC20 _crv);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @notice Deploys a new Vault
  /// @param _id The id of the vault
  /// @param _minter The address of the minter of the vault
  /// @return _vault The vault that was created
  function deployVault(uint96 _id, address _minter) external returns (IVault _vault);
}

/// @title AMPHClaimer Interface
interface IAMPHClaimer {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emited when a vault claims AMPH
   * @param _vaultClaimer The address of the vault that claimed
   * @param _cvxTotalRewards The amount of CVX sent in exchange of AMPH
   * @param _crvTotalRewards The amount of CRV sent in exchange of AMPH
   * @param _amphAmount The amount of AMPH received
   */
  event ClaimedAmph(
    address indexed _vaultClaimer, uint256 _cvxTotalRewards, uint256 _crvTotalRewards, uint256 _amphAmount
  );

  /**
   * @notice Emited when governance changes the vault controller
   * @param _newVaultController The address of the new vault controller
   */
  event ChangedVaultController(address indexed _newVaultController);

  /**
   * @notice Emited when governance recovers a token from the contract
   * @param _token the token recovered
   * @param _receiver the receiver of the tokens
   * @param _amount the amount recovered
   */
  event RecoveredDust(address indexed _token, address _receiver, uint256 _amount);

  /**
   * @notice Emited when governance changes the CVX reward fee
   * @param _newCvxReward the new fee
   */
  event ChangedCvxRewardFee(uint256 _newCvxReward);

  /**
   * @notice Emited when governance changes the CRV reward fee
   * @param _newCrvReward the new fee
   */
  event ChangedCrvRewardFee(uint256 _newCrvReward);

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /// @notice The address of the CVX token
  function CVX() external view returns (IERC20 _cvx);

  /// @notice The address of the CRV token
  function CRV() external view returns (IERC20 _crv);

  /// @notice The address of the AMPH token
  function AMPH() external view returns (IERC20 _amph);

  /// @notice The base supply of AMPH per cliff, denominated in 1e6
  function BASE_SUPPLY_PER_CLIFF() external view returns (uint256 _baseSupplyPerCliff);

  /// @notice The total amount of AMPH minted for rewards in CRV, denominated in 1e6
  function distributedAmph() external view returns (uint256 _distributedAmph);

  /// @notice The total number of cliffs (for both tokens)
  function TOTAL_CLIFFS() external view returns (uint256 _totalCliffs);

  /// @notice Percentage of rewards taken in CVX (1e18 == 100%)
  function cvxRewardFee() external view returns (uint256 _cvxRewardFee);

  /// @notice Percentage of rewards taken in CRV (1e18 == 100%)
  function crvRewardFee() external view returns (uint256 _crvRewardFee);

  /// @notice The vault controller
  function vaultController() external view returns (IVaultController _vaultController);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Claims an amount of AMPH given a CVX and CRV quantity
  /// @param _vaultId The vault id that is claiming
  /// @param _cvxTotalRewards The max CVX amount to exchange from the sender
  /// @param _crvTotalRewards The max CVR amount to exchange from the sender
  /// @param _beneficiary The receiver of the AMPH rewards
  /// @return _cvxAmountToSend The amount of CVX that the treasury got
  /// @return _crvAmountToSend The amount of CRV that the treasury got
  /// @return _claimedAmph The amount of AMPH received by the beneficiary
  function claimAmph(
    uint96 _vaultId,
    uint256 _cvxTotalRewards,
    uint256 _crvTotalRewards,
    address _beneficiary
  ) external returns (uint256 _cvxAmountToSend, uint256 _crvAmountToSend, uint256 _claimedAmph);

  /// @notice Returns the claimable amount of AMPH given a CVX and CRV quantity
  /// @param _sender The address of the account claiming
  /// @param _vaultId The vault id that is claiming
  /// @param _cvxTotalRewards The max CVX amount to exchange from the sender
  /// @param _crvTotalRewards The max CVR amount to exchange from the sender
  /// @return _cvxAmountToSend The amount of CVX the user will have to send
  /// @return _crvAmountToSend The amount of CRV the user will have to send
  /// @return _claimableAmph The amount of AMPH that would be received by the beneficiary
  function claimable(
    address _sender,
    uint96 _vaultId,
    uint256 _cvxTotalRewards,
    uint256 _crvTotalRewards
  ) external view returns (uint256 _cvxAmountToSend, uint256 _crvAmountToSend, uint256 _claimableAmph);

  /// @notice Used by governance to change the vault controller
  /// @param _newVaultController The new vault controller
  function changeVaultController(address _newVaultController) external;

  /// @notice Used by governance to recover tokens from the contract
  /// @param _token The token to recover
  /// @param _amount The amount to recover
  function recoverDust(address _token, uint256 _amount) external;

  /// @notice Used by governance to change the fee taken from the CVX reward
  /// @param _newFee The new reward fee
  function changeCvxRewardFee(uint256 _newFee) external;

  /// @notice Used by governance to change the fee taken from the CRV reward
  /// @param _newFee The new reward fee
  function changeCrvRewardFee(uint256 _newFee) external;
}

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @title Roles contract
 *   @notice Manages the roles for interactions with a contract
 */
interface IRoles is IAccessControl {
  /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when the caller of the function is not an authorized role
   */
  error Roles_Unauthorized(address _account, bytes32 _role);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

/// @title USDA Interface
/// @notice extends IERC20Metadata
interface IUSDA is IERC20Metadata, IRoles {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
  /**
   * @notice Emitted when a deposit is made
   * @param _from The address which made the deposit
   * @param _value The value deposited
   */
  event Deposit(address indexed _from, uint256 _value);

  /**
   * @notice Emitted when a withdraw is made
   * @param _from The address which made the withdraw
   * @param _value The value withdrawn
   */
  event Withdraw(address indexed _from, uint256 _value);

  /**
   * @notice Emitted when a mint is made
   * @param _to The address which made the mint
   * @param _value The value minted
   */
  event Mint(address _to, uint256 _value);

  /**
   * @notice Emitted when a burn is made
   * @param _from The address which made the burn
   * @param _value The value burned
   */
  event Burn(address _from, uint256 _value);

  /**
   * @notice Emitted when a donation is made
   * @param _from The address which made the donation
   * @param _value The value of the donation
   * @param _totalSupply The new total supply
   */
  event Donation(address indexed _from, uint256 _value, uint256 _totalSupply);

  /**
   * @notice Emitted when the owner recovers dust
   * @param _receiver The address which made the recover
   * @param _amount The value recovered
   */
  event RecoveredDust(address indexed _receiver, uint256 _amount);

  /**
   * @notice Emitted when the owner sets a pauser
   * @param _pauser The new pauser address
   */
  event PauserSet(address indexed _pauser);

  /**
   * @notice Emitted when a sUSD transfer is made from the vaultController
   * @param _target The receiver of the transfer
   * @param _susdAmount The amount sent
   */
  event VaultControllerTransfer(address _target, uint256 _susdAmount);

  /**
   * @notice Emitted when the owner adds a new vaultController giving special roles
   * @param _vaultController The address of the vault controller
   */
  event VaultControllerAdded(address indexed _vaultController);

  /**
   * @notice Emitted when the owner removes a vaultController removing special roles
   * @param _vaultController The address of the vault controller
   */
  event VaultControllerRemoved(address indexed _vaultController);

  /**
   * @notice Emitted when the owner removes a vaultController from the list
   * @param _vaultController The address of the vault controller
   */
  event VaultControllerRemovedFromList(address indexed _vaultController);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @notice Thrown when trying to deposit zero amount
  error USDA_ZeroAmount();

  /// @notice Thrown when trying to withdraw more than the balance
  error USDA_InsufficientFunds();

  /// @notice Thrown when trying to withdraw all but the reserve amount is 0
  error USDA_EmptyReserve();

  /// @notice Thrown when _msgSender is not the pauser of the contract
  error USDA_OnlyPauser();

  /// @notice Thrown when vault controller is trying to burn more than the balance
  error USDA_NotEnoughBalance();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /// @notice Returns sUSD contract (reserve)
  /// @return _sUSD The sUSD contract
  function sUSD() external view returns (IERC20 _sUSD);

  /// @notice Returns the reserve ratio
  /// @return _reserveRatio The reserve ratio
  function reserveRatio() external view returns (uint192 _reserveRatio);

  /// @notice Returns the reserve amount
  /// @return _reserveAmount The reserve amount
  function reserveAmount() external view returns (uint256 _reserveAmount);

  /// @notice The address of the pauser
  function pauser() external view returns (address _pauser);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Deposit sUSD to mint USDA
  /// @dev Caller should obtain 1 USDA for each sUSD
  /// the calculations for deposit mimic the calculations done by mint in the ampleforth contract, simply with the susd transfer
  /// 'fragments' are the units that we see, so 1000 fragments == 1000 USDA
  /// 'gons' are the internal accounting unit, used to keep scale.
  /// We use the variable _gonsPerFragment in order to convert between the two
  /// try dimensional analysis when doing the math in order to verify units are correct
  /// @param _susdAmount The amount of sUSD to deposit
  function deposit(uint256 _susdAmount) external;

  /// @notice Deposits sUSD to mint USDA and transfer to a different address
  /// @param _susdAmount The amount of sUSD to deposit
  /// @param _target The address to receive the USDA tokens
  function depositTo(uint256 _susdAmount, address _target) external;

  /// @notice Withdraw sUSD by burning USDA
  /// @dev The caller should obtain 1 sUSD for every 1 USDA
  /// @param _susdAmount The amount of sUSD to withdraw
  function withdraw(uint256 _susdAmount) external;

  /// @notice Withdraw sUSD to a specific address by burning USDA from the caller
  /// @dev The _target address should obtain 1 sUSD for every 1 USDA burned from the caller
  /// @param _susdAmount amount of sUSD to withdraw
  /// @param _target address to receive the sUSD
  function withdrawTo(uint256 _susdAmount, address _target) external;

  /// @notice Withdraw sUSD by burning USDA
  /// @dev The caller should obtain 1 sUSD for every 1 USDA
  /// @dev This function is effectively just withdraw, but we calculate the amount for the sender
  /// @param _susdWithdrawn The amount os sUSD withdrawn
  function withdrawAll() external returns (uint256 _susdWithdrawn);

  /// @notice Withdraw sUSD by burning USDA
  /// @dev This function is effectively just withdraw, but we calculate the amount for the _target
  /// @param _target should obtain 1 sUSD for every 1 USDA burned from caller
  /// @param _susdWithdrawn The amount os sUSD withdrawn
  function withdrawAllTo(address _target) external returns (uint256 _susdWithdrawn);

  /// @notice Donates susd to the protocol reserve
  /// @param _susdAmount The amount of sUSD to donate
  function donate(uint256 _susdAmount) external;

  /// @notice Recovers accidentally sent sUSD to this contract
  /// @param _to The receiver of the dust
  function recoverDust(address _to) external;

  /// @notice Sets the pauser for both USDA and VaultController
  /// @dev The pauser is a separate role from the owner
  function setPauser(address _pauser) external;

  /// @notice Pause contract
  /// @dev Can only be called by the pauser
  function pause() external;

  /// @notice Unpause contract, pauser only
  /// @dev Can only be called by the pauser
  function unpause() external;

  /// @notice Admin function to mint USDA
  /// @param _susdAmount The amount of USDA to mint, denominated in sUSD
  function mint(uint256 _susdAmount) external;

  /// @notice Admin function to burn USDA
  /// @param _susdAmount The amount of USDA to burn, denominated in sUSD
  function burn(uint256 _susdAmount) external;

  /// @notice Function for the vaultController to burn
  /// @param _target The address to burn the USDA from
  /// @param _amount The amount of USDA to burn
  function vaultControllerBurn(address _target, uint256 _amount) external;

  /// @notice Function for the vaultController to mint
  /// @param _target The address to mint the USDA to
  /// @param _amount The amount of USDA to mint
  function vaultControllerMint(address _target, uint256 _amount) external;

  /// @notice Allows VaultController to send sUSD from the reserve
  /// @param _target The address to receive the sUSD from reserve
  /// @param _susdAmount The amount of sUSD to send
  function vaultControllerTransfer(address _target, uint256 _susdAmount) external;

  /// @notice Function for the vaultController to scale all USDA balances
  /// @param _amount The amount of USDA (e18) to donate
  function vaultControllerDonate(uint256 _amount) external;

  /// @notice Adds a new vault controller
  /// @param _vaultController The new vault controller to add
  function addVaultController(address _vaultController) external;

  /// @notice Removes a vault controller
  /// @param _vaultController The vault controller to remove
  function removeVaultController(address _vaultController) external;

  /// @notice Removes a vault controller from the loop list
  /// @param _vaultController The vault controller to remove
  function removeVaultControllerFromList(address _vaultController) external;
}

/// @title VaultController Interface
interface IVaultController {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
  /**
   * @notice Emited when payInterest is called to accrue interest and distribute it
   * @param _epoch The block timestamp when the function called
   * @param _amount The increase amount of the interest factor
   * @param _curveVal The value at the curve
   */
  event InterestEvent(uint64 _epoch, uint192 _amount, uint256 _curveVal);

  /**
   * @notice Emited when a new protocol fee is being set
   * @param _protocolFee The new fee for the protocol
   */
  event NewProtocolFee(uint192 _protocolFee);

  /**
   * @notice Emited when a new erc20 token is being registered as acceptable collateral
   * @param _tokenAddress The addres of the erc20 token
   * @param _ltv The loan to value amount of the erc20
   * @param _oracleAddress The address of the oracle to use to fetch the price
   * @param _liquidationIncentive The liquidation penalty for the token
   * @param _cap The maximum amount that can be deposited
   */
  event RegisteredErc20(
    address _tokenAddress, uint256 _ltv, address _oracleAddress, uint256 _liquidationIncentive, uint256 _cap
  );

  /**
   * @notice Emited when the information about an acceptable erc20 token is being update
   * @param _tokenAddress The addres of the erc20 token to update
   * @param _ltv The new loan to value amount of the erc20
   * @param _oracleAddress The new address of the oracle to use to fetch the price
   * @param _liquidationIncentive The new liquidation penalty for the token
   * @param _cap The maximum amount that can be deposited
   * @param _poolId The convex pool id of a crv lp token
   */
  event UpdateRegisteredErc20(
    address _tokenAddress,
    uint256 _ltv,
    address _oracleAddress,
    uint256 _liquidationIncentive,
    uint256 _cap,
    uint256 _poolId
  );

  /**
   * @notice Emited when a new vault is being minted
   * @param _vaultAddress The address of the new vault
   * @param _vaultId The id of the vault
   * @param _vaultOwner The address of the owner of the vault
   */
  event NewVault(address _vaultAddress, uint256 _vaultId, address _vaultOwner);

  /**
   * @notice Emited when the owner registers a curve master
   * @param _curveMasterAddress The address of the curve master
   */
  event RegisterCurveMaster(address _curveMasterAddress);
  /**
   * @notice Emited when someone successfully borrows USDA
   * @param _vaultId The id of the vault that borrowed against
   * @param _vaultAddress The address of the vault that borrowed against
   * @param _borrowAmount The amounnt that was borrowed
   * @param _fee The fee assigned to the treasury
   */
  event BorrowUSDA(uint256 _vaultId, address _vaultAddress, uint256 _borrowAmount, uint256 _fee);

  /**
   * @notice Emited when someone successfully repayed a vault's loan
   * @param _vaultId The id of the vault that was repayed
   * @param _vaultAddress The address of the vault that was repayed
   * @param _repayAmount The amount that was repayed
   */
  event RepayUSDA(uint256 _vaultId, address _vaultAddress, uint256 _repayAmount);

  /**
   * @notice Emited when someone successfully liquidates a vault
   * @param _vaultId The id of the vault that was liquidated
   * @param _assetAddress The address of the token that was liquidated
   * @param _usdaToRepurchase The amount of USDA that was repurchased
   * @param _tokensToLiquidate The number of tokens that were taken from the vault and sent to the liquidator
   * @param _liquidationFee The number of tokens that were taken from the fee and sent to the treasury
   */
  event Liquidate(
    uint256 _vaultId,
    address _assetAddress,
    uint256 _usdaToRepurchase,
    uint256 _tokensToLiquidate,
    uint256 _liquidationFee
  );

  /**
   * @notice Emited when governance changes the claimer contract
   *  @param _oldClaimerContract The old claimer contract
   *  @param _newClaimerContract The new claimer contract
   */
  event ChangedClaimerContract(IAMPHClaimer _oldClaimerContract, IAMPHClaimer _newClaimerContract);

  /**
   * @notice Emited when the owner registers the USDA contract
   * @param _usdaContractAddress The address of the USDA contract
   */
  event RegisterUSDA(address _usdaContractAddress);

  /**
   * @notice Emited when governance changes the initial borrowing fee
   *  @param _oldBorrowingFee The old borrowing fee
   *  @param _newBorrowingFee The new borrowing fee
   */
  event ChangedInitialBorrowingFee(uint192 _oldBorrowingFee, uint192 _newBorrowingFee);

  /**
   * @notice Emited when governance changes the liquidation fee
   *  @param _oldLiquidationFee The old liquidation fee
   *  @param _newLiquidationFee The new liquidation fee
   */
  event ChangedLiquidationFee(uint192 _oldLiquidationFee, uint192 _newLiquidationFee);

  /**
   * @notice Emited when collaterals are migrated from old vault controller
   *  @param _oldVaultController The old vault controller migrated from
   *  @param _tokenAddresses The list of new collaterals
   */
  event CollateralsMigratedFrom(IVaultController _oldVaultController, address[] _tokenAddresses);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @notice Thrown when _msgSender is not the pauser of the contract
  error VaultController_OnlyPauser();

  /// @notice Thrown when the fee is too large
  error VaultController_FeeTooLarge();

  /// @notice Thrown when oracle does not exist
  error VaultController_OracleNotRegistered();

  /// @notice Thrown when the token is already registered
  error VaultController_TokenAlreadyRegistered();

  /// @notice Thrown when the token is not registered
  error VaultController_TokenNotRegistered();

  /// @notice Thrown when the _ltv is incompatible
  error VaultController_LTVIncompatible();

  /// @notice Thrown when _msgSender is not the minter
  error VaultController_OnlyMinter();

  /// @notice Thrown when vault is insolvent
  error VaultController_VaultInsolvent();

  /// @notice Thrown when repay is grater than borrow
  error VaultController_RepayTooMuch();

  /// @notice Thrown when trying to liquidate 0 tokens
  error VaultController_LiquidateZeroTokens();

  /// @notice Thrown when trying to liquidate more than is possible
  error VaultController_OverLiquidation();

  /// @notice Thrown when vault is solvent
  error VaultController_VaultSolvent();

  /// @notice Thrown when vault does not exist
  error VaultController_VaultDoesNotExist();

  /// @notice Thrown when migrating collaterals to a new vault controller
  error VaultController_WrongCollateralAddress();

  /// @notice Thrown when a not valid vault is trying to modify the total deposited
  error VaultController_NotValidVault();

  /// @notice Thrown when a deposit surpass the cap
  error VaultController_CapReached();

  /// @notice Thrown when registering a crv lp token with wrong address
  error VaultController_TokenAddressDoesNotMatchLpAddress();

  /*///////////////////////////////////////////////////////////////
                            ENUMS
  //////////////////////////////////////////////////////////////*/

  enum CollateralType {
    Single,
    CurveLPStakedOnConvex
  }

  /*///////////////////////////////////////////////////////////////
                            STRUCTS
    //////////////////////////////////////////////////////////////*/

  struct VaultSummary {
    uint96 id;
    uint192 borrowingPower;
    uint192 vaultLiability;
    address[] tokenAddresses;
    uint256[] tokenBalances;
  }

  struct Interest {
    uint64 lastTime;
    uint192 factor;
  }

  struct CollateralInfo {
    uint256 tokenId;
    uint256 ltv;
    uint256 cap;
    uint256 totalDeposited;
    uint256 liquidationIncentive;
    IOracleRelay oracle;
    CollateralType collateralType;
    IBaseRewardPool crvRewardsContract;
    uint256 poolId;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /// @notice Total number of tokens registered
  function tokensRegistered() external view returns (uint256 _tokensRegistered);

  /// @notice Total number of minted vaults
  function vaultsMinted() external view returns (uint96 _vaultsMinted);

  /// @notice Returns the block timestamp when pay interest was last called
  /// @return _lastInterestTime The block timestamp when pay interest was last called
  function lastInterestTime() external view returns (uint64 _lastInterestTime);

  /// @notice Total base liability
  function totalBaseLiability() external view returns (uint192 _totalBaseLiability);

  /// @notice Returns the latest interest factor
  /// @return _interestFactor The latest interest factor
  function interestFactor() external view returns (uint192 _interestFactor);

  /// @notice The protocol's fee
  function protocolFee() external view returns (uint192 _protocolFee);

  /// @notice The max allowed to be set as borrowing fee
  function MAX_INIT_BORROWING_FEE() external view returns (uint192 _maxInitBorrowingFee);

  /// @notice The initial borrowing fee (1e18 == 100%)
  function initialBorrowingFee() external view returns (uint192 _initialBorrowingFee);

  /// @notice The fee taken from the liquidator profit (1e18 == 100%)
  function liquidationFee() external view returns (uint192 _liquidationFee);

  /// @notice Returns an array of all the vault ids a specific wallet has
  /// @param _wallet The address of the wallet to target
  /// @return _vaultIDs The ids of the vaults the wallet has
  function vaultIDs(address _wallet) external view returns (uint96[] memory _vaultIDs);

  /// @notice Returns an array of all enabled tokens
  /// @return _enabledToken The array containing the token addresses
  function enabledTokens(uint256 _index) external view returns (address _enabledToken);

  /// @notice Returns the address of the curve master
  function curveMaster() external view returns (CurveMaster _curveMaster);

  /// @notice Returns the token id given a token's address
  /// @param _tokenAddress The address of the token to target
  /// @return _tokenId The id of the token
  function tokenId(address _tokenAddress) external view returns (uint256 _tokenId);

  /// @notice Returns the oracle given a token's address
  /// @param _tokenAddress The id of the token
  /// @return _oracle The address of the token's oracle
  function tokensOracle(address _tokenAddress) external view returns (IOracleRelay _oracle);

  /// @notice Returns the ltv of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _ltv The loan-to-value of a token
  function tokenLTV(address _tokenAddress) external view returns (uint256 _ltv);

  /// @notice Returns the liquidation incentive of an accepted token collateral
  /// @param _tokenAddress The address of the token
  /// @return _liquidationIncentive The liquidation incentive of the token
  function tokenLiquidationIncentive(address _tokenAddress) external view returns (uint256 _liquidationIncentive);

  /// @notice Returns the cap of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _cap The cap of the token
  function tokenCap(address _tokenAddress) external view returns (uint256 _cap);

  /// @notice Returns the total deposited of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _totalDeposited The total deposited of a token
  function tokenTotalDeposited(address _tokenAddress) external view returns (uint256 _totalDeposited);

  /// @notice Returns the collateral type of a token
  /// @param _tokenAddress The address of the token
  /// @return _type The collateral type of a token
  function tokenCollateralType(address _tokenAddress) external view returns (CollateralType _type);

  /// @notice Returns the address of the crvRewards contract
  /// @param _tokenAddress The address of the token
  /// @return _crvRewardsContract The address of the crvRewards contract
  function tokenCrvRewardsContract(address _tokenAddress) external view returns (IBaseRewardPool _crvRewardsContract);

  /// @notice Returns the pool id of a curve LP type token
  /// @dev    If the token is not of type CurveLPStakedOnConvex then it returns 0
  /// @param _tokenAddress The address of the token
  /// @return _poolId The pool id of a curve LP type token
  function tokenPoolId(address _tokenAddress) external view returns (uint256 _poolId);

  /// @notice Returns the collateral info of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _collateralInfo The complete collateral info of the token
  function tokenCollateralInfo(address _tokenAddress) external view returns (CollateralInfo memory _collateralInfo);

  /// @notice The convex booster interface
  function BOOSTER() external view returns (IBooster _booster);

  /// @notice The amphora claimer interface
  function claimerContract() external view returns (IAMPHClaimer _claimerContract);

  /// @notice The vault deployer interface
  function VAULT_DEPLOYER() external view returns (IVaultDeployer _vaultDeployer);

  /// @notice Returns an array of all enabled tokens
  /// @return _enabledTokens The array containing the token addresses
  function getEnabledTokens() external view returns (address[] memory _enabledTokens);

  /// @notice Returns the selected collaterals info. Will iterate from `_start` (included) until `_end` (not included)
  /// @param _start The start number to loop on the array
  /// @param _end The end number to loop on the array
  /// @return _collateralsInfo The array containing all the collateral info
  function getCollateralsInfo(
    uint256 _start,
    uint256 _end
  ) external view returns (CollateralInfo[] memory _collateralsInfo);

  /// @notice Returns the address of a vault given it's id
  /// @param _vaultID The id of the vault to target
  /// @return _vaultAddress The address of the targetted vault
  function vaultIdVaultAddress(uint96 _vaultID) external view returns (address _vaultAddress);

  /// @notice Mapping of token address to collateral info
  function tokenAddressCollateralInfo(address _token)
    external
    view
    returns (
      uint256 _tokenId,
      uint256 _ltv,
      uint256 _cap,
      uint256 _totalDeposited,
      uint256 _liquidationIncentive,
      IOracleRelay _oracle,
      CollateralType _collateralType,
      IBaseRewardPool _crvRewardsContract,
      uint256 _poolId
    );

  /// @notice The interest contract
  function interest() external view returns (uint64 _lastTime, uint192 _factor);

  /// @notice The usda interface
  function usda() external view returns (IUSDA _usda);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Returns the amount of USDA needed to reach even solvency without state changes
  /// @dev This amount is a moving target and changes with each block as payInterest is called
  /// @param _id The id of vault we want to target
  /// @return _usdaToSolvency The amount of USDA needed to reach even solvency
  function amountToSolvency(uint96 _id) external view returns (uint256 _usdaToSolvency);

  /// @notice Returns vault liability of vault
  /// @param _id The id of vault
  /// @return _liability The amount of USDA the vault owes
  function vaultLiability(uint96 _id) external view returns (uint192 _liability);

  /// @notice Returns the vault borrowing power for vault
  /// @dev Implementation in getVaultBorrowingPower
  /// @param _id The id of vault we want to target
  /// @return _borrowPower The amount of USDA the vault can borrow
  function vaultBorrowingPower(uint96 _id) external view returns (uint192 _borrowPower);

  /// @notice Returns the calculated amount of tokens to liquidate for a vault
  /// @dev The amount of tokens owed is a moving target and changes with each block as payInterest is called
  ///      This function can serve to give an indication of how many tokens can be liquidated
  ///      All this function does is call _liquidationMath with 2**256-1 as the amount
  /// @param _id The id of vault we want to target
  /// @param _token The address of token to calculate how many tokens to liquidate
  /// @return _tokensToLiquidate The amount of tokens liquidatable
  function tokensToLiquidate(uint96 _id, address _token) external view returns (uint256 _tokensToLiquidate);

  /// @notice Check a vault for over-collateralization
  /// @dev This function calls peekVaultBorrowingPower so no state change is done
  /// @param _id The id of vault we want to target
  /// @return _overCollateralized Returns true if vault over-collateralized; false if vault under-collaterlized
  function peekCheckVault(uint96 _id) external view returns (bool _overCollateralized);

  /// @notice Check a vault for over-collateralization
  /// @dev This function calls getVaultBorrowingPower to allow state changes to happen if an oracle need them
  /// @param _id The id of vault we want to target
  /// @return _overCollateralized Returns true if vault over-collateralized; false if vault under-collaterlized
  function checkVault(uint96 _id) external returns (bool _overCollateralized);

  /// @notice Returns the status of a range of vaults
  /// @dev Special view only function to help liquidators
  /// @param _start The id of the vault to start looping
  /// @param _stop The id of vault to stop looping
  /// @return _vaultSummaries An array of vault information
  function vaultSummaries(uint96 _start, uint96 _stop) external view returns (VaultSummary[] memory _vaultSummaries);

  /// @notice Returns the initial borrowing fee
  /// @param _amount The base amount
  /// @return _fee The fee calculated based on a base amount
  function getBorrowingFee(uint192 _amount) external view returns (uint192 _fee);

  /// @notice Returns the liquidation fee
  /// @param _tokensToLiquidate The collateral amount
  /// @param _assetAddress The collateral address to liquidate
  /// @return _fee The fee calculated based on amount
  function getLiquidationFee(uint192 _tokensToLiquidate, address _assetAddress) external view returns (uint192 _fee);

  /// @notice Returns the increase amount of the interest factor. Accrues interest to borrowers and distribute it to USDA holders
  /// @dev Implementation in payInterest
  /// @return _interest The increase amount of the interest factor
  function calculateInterest() external returns (uint256 _interest);

  /// @notice Creates a new vault and returns it's address
  /// @return _vaultAddress The address of the newly created vault
  function mintVault() external returns (address _vaultAddress);

  /// @notice Simulates the liquidation of an underwater vault
  /// @dev Returns all zeros if vault is solvent
  /// @param _id The id of vault we want to target
  /// @param _assetAddress The address of the token the liquidator wishes to liquidate
  /// @param _tokensToLiquidate The number of tokens to liquidate
  /// @return _collateralLiquidated The number of collateral tokens the liquidator will receive
  /// @return _usdaPaid The amount of USDA the liquidator will have to pay
  function simulateLiquidateVault(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) external view returns (uint256 _collateralLiquidated, uint256 _usdaPaid);

  /// @notice Liquidates an underwater vault
  /// @dev Pays interest before liquidation. Vaults may be liquidated up to the point where they are exactly solvent
  /// @param _id The id of vault we want to target
  /// @param _assetAddress The address of the token the liquidator wishes to liquidate
  /// @param _tokensToLiquidate The number of tokens to liquidate
  /// @return _toLiquidate The number of tokens that got liquidated
  function liquidateVault(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) external returns (uint256 _toLiquidate);

  /// @notice Borrows USDA from a vault. Only the vault minter may borrow from their vault
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to borrow
  function borrowUSDA(uint96 _id, uint192 _amount) external;

  /// @notice Borrows USDA from a vault and send the USDA to a specific address
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to borrow
  /// @param _target The address to receive borrowed USDA
  function borrowUSDAto(uint96 _id, uint192 _amount, address _target) external;

  /// @notice Borrows sUSD directly from reserve, liability is still in USDA, and USDA must be repaid
  /// @param _id The id of vault we want to target
  /// @param _susdAmount The amount of sUSD to borrow
  /// @param _target The address to receive borrowed sUSD
  function borrowsUSDto(uint96 _id, uint192 _susdAmount, address _target) external;

  /// @notice Repays a vault's USDA loan. Anyone may repay
  /// @dev Pays interest
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to repay
  function repayUSDA(uint96 _id, uint192 _amount) external;

  /// @notice Repays all of a vault's USDA. Anyone may repay a vault's liabilities
  /// @dev Pays interest
  /// @param _id The id of vault we want to target
  function repayAllUSDA(uint96 _id) external;

  /// @notice External function used by vaults to increase or decrease the `totalDeposited`.
  /// @dev Should only be called by a valid vault
  /// @param _vaultID The id of vault which is calling (used to verify)
  /// @param _amount The amount to modify
  /// @param _token The token address which should modify the total
  /// @param _increase Boolean that indicates if should increase or decrease (TRUE -> increase, FALSE -> decrease)
  function modifyTotalDeposited(uint96 _vaultID, uint256 _amount, address _token, bool _increase) external;

  /// @notice Pauses the functionality of the contract
  function pause() external;

  /// @notice Unpauses the functionality of the contract
  function unpause() external;

  /// @notice Emited when the owner registers a curve master
  /// @param _masterCurveAddress The address of the curve master
  function registerCurveMaster(address _masterCurveAddress) external;

  /// @notice Updates the protocol fee
  /// @param _newProtocolFee The new protocol fee in terms of 1e18=100%
  function changeProtocolFee(uint192 _newProtocolFee) external;

  /// @notice Register a new token to be used as collateral
  /// @param _tokenAddress The address of the token to register
  /// @param _ltv The ltv of the token, 1e18=100%
  /// @param _oracleAddress The address of oracle to fetch the price of the token
  /// @param _liquidationIncentive The liquidation penalty for the token, 1e18=100%
  /// @param _cap The maximum amount to be deposited
  function registerErc20(
    address _tokenAddress,
    uint256 _ltv,
    address _oracleAddress,
    uint256 _liquidationIncentive,
    uint256 _cap,
    uint256 _poolId
  ) external;

  /// @notice Registers the USDA contract
  /// @param _usdaAddress The address to register as USDA
  function registerUSDA(address _usdaAddress) external;

  /// @notice Updates an existing collateral with new collateral parameters
  /// @param _tokenAddress The address of the token to modify
  /// @param _ltv The new loan-to-value of the token, 1e18=100%
  /// @param _oracleAddress The address of oracle to modify for the price of the token
  /// @param _liquidationIncentive The new liquidation penalty for the token, 1e18=100%
  /// @param _cap The maximum amount to be deposited
  /// @param _poolId The convex pool id of a crv lp token
  function updateRegisteredErc20(
    address _tokenAddress,
    uint256 _ltv,
    address _oracleAddress,
    uint256 _liquidationIncentive,
    uint256 _cap,
    uint256 _poolId
  ) external;

  /// @notice Change the claimer contract, used to exchange a fee from curve lp rewards for AMPH tokens
  /// @param _newClaimerContract The new claimer contract
  function changeClaimerContract(IAMPHClaimer _newClaimerContract) external;

  /// @notice Change the initial borrowing fee
  /// @param _newBorrowingFee The new borrowing fee
  function changeInitialBorrowingFee(uint192 _newBorrowingFee) external;

  /// @notice Change the liquidation fee
  /// @param _newLiquidationFee The new liquidation fee
  function changeLiquidationFee(uint192 _newLiquidationFee) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

/// @notice Curve master keeps a record of CurveSlave contracts and links it with an address
/// @dev All numbers should be scaled to 1e18. for instance, number 5e17 represents 50%
contract CurveMaster is ICurveMaster, Ownable {
  /// @dev Mapping of token to address
  mapping(address => address) public curves;

  /// @dev The vault controller address
  address public vaultControllerAddress;

  /// @notice Returns the value of curve labled _tokenAddress at _xValue
  /// @param _tokenAddress The key to lookup the curve with in the mapping
  /// @param _xValue The x value to pass to the slave
  /// @return _value The y value of the curve
  function getValueAt(address _tokenAddress, int256 _xValue) external view override returns (int256 _value) {
    if (curves[_tokenAddress] == address(0)) revert CurveMaster_TokenNotEnabled();
    ICurveSlave _curve = ICurveSlave(curves[_tokenAddress]);
    _value = _curve.valueAt(_xValue);
    if (_value == 0) revert CurveMaster_ZeroResult();
  }

  /// @notice Set the VaultController addr in order to pay interest on curve setting
  /// @param _vaultMasterAddress The address of vault master
  function setVaultController(address _vaultMasterAddress) external override onlyOwner {
    address _oldCurveAddress = vaultControllerAddress;
    vaultControllerAddress = _vaultMasterAddress;

    emit VaultControllerSet(_oldCurveAddress, _vaultMasterAddress);
  }

  /// @notice Setting a new curve should pay interest
  /// @param _tokenAddress The address of the token
  /// @param _curveAddress The address of the curve for the contract
  function setCurve(address _tokenAddress, address _curveAddress) external override onlyOwner {
    if (vaultControllerAddress != address(0)) IVaultController(vaultControllerAddress).calculateInterest();
    address _oldCurve = curves[_tokenAddress];
    curves[_tokenAddress] = _curveAddress;

    emit CurveSet(_oldCurve, _tokenAddress, _curveAddress);
  }

  /// @notice Special function that does not calculate interest, used for deployment
  /// @param _tokenAddress The address of the token
  /// @param _curveAddress The address of the curve for the contract
  function forceSetCurve(address _tokenAddress, address _curveAddress) external override onlyOwner {
    address _oldCurve = curves[_tokenAddress];
    curves[_tokenAddress] = _curveAddress;

    emit CurveForceSet(_oldCurve, _tokenAddress, _curveAddress);
  }
}

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

/// @notice Controller of all vaults in the USDA borrow/lend system
///         VaultController contains all business logic for borrowing and lending through the protocol.
///         It is also in charge of accruing interest.
contract VaultController is Pausable, IVaultController, ExponentialNoError, Ownable {
  /// @dev The max allowed to be set as borrowing fee
  uint192 public constant MAX_INIT_BORROWING_FEE = 0.05e18;

  /// @dev The convex booster interface
  IBooster public immutable BOOSTER;

  /// @dev The vault deployer interface
  IVaultDeployer public immutable VAULT_DEPLOYER;

  /// @dev Mapping of vault id to vault address
  mapping(uint96 => address) public vaultIdVaultAddress;

  /// @dev Mapping of wallet address to vault IDs arrays
  mapping(address => uint96[]) public walletVaultIDs;

  /// @dev Mapping of token address to collateral info
  mapping(address => CollateralInfo) public tokenAddressCollateralInfo;

  /// @dev Array of enabled tokens addresses
  address[] public enabledTokens;

  /// @dev The curve master contract
  CurveMaster public curveMaster;

  /// @dev The interest contract
  Interest public interest;

  /// @dev The usda interface
  IUSDA public usda;

  /// @dev The amphora claimer interface
  IAMPHClaimer public claimerContract;

  /// @dev Total number of minted vaults
  uint96 public vaultsMinted;
  /// @dev Total number of tokens registered
  uint256 public tokensRegistered;
  /// @dev Total base liability
  uint192 public totalBaseLiability;
  /// @dev The protocol's fee
  uint192 public protocolFee;
  /// @dev The initial borrowing fee (1e18 == 100%)
  uint192 public initialBorrowingFee;
  /// @dev The fee taken from the liquidator profit (1e18 == 100%)
  uint192 public liquidationFee;

  /// @notice Any function with this modifier will call the _payInterest() function before
  modifier paysInterest() {
    _payInterest();
    _;
  }

  ///@notice Any function with this modifier can be paused or unpaused by USDA._pauser() in the case of an emergency
  modifier onlyPauser() {
    if (_msgSender() != usda.pauser()) revert VaultController_OnlyPauser();
    _;
  }

  /// @notice Can initialize collaterals from an older vault controller
  /// @param _oldVaultController The old vault controller
  /// @param _tokenAddresses The addresses of the collateral we want to take information for
  /// @param _claimerContract The claimer contract
  /// @param _vaultDeployer The deployer contract
  /// @param _initialBorrowingFee The initial borrowing fee
  /// @param _booster The convex booster address
  /// @param _liquidationFee The liquidation fee
  constructor(
    IVaultController _oldVaultController,
    address[] memory _tokenAddresses,
    IAMPHClaimer _claimerContract,
    IVaultDeployer _vaultDeployer,
    uint192 _initialBorrowingFee,
    address _booster,
    uint192 _liquidationFee
  ) {
    VAULT_DEPLOYER = _vaultDeployer;
    interest = Interest(uint64(block.timestamp), 1 ether);
    protocolFee = 1e14;
    initialBorrowingFee = _initialBorrowingFee;
    liquidationFee = _liquidationFee;

    claimerContract = _claimerContract;

    BOOSTER = IBooster(_booster);

    if (address(_oldVaultController) != address(0)) _migrateCollateralsFrom(_oldVaultController, _tokenAddresses);
  }

  /// @notice Returns the latest interest factor
  /// @return _interestFactor The latest interest factor
  function interestFactor() external view override returns (uint192 _interestFactor) {
    _interestFactor = interest.factor;
  }

  /// @notice Returns the block timestamp when pay interest was last called
  /// @return _lastInterestTime The block timestamp when pay interest was last called
  function lastInterestTime() external view override returns (uint64 _lastInterestTime) {
    _lastInterestTime = interest.lastTime;
  }

  /// @notice Returns an array of all the vault ids a specific wallet has
  /// @param _wallet The address of the wallet to target
  /// @return _vaultIDs The ids of the vaults the wallet has
  function vaultIDs(address _wallet) external view override returns (uint96[] memory _vaultIDs) {
    _vaultIDs = walletVaultIDs[_wallet];
  }

  /// @notice Returns an array of all enabled tokens
  /// @return _enabledTokens The array containing the token addresses
  function getEnabledTokens() external view override returns (address[] memory _enabledTokens) {
    _enabledTokens = enabledTokens;
  }

  /// @notice Returns the token id given a token's address
  /// @param _tokenAddress The address of the token to target
  /// @return _tokenId The id of the token
  function tokenId(address _tokenAddress) external view override returns (uint256 _tokenId) {
    _tokenId = tokenAddressCollateralInfo[_tokenAddress].tokenId;
  }

  /// @notice Returns the oracle given a token's address
  /// @param _tokenAddress The id of the token
  /// @return _oracle The address of the token's oracle
  function tokensOracle(address _tokenAddress) external view override returns (IOracleRelay _oracle) {
    _oracle = tokenAddressCollateralInfo[_tokenAddress].oracle;
  }

  /// @notice Returns the ltv of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _ltv The loan-to-value of a token
  function tokenLTV(address _tokenAddress) external view override returns (uint256 _ltv) {
    _ltv = tokenAddressCollateralInfo[_tokenAddress].ltv;
  }

  /// @notice Returns the liquidation incentive of an accepted token collateral
  /// @param _tokenAddress The address of the token
  /// @return _liquidationIncentive The liquidation incentive of the token
  function tokenLiquidationIncentive(address _tokenAddress)
    external
    view
    override
    returns (uint256 _liquidationIncentive)
  {
    _liquidationIncentive = tokenAddressCollateralInfo[_tokenAddress].liquidationIncentive;
  }

  /// @notice Returns the cap of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _cap The cap of the token
  function tokenCap(address _tokenAddress) external view override returns (uint256 _cap) {
    _cap = tokenAddressCollateralInfo[_tokenAddress].cap;
  }

  /// @notice Returns the total deposited of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _totalDeposited The total deposited of a token
  function tokenTotalDeposited(address _tokenAddress) external view override returns (uint256 _totalDeposited) {
    _totalDeposited = tokenAddressCollateralInfo[_tokenAddress].totalDeposited;
  }

  /// @notice Returns the collateral type of a token
  /// @param _tokenAddress The address of the token
  /// @return _type The collateral type of a token
  function tokenCollateralType(address _tokenAddress) external view override returns (CollateralType _type) {
    _type = tokenAddressCollateralInfo[_tokenAddress].collateralType;
  }

  /// @notice Returns the address of the crvRewards contract
  /// @param _tokenAddress The address of the token
  /// @return _crvRewardsContract The address of the crvRewards contract
  function tokenCrvRewardsContract(address _tokenAddress)
    external
    view
    override
    returns (IBaseRewardPool _crvRewardsContract)
  {
    _crvRewardsContract = tokenAddressCollateralInfo[_tokenAddress].crvRewardsContract;
  }

  /// @notice Returns the pool id of a curve LP type token
  /// @dev    If the token is not of type CurveLPStakedOnConvex then it returns 0
  /// @param _tokenAddress The address of the token
  /// @return _poolId The pool id of a curve LP type token
  function tokenPoolId(address _tokenAddress) external view override returns (uint256 _poolId) {
    _poolId = tokenAddressCollateralInfo[_tokenAddress].poolId;
  }

  /// @notice Returns the collateral info of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _collateralInfo The complete collateral info of the token
  function tokenCollateralInfo(address _tokenAddress)
    external
    view
    override
    returns (CollateralInfo memory _collateralInfo)
  {
    _collateralInfo = tokenAddressCollateralInfo[_tokenAddress];
  }

  /// @notice Returns the selected collaterals info. Will iterate from `_start` (included) until `_end` (not included)
  /// @param _start The start number to loop on the array
  /// @param _end The end number to loop on the array
  /// @return _collateralsInfo The array containing all the collateral info
  function getCollateralsInfo(
    uint256 _start,
    uint256 _end
  ) external view override returns (CollateralInfo[] memory _collateralsInfo) {
    // check if `_end` is bigger than the tokens length
    uint256 _enabledTokensLength = enabledTokens.length;
    _end = _enabledTokensLength < _end ? _enabledTokensLength : _end;

    _collateralsInfo = new CollateralInfo[](_end - _start);

    for (uint256 _i = _start; _i < _end;) {
      _collateralsInfo[_i - _start] = tokenAddressCollateralInfo[enabledTokens[_i]];

      unchecked {
        ++_i;
      }
    }
  }

  /// @notice Migrates all collateral information from previous vault controller
  /// @param _oldVaultController The address of the vault controller to take the information from
  /// @param _tokenAddresses The addresses of the tokens we want to target
  function _migrateCollateralsFrom(IVaultController _oldVaultController, address[] memory _tokenAddresses) internal {
    uint256 _tokenId;
    uint256 _tokensRegistered;
    for (uint256 _i; _i < _tokenAddresses.length;) {
      _tokenId = _oldVaultController.tokenId(_tokenAddresses[_i]);
      if (_tokenId == 0) revert VaultController_WrongCollateralAddress();
      _tokensRegistered++;

      CollateralInfo memory _collateral = _oldVaultController.tokenCollateralInfo(_tokenAddresses[_i]);
      _collateral.tokenId = _tokensRegistered;
      _collateral.totalDeposited = 0;

      enabledTokens.push(_tokenAddresses[_i]);
      tokenAddressCollateralInfo[_tokenAddresses[_i]] = _collateral;

      unchecked {
        ++_i;
      }
    }
    tokensRegistered += _tokensRegistered;

    emit CollateralsMigratedFrom(_oldVaultController, _tokenAddresses);
  }

  /// @notice Creates a new vault and returns it's address
  /// @return _vaultAddress The address of the newly created vault
  function mintVault() public override whenNotPaused returns (address _vaultAddress) {
    // increment  minted vaults
    vaultsMinted += 1;
    // mint the vault itself, deploying the contract
    _vaultAddress = _createVault(vaultsMinted, _msgSender());
    // add the vault to our system
    vaultIdVaultAddress[vaultsMinted] = _vaultAddress;

    //push new vault ID onto mapping
    walletVaultIDs[_msgSender()].push(vaultsMinted);

    // emit the event
    emit NewVault(_vaultAddress, vaultsMinted, _msgSender());
  }

  /// @notice Pauses the functionality of the contract
  function pause() external override onlyPauser {
    _pause();
  }

  /// @notice Unpauses the functionality of the contract
  function unpause() external override onlyPauser {
    _unpause();
  }

  /// @notice Registers the USDA contract
  /// @param _usdaAddress The address to register as USDA
  function registerUSDA(address _usdaAddress) external override onlyOwner {
    usda = IUSDA(_usdaAddress);
    emit RegisterUSDA(_usdaAddress);
  }

  /// @notice Emited when the owner registers a curve master
  /// @param _masterCurveAddress The address of the curve master
  function registerCurveMaster(address _masterCurveAddress) external override onlyOwner {
    curveMaster = CurveMaster(_masterCurveAddress);
    emit RegisterCurveMaster(_masterCurveAddress);
  }

  /// @notice Updates the protocol fee
  /// @param _newProtocolFee The new protocol fee in terms of 1e18=100%
  function changeProtocolFee(uint192 _newProtocolFee) external override onlyOwner {
    if (_newProtocolFee >= 1e18) revert VaultController_FeeTooLarge();
    protocolFee = _newProtocolFee;
    emit NewProtocolFee(_newProtocolFee);
  }

  /// @notice Register a new token to be used as collateral
  /// @param _tokenAddress The address of the token to register
  /// @param _ltv The ltv of the token, 1e18=100%
  /// @param _oracleAddress The address of oracle to fetch the price of the token
  /// @param _liquidationIncentive The liquidation penalty for the token, 1e18=100%
  /// @param _cap The maximum amount to be deposited
  function registerErc20(
    address _tokenAddress,
    uint256 _ltv,
    address _oracleAddress,
    uint256 _liquidationIncentive,
    uint256 _cap,
    uint256 _poolId
  ) external override onlyOwner {
    CollateralInfo storage _collateral = tokenAddressCollateralInfo[_tokenAddress];
    if (_collateral.tokenId != 0) revert VaultController_TokenAlreadyRegistered();
    if (_poolId != 0) {
      (address _lpToken,,, address _crvRewards,,) = BOOSTER.poolInfo(_poolId);
      if (_lpToken != _tokenAddress) revert VaultController_TokenAddressDoesNotMatchLpAddress();
      _collateral.collateralType = CollateralType.CurveLPStakedOnConvex;
      _collateral.crvRewardsContract = IBaseRewardPool(_crvRewards);
      _collateral.poolId = _poolId;
    } else {
      _collateral.collateralType = CollateralType.Single;
      _collateral.crvRewardsContract = IBaseRewardPool(address(0));
      _collateral.poolId = 0;
    }
    // ltv must be compatible with liquidation incentive
    if (_ltv >= (EXP_SCALE - _liquidationIncentive)) revert VaultController_LTVIncompatible();
    // increment the amount of registered token
    tokensRegistered = tokensRegistered + 1;
    // set & give the token an id
    _collateral.tokenId = tokensRegistered;
    // set the token's oracle
    _collateral.oracle = IOracleRelay(_oracleAddress);
    // set the token's ltv
    _collateral.ltv = _ltv;
    // set the token's liquidation incentive
    _collateral.liquidationIncentive = _liquidationIncentive;
    // set the cap
    _collateral.cap = _cap;
    // finally, add the token to the array of enabled tokens
    enabledTokens.push(_tokenAddress);

    emit RegisteredErc20(_tokenAddress, _ltv, _oracleAddress, _liquidationIncentive, _cap);
  }

  /// @notice Updates an existing collateral with new collateral parameters
  /// @param _tokenAddress The address of the token to modify
  /// @param _ltv The new loan-to-value of the token, 1e18=100%
  /// @param _oracleAddress The address of oracle to modify for the price of the token
  /// @param _liquidationIncentive The new liquidation penalty for the token, 1e18=100%
  /// @param _cap The maximum amount to be deposited
  /// @param _poolId The convex pool id of a crv lp token
  function updateRegisteredErc20(
    address _tokenAddress,
    uint256 _ltv,
    address _oracleAddress,
    uint256 _liquidationIncentive,
    uint256 _cap,
    uint256 _poolId
  ) external override onlyOwner {
    CollateralInfo storage _collateral = tokenAddressCollateralInfo[_tokenAddress];
    if (_collateral.tokenId == 0) revert VaultController_TokenNotRegistered();
    // _ltv must be compatible with liquidation incentive
    if (_ltv >= (EXP_SCALE - _liquidationIncentive)) revert VaultController_LTVIncompatible();
    if (_poolId != 0) {
      (address _lpToken,,, address _crvRewards,,) = BOOSTER.poolInfo(_poolId);
      if (_lpToken != _tokenAddress) revert VaultController_TokenAddressDoesNotMatchLpAddress();
      _collateral.collateralType = CollateralType.CurveLPStakedOnConvex;
      _collateral.crvRewardsContract = IBaseRewardPool(_crvRewards);
      _collateral.poolId = _poolId;
    }
    // set the oracle of the token
    _collateral.oracle = IOracleRelay(_oracleAddress);
    // set the ltv of the token
    _collateral.ltv = _ltv;
    // set the liquidation incentive of the token
    _collateral.liquidationIncentive = _liquidationIncentive;
    // set the cap
    _collateral.cap = _cap;

    emit UpdateRegisteredErc20(_tokenAddress, _ltv, _oracleAddress, _liquidationIncentive, _cap, _poolId);
  }

  /// @notice Change the claimer contract, used to exchange a fee from curve lp rewards for AMPH tokens
  /// @param _newClaimerContract The new claimer contract
  function changeClaimerContract(IAMPHClaimer _newClaimerContract) external override onlyOwner {
    IAMPHClaimer _oldClaimerContract = claimerContract;
    claimerContract = _newClaimerContract;

    emit ChangedClaimerContract(_oldClaimerContract, _newClaimerContract);
  }

  /// @notice Change the initial borrowing fee
  /// @param _newBorrowingFee The new borrowing fee
  function changeInitialBorrowingFee(uint192 _newBorrowingFee) external override onlyOwner {
    if (_newBorrowingFee >= MAX_INIT_BORROWING_FEE) revert VaultController_FeeTooLarge();
    uint192 _oldBorrowingFee = initialBorrowingFee;
    initialBorrowingFee = _newBorrowingFee;

    emit ChangedInitialBorrowingFee(_oldBorrowingFee, _newBorrowingFee);
  }

  /// @notice Change the liquidation fee
  /// @param _newLiquidationFee The new liquidation fee
  function changeLiquidationFee(uint192 _newLiquidationFee) external override onlyOwner {
    if (_newLiquidationFee >= 1e18) revert VaultController_FeeTooLarge();
    uint192 _oldLiquidationFee = liquidationFee;
    liquidationFee = _newLiquidationFee;

    emit ChangedLiquidationFee(_oldLiquidationFee, _newLiquidationFee);
  }

  /// @notice Check a vault for over-collateralization
  /// @dev This function calls peekVaultBorrowingPower so no state change is done
  /// @param _id The id of vault we want to target
  /// @return _overCollateralized Returns true if vault over-collateralized; false if vault under-collaterlized
  function peekCheckVault(uint96 _id) public view override returns (bool _overCollateralized) {
    // grab the vault by id if part of our system. revert if not
    IVault _vault = _getVault(_id);
    // calculate the total value of the vault's liquidity
    uint256 _totalLiquidityValue = _peekVaultBorrowingPower(_vault);
    // calculate the total liability of the vault
    uint256 _usdaLiability = _truncate((_vault.baseLiability() * interest.factor));
    // if the ltv >= liability, the vault is solvent
    _overCollateralized = (_totalLiquidityValue >= _usdaLiability);
  }

  /// @notice Check a vault for over-collateralization
  /// @dev This function calls getVaultBorrowingPower to allow state changes to happen if an oracle need them
  /// @param _id The id of vault we want to target
  /// @return _overCollateralized Returns true if vault over-collateralized; false if vault under-collaterlized
  function checkVault(uint96 _id) public returns (bool _overCollateralized) {
    // grab the vault by id if part of our system. revert if not
    IVault _vault = _getVault(_id);
    // calculate the total value of the vault's liquidity
    uint256 _totalLiquidityValue = _getVaultBorrowingPower(_vault);
    // calculate the total liability of the vault
    uint256 _usdaLiability = _truncate((_vault.baseLiability() * interest.factor));
    // if the ltv >= liability, the vault is solvent
    _overCollateralized = (_totalLiquidityValue >= _usdaLiability);
  }

  /// @notice Borrows USDA from a vault. Only the vault minter may borrow from their vault
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to borrow
  function borrowUSDA(uint96 _id, uint192 _amount) external override {
    _borrow(_id, _amount, _msgSender(), true);
  }

  /// @notice Borrows USDA from a vault and send the USDA to a specific address
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to borrow
  /// @param _target The address to receive borrowed USDA
  function borrowUSDAto(uint96 _id, uint192 _amount, address _target) external override {
    _borrow(_id, _amount, _target, true);
  }

  /// @notice Borrows sUSD directly from reserve, liability is still in USDA, and USDA must be repaid
  /// @param _id The id of vault we want to target
  /// @param _susdAmount The amount of sUSD to borrow
  /// @param _target The address to receive borrowed sUSD
  function borrowsUSDto(uint96 _id, uint192 _susdAmount, address _target) external override {
    _borrow(_id, _susdAmount, _target, false);
  }

  /// @notice Returns the initial borrowing fee
  /// @param _amount The base amount
  /// @return _fee The fee calculated based on a base amount
  function getBorrowingFee(uint192 _amount) public view override returns (uint192 _fee) {
    // _amount * (100% + initialBorrowingFee)
    _fee = _safeu192(_truncate(uint256(_amount * (1e18 + initialBorrowingFee)))) - _amount;
  }

  /// @notice Returns the liquidation fee
  /// @param _tokensToLiquidate The collateral amount
  /// @param _assetAddress The collateral address to liquidate
  /// @return _fee The fee calculated based on amount
  function getLiquidationFee(
    uint192 _tokensToLiquidate,
    address _assetAddress
  ) public view override returns (uint192 _fee) {
    uint256 _liquidationIncentive = tokenAddressCollateralInfo[_assetAddress].liquidationIncentive;
    // _tokensToLiquidate * (100% + _liquidationIncentive)
    uint192 _liquidatorExpectedProfit =
      _safeu192(_truncate(uint256(_tokensToLiquidate * (1e18 + _liquidationIncentive)))) - _tokensToLiquidate;
    // _liquidatorExpectedProfit * (100% + liquidationFee)
    _fee =
      _safeu192(_truncate(uint256(_liquidatorExpectedProfit * (1e18 + liquidationFee)))) - _liquidatorExpectedProfit;
  }

  /// @notice Business logic to perform the USDA loan
  /// @dev Pays interest
  /// @param _id The vault's id to borrow against
  /// @param _amount The amount of USDA to borrow
  /// @param _target The address to receive borrowed USDA
  /// @param _isUSDA Boolean indicating if the borrowed asset is USDA (if FALSE is sUSD)
  function _borrow(uint96 _id, uint192 _amount, address _target, bool _isUSDA) internal paysInterest whenNotPaused {
    // grab the vault by id if part of our system. revert if not
    IVault _vault = _getVault(_id);
    // only the minter of the vault may borrow from their vault
    if (_msgSender() != _vault.minter()) revert VaultController_OnlyMinter();
    // add the fee
    uint192 _fee = getBorrowingFee(_amount);
    // the base amount is the amount of USDA they wish to borrow divided by the interest factor, accounting for the fee
    uint192 _baseAmount = _safeu192(uint256((_amount + _fee) * EXP_SCALE) / uint256(interest.factor));
    // _baseLiability should contain the vault's new liability, in terms of base units
    // true indicates that we are adding to the liability
    uint256 _baseLiability = _vault.modifyLiability(true, _baseAmount);
    // increase the total base liability by the _baseAmount
    // the same amount we added to the vault's liability
    totalBaseLiability += _baseAmount;
    // now take the vault's total base liability and multiply it by the interest factor
    uint256 _usdaLiability = _truncate(uint256(interest.factor) * _baseLiability);
    // now get the ltv of the vault, aka their borrowing power, in usda
    uint256 _totalLiquidityValue = _getVaultBorrowingPower(_vault);
    // the ltv must be above the newly calculated _usdaLiability, else revert
    if (_totalLiquidityValue < _usdaLiability) revert VaultController_VaultInsolvent();

    if (_isUSDA) {
      // now send usda to the target, equal to the amount they are owed
      usda.vaultControllerMint(_target, _amount);
    } else {
      // send sUSD to the target from reserve instead of mint
      usda.vaultControllerTransfer(_target, _amount);
    }

    // also send the fee to the treasury
    if (_fee > 0) usda.vaultControllerMint(owner(), _fee);

    // emit the event
    emit BorrowUSDA(_id, address(_vault), _amount, _fee);
  }

  /// @notice Repays a vault's USDA loan. Anyone may repay
  /// @dev Pays interest
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to repay
  function repayUSDA(uint96 _id, uint192 _amount) external override {
    _repay(_id, _amount, false);
  }

  /// @notice Repays all of a vault's USDA. Anyone may repay a vault's liabilities
  /// @dev Pays interest
  /// @param _id The id of vault we want to target
  function repayAllUSDA(uint96 _id) external override {
    _repay(_id, 0, true);
  }

  /// @notice Business logic to perform the USDA repay
  /// @dev Pays interest
  /// @param _id The vault's id to repay
  /// @param _amountInUSDA The amount of USDA to borrow
  /// @param _repayAll Boolean if TRUE, repay all debt
  function _repay(uint96 _id, uint192 _amountInUSDA, bool _repayAll) internal paysInterest whenNotPaused {
    // grab the vault by id if part of our system. revert if not
    IVault _vault = _getVault(_id);
    uint192 _baseAmount;

    // if _repayAll == TRUE, repay total liability
    if (_repayAll) {
      // store the vault baseLiability in memory
      _baseAmount = _safeu192(_vault.baseLiability());
      // get the total USDA liability, equal to the interest factor * vault's base liabilty
      _amountInUSDA = _safeu192(_truncate(interest.factor * _baseAmount));
    } else {
      // the base amount is the amount of USDA entered divided by the interest factor
      _baseAmount = _safeu192((_amountInUSDA * EXP_SCALE) / interest.factor);
    }
    // decrease the total base liability by the calculated base amount
    totalBaseLiability -= _baseAmount;
    // ensure that _baseAmount is lower than the vault's base liability.
    // this may not be needed, since modifyLiability *should* revert if is not true
    if (_baseAmount > _vault.baseLiability()) revert VaultController_RepayTooMuch();
    // decrease the vault's liability by the calculated base amount
    _vault.modifyLiability(false, _baseAmount);
    // burn the amount of USDA submitted from the sender
    usda.vaultControllerBurn(_msgSender(), _amountInUSDA);

    emit RepayUSDA(_id, address(_vault), _amountInUSDA);
  }

  /// @notice Simulates the liquidation of an underwater vault
  /// @dev Returns all zeros if vault is solvent
  /// @param _id The id of vault we want to target
  /// @param _assetAddress The address of the token the liquidator wishes to liquidate
  /// @param _tokensToLiquidate The number of tokens to liquidate
  /// @return _collateralLiquidated The number of collateral tokens the liquidator will receive
  /// @return _usdaPaid The amount of USDA the liquidator will have to pay
  function simulateLiquidateVault(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) external view override returns (uint256 _collateralLiquidated, uint256 _usdaPaid) {
    // cannot liquidate 0
    if (_tokensToLiquidate == 0) revert VaultController_LiquidateZeroTokens();
    // check for registered asset
    if (tokenAddressCollateralInfo[_assetAddress].tokenId == 0) revert VaultController_TokenNotRegistered();

    // calculate the amount to liquidate and the 'bad fill price' using liquidationMath
    // see _liquidationMath for more detailed explaination of the math
    (uint256 _tokenAmount, uint256 _badFillPrice) = _peekLiquidationMath(_id, _assetAddress, _tokensToLiquidate);
    // set _tokensToLiquidate to this calculated amount if the function does not fail
    _collateralLiquidated = _tokenAmount != 0 ? _tokenAmount : _tokensToLiquidate;
    // the USDA to repurchase is equal to the bad fill price multiplied by the amount of tokens to liquidate
    _usdaPaid = _truncate(_badFillPrice * _collateralLiquidated);
    // extract fee
    _collateralLiquidated -= getLiquidationFee(uint192(_collateralLiquidated), _assetAddress);
  }

  /// @notice Liquidates an underwater vault
  /// @dev Pays interest before liquidation. Vaults may be liquidated up to the point where they are exactly solvent
  /// @param _id The id of vault we want to target
  /// @param _assetAddress The address of the token the liquidator wishes to liquidate
  /// @param _tokensToLiquidate The number of tokens to liquidate
  /// @return _toLiquidate The number of tokens that got liquidated
  function liquidateVault(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) external override paysInterest whenNotPaused returns (uint256 _toLiquidate) {
    // cannot liquidate 0
    if (_tokensToLiquidate == 0) revert VaultController_LiquidateZeroTokens();
    // check for registered asset
    if (tokenAddressCollateralInfo[_assetAddress].tokenId == 0) revert VaultController_TokenNotRegistered();

    // calculate the amount to liquidate and the 'bad fill price' using liquidationMath
    // see _liquidationMath for more detailed explaination of the math
    (uint256 _tokenAmount, uint256 _badFillPrice) = _liquidationMath(_id, _assetAddress, _tokensToLiquidate);
    // set _tokensToLiquidate to this calculated amount if the function does not fail
    if (_tokenAmount > 0) _tokensToLiquidate = _tokenAmount;
    // the USDA to repurchase is equal to the bad fill price multiplied by the amount of tokens to liquidate
    uint256 _usdaToRepurchase = _truncate(_badFillPrice * _tokensToLiquidate);
    // get the vault that the liquidator wishes to liquidate
    IVault _vault = _getVault(_id);

    // decrease the vault's liability
    _vault.modifyLiability(false, (_usdaToRepurchase * 1e18) / interest.factor);

    // decrease the total base liability
    totalBaseLiability -= _safeu192((_usdaToRepurchase * 1e18) / interest.factor);

    // decrease liquidator's USDA balance
    usda.vaultControllerBurn(_msgSender(), _usdaToRepurchase);

    // withdraw from convex
    CollateralInfo memory _assetInfo = tokenAddressCollateralInfo[_assetAddress];
    if (_vault.isTokenStaked(_assetAddress)) {
      _vault.controllerWithdrawAndUnwrap(_assetInfo.crvRewardsContract, _tokensToLiquidate);
    }

    uint192 _liquidationFee = getLiquidationFee(uint192(_tokensToLiquidate), _assetAddress);

    // finally, deliver tokens to liquidator
    _vault.controllerTransfer(_assetAddress, _msgSender(), _tokensToLiquidate - _liquidationFee);
    // and the fee to the treasury
    _vault.controllerTransfer(_assetAddress, owner(), _liquidationFee);
    // and reduces total
    _modifyTotalDeposited(_tokensToLiquidate, _assetAddress, false);

    // this mainly prevents reentrancy
    if (_getVaultBorrowingPower(_vault) > _vaultLiability(_id)) revert VaultController_OverLiquidation();

    // emit the event
    emit Liquidate(_id, _assetAddress, _usdaToRepurchase, _tokensToLiquidate - _liquidationFee, _liquidationFee);
    // return the amount of tokens liquidated (including fee)
    _toLiquidate = _tokensToLiquidate;
  }

  /// @notice Returns the calculated amount of tokens to liquidate for a vault
  /// @dev The amount of tokens owed is a moving target and changes with each block as payInterest is called
  ///      This function can serve to give an indication of how many tokens can be liquidated
  ///      All this function does is call _liquidationMath with 2**256-1 as the amount
  /// @param _id The id of vault we want to target
  /// @param _assetAddress The address of token to calculate how many tokens to liquidate
  /// @return _tokensToLiquidate The amount of tokens liquidatable
  function tokensToLiquidate(
    uint96 _id,
    address _assetAddress
  ) external view override returns (uint256 _tokensToLiquidate) {
    (
      _tokensToLiquidate, // bad fill price
    ) = _peekLiquidationMath(_id, _assetAddress, 2 ** 256 - 1);
  }

  /// @notice Internal function with business logic for liquidation math without any state changes
  /// @param _id The vault to get info for
  /// @param _assetAddress The token to calculate how many tokens to liquidate
  /// @param _tokensToLiquidate The max amount of tokens one wishes to liquidate
  /// @return _actualTokensToLiquidate The amount of tokens underwater this vault is
  /// @return _badFillPrice The bad fill price for the token
  function _peekLiquidationMath(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) internal view returns (uint256 _actualTokensToLiquidate, uint256 _badFillPrice) {
    //require that the vault is not solvent
    if (peekCheckVault(_id)) revert VaultController_VaultSolvent();

    CollateralInfo memory _collateral = tokenAddressCollateralInfo[_assetAddress];
    uint256 _price = _collateral.oracle.peekValue();
    uint256 _usdaToSolvency = _peekAmountToSolvency(_id);

    (_actualTokensToLiquidate, _badFillPrice) =
      _calculateTokensToLiquidate(_collateral, _id, _tokensToLiquidate, _assetAddress, _price, _usdaToSolvency);
  }

  /// @notice Internal function with business logic for liquidation math
  /// @param _id The vault to get info for
  /// @param _assetAddress The token to calculate how many tokens to liquidate
  /// @param _tokensToLiquidate The max amount of tokens one wishes to liquidate
  /// @return _actualTokensToLiquidate The amount of tokens underwater this vault is
  /// @return _badFillPrice The bad fill price for the token
  function _liquidationMath(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) internal returns (uint256 _actualTokensToLiquidate, uint256 _badFillPrice) {
    //require that the vault is not solvent
    if (checkVault(_id)) revert VaultController_VaultSolvent();

    CollateralInfo memory _collateral = tokenAddressCollateralInfo[_assetAddress];
    uint256 _price = _collateral.oracle.currentValue();
    uint256 _usdaToSolvency = _amountToSolvency(_id);

    (_actualTokensToLiquidate, _badFillPrice) =
      _calculateTokensToLiquidate(_collateral, _id, _tokensToLiquidate, _assetAddress, _price, _usdaToSolvency);
  }

  /// @notice Calculates the amount of tokens to liquidate for a vault
  /// @param _collateral The collateral to liquidate
  /// @param _id The vault to calculate the liquidation
  /// @param _tokensToLiquidate The max amount of tokens one wishes to liquidate
  /// @param _assetAddress The token to calculate how many tokens to liquidate
  /// @param _price The price of the collateral
  /// @param _usdaToSolvency The amount of USDA needed to make the vault solvent
  /// @return _actualTokensToLiquidate The amount of tokens underwater this vault is
  /// @return _badFillPrice The bad fill price for the token
  function _calculateTokensToLiquidate(
    CollateralInfo memory _collateral,
    uint96 _id,
    uint256 _tokensToLiquidate,
    address _assetAddress,
    uint256 _price,
    uint256 _usdaToSolvency
  ) internal view returns (uint256 _actualTokensToLiquidate, uint256 _badFillPrice) {
    IVault _vault = _getVault(_id);
    // get price discounted by liquidation penalty
    // price * (100% - liquidationIncentive)
    _badFillPrice = _truncate(_price * (1e18 - _collateral.liquidationIncentive));

    // the ltv discount is the amount of collateral value that one token provides
    uint256 _ltvDiscount = _truncate(_price * _collateral.ltv);
    // this number is the denominator when calculating the _maxTokensToLiquidate
    // it is simply the badFillPrice - ltvDiscount
    uint256 _denominator = _badFillPrice - _ltvDiscount;

    // the maximum amount of tokens to liquidate is the amount that will bring the vault to solvency
    // divided by the denominator
    uint256 _maxTokensToLiquidate = (_usdaToSolvency * 1e18) / _denominator;
    //Cannot liquidate more than is necessary to make vault over-collateralized
    if (_tokensToLiquidate > _maxTokensToLiquidate) _tokensToLiquidate = _maxTokensToLiquidate;

    uint256 _balance = _vault.balances(_assetAddress);

    //Cannot liquidate more collateral than there is in the vault
    if (_tokensToLiquidate > _balance) _tokensToLiquidate = _balance;

    _actualTokensToLiquidate = _tokensToLiquidate;
  }

  /// @notice Internal helper function to wrap getting of vaults
  /// @dev It will revert if the vault does not exist
  /// @param _id The id of vault
  /// @return _vault The vault for that id
  function _getVault(uint96 _id) internal view returns (IVault _vault) {
    address _vaultAddress = vaultIdVaultAddress[_id];
    if (_vaultAddress == address(0)) revert VaultController_VaultDoesNotExist();
    _vault = IVault(_vaultAddress);
  }

  /// @notice Returns the amount of USDA needed to reach even solvency without state changes
  /// @dev This amount is a moving target and changes with each block as payInterest is called
  /// @param _id The id of vault we want to target
  /// @return _usdaToSolvency The amount of USDA needed to reach even solvency
  function amountToSolvency(uint96 _id) external view override returns (uint256 _usdaToSolvency) {
    if (peekCheckVault(_id)) revert VaultController_VaultSolvent();
    _usdaToSolvency = _peekAmountToSolvency(_id);
  }

  /// @notice Bussiness logic for amountToSolvency without any state changes
  /// @param _id The id of vault
  /// @return _usdaToSolvency The amount of USDA needed to reach even solvency
  function _peekAmountToSolvency(uint96 _id) internal view returns (uint256 _usdaToSolvency) {
    _usdaToSolvency = _vaultLiability(_id) - _peekVaultBorrowingPower(_getVault(_id));
  }

  /// @notice Bussiness logic for amountToSolvency
  /// @param _id The id of vault
  /// @return _usdaToSolvency The amount of USDA needed to reach even solvency
  function _amountToSolvency(uint96 _id) internal returns (uint256 _usdaToSolvency) {
    _usdaToSolvency = _vaultLiability(_id) - _getVaultBorrowingPower(_getVault(_id));
  }

  /// @notice Returns vault liability of vault
  /// @param _id The id of vault
  /// @return _liability The amount of USDA the vault owes
  function vaultLiability(uint96 _id) external view override returns (uint192 _liability) {
    _liability = _vaultLiability(_id);
  }

  /// @notice Returns the liability of a vault
  /// @dev Implementation in _vaultLiability
  /// @param _id The id of vault we want to target
  /// @return _liability The amount of USDA the vault owes
  function _vaultLiability(uint96 _id) internal view returns (uint192 _liability) {
    address _vaultAddress = vaultIdVaultAddress[_id];
    if (_vaultAddress == address(0)) revert VaultController_VaultDoesNotExist();
    IVault _vault = IVault(_vaultAddress);
    _liability = _safeu192(_truncate(_vault.baseLiability() * interest.factor));
  }

  /// @notice Returns the vault borrowing power for vault
  /// @dev Implementation in getVaultBorrowingPower
  /// @param _id The id of vault we want to target
  /// @return _borrowPower The amount of USDA the vault can borrow
  function vaultBorrowingPower(uint96 _id) external view override returns (uint192 _borrowPower) {
    uint192 _bp = _peekVaultBorrowingPower(_getVault(_id));
    _borrowPower = _bp - getBorrowingFee(_bp);
  }

  /// @notice Returns the borrowing power of a vault
  /// @param _vault The vault to get the borrowing power of
  /// @return _borrowPower The borrowing power of the vault
  //solhint-disable-next-line code-complexity
  function _getVaultBorrowingPower(IVault _vault) private returns (uint192 _borrowPower) {
    // loop over each registed token, adding the indivuduals ltv to the total ltv of the vault
    for (uint192 _i; _i < enabledTokens.length; ++_i) {
      CollateralInfo memory _collateral = tokenAddressCollateralInfo[enabledTokens[_i]];
      // if the ltv is 0, continue
      if (_collateral.ltv == 0) continue;
      // get the address of the token through the array of enabled tokens
      // note that index 0 of enabledTokens corresponds to a vaultId of 1, so we must subtract 1 from i to get the correct index
      address _tokenAddress = enabledTokens[_i];
      // the balance is the vault's token balance of the current collateral token in the loop
      uint256 _balance = _vault.balances(_tokenAddress);
      if (_balance == 0) continue;
      // the raw price is simply the oracle price of the token
      uint192 _rawPrice = _safeu192(_collateral.oracle.currentValue());
      if (_rawPrice == 0) continue;
      // the token value is equal to the price * balance * tokenLTV
      uint192 _tokenValue = _safeu192(_truncate(_truncate(_rawPrice * _balance * _collateral.ltv)));
      // increase the ltv of the vault by the token value
      _borrowPower += _tokenValue;
    }
  }

  /// @notice Returns the borrowing power of a vault without making state changes
  /// @param _vault The vault to get the borrowing power of
  /// @return _borrowPower The borrowing power of the vault
  //solhint-disable-next-line code-complexity
  function _peekVaultBorrowingPower(IVault _vault) private view returns (uint192 _borrowPower) {
    // loop over each registed token, adding the indivuduals ltv to the total ltv of the vault
    for (uint192 _i; _i < enabledTokens.length; ++_i) {
      CollateralInfo memory _collateral = tokenAddressCollateralInfo[enabledTokens[_i]];
      // if the ltv is 0, continue
      if (_collateral.ltv == 0) continue;
      // get the address of the token through the array of enabled tokens
      // note that index 0 of enabledTokens corresponds to a vaultId of 1, so we must subtract 1 from i to get the correct index
      address _tokenAddress = enabledTokens[_i];
      // the balance is the vault's token balance of the current collateral token in the loop
      uint256 _balance = _vault.balances(_tokenAddress);
      if (_balance == 0) continue;
      // the raw price is simply the oracle price of the token
      uint192 _rawPrice = _safeu192(_collateral.oracle.peekValue());
      if (_rawPrice == 0) continue;
      // the token value is equal to the price * balance * tokenLTV
      uint192 _tokenValue = _safeu192(_truncate(_truncate(_rawPrice * _balance * _collateral.ltv)));
      // increase the ltv of the vault by the token value
      _borrowPower += _tokenValue;
    }
  }

  /// @notice Returns the increase amount of the interest factor. Accrues interest to borrowers and distribute it to USDA holders
  /// @dev Implementation in payInterest
  /// @return _interest The increase amount of the interest factor
  function calculateInterest() external override returns (uint256 _interest) {
    _interest = _payInterest();
  }

  /// @notice Accrue interest to borrowers and distribute it to USDA holders.
  /// @dev This function is called before any function that changes the reserve ratio
  /// @return _interest The interest to distribute to USDA holders
  function _payInterest() private returns (uint256 _interest) {
    // calculate the time difference between the current block and the last time the block was called
    uint64 _timeDifference = uint64(block.timestamp) - interest.lastTime;
    // if the time difference is 0, there is no interest. this saves gas in the case that
    // if multiple users call interest paying functions in the same block
    if (_timeDifference == 0) return 0;
    // the current reserve ratio, cast to a uint256
    uint256 _ui18 = uint256(usda.reserveRatio());
    // cast the reserve ratio now to an int in order to get a curve value
    int256 _reserveRatio = int256(_ui18);
    // calculate the value at the curve. this vault controller is a USDA vault and will reference
    // the vault at address 0
    int256 _intCurveVal = curveMaster.getValueAt(address(0x00), _reserveRatio);
    // cast the integer curve value to a u192
    uint192 _curveVal = _safeu192(uint256(_intCurveVal));
    // calculate the amount of total outstanding loans before and after this interest accrual
    // first calculate how much the interest factor should increase by
    // this is equal to (timedifference * (curve value) / (seconds in a year)) * (interest factor)
    uint192 _e18FactorIncrease = _safeu192(
      _truncate(
        _truncate((uint256(_timeDifference) * uint256(1e18) * uint256(_curveVal)) / (365 days + 6 hours))
          * uint256(interest.factor)
      )
    );
    // get the total outstanding value before we increase the interest factor
    uint192 _valueBefore = _safeu192(_truncate(uint256(totalBaseLiability) * uint256(interest.factor)));
    // interest is a struct which contains the last timestamp and the current interest factor
    // set the value of this struct to a struct containing {(current block timestamp), (interest factor + increase)}
    // this should save ~5000 gas/call
    interest = Interest(uint64(block.timestamp), interest.factor + _e18FactorIncrease);
    // using that new value, calculate the new total outstanding value
    uint192 _valueAfter = _safeu192(_truncate(uint256(totalBaseLiability) * uint256(interest.factor)));
    // valueAfter - valueBefore is now equal to the true amount of interest accured
    // this mitigates rounding errors
    // the protocol's fee amount is equal to this value multiplied by the protocol fee percentage, 1e18=100%
    uint192 _protocolAmount = _safeu192(_truncate(uint256(_valueAfter - _valueBefore) * uint256(protocolFee)));
    // donate the true amount of interest less the amount which the protocol is taking for itself
    // this donation is what pays out interest to USDA holders
    usda.vaultControllerDonate(_valueAfter - _valueBefore - _protocolAmount);
    // send the protocol's fee to the owner of this contract.
    usda.vaultControllerMint(owner(), _protocolAmount);
    // emit the event
    emit InterestEvent(uint64(block.timestamp), _e18FactorIncrease, _curveVal);
    // return the interest factor increase
    _interest = _e18FactorIncrease;
  }

  /// @notice Deploys a new Vault
  /// @param _id The id of the vault
  /// @param _minter The address of the minter of the vault
  /// @return _vault The vault that was created
  function _createVault(uint96 _id, address _minter) internal virtual returns (address _vault) {
    _vault = address(VAULT_DEPLOYER.deployVault(_id, _minter));
  }

  /// @notice Returns the status of a range of vaults
  /// @dev Special view only function to help liquidators
  /// @param _start The id of the vault to start looping
  /// @param _stop The id of vault to stop looping
  /// @return _vaultSummaries An array of vault information
  function vaultSummaries(
    uint96 _start,
    uint96 _stop
  ) public view override returns (VaultSummary[] memory _vaultSummaries) {
    if (_stop > vaultsMinted) _stop = vaultsMinted;
    _vaultSummaries = new VaultSummary[](_stop - _start + 1);
    for (uint96 _i = _start; _i <= _stop;) {
      IVault _vault = _getVault(_i);
      uint256[] memory _tokenBalances = new uint256[](enabledTokens.length);

      for (uint256 _j; _j < enabledTokens.length;) {
        _tokenBalances[_j] = _vault.balances(enabledTokens[_j]);

        unchecked {
          ++_j;
        }
      }
      _vaultSummaries[_i - _start] =
        VaultSummary(_i, _peekVaultBorrowingPower(_vault), this.vaultLiability(_i), enabledTokens, _tokenBalances);

      unchecked {
        ++_i;
      }
    }
  }

  /// @notice Modifies the total deposited in the protocol
  function _modifyTotalDeposited(uint256 _amount, address _token, bool _increase) internal {
    CollateralInfo memory _collateral = tokenAddressCollateralInfo[_token];
    if (_collateral.tokenId == 0) revert VaultController_TokenNotRegistered();
    if (_increase && (_collateral.totalDeposited + _amount) > _collateral.cap) revert VaultController_CapReached();

    tokenAddressCollateralInfo[_token].totalDeposited =
      _increase ? _collateral.totalDeposited + _amount : _collateral.totalDeposited - _amount;
  }

  /// @notice External function used by vaults to increase or decrease the `totalDeposited`.
  /// @dev Should only be called by a valid vault
  /// @param _vaultID The id of vault which is calling (used to verify)
  /// @param _amount The amount to modify
  /// @param _token The token address which should modify the total
  /// @param _increase Boolean that indicates if should increase or decrease (TRUE -> increase, FALSE -> decrease)
  function modifyTotalDeposited(uint96 _vaultID, uint256 _amount, address _token, bool _increase) external override {
    if (_msgSender() != vaultIdVaultAddress[_vaultID]) revert VaultController_NotValidVault();
    _modifyTotalDeposited(_amount, _token, _increase);
  }
}