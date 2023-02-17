// SPDX-License-Identifier: BUSL-1.1
// See bluejay.finance/license
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./LoanPool.sol";
import "./LoanPoolFactory.sol";
import "./CreditLineBase.sol";

contract LoanPoolViewer {
  error LoanPoolNotDeployed();

  function getLoanDetails(address pool, address owner)
    public
    view
    returns (
      bytes32 codeHash,
      uint256[33] memory uints,
      address[6] memory addresses,
      bytes[2] memory strings
    )
  {
    address viewerAddr = address(this);
    assembly {
      codeHash := extcodehash(viewerAddr)
    }
    LoanPool loanPool = LoanPool(pool);
    address factory = loanPool.deployer();
    if (!ILoanPoolFactory(factory).loanPoolDeployed(address(loanPool))) {
      revert LoanPoolNotDeployed();
    }

    ICreditLineBase creditLine = loanPool.creditLine();
    IERC20Metadata fundingAsset = IERC20Metadata(
      address(loanPool.fundingAsset())
    );

    uints = [
      loanPool.fundingStart(),
      loanPool.fundingEnd(),
      loanPool.minFundingRequired(),
      loanPool.drawdownPeriod(),
      loanPool.fees(),
      loanPool.totalSupply(),
      loanPool.repayments(owner),
      loanPool.balanceAvailable(owner),
      loanPool.shareOfPool(owner),
      loanPool.balanceOf(owner),
      creditLine.maxLimit(),
      creditLine.interestApr(),
      creditLine.lateFeeApr(),
      creditLine.paymentPeriod(),
      creditLine.loanTenureInPeriods(),
      creditLine.gracePeriod(),
      creditLine.principalBalance(),
      creditLine.interestBalance(),
      creditLine.totalPrincipalRepaid(),
      creditLine.totalInterestRepaid(),
      creditLine.additionalRepayment(),
      creditLine.lateInterestAccrued(),
      creditLine.interestAccruedAsOf(),
      creditLine.lastFullPaymentTime(),
      creditLine.minPaymentPerPeriod(),
      creditLine.loanStartTime(),
      creditLine.paymentDue(),
      creditLine.minPaymentForSchedule(),
      creditLine.totalRepayments(),
      uint256(creditLine.loanState()),
      fundingAsset.decimals(),
      fundingAsset.balanceOf(owner),
      fundingAsset.allowance(owner, pool)
    ];

    addresses = [
      factory,
      address(creditLine),
      getMinimalProxyTarget(address(creditLine)),
      address(fundingAsset),
      loanPool.borrower(),
      loanPool.feeRecipient()
    ];

    strings = [bytes(fundingAsset.name()), bytes(fundingAsset.symbol())];
  }

  function getMinimalProxyTarget(address proxy)
    public
    view
    returns (address targetAddr)
  {
    bytes memory target = new bytes(20);
    assembly {
      let size := 0x14
      extcodecopy(proxy, add(target, 0x20), 0x0A, size)
    }
    targetAddr = address(bytes20(target));
  }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

// SPDX-License-Identifier: BUSL-1.1
// See bluejay.finance/license
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./interfaces/ILoanPool.sol";

contract LoanPool is ILoanPool, ERC20Upgradeable, OwnableUpgradeable {
  using SafeERC20 for IERC20;

  uint256 constant WAD = 10**18;

  /// @notice CreditLine contract that this loan pool is using to account for the loan
  ICreditLineBase public override creditLine;

  /// @notice ERC20 token that is being used as the loan currency
  IERC20 public override fundingAsset;

  /// @notice Address of the pool factory if deployed & initialized by the factory
  address public override deployer;

  /// @notice Address of the borrower
  address public override borrower;

  /// @notice Address of the fee receiver
  address public override feeRecipient;

  /// @notice Timestamp the pool is accepting deposits, in unix epoch time
  uint256 public override fundingStart;

  /// @notice Timestamp the pool stops accepting deposits, in unix epoch time
  uint256 public override fundingEnd;

  /// @notice Minimum amount required when funding is closed for successful funding,
  /// in funding asset decimals
  uint256 public override minFundingRequired;

  /// @notice Duration after fundingEnd where drawdown can happen,
  /// or funds will be returned for inactive borrower, in seconds
  uint256 public override drawdownPeriod;

  /// @notice Fee for successful funding, in WAD
  uint256 public override fees;

  /// @notice Amount of assets repaid to individual lenders when they withdraw,
  /// in funding asset decimals
  mapping(address => uint256) public override repayments;

  modifier nonZero(uint256 _value) {
    if (_value == 0) revert ZeroAmount();
    _;
  }

  /// @notice Initialize the loan pool
  /// @param _creditLine CreditLine contract that this loan pool is using to account for the loan
  /// @param _fundingAsset ERC20 token that is being used as the loan currency
  /// @param _borrower Address of the borrower
  /// @param _feeRecipient Address of the fee receiver
  /// @param _uints Array of uints, in order:
  // _uints[0] _maxLimit Maximum amount of assets that can be borrowed, in asset's decimals
  // _uints[1] _interestApr Annual interest rate, in WAD
  // _uints[2] _paymentPeriod Length of each payment period, in seconds
  // _uints[3] _gracePeriod Length of the grace period (late fees is not applied), in seconds
  // _uints[4] _lateFeeApr Additional annual interest rate applied on late payments, in WAD
  // _uints[5] _loanTenureInPeriods Number of periods before the loan is due, in wei
  // _uints[6] _fundingStart Timestamp of the start of the funding period, in unix epoch time
  // _uints[7] _fundingPeriod Length of the funding period, in seconds
  // _uints[8] _minFundingRequired Minimum amount of funding required, in asset's decimals
  // _uints[9] _drawdownPeriod Length of the drawdown period before refund occurs, in seconds
  // _uints[10] _fee Fee for the loan, in WAD
  function initialize(
    ICreditLineBase _creditLine,
    IERC20 _fundingAsset,
    address _borrower,
    address _feeRecipient,
    uint256[11] calldata _uints // collapsing because of stack too deep
  ) public override initializer {
    __ERC20_init("LoanPool", "LP");
    _transferOwnership(_borrower);
    deployer = msg.sender;

    _creditLine.initialize(
      _uints[0],
      _uints[1],
      _uints[2],
      _uints[3],
      _uints[4],
      _uints[5]
    );

    creditLine = _creditLine;
    fundingAsset = _fundingAsset;
    borrower = _borrower;
    feeRecipient = _feeRecipient;
    fundingStart = _uints[6];
    fundingEnd = _uints[6] + _uints[7];
    minFundingRequired = _uints[8];
    drawdownPeriod = _uints[9];
    fees = _uints[10];
  }

  // =============================== BORROWER FUNCTIONS =================================

  /// @notice Drawdown funds raised on the loan pool as borrower and start the interest accrual
  function drawdown() public override onlyOwner {
    if (block.timestamp >= fundingEnd + drawdownPeriod)
      revert DrawdownPeriodEnded();

    uint256 loanAmount = creditLine.drawdown();
    if (loanAmount < minFundingRequired) revert MinimumFundingNotReached();
    fundingAsset.safeTransfer(borrower, loanAmount);

    uint256 successFees = totalSupply() - loanAmount;
    if (successFees > 0) {
      emit FeesCollected(borrower, feeRecipient, successFees);
      fundingAsset.safeTransfer(feeRecipient, successFees);
    }
    emit Drawndown(msg.sender, loanAmount);
  }

  /// @notice Repay funds to the loan pool as borrower
  /// @dev No access control applied to allow anyone to repay on behalf of the borrower
  /// @param amount Amount of funds to repay, in funding asset decimals
  function repay(uint256 amount) public override nonZero(amount) {
    fundingAsset.safeTransferFrom(msg.sender, address(this), amount);
    creditLine.repay(amount);
    emit Repay(msg.sender, amount);

    // In event that borrower repays more than needed, return excess to borrower
    uint256 additionalRepayment = creditLine.additionalRepayment();
    if (additionalRepayment > 0) {
      fundingAsset.safeTransfer(msg.sender, additionalRepayment);
      emit RefundAdditionalPayment(msg.sender, additionalRepayment);
    }
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Deposit funds into the loan pool as lender
  /// @param amount Amount of funds to deposit, in funding asset decimals
  /// @param recipient Address to credit the deposit to
  function fund(uint256 amount, address recipient)
    public
    override
    nonZero(amount)
  {
    if (block.timestamp < fundingStart) revert FundingPeriodNotStarted();
    if (block.timestamp > fundingEnd) revert FundingPeriodEnded();

    fundingAsset.safeTransferFrom(msg.sender, address(this), amount);
    creditLine.fund(amount - (amount * fees) / WAD);

    _mint(recipient, amount);
    emit Fund(msg.sender, recipient, amount);
  }

  /// @notice Withdraw funds from the loan pool as lender whenever loan is repaid
  /// @param amount Amount to withdraw, in funding asset decimals
  /// @param recipient Address to withdraw to
  function withdraw(uint256 amount, address recipient)
    public
    override
    nonZero(amount)
  {
    uint256 balance = balanceAvailable(msg.sender);
    if (amount > balance) revert InsufficientBalance();

    repayments[msg.sender] += amount;
    fundingAsset.safeTransfer(recipient, amount);
    emit Withdraw(msg.sender, recipient, amount);
  }

  /// @notice Mark the loan as refunding when funding period is over and minimum funding is not reached
  function refundMinimumNotMet() public override {
    if (block.timestamp <= fundingEnd) revert FundingPeriodNotEnded();
    if (creditLine.principalBalance() >= minFundingRequired)
      revert MinimumFundingReached();
    creditLine.refund();
    emit Refunded();
  }

  /// @notice Mark the loan as refunding when borrower does not drawdown in time
  function refundInactiveBorrower() public override {
    if (block.timestamp < fundingEnd + drawdownPeriod)
      revert DrawdownPeriodNotEnded();
    if (creditLine.loanState() != ICreditLineBase.State.Funding)
      revert NotFundingState();
    creditLine.refund();
    emit Refunded();
  }

  /// @notice Withdraw funds from the loan pool as lender when the pool is in refunding state
  function refund(address recipient) public override {
    if (creditLine.loanState() != ICreditLineBase.State.Refund)
      revert NotRefundState();
    uint256 amount = balanceOf(msg.sender);
    if (amount == 0) revert ZeroAmount();
    _burn(msg.sender, amount);
    fundingAsset.safeTransfer(recipient, amount);
    emit Refund(msg.sender, recipient, amount);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Get the amount of funds that a lender can withdraw from the loan pool
  /// @param account Address of the lender
  /// @return balance Amount of funds that can be withdrawn, in funding asset decimals
  function balanceAvailable(address account)
    public
    view
    override
    returns (uint256 balance)
  {
    uint256 totalRepayments = creditLine.totalRepayments();
    uint256 repaymentShare = (shareOfPool(account) * totalRepayments) / WAD;
    uint256 amountRepaid = repayments[account];
    balance = repaymentShare > amountRepaid ? repaymentShare - amountRepaid : 0;
  }

  /// @notice Get the share of the loan pool that a lender has
  /// @param account Address of the lender
  /// @return share Share of the loan pool, in WAD
  function shareOfPool(address account)
    public
    view
    override
    returns (uint256 share)
  {
    uint256 totalSupply = totalSupply();
    if (totalSupply == 0) return 0;
    share = (balanceOf(account) * WAD) / totalSupply;
  }

  /// @notice Get the number of decimals of the funding asset
  /// @dev This allow wallets to display the correct number of decimals
  function decimals() public view virtual override returns (uint8) {
    return IERC20Metadata(address(fundingAsset)).decimals();
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Disable transfer of the loan pool token
  /// @dev Enable transfer for unencumbered tokens only in future iterations
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256
  ) internal virtual override {
    if (from != address(0) && to != address(0)) revert TransferDisabled();
  }
}

// SPDX-License-Identifier: BUSL-1.1
// See bluejay.finance/license
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/ILoanPool.sol";
import "./interfaces/ICreditLineBase.sol";
import "./interfaces/ILoanPoolFactory.sol";

contract LoanPoolFactory is ILoanPoolFactory, AccessControl {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @notice Address of the fee recipient
  address public override feeRecipient;

  /// @notice Address of the loan pool template
  address public override loanPoolTemplate;

  /// @notice Credit line template that can be used with the factory
  mapping(address => bool) public override isCreditLineTemplate;

  /// @notice Fees for a particular fee tier, in WAD
  mapping(uint256 => uint256) public override feesForTier;

  /// @notice Fee tier for a particular asset
  mapping(address => uint256) public override feesTierForAsset;

  /// @notice Is a loan pool deployed by this factory contract
  mapping(address => bool) public override loanPoolDeployed;

  /// @notice Checks that the credit line template is registered
  /// @param template Address of the credit line template
  modifier onlyCreditLineTemplate(address template) {
    if (!isCreditLineTemplate[template])
      revert CreditLineTemplateNotRegistered();
    _;
  }

  /// @notice Constructor of the factory
  /// @param _feeRecipient Address of the fee recipient
  /// @param _loanPoolTemplate Address of the loan pool template
  /// @param _defaultFees Fees for the default fee tier
  constructor(
    address _feeRecipient,
    address _loanPoolTemplate,
    uint256 _defaultFees
  ) {
    feeRecipient = _feeRecipient;
    loanPoolTemplate = _loanPoolTemplate;
    feesForTier[0] = _defaultFees;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Creates a new loan pool
  /// @param creditLineTemplate Address of the credit line template
  /// @param fundingAsset Address of the asset used for the loan
  /// @param borrower Address of the borrower
  /// @param _uints Array of values to initialize the loan, see params for _createPool
  /// @return loanPool Address of the loan pool
  /// @return creditLine Address of the credit line
  function createPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[10] calldata _uints
  ) public override returns (ILoanPool loanPool, ICreditLineBase creditLine) {
    uint256 fee = feesOnAsset(fundingAsset);
    (loanPool, creditLine) = _createPool(
      creditLineTemplate,
      fundingAsset,
      borrower,
      [
        _uints[0],
        _uints[1],
        _uints[2],
        _uints[3],
        _uints[4],
        _uints[5],
        _uints[6],
        _uints[7],
        _uints[8],
        _uints[9],
        fee
      ]
    );
  }

  // =============================== MANAGERS FUNCTIONS =================================

  /// @notice Creates a new loan pool, with a custom fee, in WAD
  /// @param creditLineTemplate Address of the credit line template
  /// @param fundingAsset Address of the asset used for the loan
  /// @param borrower Address of the borrower
  /// @param _uints Array of values to initialize the loan, see params for _createPool
  /// @return loanPool Address of the loan pool
  /// @return creditLine Address of the credit line
  function createCustomPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[11] calldata _uints
  )
    public
    override
    onlyRole(MANAGER_ROLE)
    returns (ILoanPool loanPool, ICreditLineBase creditLine)
  {
    (loanPool, creditLine) = _createPool(
      creditLineTemplate,
      fundingAsset,
      borrower,
      _uints
    );
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function to create a new loan pool
  /// @param creditLineTemplate Address of the credit line template
  /// @param fundingAsset Address of the asset used for the loan
  /// @param borrower Address of the borrower
  /// @param _uints Array of values to initialize the loan
  // _uints[0] _maxLimit Maximum amount of assets that can be borrowed, in asset's decimals
  // _uints[1] _interestApr Annual interest rate, in WAD
  // _uints[2] _paymentPeriod Length of each payment period, in seconds
  // _uints[3] _gracePeriod Length of the grace period (late fees is not applied), in seconds
  // _uints[4] _lateFeeApr Additional annual interest rate applied on late payments, in WAD
  // _uints[5] _loanTenureInPeriods Number of periods before the loan is due, in wei
  // _uints[6] _fundingStart Timestamp of the start of the funding period, in unix epoch time
  // _uints[7] _fundingPeriod Length of the funding period, in seconds
  // _uints[8] _minFundingRequired Minimum amount of funding required, in asset's decimals
  // _uints[9] _drawdownPeriod Length of the drawdown period before refund occurs, in seconds
  // _uints[10] _fee Fee for the loan, in WAD
  /// @return loanPool Address of the loan pool
  /// @return creditLine Address of the credit line
  function _createPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[11] memory _uints
  )
    internal
    onlyCreditLineTemplate(creditLineTemplate)
    returns (ILoanPool loanPool, ICreditLineBase creditLine)
  {
    creditLine = ICreditLineBase(Clones.clone(creditLineTemplate));
    loanPool = ILoanPool(Clones.clone(loanPoolTemplate));
    loanPool.initialize(
      creditLine,
      IERC20(fundingAsset),
      borrower,
      feeRecipient,
      _uints
    );
    loanPoolDeployed[address(loanPool)] = true;
    emit LoanPoolCreated(
      address(loanPool),
      borrower,
      fundingAsset,
      creditLineTemplate,
      address(creditLine),
      _uints[0],
      _uints[10]
    );
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Add a new credit line template that determines the loan term
  /// @param _creditLine Address of the credit line template
  function addCreditLine(address _creditLine)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    isCreditLineTemplate[_creditLine] = true;
    emit UpdateCreditLineTemplate(_creditLine, true);
  }

  /// @notice Remove a credit line template
  /// @param _creditLine Address of the credit line template
  function removeCreditLine(address _creditLine)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    isCreditLineTemplate[_creditLine] = false;
    emit UpdateCreditLineTemplate(_creditLine, false);
  }

  /// @notice Set the fees for a given tier of assets
  /// @dev Tier 0 is the default for assets that did not get tagged explicitly
  /// @param tier Tier of the asset
  /// @param fee Fees, in WAD
  function setFeeTier(uint256 tier, uint256 fee)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    feesForTier[tier] = fee;
    emit UpdateFeeTier(tier, fee);
  }

  /// @notice Set the fee tier for a given asset
  /// @param asset Address of the asset
  /// @param tier Tier of the asset
  function setAssetFeeTier(address asset, uint256 tier)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    feesTierForAsset[asset] = tier;
    emit UpdateAssetFeeTier(asset, tier);
  }

  /// @notice Set the fee recipient
  /// @param _feeRecipient Address of the fee recipient
  function setFeeRecipient(address _feeRecipient)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    feeRecipient = _feeRecipient;
    emit UpdateFeeRecipient(_feeRecipient);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Get the fees applied on the loan for a given asset
  /// @param asset Address of the asset
  /// @return fee Fees, in WAD
  function feesOnAsset(address asset)
    public
    view
    override
    returns (uint256 fee)
  {
    fee = feesForTier[feesTierForAsset[asset]];
  }
}

