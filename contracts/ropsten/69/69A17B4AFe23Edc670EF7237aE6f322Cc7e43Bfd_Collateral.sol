// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./interfaces/ICollateral.sol";
import "./interfaces/IStrategyController.sol";
import "./interfaces/IHook.sol";
import "./openzeppelin/ERC20UpgradeableRenameable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract Collateral is
  ICollateral,
  ERC20UpgradeableRenameable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bool private _depositsAllowed;
  bool private _withdrawalsAllowed;
  address private _treasury;
  uint256 private _mintingFee;
  uint256 private _redemptionFee;
  IERC20Upgradeable private _baseToken;
  IStrategyController private _strategyController;

  uint256 private _delayedWithdrawalExpiry;
  mapping(address => WithdrawalRequest) private _accountToWithdrawalRequest;

  IHook private _depositHook;
  IHook private _withdrawHook;

  uint256 private constant FEE_DENOMINATOR = 1000000;
  uint256 private constant FEE_LIMIT = 50000;

  function initialize(address _newBaseToken, address _newTreasury) public initializer {
    __Ownable_init_unchained();
    __ReentrancyGuard_init_unchained();
    __ERC20_init_unchained(string("prePO Collateral Token"), string("preCT"));
    _baseToken = IERC20Upgradeable(_newBaseToken);
    _treasury = _newTreasury;
  }

  function deposit(uint256 _amount) external override nonReentrant returns (uint256) {
    require(_depositsAllowed, "Deposits not allowed");
    _baseToken.safeTransferFrom(msg.sender, address(this), _amount);
    // Calculate fees and shares to mint including latent contract funds
    uint256 _amountToDeposit = _baseToken.balanceOf(address(this));
    // Record deposit before fee is taken
    if (address(_depositHook) != address(0)) {
      _depositHook.hook(msg.sender, _amount, _amountToDeposit);
    }
    /**
     * Add 1 to avoid rounding to zero, only process deposit if user is
     * depositing an amount large enough to pay a fee.
     */
    uint256 _fee = (_amountToDeposit * _mintingFee) / FEE_DENOMINATOR + 1;
    require(_amountToDeposit > _fee, "Deposit amount too small");
    _baseToken.safeTransfer(_treasury, _fee);
    unchecked {
      _amountToDeposit -= _fee;
    }

    uint256 _valueBefore = _strategyController.totalValue();
    _baseToken.approve(address(_strategyController), _amountToDeposit);
    _strategyController.deposit(_amountToDeposit);
    uint256 _valueAfter = _strategyController.totalValue();
    _amountToDeposit = _valueAfter - _valueBefore;

    uint256 _shares = 0;
    if (totalSupply() == 0) {
      _shares = _amountToDeposit;
    } else {
      /**
       * # of shares owed = amount deposited / cost per share, cost per
       * share = total supply / total value.
       */
      _shares = (_amountToDeposit * totalSupply()) / (_valueBefore);
    }
    _mint(msg.sender, _shares);
    return _shares;
  }

  function initiateWithdrawal(uint256 _amount) external override {
    /**
     * Checking the balance before initiation is necessary since a user
     * could initiate an unlimited withdrawal amount ahead of time,
     * negating the protection a delayed withdrawal offers.
     */
    require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
    _accountToWithdrawalRequest[msg.sender].amount = _amount;
    _accountToWithdrawalRequest[msg.sender].blockNumber = block.number;
  }

  function uninitiateWithdrawal() external override {
    _accountToWithdrawalRequest[msg.sender].amount = 0;
    _accountToWithdrawalRequest[msg.sender].blockNumber = 0;
  }

  function _processDelayedWithdrawal(address _account, uint256 _amount) internal {
    /**
     * Verify that the withdrawal being processed matches what was
     * recorded during initiation.
     */
    require(
      _accountToWithdrawalRequest[_account].amount == _amount,
      "Initiated amount does not match"
    );
    uint256 _recordedBlock = _accountToWithdrawalRequest[_account].blockNumber;
    require(
      _recordedBlock + _delayedWithdrawalExpiry >= block.number,
      "Must withdraw before expiry"
    );
    require(block.number > _recordedBlock, "Must withdraw in a later block");
    // Reset the initiation prior to withdrawal.
    _accountToWithdrawalRequest[_account].amount = 0;
    _accountToWithdrawalRequest[_account].blockNumber = 0;
  }

  function withdraw(uint256 _amount) external override nonReentrant returns (uint256) {
    require(_withdrawalsAllowed, "Withdrawals not allowed");
    if (_delayedWithdrawalExpiry != 0) {
      _processDelayedWithdrawal(msg.sender, _amount);
    }
    uint256 _owed = (_strategyController.totalValue() * _amount) / totalSupply();
    _burn(msg.sender, _amount);

    uint256 _balanceBefore = _baseToken.balanceOf(address(this));
    _strategyController.withdraw(address(this), _owed);
    uint256 _balanceAfter = _baseToken.balanceOf(address(this));

    uint256 _amountWithdrawn = _balanceAfter - _balanceBefore;
    // Record withdrawal before fee is taken
    if (address(_withdrawHook) != address(0)) {
      _withdrawHook.hook(msg.sender, _amount, _amountWithdrawn);
    }

    /**
     * Send redemption fee to the protocol treasury. Add 1 to avoid
     * rounding to zero, only process withdrawal if user is
     * withdrawing an amount large enough to pay a fee.
     */
    uint256 _fee = (_amountWithdrawn * _redemptionFee) / FEE_DENOMINATOR + 1;
    require(_amountWithdrawn > _fee, "Withdrawal amount too small");
    _baseToken.safeTransfer(_treasury, _fee);
    unchecked {
      _amountWithdrawn -= _fee;
    }
    _baseToken.safeTransfer(msg.sender, _amountWithdrawn);
    return _amountWithdrawn;
  }

  function setName(string memory _newName) external onlyOwner {
    _setName(_newName);
  }

  function setSymbol(string memory _newSymbol) external onlyOwner {
    _setSymbol(_newSymbol);
  }

  function setDepositsAllowed(bool _allowed) external override onlyOwner {
    _depositsAllowed = _allowed;
    emit DepositsAllowedChanged(_allowed);
  }

  function setWithdrawalsAllowed(bool _allowed) external override onlyOwner {
    _withdrawalsAllowed = _allowed;
    emit WithdrawalsAllowedChanged(_allowed);
  }

  function setStrategyController(IStrategyController _newStrategyController)
    external
    override
    onlyOwner
  {
    _strategyController = _newStrategyController;
    emit StrategyControllerChanged(address(_strategyController));
  }

  function setDelayedWithdrawalExpiry(uint256 _newDelayedWithdrawalExpiry)
    external
    override
    onlyOwner
  {
    _delayedWithdrawalExpiry = _newDelayedWithdrawalExpiry;
    emit DelayedWithdrawalExpiryChanged(_delayedWithdrawalExpiry);
  }

  function setMintingFee(uint256 _newMintingFee) external override onlyOwner {
    require(_newMintingFee <= FEE_LIMIT, "Exceeds fee limit");
    _mintingFee = _newMintingFee;
    emit MintingFeeChanged(_mintingFee);
  }

  function setRedemptionFee(uint256 _newRedemptionFee) external override onlyOwner {
    require(_newRedemptionFee <= FEE_LIMIT, "Exceeds fee limit");
    _redemptionFee = _newRedemptionFee;
    emit RedemptionFeeChanged(_redemptionFee);
  }

  function setDepositHook(IHook _newDepositHook) external override onlyOwner {
    _depositHook = _newDepositHook;
    emit DepositHookChanged(address(_depositHook));
  }

  function setWithdrawHook(IHook _newWithdrawHook) external override onlyOwner {
    _withdrawHook = _newWithdrawHook;
    emit WithdrawHookChanged(address(_withdrawHook));
  }

  function getDepositsAllowed() external view override returns (bool) {
    return _depositsAllowed;
  }

  function getWithdrawalsAllowed() external view override returns (bool) {
    return _withdrawalsAllowed;
  }

  function getTreasury() external view override returns (address) {
    return _treasury;
  }

  function getMintingFee() external view override returns (uint256) {
    return _mintingFee;
  }

  function getRedemptionFee() external view override returns (uint256) {
    return _redemptionFee;
  }

  function getBaseToken() external view override returns (IERC20Upgradeable) {
    return _baseToken;
  }

  function getStrategyController() external view override returns (IStrategyController) {
    return _strategyController;
  }

  function getDelayedWithdrawalExpiry() external view override returns (uint256) {
    return _delayedWithdrawalExpiry;
  }

  function getWithdrawalRequest(address _account)
    external
    view
    override
    returns (WithdrawalRequest memory)
  {
    return _accountToWithdrawalRequest[_account];
  }

  function getDepositHook() external view override returns (IHook) {
    return _depositHook;
  }

  function getWithdrawHook() external view override returns (IHook) {
    return _withdrawHook;
  }

  function getAmountForShares(uint256 _shares) external view override returns (uint256) {
    if (totalSupply() == 0) {
      return _shares;
    }
    return (_shares * totalAssets()) / totalSupply();
  }

  function getSharesForAmount(uint256 _amount) external view override returns (uint256) {
    uint256 _totalAssets = totalAssets();
    return (_totalAssets > 0) ? ((_amount * totalSupply()) / _totalAssets) : 0;
  }

  function getFeeDenominator() external pure override returns (uint256) {
    return FEE_DENOMINATOR;
  }

  function getFeeLimit() external pure override returns (uint256) {
    return FEE_LIMIT;
  }

  function totalAssets() public view override returns (uint256) {
    return _baseToken.balanceOf(address(this)) + _strategyController.totalValue();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./IHook.sol";
import "./IStrategyController.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @notice Used for minting and redeeming prePO Collateral tokens. A
 * Collateral token is a share of a yield-bearing vault, its Base Token value
 * varying based on the current value of the vault's assets.
 */
interface ICollateral is IERC20Upgradeable {
  /**
   * @notice Used to keep track of whether or not a user has initiated a
   * withdrawal in a block prior to calling withdraw().
   * @member amount The requested amount of Collateral to withdraw.
   * @member blockNumber The block in which the request was made.
   */
  struct WithdrawalRequest {
    uint256 amount;
    uint256 blockNumber;
  }

  /// @dev Emitted via `setName()`.
  /// @param name Token name
  event NameChanged(string name);

  /// @dev Emitted via `setSymbol()`.
  /// @param symbol Token symbol
  event SymbolChanged(string symbol);

  /// @dev Emitted via `setDepositsAllowed()`.
  /// @param allowed Whether deposits are allowed
  event DepositsAllowedChanged(bool allowed);

  /// @dev Emitted via `setWithdrawalsAllowed()`.
  /// @param allowed Whether withdrawals are allowed
  event WithdrawalsAllowedChanged(bool allowed);

  /// @dev Emitted via `setStrategyController()`.
  /// @param controller The address of the new Strategy Controller
  event StrategyControllerChanged(address controller);

  /// @dev Emitted via `setMintingFee()`.
  /// @param fee The new fee
  event MintingFeeChanged(uint256 fee);

  /// @dev Emitted via `setRedemptionFee()`.
  /// @param fee The new fee
  event RedemptionFeeChanged(uint256 fee);

  /// @dev Emitted via `setDelayedWithdrawal()`.
  /// @param enabled Whether or not delayed withdrawals are enabled
  event DelayedWithdrawalChanged(bool enabled);

  /// @dev Emitted via `setDelayedWithdrawalExpiry()`.
  /// @param expiry The new expiry
  event DelayedWithdrawalExpiryChanged(uint256 expiry);

  /// @dev Emitted via `setDepositHook()`.
  /// @param hook The new deposit hook
  event DepositHookChanged(address hook);

  /// @dev Emitted via `setWithdrawalHook()`.
  /// @param hook The new withdraw hook
  event WithdrawHookChanged(address hook);

  /**
   * @notice Mints Collateral tokens for `amount` Base Token.
   * @dev Assumes approval has been given by the user for the
   * Collateral contract to spend their funds.
   * @param amount The amount of Base Token to deposit
   * @return The amount of Collateral minted
   */
  function deposit(uint256 amount) external returns (uint256);

  /**
   * @notice Creates a request to allow a withdrawal for `amount` Collateral
   * in a later block.
   * @dev The user's balance must be >= the amount requested to
   * initiate a withdrawal. If this function is called when there is already
   * an existing withdrawal request, the existing request is overwritten
   * with the new `amount` and current block number.
   * @param amount The amount of Collateral to withdraw
   */
  function initiateWithdrawal(uint256 amount) external;

  /**
   * @notice Resets the existing withdrawal request on record for the caller.
   * @dev This call will not revert if a user doesn't have an existing
   * request and will simply reset the user's already empty request record.
   */
  function uninitiateWithdrawal() external;

  /**
   * @notice Burns `amount` Collateral tokens in exchange for Base Token.
   * @dev If `delayedWithdrawalExpiry` is non-zero, a withdrawal request
   * must be initiated in a prior block no more than
   * `delayedWithdrawalExpiry` blocks before. The amount specified in the
   * request must match the amount being withdrawn.
   * @param amount The amount of Collateral to burn
   * @return Amount of Base Token withdrawn
   */
  function withdraw(uint256 amount) external returns (uint256);

  /**
   * @notice Sets whether deposits to the Collateral vault are allowed.
   * @dev Only callable by `owner()`.
   * @param allowed Whether deposits are allowed
   */
  function setDepositsAllowed(bool allowed) external;

  /**
   * @notice Sets whether withdrawals from the Collateral vault are allowed.
   * @dev Only callable by `owner()`.
   * @param allowed Whether withdrawals are allowed
   */
  function setWithdrawalsAllowed(bool allowed) external;

  /**
   * @notice Sets the contract that controls which strategy funds are sent
   * to.
   * @dev Only callable by `owner()`.
   * @param newController Address of a contract implementing `IStrategyController`
   */
  function setStrategyController(IStrategyController newController) external;

  /**
   * @notice Sets the number of blocks to pass before expiring a withdrawal
   * request.
   * @dev If this is set to zero, withdrawal requests are ignored.
   *
   * Only callable by `owner()`.
   * @param expiry Blocks before expiring a withdrawal request
   */
  function setDelayedWithdrawalExpiry(uint256 expiry) external;

  /**
   * @notice Sets the fee for minting Collateral, must be a 4 decimal place
   * percentage value e.g. 4.9999% = 49999.
   * @dev Only callable by `owner()`.
   * @param newMintingFee The new fee for minting Collateral
   */
  function setMintingFee(uint256 newMintingFee) external;

  /**
   * @notice Sets the fee for redeeming Collateral, must be a 4 decimal place
   * percentage value e.g. 4.9999% = 49999.
   * @dev Only callable by `owner()`.
   * @param newRedemptionFee The new fee for redeeming Collateral
   */
  function setRedemptionFee(uint256 newRedemptionFee) external;

  /**
   * @notice Sets the contract implementing `IHook` that will be called
   * during the `deposit()` function.
   * @dev Only callable by `owner()`.
   * @param newDepositHook Address of a contract implementing `IHook`
   */
  function setDepositHook(IHook newDepositHook) external;

  /**
   * @notice Sets the contract implementing `IHook` that will be called
   * during the `withdraw()` function.
   * @dev Only callable by `owner()`.
   * @param newWithdrawHook Address of a contract implementing `IHook`
   */
  function setWithdrawHook(IHook newWithdrawHook) external;

  /// @return Whether deposits are allowed
  function getDepositsAllowed() external view returns (bool);

  /// @return Whether withdrawals are allowed
  function getWithdrawalsAllowed() external view returns (bool);

  /// @return Address where fees are sent to
  function getTreasury() external view returns (address);

  /**
   * @return Fee for minting Collateral
   * @dev Fee has four decimals places of percentage value precision
   * e.g. 4.9999% = 49999.
   */
  function getMintingFee() external view returns (uint256);

  /**
   * @return Fee for redeeming Collateral
   * @dev Fee has four decimals places of percentage value precision
   * e.g. 4.9999% = 49999.
   */
  function getRedemptionFee() external view returns (uint256);

  /**
   * @notice This asset will be required for minting Collateral, and
   * returned when redeeming Collateral.
   * @return The ERC20 token backing Collateral shares
   */
  function getBaseToken() external view returns (IERC20Upgradeable);

  /**
   * @notice The Strategy Controller intermediates any interactions between
   * this vault and a yield-earning strategy.
   * @return The current Strategy Controller
   */
  function getStrategyController() external view returns (IStrategyController);

  /**
   * @return Blocks that can pass before a withdrawal request expires
   */
  function getDelayedWithdrawalExpiry() external view returns (uint256);

  /// @return The withdrawal request on record for `account`
  function getWithdrawalRequest(address account) external view returns (WithdrawalRequest memory);

  /**
   * @return The `IHook` that runs during the `deposit()` function
   */
  function getDepositHook() external view returns (IHook);

  /**
   * @return The `IHook` that runs during the `withdraw()` function
   */
  function getWithdrawHook() external view returns (IHook);

  /**
   * @notice Gets the amount of Base Token received for redeeming `shares`
   * Collateral.
   * @param shares Amount of shares that would be redeemed
   * @return Amount of Base Token received
   */
  function getAmountForShares(uint256 shares) external view returns (uint256);

  /// @param amount Amount of Base Token that would be deposited
  /// @return Shares received for depositing `amount` Base Token
  function getSharesForAmount(uint256 amount) external view returns (uint256);

  /**
   * @notice Returns the sum of the contract's latent Base Token balance and
   * the estimated Base Token value of the strategy's assets.
   * @dev This call relies on the `totalValue()` returned by the
   * Strategy Controller. The Collateral vault trusts the Strategy Controller
   * to relay an accurate value of the Strategy's assets.
   * @return Total assets denominated in Base Token
   */
  function totalAssets() external view returns (uint256);

  /**
   * @notice Returns the denominator for calculating fees from 4 decimal
   * place percentage values e.g. 4.9999% = 49999.
   * @return Denominator
   */
  function getFeeDenominator() external pure returns (uint256);

  /**
   * @notice Returns the fee limit of 5% represented as 4 decimal place
   * percentage value e.g. 4.9999% = 49999.
   * @return Fee limit
   */
  function getFeeLimit() external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./IStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Strategy Controller acts as an intermediary between the Strategy
 * and the PrePO Collateral contract.
 *
 * The Collateral contract should never interact with the Strategy directly
 * and only perform operations via the Strategy Controller.
 */
interface IStrategyController {
  /// @dev Emitted via `setVault()`.
  /// @param vault The new vault address
  event VaultChanged(address vault);

  /// @dev Emitted via `migrate()`.
  /// @param oldStrategy The old strategy address
  /// @param newStrategy The new strategy address
  /// @param amount The amount migrated
  event StrategyMigrated(address oldStrategy, address newStrategy, uint256 amount);

  /**
   * @notice Deposits the specified amount of Base Token into the Strategy.
   * @dev Only the vault (Collateral contract) may call this function.
   *
   * Assumes approval to transfer amount from the Collateral contract
   * has been given.
   * @param amount Amount of Base Token to deposit
   */
  function deposit(uint256 amount) external;

  /**
   * @notice Withdraws the requested amount of Base Token from the Strategy
   * to the recipient.
   * @dev Only the vault (Collateral contract) may call this function.
   *
   * This withdrawal is optimistic, returned amount might be less than
   * the amount specified.
   * @param amount Amount of Base Token to withdraw
   * @param recipient Address to receive the Base Token
   */
  function withdraw(address recipient, uint256 amount) external;

  /**
   * @notice Migrates funds from currently configured Strategy to a new
   * Strategy and replaces it.
   * @dev If a Strategy is not already set, it sets the Controller's
   * Strategy to the new value with no funds being exchanged.
   *
   * Gives infinite Base Token approval to the new strategy and sets it
   * to zero for the old one.
   *
   * Only callable by `owner()`.
   * @param newStrategy Address of the new Strategy
   */
  function migrate(IStrategy newStrategy) external;

  /**
   * @notice Sets the vault that is allowed to deposit/withdraw through this
   * StrategyController.
   * @dev Only callable by `owner()`.
   * @param newVault Address of the new vault
   */
  function setVault(address newVault) external;

  /**
   * @notice Returns the Base Token balance of this contract and the
   * `totalValue()` returned by the Strategy.
   * @return The total value of assets within the strategy
   */
  function totalValue() external view returns (uint256);

  /**
   * @notice Returns the vault that is allowed to deposit/withdraw through
   * this Strategy Controller.
   * @return The vault address
   */
  function getVault() external view returns (address);

  /**
   * @notice Returns the ERC20 asset that this Strategy Controller supports
   * handling funds with.
   * @return The Base Token address
   */
  function getBaseToken() external view returns (IERC20);

  /**
   * @return The Strategy that this Strategy Controller manages
   */
  function getStrategy() external view returns (IStrategy);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

/// @notice Used for adding additional checks and/or data recording when
/// interacting with the Collateral vault.
interface IHook {
  /**
   * @dev Emitted via `setVault()`.
   * @param vault The new vault address
   */
  event VaultChanged(address vault);

  /**
   * @dev This hook should only contain calls to external contracts, where
   * the actual implementation and state of a feature will reside.
   *
   * `initialAmount` for `deposit()` and `withdraw()` is the `amount`
   * parameter passed in by the caller.
   *
   * `finalAmount` for `deposit()` is the Base Token amount provided by
   * the user and any latent contract balance that is included in the
   * deposit.
   *
   * `finalAmount` for `withdraw()` is the Base Token amount returned
   * by the configured Strategy.
   *
   * Only callable by the vault.
   * @param sender The account calling the Collateral vault
   * @param initialAmount The amount passed to the Collateral vault
   * @param finalAmount The amount actually involved in the transaction
   */
  function hook(
    address sender,
    uint256 initialAmount,
    uint256 finalAmount
  ) external;

  /**
   * @notice Sets the vault that will be allowed to call this hook.
   * @dev Only callable by owner().
   * @param newVault The vault address
   */
  function setVault(address newVault) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity =0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * Modifications from OpenZeppelin's ERC20Upgradeable contract: added internal
 * methods '_setName' and '_setSymbol' to allow changing the name and symbol.
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
contract ERC20UpgradeableRenameable is
  Initializable,
  ContextUpgradeable,
  IERC20Upgradeable,
  IERC20MetadataUpgradeable
{
  event NameChange(string name);
  event SymbolChange(string symbol);

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
   */
  function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
    __Context_init_unchained();
    __ERC20_init_unchained(name_, symbol_);
  }

  function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
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

  function _setName(string memory _newName) internal virtual {
    _name = _newName;
    emit NameChange(_newName);
  }

  function _setSymbol(string memory _newSymbol) internal virtual {
    _symbol = _newSymbol;
    emit SymbolChange(_newSymbol);
  }

  uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./IStrategyController.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Strategy that deploys Base Token to earn yield denominated in Base
 * Token.
 * @dev `owner()` can call emergency functions and setters, only controller
 * can call deposit/withdraw.
 */
interface IStrategy {
  /**
   * @notice Deposits `amount` Base Token into the strategy.
   * @dev Assumes the StrategyController has given infinite spend approval
   * to the strategy.
   * @param amount Amount of Base Token to deposit
   */
  function deposit(uint256 amount) external;

  /**
   * @notice Withdraws `amount` Base Token from the strategy to `recipient`.
   * @dev This withdrawal is optimistic, returned amount might be less than
   * the amount specified.
   * @param recipient Address to receive the Base Token
   * @param amount Amount of Base Token to withdraw
   */
  function withdraw(address recipient, uint256 amount) external;

  /**
   * @notice Returns the Base Token balance of this contract and
   * the estimated value of deployed assets.
   * @return Total value of assets within the strategy
   */
  function totalValue() external view returns (uint256);

  /**
   * @notice Returns the Strategy Controller that intermediates interactions
   * between a vault and this strategy.
   * @dev Functions with the `onlyController` modifier can only be called by
   * this Strategy Controller.
   * @return The Strategy Controller address
   */
  function getController() external view returns (IStrategyController);

  /**
   * @notice The ERC20 asset that this strategy utilizes to earn yield and
   * return profits with.
   * @return The Base Token address
   */
  function getBaseToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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