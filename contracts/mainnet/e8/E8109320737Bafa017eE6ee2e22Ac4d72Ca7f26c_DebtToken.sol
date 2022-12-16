// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./access/Manageable.sol";
import "./storage/DebtTokenStorage.sol";
import "./lib/WadRayMath.sol";

error SyntheticDoesNotExist();
error SyntheticIsInactive();
error DebtTokenInactive();
error NameIsNull();
error SymbolIsNull();
error PoolIsNull();
error SyntheticIsNull();
error AllowanceNotSupported();
error ApprovalNotSupported();
error AmountIsZero();
error NotEnoughCollateral();
error DebtLowerThanTheFloor();
error RemainingDebtIsLowerThanTheFloor();
error TransferNotSupported();
error BurnFromNullAddress();
error BurnAmountExceedsBalance();
error MintToNullAddress();
error SurpassMaxDebtSupply();
error NewValueIsSameAsCurrent();

/**
 * @title Non-transferable token that represents users' debts
 */
contract DebtToken is ReentrancyGuard, Manageable, DebtTokenStorageV1 {
    using WadRayMath for uint256;

    uint256 public constant SECONDS_PER_YEAR = 365.25 days;
    uint256 private constant HUNDRED_PERCENT = 1e18;

    string public constant VERSION = "1.0.0";

    /// @notice Emitted when synthetic's debt is repaid
    event DebtRepaid(address indexed payer, address indexed account, uint256 amount, uint256 repaid, uint256 fee);

    /// @notice Emitted when active flag is updated
    event DebtTokenActiveUpdated(bool newActive);

    /// @notice Emitted when interest rate is updated
    event InterestRateUpdated(uint256 oldInterestRate, uint256 newInterestRate);

    /// @notice Emitted when max total supply is updated
    event MaxTotalSupplyUpdated(uint256 oldMaxTotalSupply, uint256 newMaxTotalSupply);

    /// @notice Emitted when synthetic token is issued
    event SyntheticTokenIssued(
        address indexed account,
        address indexed to,
        uint256 amount,
        uint256 issued,
        uint256 fee
    );

    /**
     * @dev Throws if sender can't burn
     */
    modifier onlyIfCanBurn() {
        if (msg.sender != address(pool)) revert SenderIsNotPool();
        _;
    }

    /**
     * @dev Throws if synthetic token doesn't exist
     */
    modifier onlyIfSyntheticTokenExists() {
        if (!pool.doesSyntheticTokenExist(syntheticToken)) revert SyntheticDoesNotExist();
        _;
    }

    /**
     * @dev Throws if synthetic token isn't enabled
     */
    modifier onlyIfSyntheticTokenIsActive() {
        if (!syntheticToken.isActive()) revert SyntheticIsInactive();
        if (!isActive) revert DebtTokenInactive();
        _;
    }

    /**
     * @notice Update reward contracts' states
     * @dev Should be called before balance changes (i.e. mint/burn)
     */
    modifier updateRewardsBeforeMintOrBurn(address account_) {
        IRewardsDistributor[] memory _rewardsDistributors = pool.getRewardsDistributors();
        ISyntheticToken _syntheticToken = syntheticToken;
        uint256 _length = _rewardsDistributors.length;
        for (uint256 i; i < _length; ++i) {
            _rewardsDistributors[i].updateBeforeMintOrBurn(_syntheticToken, account_);
        }
        _;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        IPool pool_,
        ISyntheticToken syntheticToken_,
        uint256 interestRate_,
        uint256 maxTotalSupply_
    ) external initializer {
        if (bytes(name_).length == 0) revert NameIsNull();
        if (bytes(symbol_).length == 0) revert SymbolIsNull();
        if (address(pool_) == address(0)) revert PoolIsNull();
        if (address(syntheticToken_) == address(0)) revert SyntheticIsNull();

        __ReentrancyGuard_init();
        __Manageable_init(pool_);

        name = name_;
        symbol = symbol_;
        decimals = syntheticToken_.decimals();
        syntheticToken = syntheticToken_;
        lastTimestampAccrued = block.timestamp;
        debtIndex = 1e18;
        interestRate = interestRate_;
        maxTotalSupply = maxTotalSupply_;
        isActive = true;
    }

    /**
     * @notice Accrue interest over debt supply
     */
    function accrueInterest() public override {
        (
            uint256 _interestAmountAccrued,
            uint256 _debtIndex,
            uint256 _lastTimestampAccrued
        ) = _calculateInterestAccrual();

        if (block.timestamp == _lastTimestampAccrued) {
            return;
        }

        lastTimestampAccrued = block.timestamp;

        if (_interestAmountAccrued > 0) {
            totalSupply_ += _interestAmountAccrued;
            debtIndex = _debtIndex;
            // Note: We could save gas by having an accumulator and a function to mint accumulated fee
            syntheticToken.mint(pool.feeCollector(), _interestAmountAccrued);
        }
    }

    /// @inheritdoc IERC20
    function allowance(
        address, /*owner_*/
        address /*spender_*/
    ) external pure override returns (uint256) {
        revert AllowanceNotSupported();
    }

    /// @inheritdoc IERC20
    // solhint-disable-next-line
    function approve(
        address, /*spender_*/
        uint256 /*amount_*/
    ) external override returns (bool) {
        revert ApprovalNotSupported();
    }

    /**
     * @notice Get the updated (principal + interest) user's debt
     */
    function balanceOf(address account_) public view override returns (uint256) {
        uint256 _principal = principalOf[account_];
        if (_principal == 0) {
            return 0;
        }

        (, uint256 _debtIndex, ) = _calculateInterestAccrual();

        // Note: The `debtIndex / debtIndexOf` gives the interest to apply to the principal amount
        return (_principal * _debtIndex) / debtIndexOf[account_];
    }

    /**
     * @notice Burn debt token
     * @param from_ The account to burn from
     * @param amount_ The amount to burn
     */
    function burn(address from_, uint256 amount_) external override onlyIfCanBurn {
        _burn(from_, amount_);
    }

    /**
     * @notice Lock collateral and mint synthetic token
     * @param amount_ The amount to mint
     * @param to_ The beneficiary account
     * @return _issued The amount issued after fees
     * @return _fee The fee amount collected
     */
    function issue(uint256 amount_, address to_)
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfSyntheticTokenExists
        onlyIfSyntheticTokenIsActive
        returns (uint256 _issued, uint256 _fee)
    {
        if (amount_ == 0) revert AmountIsZero();

        accrueInterest();

        IPool _pool = pool;
        ISyntheticToken _syntheticToken = syntheticToken;

        (, , , , uint256 _issuableInUsd) = _pool.debtPositionOf(msg.sender);

        IMasterOracle _masterOracle = _pool.masterOracle();

        if (amount_ > _masterOracle.quoteUsdToToken(address(syntheticToken), _issuableInUsd)) {
            revert NotEnoughCollateral();
        }

        uint256 _debtFloorInUsd = _pool.debtFloorInUsd();

        if (
            _debtFloorInUsd > 0 &&
            _masterOracle.quoteTokenToUsd(address(syntheticToken), balanceOf(msg.sender) + amount_) < _debtFloorInUsd
        ) {
            revert DebtLowerThanTheFloor();
        }

        (_issued, _fee) = quoteIssueOut(amount_);
        if (_fee > 0) {
            _syntheticToken.mint(_pool.feeCollector(), _fee);
        }

        _syntheticToken.mint(to_, _issued);
        _mint(msg.sender, amount_);

        emit SyntheticTokenIssued(msg.sender, to_, amount_, _issued, _fee);
    }

    /**
     * @notice Return interest rate (in percent) per second
     */
    function interestRatePerSecond() public view override returns (uint256) {
        return interestRate / SECONDS_PER_YEAR;
    }

    /**
     * @notice Quote gross `_amount` to issue `amountToIssue_` synthetic tokens
     * @param amountToIssue_ Synth to issue
     * @return _amount Gross amount
     * @return _fee The fee amount to collect
     */
    function quoteIssueIn(uint256 amountToIssue_) external view override returns (uint256 _amount, uint256 _fee) {
        uint256 _issueFee = pool.issueFee();
        if (_issueFee == 0) {
            return (amountToIssue_, _fee);
        }

        _amount = amountToIssue_.wadDiv(HUNDRED_PERCENT - _issueFee);
        _fee = _amount - amountToIssue_;
    }

    /**
     * @notice Quote synthetic tokens `_amountToIssue` by using gross `_amount`
     * @param amount_ Gross amount
     * @return _amountToIssue Synth to issue
     * @return _fee The fee amount to collect
     */
    function quoteIssueOut(uint256 amount_) public view override returns (uint256 _amountToIssue, uint256 _fee) {
        uint256 _issueFee = pool.issueFee();
        if (_issueFee == 0) {
            return (amount_, _fee);
        }

        _fee = amount_.wadMul(_issueFee);
        _amountToIssue = amount_ - _fee;
    }

    /**
     * @notice Quote synthetic token `_amount` need to repay `amountToRepay_` debt
     * @param amountToRepay_ Debt amount to repay
     * @return _amount Gross amount
     * @return _fee The fee amount to collect
     */
    function quoteRepayIn(uint256 amountToRepay_) public view override returns (uint256 _amount, uint256 _fee) {
        uint256 _repayFee = pool.repayFee();
        if (_repayFee == 0) {
            return (amountToRepay_, _fee);
        }

        _fee = amountToRepay_.wadMul(_repayFee);
        _amount = amountToRepay_ + _fee;
    }

    /**
     * @notice Quote debt `_amountToRepay` by burning `_amount` synthetic tokens
     * @param amount_ Gross amount
     * @return _amountToRepay Debt amount to repay
     * @return _fee The fee amount to collect
     */
    function quoteRepayOut(uint256 amount_) public view override returns (uint256 _amountToRepay, uint256 _fee) {
        uint256 _repayFee = pool.repayFee();
        if (_repayFee == 0) {
            return (amount_, _fee);
        }

        _amountToRepay = amount_.wadDiv(HUNDRED_PERCENT + _repayFee);
        _fee = amount_ - _amountToRepay;
    }

    /**
     * @notice Send synthetic token to decrease debt
     * @dev The msg.sender is the payer and the account beneficed
     * @param onBehalfOf_ The account that will have debt decreased
     * @param amount_ The amount of synthetic token to burn (this is the gross amount, the repay fee will be subtracted from it)
     * @return _repaid The amount repaid after fees
     */
    function repay(address onBehalfOf_, uint256 amount_)
        external
        override
        whenNotShutdown
        nonReentrant
        returns (uint256 _repaid, uint256 _fee)
    {
        if (amount_ == 0) revert AmountIsZero();

        accrueInterest();

        IPool _pool = pool;
        ISyntheticToken _syntheticToken = syntheticToken;

        (_repaid, _fee) = quoteRepayOut(amount_);
        if (_fee > 0) {
            _syntheticToken.seize(msg.sender, _pool.feeCollector(), _fee);
        }

        uint256 _debtFloorInUsd = _pool.debtFloorInUsd();
        if (_debtFloorInUsd > 0) {
            uint256 _newDebtInUsd = _pool.masterOracle().quoteTokenToUsd(
                address(_syntheticToken),
                balanceOf(onBehalfOf_) - _repaid
            );
            if (_newDebtInUsd > 0 && _newDebtInUsd < _debtFloorInUsd) {
                revert RemainingDebtIsLowerThanTheFloor();
            }
        }

        _syntheticToken.burn(msg.sender, _repaid);
        _burn(onBehalfOf_, _repaid);

        emit DebtRepaid(msg.sender, onBehalfOf_, amount_, _repaid, _fee);
    }

    /**
     * @notice Send synthetic token to decrease debt
     * @dev This function helps users to no leave debt dust behind
     * @param onBehalfOf_ The account that will have debt decreased
     * @return _repaid The amount repaid after fees
     * @return _fee The fee amount collected
     */
    function repayAll(address onBehalfOf_)
        external
        override
        whenNotShutdown
        nonReentrant
        returns (uint256 _repaid, uint256 _fee)
    {
        accrueInterest();

        _repaid = balanceOf(onBehalfOf_);
        if (_repaid == 0) revert AmountIsZero();

        ISyntheticToken _syntheticToken = syntheticToken;

        uint256 _amount;
        (_amount, _fee) = quoteRepayIn(_repaid);

        if (_fee > 0) {
            _syntheticToken.seize(msg.sender, pool.feeCollector(), _fee);
        }

        _syntheticToken.burn(msg.sender, _repaid);
        _burn(onBehalfOf_, _repaid);

        emit DebtRepaid(msg.sender, onBehalfOf_, _amount, _repaid, _fee);
    }

    /**
     * @notice Return the total supply
     */
    function totalSupply() external view override returns (uint256) {
        (uint256 _interestAmountAccrued, , ) = _calculateInterestAccrual();
        return totalSupply_ + _interestAmountAccrued;
    }

    /// @inheritdoc IERC20
    // solhint-disable-next-line
    function transfer(
        address, /*recipient_*/
        uint256 /*amount_*/
    ) external override returns (bool) {
        revert TransferNotSupported();
    }

    /// @inheritdoc IERC20
    // solhint-disable-next-line
    function transferFrom(
        address, /*sender_*/
        address, /*recipient_*/
        uint256 /*amount_*/
    ) external override returns (bool) {
        revert TransferNotSupported();
    }

    /**
     * @notice Add this token to the debt tokens list if the recipient is receiving it for the 1st time
     */
    function _addToDebtTokensOfRecipientIfNeeded(address recipient_, uint256 recipientBalanceBefore_) private {
        if (recipientBalanceBefore_ == 0) {
            pool.addToDebtTokensOfAccount(recipient_);
        }
    }

    /**
     * @notice Destroy `amount` tokens from `account`, reducing the
     * total supply
     */
    function _burn(address account_, uint256 amount_) private updateRewardsBeforeMintOrBurn(account_) {
        if (account_ == address(0)) revert BurnFromNullAddress();

        uint256 _accountBalance = balanceOf(account_);
        if (_accountBalance < amount_) revert BurnAmountExceedsBalance();

        unchecked {
            principalOf[account_] = _accountBalance - amount_;
            debtIndexOf[account_] = debtIndex;
            totalSupply_ -= amount_;
        }

        emit Transfer(account_, address(0), amount_);

        _removeFromDebtTokensOfSenderIfNeeded(account_, balanceOf(account_));
    }

    /**
     * @notice Calculate interest to accrue
     * @dev This util function avoids code duplication across `balanceOf` and `accrueInterest`
     * @return _interestAmountAccrued The total amount of debt tokens accrued
     * @return _debtIndex The new `debtIndex` value
     */
    function _calculateInterestAccrual()
        private
        view
        returns (
            uint256 _interestAmountAccrued,
            uint256 _debtIndex,
            uint256 _lastTimestampAccrued
        )
    {
        _lastTimestampAccrued = lastTimestampAccrued;
        _debtIndex = debtIndex;

        if (block.timestamp > _lastTimestampAccrued) {
            uint256 _interestRateToAccrue = interestRatePerSecond() * (block.timestamp - _lastTimestampAccrued);
            if (_interestRateToAccrue > 0) {
                _interestAmountAccrued = _interestRateToAccrue.wadMul(totalSupply_);
                _debtIndex += _interestRateToAccrue.wadMul(debtIndex);
            }
        }
    }

    /**
     * @notice Create `amount` tokens and assigns them to `account`, increasing
     * the total supply
     */
    function _mint(address account_, uint256 amount_) private updateRewardsBeforeMintOrBurn(account_) {
        if (account_ == address(0)) revert MintToNullAddress();

        uint256 _balanceBefore = balanceOf(account_);

        totalSupply_ += amount_;
        if (totalSupply_ > maxTotalSupply) revert SurpassMaxDebtSupply();

        principalOf[account_] += amount_;
        debtIndexOf[account_] = debtIndex;
        emit Transfer(address(0), account_, amount_);

        _addToDebtTokensOfRecipientIfNeeded(account_, _balanceBefore);
    }

    /**
     * @notice Remove this token to the debt tokens list if the sender's balance goes to zero
     */
    function _removeFromDebtTokensOfSenderIfNeeded(address sender_, uint256 senderBalanceAfter_) private {
        if (senderBalanceAfter_ == 0) {
            pool.removeFromDebtTokensOfAccount(sender_);
        }
    }

    /**
     * @notice Update max total supply
     */
    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external override onlyGovernor {
        uint256 _currentMaxTotalSupply = maxTotalSupply;
        if (newMaxTotalSupply_ == _currentMaxTotalSupply) revert NewValueIsSameAsCurrent();
        emit MaxTotalSupplyUpdated(_currentMaxTotalSupply, newMaxTotalSupply_);
        maxTotalSupply = newMaxTotalSupply_;
    }

    /**
     * @notice Update interest rate (APR)
     */
    function updateInterestRate(uint256 newInterestRate_) external override onlyGovernor {
        accrueInterest();
        uint256 _currentInterestRate = interestRate;
        if (newInterestRate_ == _currentInterestRate) revert NewValueIsSameAsCurrent();
        emit InterestRateUpdated(_currentInterestRate, newInterestRate_);
        interestRate = newInterestRate_;
    }

    /**
     * @notice Enable/Disable the Debt Token
     */
    function toggleIsActive() external override onlyGovernor {
        bool _newIsActive = !isActive;
        emit DebtTokenActiveUpdated(_newIsActive);
        isActive = _newIsActive;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "../utils/TokenHolder.sol";
import "../interfaces/IGovernable.sol";
import "../interfaces/IManageable.sol";

error SenderIsNotPool();
error SenderIsNotGovernor();
error IsPaused();
error IsShutdown();
error PoolAddressIsNull();

/**
 * @title Reusable contract that handles accesses
 */
abstract contract Manageable is IManageable, TokenHolder, Initializable {
    /**
     * @notice Pool contract
     */
    IPool public pool;

    /**
     * @dev Throws if `msg.sender` isn't the pool
     */
    modifier onlyPool() {
        if (msg.sender != address(pool)) revert SenderIsNotPool();
        _;
    }

    /**
     * @dev Throws if `msg.sender` isn't the governor
     */
    modifier onlyGovernor() {
        if (msg.sender != governor()) revert SenderIsNotGovernor();
        _;
    }

    /**
     * @dev Throws if contract is paused
     */
    modifier whenNotPaused() {
        if (pool.paused()) revert IsPaused();
        _;
    }

    /**
     * @dev Throws if contract is shutdown
     */
    modifier whenNotShutdown() {
        if (pool.everythingStopped()) revert IsShutdown();
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Manageable_init(IPool pool_) internal initializer {
        if (address(pool_) == address(0)) revert PoolAddressIsNull();
        pool = pool_;
    }

    /**
     * @notice Get the governor
     * @return _governor The governor
     */
    function governor() public view returns (address _governor) {
        _governor = IGovernable(address(pool)).governor();
    }

    /// @inheritdoc TokenHolder
    function _requireCanSweep() internal view override onlyGovernor {}

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
abstract contract ReentrancyGuard is Initializable {
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

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISyntheticToken.sol";

interface IDebtToken is IERC20Metadata {
    function lastTimestampAccrued() external view returns (uint256);

    function isActive() external view returns (bool);

    function syntheticToken() external view returns (ISyntheticToken);

    function accrueInterest() external;

    function debtIndex() external returns (uint256 debtIndex_);

    function burn(address from_, uint256 amount_) external;

    function issue(uint256 amount_, address to_) external returns (uint256 _issued, uint256 _fee);

    function repay(address onBehalfOf_, uint256 amount_) external returns (uint256 _repaid, uint256 _fee);

    function repayAll(address onBehalfOf_) external returns (uint256 _repaid, uint256 _fee);

    function quoteIssueIn(uint256 amountToIssue_) external view returns (uint256 _amount, uint256 _fee);

    function quoteIssueOut(uint256 amount_) external view returns (uint256 _amountToIssue, uint256 _fee);

    function quoteRepayIn(uint256 amountToRepay_) external view returns (uint256 _amount, uint256 _fee);

    function quoteRepayOut(uint256 amount_) external view returns (uint256 _amountToRepay, uint256 _fee);

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;

    function updateInterestRate(uint256 newInterestRate_) external;

    function maxTotalSupply() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function interestRatePerSecond() external view returns (uint256);

    function toggleIsActive() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

interface IDepositToken is IERC20Metadata {
    function underlying() external view returns (IERC20);

    function collateralFactor() external view returns (uint256);

    function unlockedBalanceOf(address account_) external view returns (uint256);

    function lockedBalanceOf(address account_) external view returns (uint256);

    function deposit(uint256 amount_, address onBehalfOf_) external returns (uint256 _deposited, uint256 _fee);

    function quoteDepositIn(uint256 amountToDeposit_) external view returns (uint256 _amount, uint256 _fee);

    function quoteDepositOut(uint256 amount_) external view returns (uint256 _amountToDeposit, uint256 _fee);

    function quoteWithdrawIn(uint256 amountToWithdraw_) external view returns (uint256 _amount, uint256 _fee);

    function quoteWithdrawOut(uint256 amount_) external view returns (uint256 _amountToWithdraw, uint256 _fee);

    function withdraw(uint256 amount_, address to_) external returns (uint256 _withdrawn, uint256 _fee);

    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external;

    function updateCollateralFactor(uint128 newCollateralFactor_) external;

    function isActive() external view returns (bool);

    function toggleIsActive() external;

    function maxTotalSupply() external view returns (uint256);

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IPool.sol";

/**
 * @notice Manageable interface
 */
interface IManageable {
    function pool() external view returns (IPool _pool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPauseable {
    function paused() external view returns (bool);

    function everythingStopped() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IDepositToken.sol";
import "./IDebtToken.sol";
import "./ITreasury.sol";
import "./IRewardsDistributor.sol";
import "./IPoolRegistry.sol";

/**
 * @notice Pool interface
 */
interface IPool is IPauseable, IGovernable {
    function debtFloorInUsd() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function issueFee() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function repayFee() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function liquidationFees() external view returns (uint128 liquidatorIncentive, uint128 protocolFee);

    function feeCollector() external view returns (address);

    function maxLiquidable() external view returns (uint256);

    function doesSyntheticTokenExist(ISyntheticToken syntheticToken_) external view returns (bool);

    function doesDebtTokenExist(IDebtToken debtToken_) external view returns (bool);

    function doesDepositTokenExist(IDepositToken depositToken_) external view returns (bool);

    function depositTokenOf(IERC20 underlying_) external view returns (IDepositToken);

    function debtTokenOf(ISyntheticToken syntheticToken_) external view returns (IDebtToken);

    function getDepositTokens() external view returns (address[] memory);

    function getDebtTokens() external view returns (address[] memory);

    function getRewardsDistributors() external view returns (IRewardsDistributor[] memory);

    function debtOf(address account_) external view returns (uint256 _debtInUsd);

    function depositOf(address account_) external view returns (uint256 _depositInUsd, uint256 _issuableLimitInUsd);

    function debtPositionOf(address account_)
        external
        view
        returns (
            bool _isHealthy,
            uint256 _depositInUsd,
            uint256 _debtInUsd,
            uint256 _issuableLimitInUsd,
            uint256 _issuableInUsd
        );

    function addDebtToken(IDebtToken debtToken_) external;

    function removeDebtToken(IDebtToken debtToken_) external;

    function addDepositToken(address depositToken_) external;

    function removeDepositToken(IDepositToken depositToken_) external;

    function liquidate(
        ISyntheticToken syntheticToken_,
        address account_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    )
        external
        returns (
            uint256 _totalSeized,
            uint256 _toLiquidator,
            uint256 _fee
        );

    function quoteLiquidateIn(
        ISyntheticToken syntheticToken_,
        uint256 totalToSeized_,
        IDepositToken depositToken_
    )
        external
        view
        returns (
            uint256 _amountToRepay,
            uint256 _toLiquidator,
            uint256 _fee
        );

    function quoteLiquidateMax(
        ISyntheticToken syntheticToken_,
        address account_,
        IDepositToken depositToken_
    ) external view returns (uint256 _maxAmountToRepay);

    function quoteLiquidateOut(
        ISyntheticToken syntheticToken_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    )
        external
        view
        returns (
            uint256 _totalSeized,
            uint256 _toLiquidator,
            uint256 _fee
        );

    function quoteSwapIn(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountOut_
    ) external view returns (uint256 _amountIn, uint256 _fee);

    function quoteSwapOut(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _fee);

    function swap(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, uint256 _fee);

    function updateSwapFee(uint256 newSwapFee_) external;

    function updateDebtFloor(uint256 newDebtFloorInUsd_) external;

    function updateDepositFee(uint256 newDepositFee_) external;

    function updateIssueFee(uint256 newIssueFee_) external;

    function updateWithdrawFee(uint256 newWithdrawFee_) external;

    function updateRepayFee(uint256 newRepayFee_) external;

    function updateLiquidatorIncentive(uint128 newLiquidatorIncentive_) external;

    function updateProtocolLiquidationFee(uint128 newProtocolLiquidationFee_) external;

    function updateMaxLiquidable(uint256 newMaxLiquidable_) external;

    function updateTreasury(ITreasury newTreasury_) external;

    function treasury() external view returns (ITreasury);

    function masterOracle() external view returns (IMasterOracle);

    function poolRegistry() external view returns (IPoolRegistry);

    function addToDepositTokensOfAccount(address account_) external;

    function removeFromDepositTokensOfAccount(address account_) external;

    function addToDebtTokensOfAccount(address account_) external;

    function removeFromDebtTokensOfAccount(address account_) external;

    function getDepositTokensOfAccount(address account_) external view returns (address[] memory);

    function getDebtTokensOfAccount(address account_) external view returns (address[] memory);

    function addRewardsDistributor(IRewardsDistributor distributor_) external;

    function removeRewardsDistributor(IRewardsDistributor distributor_) external;

    function toggleIsSwapActive() external;

    function isSwapActive() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./external/IMasterOracle.sol";
import "./IPauseable.sol";
import "./IGovernable.sol";
import "./ISyntheticToken.sol";

interface IPoolRegistry is IPauseable, IGovernable {
    function isPoolRegistered(address pool_) external view returns (bool);

    function feeCollector() external view returns (address);

    function nativeTokenGateway() external view returns (address);

    function getPools() external view returns (address[] memory);

    function registerPool(address pool_) external;

    function unregisterPool(address pool_) external;

    function masterOracle() external view returns (IMasterOracle);

    function updateMasterOracle(IMasterOracle newOracle_) external;

    function updateFeeCollector(address newFeeCollector_) external;

    function updateNativeTokenGateway(address newGateway_) external;

    function idOfPool(address pool_) external view returns (uint256);

    function nextPoolId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/IERC20.sol";

/**
 * @notice Reward Distributor interface
 */
interface IRewardsDistributor {
    function rewardToken() external view returns (IERC20);

    function tokenSpeeds(IERC20 token_) external view returns (uint256);

    function tokensAccruedOf(address account_) external view returns (uint256);

    function updateBeforeMintOrBurn(IERC20 token_, address account_) external;

    function updateBeforeTransfer(
        IERC20 token_,
        address from_,
        address to_
    ) external;

    function claimable(address account_) external view returns (uint256 _claimable);

    function claimable(address account_, IERC20 token_) external view returns (uint256 _claimable);

    function claimRewards(address account_) external;

    function claimRewards(address account_, IERC20[] memory tokens_) external;

    function claimRewards(address[] memory accounts_, IERC20[] memory tokens_) external;

    function updateTokenSpeed(IERC20 token_, uint256 newSpeed_) external;

    function updateTokenSpeeds(IERC20[] calldata tokens_, uint256[] calldata speeds_) external;

    function tokens(uint256) external view returns (IERC20);

    function tokenStates(IERC20) external view returns (uint224 index, uint32 timestamp);

    function accountIndexOf(IERC20, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IDebtToken.sol";
import "./IPoolRegistry.sol";

interface ISyntheticToken is IERC20Metadata {
    function isActive() external view returns (bool);

    function mint(address to_, uint256 amount_) external;

    function burn(address from_, uint256 amount) external;

    function poolRegistry() external returns (IPoolRegistry);

    function toggleIsActive() external;

    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external;

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;

    function maxTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITreasury {
    function pull(address to_, uint256 amount_) external;

    function migrateTo(address newTreasury_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasterOracle {
    function quoteTokenToUsd(address _asset, uint256 _amount) external view returns (uint256 _amountInUsd);

    function quoteUsdToToken(address _asset, uint256 _amountInUsd) external view returns (uint256 _amount);

    function quote(
        address _assetIn,
        address _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Math library
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 * @dev Based on https://github.com/dapphub/ds-math/blob/master/src/math.sol
 */
library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * WAD + b / 2) / b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IDebtToken.sol";

abstract contract DebtTokenStorageV1 is IDebtToken {
    /**
     * @notice The name of the token
     */
    string public override name;

    /**
     * @notice The symbol of the token
     */
    string public override symbol;

    /**
     * @notice The mapping of the users' minted tokens
     * @dev This value changes within the mint and burn operations
     */
    mapping(address => uint256) internal principalOf;

    /**
     * @notice The `debtIndex` "snapshot" of the account's latest `principalOf` update (i.e. mint/burn)
     */
    mapping(address => uint256) internal debtIndexOf;

    /**
     * @notice The supply cap
     */
    uint256 public override maxTotalSupply;

    /**
     * @notice The total amount of minted tokens
     */
    uint256 internal totalSupply_;

    /**
     * @notice The timestamp when interest accrual was calculated for the last time
     */
    uint256 public override lastTimestampAccrued;

    /**
     * @notice Accumulator of the total earned interest rate since the beginning
     */
    uint256 public override debtIndex;

    /**
     * @notice Interest rate
     * @dev Use 0.1e18 for 10% APR
     */
    uint256 public override interestRate;

    /**
     * @notice The Synthetic token
     */
    ISyntheticToken public override syntheticToken;

    /**
     * @notice If true, disables msAsset minting on this pool
     */
    bool public override isActive;

    /**
     * @notice The decimals of the token
     */
    uint8 public override decimals;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/utils/SafeERC20.sol";

error FallbackIsNotAllowed();
error ReceiveIsNotAllowed();

/**
 * @title Utils contract that handles tokens sent to it
 */
abstract contract TokenHolder {
    using SafeERC20 for IERC20;

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert FallbackIsNotAllowed();
    }

    /**
     * @dev Revert when receiving by default
     */
    receive() external payable virtual {
        revert ReceiveIsNotAllowed();
    }

    /**
     * @notice ERC20 recovery in case of stuck tokens due direct transfers to the contract address.
     * @param token_ The token to transfer
     * @param to_ The recipient of the transfer
     * @param amount_ The amount to send
     */
    function sweep(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external {
        _requireCanSweep();

        if (address(token_) == address(0)) {
            Address.sendValue(payable(to_), amount_);
        } else {
            token_.safeTransfer(to_, amount_);
        }
    }

    /**
     * @notice Function that reverts if the caller isn't allowed to sweep tokens
     * @dev Usually requires the owner or governor as the caller
     */
    function _requireCanSweep() internal view virtual;
}