// SPDX-License-Identifier: BUSL-1.1
// See bluejay.finance/license
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ICreditLineBase.sol";

/// @title CreditLineBase
/// @author Bluejay Core Team
/// @notice Base contract for credit line to perform bookeeping of the loan.
/// @dev The child contract should implement the logic to calculate `minPaymentPerPeriod` or
/// override `minPaymentAtTimestamp` for determination of late payments.
abstract contract CreditLineBase is
  ICreditLineBase,
  Initializable,
  OwnableUpgradeable
{
  uint256 constant WAD = 10**18;

  /// @notice Max amount that is allowed to be borrowed, in lending asset decimals
  uint256 public override maxLimit;

  /// @notice Annual interest rate of the loan, in WAD
  uint256 public override interestApr;

  /// @notice Annual interest rate when payment is late, in WAD
  /// Late interest is applied on the principal balance
  uint256 public override lateFeeApr;

  /// @notice Length of time between repayment, in seconds
  /// The first repayment will start at the first period after drawdown happens
  uint256 public override paymentPeriod;

  /// @notice Expected number of periods to repay the loan, in wei
  /// @dev All principal plus balance are due on the end of last period
  uint256 public override loanTenureInPeriods;

  /// @notice Time from a payment period where late interest is not charged, in seconds
  uint256 public override gracePeriod;

  /// @notice Amount of principal balance, in lending asset decimals
  uint256 public override principalBalance;

  /// @notice Amount of interest balance, in lending asset decimals
  /// @dev Does not account for additional interest that has been accrued since the last repayment
  uint256 public override interestBalance;

  /// @notice Cumulative sum of repayment towards principal, in lending asset decimals
  uint256 public override totalPrincipalRepaid;

  /// @notice Cumulative sum of repayment towards interest, in lending asset decimals
  uint256 public override totalInterestRepaid;

  /// @notice Additional repayments made on top of all principal and interest, in lending asset decimals
  /// @dev Additional repayments should be refunded to the borrower
  uint256 public override additionalRepayment;

  /// @notice Cumulative sum of late interest, in lending asset decimals
  /// @dev Value is used to adjust the payment schedule so that the expected repayment
  /// increases to ensure borrower can repay on schedule
  uint256 public override lateInterestAccrued;

  /// @notice Timestamp of the last time interest was accrued and updated, in unix epoch time
  /// @dev Value is always incremented as multiples of the `paymentPeriod`
  uint256 public override interestAccruedAsOf;

  /// @notice Timestamp of the last time full payment was made (ie not late), in unix epoch time
  uint256 public override lastFullPaymentTime;

  /// @notice Minimum amount of payment (principal and/or interest) expected each period, in lending asset decimals
  /// The value is not set until drawdown happens
  /// @dev This can be changed in child contract and/or when a drawdown happens. This is required when using
  /// this base implementation for `minPaymentAtTimestamp`.
  uint256 public override minPaymentPerPeriod;

  /// @notice Timestamp where interest calculation starts, in unix epoch time
  /// @dev This value is set during the drawdown of the loan
  uint256 public override loanStartTime;

  /// @notice State of the loan
  State public override loanState;

  /// @notice Check if the contract is in the correct loan state
  modifier onlyState(State state) {
    if (loanState != state) revert IncorrectState(state, loanState);
    _;
  }

  /// @notice Initialize the contract
  /// @dev Initializing does not immediately start the interest accrual
  /// @param _maxLimit Max amount that is allowed to be borrowed, in lending asset decimals
  /// @param _interestApr Annual interest rate of the loan, in WAD
  /// @param _paymentPeriod Length of time between repayment, in seconds
  /// @param _gracePeriod Time from a payment period where late interest is not charged, in seconds
  /// @param _lateFeeApr Annual interest rate when payment is late, in WAD
  /// @param _loanTenureInPeriods Expected number of periods to repay the loan, in wei
  function initialize(
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriod,
    uint256 _gracePeriod,
    uint256 _lateFeeApr,
    uint256 _loanTenureInPeriods
  ) public virtual override initializer {
    __Ownable_init();
    maxLimit = _maxLimit;
    interestApr = _interestApr;
    paymentPeriod = _paymentPeriod;
    gracePeriod = _gracePeriod;
    lateFeeApr = _lateFeeApr;
    loanTenureInPeriods = _loanTenureInPeriods;
    loanState = State.Funding;
    emit LoanStateUpdate(State.Funding);
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Account for funds received from lenders
  /// @param amount Amount of funds received, in lending asset decimals
  function fund(uint256 amount)
    public
    override
    onlyState(State.Funding)
    onlyOwner
  {
    if (principalBalance + amount > maxLimit) revert MaxLimitExceeded();
    principalBalance += amount;
  }

  /// @notice Drawdown the loan and start interest accrual
  /// @return amount Amount of funds drawn down, in lending asset decimals
  function drawdown()
    public
    override
    onlyState(State.Funding)
    onlyOwner
    returns (uint256 amount)
  {
    loanStartTime = block.timestamp;
    interestAccruedAsOf = block.timestamp;
    lastFullPaymentTime = block.timestamp;
    amount = principalBalance;

    loanState = State.Repayment;
    emit LoanStateUpdate(State.Repayment);

    _afterDrawdown();
  }

  /// @notice Mark the loan as refund state
  /// @dev Child contract should implement the logic to refund the loan
  function refund() public override onlyState(State.Funding) onlyOwner {
    loanState = State.Refund;
    emit LoanStateUpdate(State.Refund);
  }

  /// @notice Make repayment towards the loan
  /// @param amount Amount of repayment, in lending asset decimals
  /// @return interestPayment payment toward interest, in lending asset decimals
  /// @return principalPayment payment toward principal, in lending asset decimals
  /// @return additionalBalancePayment excess repayment, in lending asset decimals
  function repay(uint256 amount)
    public
    override
    onlyOwner
    onlyState(State.Repayment)
    returns (
      uint256 interestPayment,
      uint256 principalPayment,
      uint256 additionalBalancePayment
    )
  {
    // Update accounting variables
    _assess();

    // Apply payment to principal, interest, and additional payments
    (
      interestPayment,
      principalPayment,
      additionalBalancePayment
    ) = allocatePayment(amount, interestBalance, principalBalance);
    principalBalance -= principalPayment;
    interestBalance -= interestPayment;
    totalPrincipalRepaid += principalPayment;
    totalInterestRepaid += interestPayment;
    additionalRepayment += additionalBalancePayment;

    // Update lastFullPaymentTime if payment hits payment schedule
    if (totalPrincipalRepaid + totalInterestRepaid >= minPaymentForSchedule()) {
      lastFullPaymentTime = interestAccruedAsOf;
    }

    // Update state if loan is fully repaid
    if (principalBalance == 0) {
      loanState = State.Repaid;
      emit LoanStateUpdate(State.Repaid);
    }
    emit Repayment(
      block.timestamp,
      amount,
      interestPayment,
      principalPayment,
      additionalBalancePayment
    );
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Hook fired after drawdown
  /// @dev To implement logic for adjusting `minPaymentPerPeriod` after drawdown
  /// according to what is actually borrowed vs the max limit in the child contract
  function _afterDrawdown() internal virtual {}

  /// @notice Make adjustments interest and late interest since the last assessment
  function _assess() internal {
    (
      uint256 interestOwed,
      uint256 lateInterestOwed,
      uint256 fullPeriodsElapsed
    ) = interestAccruedSinceLastAssessed();

    // Make accounting adjustments
    interestBalance += interestOwed;
    interestBalance += lateInterestOwed;
    lateInterestAccrued += lateInterestOwed;
    interestAccruedAsOf += fullPeriodsElapsed * paymentPeriod;
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Split a payment into interest, principal, and additional balance
  /// @param amount Amount of payment, in lending asset decimals
  /// @param interestOutstanding Interest balance outstanding, in lending asset decimals
  /// @param principalOutstanding Principal balance outstanding, in lending asset decimals
  /// @return interestPayment payment toward interest, in lending asset decimals
  /// @return principalPayment payment toward principal, in lending asset decimals
  /// @return additionalBalancePayment excess repayment, in lending asset decimals
  function allocatePayment(
    uint256 amount,
    uint256 interestOutstanding,
    uint256 principalOutstanding
  )
    public
    pure
    override
    returns (
      uint256 interestPayment,
      uint256 principalPayment,
      uint256 additionalBalancePayment
    )
  {
    // Allocate to interest first
    interestPayment = amount >= interestOutstanding
      ? interestOutstanding
      : amount;
    amount -= interestPayment;

    // Allocate to principal next
    principalPayment = amount >= principalOutstanding
      ? principalOutstanding
      : amount;
    amount -= principalPayment;

    // Finally apply remaining as additional balance
    additionalBalancePayment = amount;
  }

  /// @notice Calculate the minimum amount of total repayment against the schedule
  /// @return amount Minimum amount, in lending asset decimals
  function minPaymentForSchedule()
    public
    view
    override
    returns (uint256 amount)
  {
    return minPaymentAtTimestamp(block.timestamp);
  }

  /// @notice Calculate the payment due now to avoid further late payment charges
  /// @return amount Payment due, in lending asset decimals
  function paymentDue() public view virtual override returns (uint256 amount) {
    amount = minPaymentAtTimestamp(block.timestamp);

    uint256 periodsElapsed = (block.timestamp - loanStartTime) / paymentPeriod;
    (
      uint256 interestOwed,
      uint256 lateInterestOwed,

    ) = interestAccruedAtTimestamp(block.timestamp);
    amount += lateInterestOwed;
    if (periodsElapsed >= loanTenureInPeriods) {
      // Need to add interest in final payment, since `minPaymentAtTimestamp`
      // assumes the interest has been added
      amount += interestOwed;
    }
    uint256 repaid = totalPrincipalRepaid + totalInterestRepaid;
    if (amount > repaid) {
      amount -= repaid;
    } else {
      amount = 0;
    }
  }

  /// @notice Calculate the minimum amount of total repayment against the schedule
  /// @dev Ensure `interestOwed` and `lateInterestOwed` is already accounted for as a precondition
  /// Child contract can override this to have different payment schedule
  /// @param timestamp Timestamp to calculate the minimum payment, in unix epoch time
  /// @return amount Minimum amount, in lending asset decimals
  function minPaymentAtTimestamp(uint256 timestamp)
    public
    view
    virtual
    override
    returns (uint256 amount)
  {
    if (timestamp <= loanStartTime) return 0;
    if (principalBalance == 0) return 0;
    uint256 periodsElapsed = (timestamp - loanStartTime) / paymentPeriod;
    if (periodsElapsed < loanTenureInPeriods) {
      amount = periodsElapsed * minPaymentPerPeriod + lateInterestAccrued;
    } else {
      amount =
        principalBalance +
        interestBalance +
        totalInterestRepaid +
        totalPrincipalRepaid;
    }
  }

  /// @notice Calculate the interest accrued since the last assessment
  /// @return interestOwed Regular interest accrued, in lending asset decimals
  /// @return lateInterestOwed Late interest accrued, in lending asset decimals
  /// @return fullPeriodsElapsed Number of full periods elapsed
  function interestAccruedSinceLastAssessed()
    public
    view
    override
    returns (
      uint256 interestOwed,
      uint256 lateInterestOwed,
      uint256 fullPeriodsElapsed
    )
  {
    return interestAccruedAtTimestamp(block.timestamp);
  }

  /// @notice Calculate the interest accrued at a given timestamp
  /// @return interestOwed Regular interest accrued, in lending asset decimals
  /// @return lateInterestOwed Late interest accrued, in lending asset decimals
  /// @return fullPeriodsElapsed Number of full periods elapsed
  function interestAccruedAtTimestamp(uint256 timestamp)
    public
    view
    override
    returns (
      uint256 interestOwed,
      uint256 lateInterestOwed,
      uint256 fullPeriodsElapsed
    )
  {
    if (principalBalance == 0) {
      return (interestOwed, lateInterestOwed, fullPeriodsElapsed);
    }
    // Calculate regular interest payments
    fullPeriodsElapsed = (timestamp - interestAccruedAsOf) / paymentPeriod;
    if (fullPeriodsElapsed == 0) {
      return (interestOwed, lateInterestOwed, fullPeriodsElapsed);
    }
    interestOwed += interestOnBalance(fullPeriodsElapsed * paymentPeriod);

    // Calculate late interest payments
    if (timestamp > lastFullPaymentTime + gracePeriod) {
      // Do not apply grace period, if last full payment was before period start
      uint256 latePeriodsElapsed = (
        lastFullPaymentTime < interestAccruedAsOf
          ? (timestamp - interestAccruedAsOf)
          : (timestamp - interestAccruedAsOf - gracePeriod)
      ) / paymentPeriod;
      lateInterestOwed += lateInterestOnBalance(
        latePeriodsElapsed * paymentPeriod
      );
    }
  }

  /// @notice Calculate the regular interest accrued on the principal balance
  /// @param period Period to calculate interest on, in seconds
  /// @return interestOwed Regular interest accrued, in lending asset decimals
  function interestOnBalance(uint256 period)
    public
    view
    override
    returns (uint256 interestOwed)
  {
    return (principalBalance * interestApr * period) / (365 days * WAD);
  }

  /// @notice Calculate the late interest accrued on the principal balance
  /// @param period Period to calculate interest on, in seconds
  /// @return interestOwed Late interest accrued, in lending asset decimals
  function lateInterestOnBalance(uint256 period)
    public
    view
    override
    returns (uint256 interestOwed)
  {
    return (principalBalance * lateFeeApr * period) / (365 days * WAD);
  }

  /// @notice Get the sum of all repayments made
  /// @return amount Total repayment, in lending asset decimals
  function totalRepayments() public view override returns (uint256 amount) {
    amount = totalPrincipalRepaid + totalInterestRepaid;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ICreditLineBase.sol";

interface ILoanPool {
  /// @notice Amount is zero
  error ZeroAmount();

  /// @notice Funding period has not started
  error FundingPeriodNotStarted();

  /// @notice Funding period has ended
  error FundingPeriodEnded();

  /// @notice Funding period has not ended
  error FundingPeriodNotEnded();

  /// @notice Minimum amount of funds has been raised
  error MinimumFundingReached();

  /// @notice Minimum amount of funds has not been raised
  error MinimumFundingNotReached();

  /// @notice Drawdown period has not ended
  error DrawdownPeriodNotEnded();

  /// @notice Drawdown period has ended
  error DrawdownPeriodEnded();

  /// @notice Loan is not in funding state
  error NotFundingState();

  /// @notice Insufficient balance for withdraw
  error InsufficientBalance();

  /// @notice Tokens cannot be transferred
  error TransferDisabled();

  /// @notice Loan is not in refund state
  error NotRefundState();

  /// @notice Funds have been deposited into the loan pool
  /// @param lender Address of the lender
  /// @param recipient Address where loan token is credited to
  /// @param amount Amount of funds deposited
  event Fund(address indexed lender, address indexed recipient, uint256 amount);

  /// @notice Lenders are allowed to withdraw their funds from the loan pool
  event Refunded();

  /// @notice Borrower has drawndown on the loan
  event Drawndown(address indexed borrower, uint256 amount);

  /// @notice Fees are collected from the loan pool
  /// @param borrower Address of borrower
  /// @param recipient Address where fees are credited to
  /// @param amount Amount of fees collected
  event FeesCollected(
    address indexed borrower,
    address indexed recipient,
    uint256 amount
  );

  /// @notice Funds are beind refunded to lender
  /// @param lender Address of the lender
  /// @param recipient Address where refunds are being sent
  /// @param amount Amount of funds refunded
  event Refund(
    address indexed lender,
    address indexed recipient,
    uint256 amount
  );

  /// @notice Borrower repays funds to the loan pool
  /// @param payer Address of the payer
  /// @param amount Amount of funds repaid
  event Repay(address indexed payer, uint256 amount);

  /// @notice Additional payments was refunded to the borrower
  /// @param payer Address of the payer
  /// @param amount Amount of funds refunded
  event RefundAdditionalPayment(address indexed payer, uint256 amount);

  /// @notice Funds are being withdrawn from the loan pool as lender
  /// after funds are repaid by the borrower
  /// @param lender Address of the lender
  /// @param recipient Address where funds are being sent
  /// @param amount Amount of funds withdrawn
  event Withdraw(
    address indexed lender,
    address indexed recipient,
    uint256 amount
  );

  function initialize(
    ICreditLineBase _creditLine,
    IERC20 _fundingAsset,
    address _borrower,
    address _feeRecipient,
    uint256[11] calldata _uints // collapsing because of stack too deep
  ) external;

  function creditLine() external view returns (ICreditLineBase);

  function fundingAsset() external view returns (IERC20);

  function borrower() external view returns (address);

  function deployer() external view returns (address);

  function feeRecipient() external view returns (address);

  function fundingStart() external view returns (uint256);

  function fundingEnd() external view returns (uint256);

  function minFundingRequired() external view returns (uint256);

  function drawdownPeriod() external view returns (uint256);

  function fees() external view returns (uint256);

  function repayments(address) external view returns (uint256);

  function fund(uint256 amount, address recipient) external;

  function refundMinimumNotMet() external;

  function refundInactiveBorrower() external;

  function refund(address recipient) external;

  function drawdown() external;

  function repay(uint256 amount) external;

  function withdraw(uint256 amount, address recipient) external;

  function balanceAvailable(address account)
    external
    view
    returns (uint256 balance);

  function shareOfPool(address account) external view returns (uint256 share);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
pragma solidity ^0.8.4;

interface ICreditLineBase {
  /// @notice State of the loan
  /// @param Funding loan is currently fundraising from lenders
  /// @param Refund funding failed, funds to be returned to lenders, terminal state
  /// @param Repayment loan has been drawndown and borrower is repaying the loan
  /// @param Repaid loan has been fully repaid by borrower, terminal state
  enum State {
    Funding,
    Refund,
    Repayment,
    Repaid
  }

  /// @notice When a function is executed under the wrong loan state
  /// @param expectedState State that the loan should be in for the function to execute
  /// @param currentState State that the loan is currently in
  error IncorrectState(State expectedState, State currentState);

  /// @notice Funding exceeds the max limit
  error MaxLimitExceeded();

  /// @notice Loan state of the credit line has been updated
  /// @param newState State of the loan after the update
  event LoanStateUpdate(State indexed newState);

  /// @notice Repayment has been made towards loan
  /// @param timestamp Timestamp of repayment
  /// @param amount Amount of repayment
  /// @param interestRepaid Payment towards interest
  /// @param principalRepaid Payment towards principal
  /// @param additionalRepayment Excess payments
  event Repayment(
    uint256 timestamp,
    uint256 amount,
    uint256 interestRepaid,
    uint256 principalRepaid,
    uint256 additionalRepayment
  );

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriod() external view returns (uint256);

  function gracePeriod() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function principalBalance() external view returns (uint256);

  function interestBalance() external view returns (uint256);

  function totalPrincipalRepaid() external view returns (uint256);

  function totalInterestRepaid() external view returns (uint256);

  function additionalRepayment() external view returns (uint256);

  function lateInterestAccrued() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);

  function minPaymentPerPeriod() external view returns (uint256);

  function loanStartTime() external view returns (uint256);

  function loanTenureInPeriods() external view returns (uint256);

  function loanState() external view returns (State);

  function initialize(
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriod,
    uint256 _gracePeriod,
    uint256 _lateFeeApr,
    uint256 _loanTenureInPeriods
  ) external;

  function fund(uint256 amount) external;

  function drawdown() external returns (uint256 amount);

  function refund() external;

  function repay(uint256 amount)
    external
    returns (
      uint256 interestPayment,
      uint256 principalPayment,
      uint256 additionalBalancePayment
    );

  function allocatePayment(
    uint256 amount,
    uint256 interestOutstanding,
    uint256 principalOutstanding
  )
    external
    pure
    returns (
      uint256 interestPayment,
      uint256 principalPayment,
      uint256 additionalBalancePayment
    );

  function minPaymentForSchedule() external view returns (uint256 amount);

  function paymentDue() external view returns (uint256 amount);

  function minPaymentAtTimestamp(uint256 timestamp)
    external
    view
    returns (uint256 amount);

  function interestAccruedSinceLastAssessed()
    external
    view
    returns (
      uint256 interestOwed,
      uint256 lateInterestOwed,
      uint256 fullPeriodsElapsed
    );

  function interestAccruedAtTimestamp(uint256 timestamp)
    external
    view
    returns (
      uint256 interestOwed,
      uint256 lateInterestOwed,
      uint256 fullPeriodsElapsed
    );

  function interestOnBalance(uint256 timePeriod)
    external
    view
    returns (uint256 interestOwed);

  function lateInterestOnBalance(uint256 timePeriod)
    external
    view
    returns (uint256 interestOwed);

  function totalRepayments() external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ILoanPool.sol";
import "./ICreditLineBase.sol";

interface ILoanPoolFactory {
  /// @notice Credit line template is not registered with the factory
  error CreditLineTemplateNotRegistered();

  /// @notice New loan pool has been created
  /// @param loanPool Address of the loan pool
  /// @param borrower Address of the borrower
  /// @param fundingAsset Address of the asset used for the loan
  /// @param creditLineTemplate Address of the template which loan terms
  /// @param creditLine Address of the credit line
  /// @param maxLimit Maximum amount of funds that can be raised
  /// @param fees Fees charged for the loan
  event LoanPoolCreated(
    address indexed loanPool,
    address indexed borrower,
    address indexed fundingAsset,
    address creditLineTemplate,
    address creditLine,
    uint256 maxLimit,
    uint256 fees
  );

  /// @notice Fee recipient has been updated
  /// @param feeRecipient Address of fee recipient
  event UpdateFeeRecipient(address indexed feeRecipient);

  /// @notice Fee tier of a particular asset has been updated
  /// @param asset Address of the asset
  /// @param tier Updated fee tier of the asset
  event UpdateAssetFeeTier(address indexed asset, uint256 indexed tier);

  /// @notice Updated fees for a fee tier
  /// @param tier Fee tier
  /// @param fees Fees for the fee tier
  event UpdateFeeTier(uint256 indexed tier, uint256 fees);

  /// @notice Credit line template has been registered or unregistered
  /// @param creditLineTemplate Address of the credit line template
  /// @param isRegistered If the template can be used in creating new loan pools
  event UpdateCreditLineTemplate(
    address indexed creditLineTemplate,
    bool indexed isRegistered
  );

  function createPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[10] calldata _uints
  ) external returns (ILoanPool loanPool, ICreditLineBase creditLine);

  function createCustomPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[11] calldata _uints
  ) external returns (ILoanPool loanPool, ICreditLineBase creditLine);

  function feeRecipient() external view returns (address);

  function loanPoolTemplate() external view returns (address);

  function isCreditLineTemplate(address template) external view returns (bool);

  function feesForTier(uint256 tier) external view returns (uint256);

  function feesTierForAsset(address asset) external view returns (uint256);

  function loanPoolDeployed(address) external view returns (bool);

  function feesOnAsset(address asset) external view returns (uint256 fee);

  function addCreditLine(address _creditLine) external;

  function removeCreditLine(address _creditLine) external;

  function setFeeTier(uint256 tier, uint256 fee) external;

  function setAssetFeeTier(address asset, uint256 tier) external;

  function setFeeRecipient(address _feeRecipient) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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