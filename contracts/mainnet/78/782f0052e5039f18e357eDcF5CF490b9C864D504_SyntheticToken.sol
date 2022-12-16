// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IManageable.sol";
import "./lib/WadRayMath.sol";
import "./storage/SyntheticTokenStorage.sol";

error SenderIsNotGovernor();
error SenderCanNotBurn();
error SenderCanNotMint();
error SenderCanNotSeize();
error SyntheticIsInactive();
error NameIsNull();
error SymbolIsNull();
error DecimalsIsNull();
error PoolRegistryIsNull();
error DecreasedAllowanceBelowZero();
error AmountExceedsAllowance();
error ApproveFromTheZeroAddress();
error ApproveToTheZeroAddress();
error BurnFromTheZeroAddress();
error BurnAmountExceedsBalance();
error MintToTheZeroAddress();
error SurpassMaxSynthSupply();
error TransferFromTheZeroAddress();
error TransferToTheZeroAddress();
error TransferAmountExceedsBalance();
error NewValueIsSameAsCurrent();

/**
 * @title Synthetic Token contract
 */
contract SyntheticToken is Initializable, SyntheticTokenStorageV1 {
    using WadRayMath for uint256;

    string public constant VERSION = "1.0.0";

    /// @notice Emitted when active flag is updated
    event SyntheticTokenActiveUpdated(bool newActive);

    /// @notice Emitted when max total supply is updated
    event MaxTotalSupplyUpdated(uint256 oldMaxTotalSupply, uint256 newMaxTotalSupply);

    /**
     * @notice Throws if caller isn't the governor
     */
    modifier onlyGovernor() {
        if (msg.sender != poolRegistry.governor()) revert SenderIsNotGovernor();
        _;
    }

    /**
     * @dev Throws if sender can't burn
     */
    modifier onlyIfCanBurn() {
        if (!_isMsgSenderPool() && !_isMsgSenderDebtToken()) revert SenderCanNotBurn();
        _;
    }

    /**
     * @dev Throws if sender can't mint
     */
    modifier onlyIfCanMint() {
        if (!_isMsgSenderPool() && !_isMsgSenderDebtToken()) revert SenderCanNotMint();
        _;
    }

    /**
     * @dev Throws if sender can't seize
     */
    modifier onlyIfCanSeize() {
        if (!_isMsgSenderPool() && !_isMsgSenderDebtToken()) revert SenderCanNotSeize();
        _;
    }

    /**
     * @dev Throws if synthetic token isn't enabled
     */
    modifier onlyIfSyntheticTokenIsActive() {
        if (!isActive) revert SyntheticIsInactive();
        _;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        IPoolRegistry poolRegistry_
    ) external initializer {
        if (bytes(name_).length == 0) revert NameIsNull();
        if (bytes(symbol_).length == 0) revert SymbolIsNull();
        if (decimals_ == 0) revert DecimalsIsNull();
        if (address(poolRegistry_) == address(0)) revert PoolRegistryIsNull();

        poolRegistry = poolRegistry_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        isActive = true;
        maxTotalSupply = type(uint256).max;
    }

    /**
     * @notice Set `amount` as the allowance of `spender` over the caller's tokens
     */
    function approve(address spender_, uint256 amount_) external override returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    /**
     * @notice Burn synthetic token
     * @param from_ The account to burn from
     * @param amount_ The amount to burn
     */
    function burn(address from_, uint256 amount_) external override onlyIfCanBurn {
        _burn(from_, amount_);
    }

    /**
     * @notice Atomically decrease the allowance granted to `spender` by the caller
     */
    function decreaseAllowance(address spender_, uint256 subtractedValue_) external returns (bool) {
        uint256 _currentAllowance = allowance[msg.sender][spender_];
        if (_currentAllowance < subtractedValue_) revert DecreasedAllowanceBelowZero();
        unchecked {
            _approve(msg.sender, spender_, _currentAllowance - subtractedValue_);
        }
        return true;
    }

    /**
     * @notice Atomically increase the allowance granted to `spender` by the caller
     */
    function increaseAllowance(address spender_, uint256 addedValue_) external returns (bool) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedValue_);
        return true;
    }

    /**
     * @notice Mint synthetic token
     * @param to_ The account to mint to
     * @param amount_ The amount to mint
     */
    function mint(address to_, uint256 amount_) external override onlyIfCanMint {
        _mint(to_, amount_);
    }

    /**
     * @notice Seize synthetic tokens
     * @dev Same as _transfer
     * @param to_ The account to seize from
     * @param to_ The beneficiary account
     * @param amount_ The amount to seize
     */
    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external override onlyIfCanSeize {
        _transfer(from_, to_, amount_);
    }

    /// @inheritdoc IERC20
    function transfer(address recipient_, uint256 amount_) external override returns (bool) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address sender_,
        address recipient_,
        uint256 amount_
    ) external override returns (bool) {
        _transfer(sender_, recipient_, amount_);

        uint256 _currentAllowance = allowance[sender_][msg.sender];
        if (_currentAllowance != type(uint256).max) {
            if (_currentAllowance < amount_) revert AmountExceedsAllowance();
            unchecked {
                _approve(sender_, msg.sender, _currentAllowance - amount_);
            }
        }

        return true;
    }

    /**
     * @notice Set `amount` as the allowance of `spender` over the `owner` s tokens
     */
    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) private {
        if (owner_ == address(0)) revert ApproveFromTheZeroAddress();
        if (spender_ == address(0)) revert ApproveToTheZeroAddress();

        allowance[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @notice Destroy `amount` tokens from `account`, reducing the
     * total supply
     */
    function _burn(address account_, uint256 amount_) private {
        if (account_ == address(0)) revert BurnFromTheZeroAddress();

        uint256 _currentBalance = balanceOf[account_];
        if (_currentBalance < amount_) revert BurnAmountExceedsBalance();
        unchecked {
            balanceOf[account_] = _currentBalance - amount_;
            totalSupply -= amount_;
        }

        emit Transfer(account_, address(0), amount_);
    }

    /**
     * @notice Check if the sender is a valid DebtToken contract
     */
    function _isMsgSenderDebtToken() private view returns (bool) {
        IPool _pool = IManageable(msg.sender).pool();

        return
            poolRegistry.isPoolRegistered(address(_pool)) &&
            _pool.doesDebtTokenExist(IDebtToken(msg.sender)) &&
            IDebtToken(msg.sender).syntheticToken() == this;
    }

    /**
     * @notice Check if the sender is a valid Pool contract
     */
    function _isMsgSenderPool() private view returns (bool) {
        return poolRegistry.isPoolRegistered(msg.sender) && IPool(msg.sender).doesSyntheticTokenExist(this);
    }

    /**
     * @notice Create `amount` tokens and assigns them to `account`, increasing
     * the total supply
     */
    function _mint(address account_, uint256 amount_) private onlyIfSyntheticTokenIsActive {
        if (account_ == address(0)) revert MintToTheZeroAddress();

        totalSupply += amount_;
        if (totalSupply > maxTotalSupply) revert SurpassMaxSynthSupply();
        balanceOf[account_] += amount_;
        emit Transfer(address(0), account_, amount_);
    }

    /**
     * @notice Move `amount` of tokens from `sender` to `recipient`
     */
    function _transfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) private {
        if (sender_ == address(0)) revert TransferFromTheZeroAddress();
        if (recipient_ == address(0)) revert TransferToTheZeroAddress();

        uint256 senderBalance = balanceOf[sender_];
        if (senderBalance < amount_) revert TransferAmountExceedsBalance();
        unchecked {
            balanceOf[sender_] = senderBalance - amount_;
            balanceOf[recipient_] += amount_;
        }

        emit Transfer(sender_, recipient_, amount_);
    }

    /**
     * @notice Enable/Disable Synthetic Token
     */
    function toggleIsActive() external override onlyGovernor {
        bool _newIsActive = !isActive;
        emit SyntheticTokenActiveUpdated(_newIsActive);
        isActive = _newIsActive;
    }

    /**
     * @notice Update max total supply
     * @param newMaxTotalSupply_ The new max total supply
     */
    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external override onlyGovernor {
        uint256 _currentMaxTotalSupply = maxTotalSupply;
        if (newMaxTotalSupply_ == _currentMaxTotalSupply) revert NewValueIsSameAsCurrent();
        emit MaxTotalSupplyUpdated(_currentMaxTotalSupply, newMaxTotalSupply_);
        maxTotalSupply = newMaxTotalSupply_;
    }
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

import "../interfaces/ISyntheticToken.sol";

abstract contract SyntheticTokenStorageV1 is ISyntheticToken {
    /**
     * @notice The name of the token
     */
    string public override name;

    /**
     * @notice The symbol of the token
     */
    string public override symbol;

    /**
     * @dev The amount of tokens owned by `account`
     */
    mapping(address => uint256) public override balanceOf;

    /**
     * @dev The remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}
     */
    mapping(address => mapping(address => uint256)) public override allowance;

    /**
     * @dev Amount of tokens in existence
     */
    uint256 public override totalSupply;

    /**
     * @notice The supply cap
     */
    uint256 public override maxTotalSupply;

    /**
     * @dev The Pool Registry
     */
    IPoolRegistry public override poolRegistry;

    /**
     * @notice If true, disables msAsset minting globally
     */
    bool public override isActive;

    /**
     * @notice The decimals of the token
     */
    uint8 public override decimals;
}