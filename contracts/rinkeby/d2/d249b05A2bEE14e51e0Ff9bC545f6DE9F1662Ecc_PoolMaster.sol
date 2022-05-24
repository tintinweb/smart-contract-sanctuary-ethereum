// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PoolMetadata.sol";
import "./PoolRewards.sol";
import "./PoolConfiguration.sol";

/// @notice This is perimary protocol contract, describing borrowing Pool
contract PoolMaster is PoolRewards, PoolConfiguration, PoolMetadata {
    // CONSTRUCTOR

    /// @notice Upgradeable contract constructor
    /// @param manager_ Address of the Pool's manager
    /// @param currency_ Address of the currency token
    function initialize(address manager_, IERC20Upgradeable currency_)
        public
        initializer
    {
        __PoolBaseInfo_init(manager_, currency_);
    }

    // VERSION

    function version() external pure virtual returns (string memory) {
        return "1.1.0";
    }

    // OVERRIDES

    /// @notice Override of the mint function, see {IERC20-_mint}
    function _mint(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, PoolRewards)
    {
        super._mint(account, amount);
    }

    /// @notice Override of the mint function, see {IERC20-_burn}
    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, PoolRewards)
    {
        super._burn(account, amount);
    }

    /// @notice Override of the transfer function, see {IERC20-_transfer}
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, PoolRewards) {
        super._transfer(from, to, amount);
    }

    /// @notice Override of the decimals function, see {IERC20Metadata-decimals}
    /// @return Cp-token decimals
    function decimals()
        public
        view
        override(ERC20Upgradeable, PoolMetadata)
        returns (uint8)
    {
        return super.decimals();
    }

    /// @notice Override of the decimals function, see {IERC20Metadata-symbol}
    /// @return Pool's symbol
    function symbol()
        public
        view
        override(ERC20Upgradeable, PoolMetadata)
        returns (string memory)
    {
        return super.symbol();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./PoolBase.sol";
import "../libraries/Decimal.sol";

/// @notice This contract describes Pool's external view functions for observing it's current state
abstract contract PoolMetadata is PoolBase {
    using Decimal for uint256;

    /// @notice Function that returns cp-token decimals
    /// @return Cp-token decimals
    function decimals() public view virtual override returns (uint8) {
        return IERC20MetadataUpgradeable(address(currency)).decimals();
    }

    /// @notice Function returns pool's symbol
    /// @return Pool's symbol
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice Function returns current (with accrual) pool state
    /// @return Current state
    function state() external view returns (State) {
        return _state(_accrueInterestVirtual());
    }

    /// @notice Function returns current (with accrual) last accrual timestamp
    /// @return Last accrual timestamp
    function lastAccrual() external view returns (uint256) {
        return _accrueInterestVirtual().lastAccrual;
    }

    /// @notice Function returns current (with accrual) interest value
    /// @return Current interest
    function interest() external view returns (uint256) {
        return _interest(_accrueInterestVirtual());
    }

    /// @notice Function returns current (with accrual) amount of funds available to LP for withdrawal
    /// @return Current available to withdraw funds
    function availableToWithdraw() external view returns (uint256) {
        if (debtClaimed) {
            return cash();
        } else {
            BorrowInfo memory info = _accrueInterestVirtual();
            return
                MathUpgradeable.min(
                    _availableToProviders(info),
                    _availableProvisionalDefault(info)
                );
        }
    }

    /// @notice Function returns current (with accrual) amount of funds available for manager to borrow
    /// @return Current available to borrow funds
    function availableToBorrow() external view returns (uint256) {
        return _availableToBorrow(_accrueInterestVirtual());
    }

    /// @notice Function returns current (with accrual) pool size
    /// @return Current pool size

    function poolSize() external view returns (uint256) {
        return _poolSize(_accrueInterestVirtual());
    }

    /// @notice Function returns current principal value
    /// @return Current principal
    function principal() external view returns (uint256) {
        return _info.principal;
    }

    /// @notice Function returns current (with accrual) total borrows value
    /// @return Current borrows
    function borrows() external view returns (uint256) {
        return _accrueInterestVirtual().borrows;
    }

    /// @notice Function returns current (with accrual) reserves value
    /// @return Current reserves
    function reserves() public view returns (uint256) {
        return _accrueInterestVirtual().reserves;
    }

    /// @notice Function returns current (with accrual) insurance value
    /// @return Current insurance
    function insurance() external view returns (uint256) {
        return _accrueInterestVirtual().insurance;
    }

    /// @notice Function returns timestamp when pool entered zero utilization state (0 if didn't enter)
    /// @return Timestamp of entering zero utilization
    function enteredZeroUtilization() external view returns (uint256) {
        return _info.enteredZeroUtilization;
    }

    /// @notice Function returns timestamp when pool entered warning utilization state (0 if didn't enter)
    /// @return Timestamp of entering warning utilization
    function enteredProvisionalDefault() external view returns (uint256) {
        return _accrueInterestVirtual().enteredProvisionalDefault;
    }

    /// @notice Function returns current (with accrual) exchange rate of cpTokens for currency tokens
    /// @return Current exchange rate as 10-digits decimal
    function getCurrentExchangeRate() external view returns (uint256) {
        if (totalSupply() == 0) {
            return Decimal.ONE;
        } else if (debtClaimed) {
            return cash().divDecimal(totalSupply());
        } else {
            BorrowInfo memory info = _accrueInterestVirtual();
            return
                (_availableToProviders(info) + info.borrows).divDecimal(
                    totalSupply()
                );
        }
    }

    /// @notice Function to get current borrow interest rate
    /// @return Borrow interest rate as 18-digit decimal
    function getBorrowRate() public view returns (uint256) {
        BorrowInfo memory info = _accrueInterestVirtual();
        return
            interestRateModel.getBorrowRate(
                cash(),
                info.borrows,
                info.reserves + info.insurance + (info.borrows - info.principal)
            );
    }

    /// @notice Function to get current supply interest rate
    /// @return Supply interest rate as 18-digit decimal
    function getSupplyRate() external view returns (uint256) {
        BorrowInfo memory info = _accrueInterestVirtual();
        return
            interestRateModel.getSupplyRate(
                cash(),
                info.borrows,
                info.reserves +
                    info.insurance +
                    (info.borrows - info.principal),
                reserveFactor + insuranceFactor
            );
    }

    /// @notice Function to get current utilization rate
    /// @return Utilization rate as 18-digit decimal
    function getUtilizationRate() external view returns (uint256) {
        BorrowInfo memory info = _accrueInterestVirtual();
        return
            interestRateModel.utilizationRate(
                cash(),
                info.borrows,
                info.insurance + info.reserves + _interest(info)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./PoolBase.sol";

/// @notice This contract describes everything related to Pool's reward logic
abstract contract PoolRewards is PoolBase {
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Amount of CPOOL rewards per second for liquidity providers in this pool
    uint256 public rewardPerSecond;

    /// @notice Value by which all rewards are magnified for calculation
    uint256 internal constant REWARD_MAGNITUDE = 2**128;

    /// @notice Timestamp when last staking reward distribution occured
    uint256 internal _lastRewardDistribution;

    /// @notice Reward per LP token, magnified by 2**128 for increased precision
    uint256 internal _magnifiedRewardPerShare;

    /// @notice Reward corrections of accounts (to remain previous rewards unchanged when user's balance changes)
    mapping(address => int256) internal _magnifiedRewardCorrections;

    /// @notice Reward withdrawals of accounts
    mapping(address => uint256) internal _withdrawals;

    // EVENTS

    /// @notice Event emitted when account withdraws his reward
    /// @param account Account who withdraws reward
    /// @param amount Amount of reward tokens withdrawn
    event RewardWithdrawn(address indexed account, uint256 amount);

    /// @notice Event emitted when new reward per block is set
    /// @param newRewardPerSecond New amount of reward tokens distirbuted per second
    event RewardPerSecondSet(uint256 newRewardPerSecond);

    // PUBLIC FUNCTIONS

    /// @notice Function is called through Factory to withdraw reward for some user
    /// @param account Account to withdraw reward for
    /// @return Withdrawn amount
    function withdrawReward(address account)
        external
        onlyFactory
        returns (uint256)
    {
        _accrueInterest();
        _distributeReward();

        uint256 withdrawable = withdrawableRewardOf(account);
        if (withdrawable > 0) {
            _withdrawals[account] += withdrawable;
            emit RewardWithdrawn(account, withdrawable);
        }

        return withdrawable;
    }

    /// @notice Function is called by Factory to set new reward speed per second
    /// @param rewardPerSecond_ New reward per second
    function setRewardPerSecond(uint256 rewardPerSecond_) external onlyFactory {
        _accrueInterest();
        _distributeReward();
        if (_lastRewardDistribution == 0) {
            _lastRewardDistribution = _info.lastAccrual;
        }
        rewardPerSecond = rewardPerSecond_;

        emit RewardPerSecondSet(rewardPerSecond_);
    }

    // VIEW FUNCTIONS

    /// @notice Gets total accumulated reward of some account
    /// @return Total accumulated reward of account
    function accumulativeRewardOf(address account)
        public
        view
        returns (uint256)
    {
        BorrowInfo memory info = _accrueInterestVirtual();
        uint256 currentRewardPerShare = _magnifiedRewardPerShare;
        if (
            _lastRewardDistribution != 0 &&
            info.lastAccrual > _lastRewardDistribution &&
            totalSupply() > 0
        ) {
            uint256 period = info.lastAccrual - _lastRewardDistribution;
            currentRewardPerShare +=
                (REWARD_MAGNITUDE * period * rewardPerSecond) /
                totalSupply();
        }

        return
            ((balanceOf(account) * currentRewardPerShare).toInt256() +
                _magnifiedRewardCorrections[account]).toUint256() /
            REWARD_MAGNITUDE;
    }

    /// @notice Gets withdrawn part of reward of some account
    /// @return Withdrawn reward of account
    function withdrawnRewardOf(address account) public view returns (uint256) {
        return _withdrawals[account];
    }

    /// @notice Gets currently withdrawable reward of some account
    /// @return Withdrawable reward of account
    function withdrawableRewardOf(address account)
        public
        view
        returns (uint256)
    {
        return accumulativeRewardOf(account) - withdrawnRewardOf(account);
    }

    // INTERNAL FUNCTIONS

    /// @notice Internal function for rewards distribution
    function _distributeReward() internal {
        if (
            rewardPerSecond > 0 &&
            _lastRewardDistribution != 0 &&
            _info.lastAccrual > _lastRewardDistribution &&
            totalSupply() > 0
        ) {
            uint256 period = _info.lastAccrual - _lastRewardDistribution;
            _magnifiedRewardPerShare +=
                (REWARD_MAGNITUDE * period * rewardPerSecond) /
                totalSupply();
        }
        _lastRewardDistribution = _info.lastAccrual;
    }

    /// @notice Override of mint function with rewards corrections
    /// @param account Account to mint for
    /// @param amount Amount to mint
    function _mint(address account, uint256 amount) internal virtual override {
        _distributeReward();

        super._mint(account, amount);
        _magnifiedRewardCorrections[account] -= (_magnifiedRewardPerShare *
            amount).toInt256();
    }

    /// @notice Override of burn function with rewards corrections
    /// @param account Account to burn from
    /// @param amount Amount to burn
    function _burn(address account, uint256 amount) internal virtual override {
        _distributeReward();

        super._burn(account, amount);
        _magnifiedRewardCorrections[account] += (_magnifiedRewardPerShare *
            amount).toInt256();
    }

    /// @notice Override of transfer function with rewards corrections
    /// @param from Account to transfer from
    /// @param to Account to transfer to
    /// @param amount Amount to transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        _accrueInterest();
        _distributeReward();

        super._transfer(from, to, amount);
        _magnifiedRewardCorrections[from] += (_magnifiedRewardPerShare * amount)
            .toInt256();
        _magnifiedRewardCorrections[to] -= (_magnifiedRewardPerShare * amount)
            .toInt256();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PoolBase.sol";

/// @notice This contract describes pool's configuration functions
abstract contract PoolConfiguration is PoolBase {
    /// @notice Function is used to update pool's manager (only called through factory)
    /// @param manager_ New manager of the pool
    function setManager(address manager_) external onlyFactory {
        require(manager_ != address(0), "AIZ");
        manager = manager_;
    }

    /// @notice Function is used to update pool's interest rate model (only called by governor)
    /// @param interestRateModel_ New IRM of the pool
    function setInterestRateModel(IInterestRateModel interestRateModel_)
        external
        onlyGovernor
    {
        require(address(interestRateModel_) != address(0), "AIZ");

        _accrueInterest();
        interestRateModel = interestRateModel_;
    }

    /// @notice Function is used to update pool's reserve factor (only called by governor)
    /// @param reserveFactor_ New reserve factor of the pool
    function setReserveFactor(uint256 reserveFactor_) external onlyGovernor {
        require(reserveFactor + insuranceFactor <= Decimal.ONE, "GTO");
        reserveFactor = reserveFactor_;
    }

    /// @notice Function is used to update pool's insurance factor (only called by governor)
    /// @param insuranceFactor_ New insurance factor of the pool
    function setInsuranceFactor(uint256 insuranceFactor_)
        external
        onlyGovernor
    {
        require(reserveFactor + insuranceFactor <= Decimal.ONE, "GTO");
        insuranceFactor = insuranceFactor_;
    }

    /// @notice Function is used to update pool's warning utilization (only called by governor)
    /// @param warningUtilization_ New warning utilization of the pool
    function setWarningUtilization(uint256 warningUtilization_)
        external
        onlyGovernor
    {
        require(warningUtilization <= Decimal.ONE, "GTO");

        _accrueInterest();
        warningUtilization = warningUtilization_;
        _checkUtilization();
    }

    /// @notice Function is used to update pool's provisional default utilization (only called by governor)
    /// @param provisionalDefaultUtilization_ New provisional default utilization of the pool
    function setProvisionalDefaultUtilization(
        uint256 provisionalDefaultUtilization_
    ) external onlyGovernor {
        require(provisionalDefaultUtilization_ <= Decimal.ONE, "GTO");

        _accrueInterest();
        provisionalDefaultUtilization = provisionalDefaultUtilization_;
        _checkUtilization();
    }

    /// @notice Function is used to update pool's warning grace period (only called by governor)
    /// @param warningGracePeriod_ New warning grace period of the pool
    function setWarningGracePeriod(uint256 warningGracePeriod_)
        external
        onlyGovernor
    {
        _accrueInterest();
        warningGracePeriod = warningGracePeriod_;
        _checkUtilization();
    }

    /// @notice Function is used to update pool's max inactive period (only called by governor)
    /// @param maxInactivePeriod_ New max inactive period of the pool
    function setMaxInactivePeriod(uint256 maxInactivePeriod_)
        external
        onlyGovernor
    {
        _accrueInterest();
        maxInactivePeriod = maxInactivePeriod_;
    }

    /// @notice Function is used to update pool's period to start auction (only called by governor)
    /// @param periodToStartAuction_ New period to start auction of the pool
    function setPeriodToStartAuction(uint256 periodToStartAuction_)
        external
        onlyGovernor
    {
        periodToStartAuction = periodToStartAuction_;
    }

    /// @notice Function is used to update pool's symbol (only called by governor)
    /// @param symbol_ New symbol of the pool
    function setSymbol(string memory symbol_) external onlyGovernor {
        _symbol = symbol_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "./PoolBaseInfo.sol";
import "../libraries/Decimal.sol";
import "../interfaces/IAuction.sol";

/// @notice This contract describes basic logic of the Pool - everything related to borrowing
abstract contract PoolBase is PoolBaseInfo {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Decimal for uint256;

    // PUBLIC FUNCTIONS

    /// @notice Function is used to provide liquidity for Pool in exchange for cpTokens
    /// @dev Approval for desired amount of currency token should be given in prior
    /// @param currencyAmount Amount of currency token that user want to provide
    function provide(uint256 currencyAmount) external {
        _provide(currencyAmount);
    }

    /// @notice Function is used to provide liquidity for Pool in exchange for cpTokens, using EIP2612 off-chain signed permit for currency
    /// @param currencyAmount Amount of currency token that user want to provide
    /// @param deadline Deadline for EIP2612 approval
    /// @param v V component of permit signature
    /// @param r R component of permit signature
    /// @param s S component of permit signature
    function provideWithPermit(
        uint256 currencyAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20PermitUpgradeable(address(currency)).permit(
            msg.sender,
            address(this),
            currencyAmount,
            deadline,
            v,
            r,
            s
        );
        _provide(currencyAmount);
    }

    /// @notice Function is used to redeem previously provided liquidity with interest, burning cpTokens
    /// @param tokens Amount of cpTokens to burn (MaxUint256 to burn maximal possible)
    function redeem(uint256 tokens) external {
        _accrueInterest();

        uint256 exchangeRate = _storedExchangeRate();
        uint256 currencyAmount;
        if (tokens == type(uint256).max) {
            (tokens, currencyAmount) = _maxWithdrawable(exchangeRate);
        } else {
            currencyAmount = tokens.mulDecimal(exchangeRate);
        }
        _redeem(tokens, currencyAmount);
    }

    /// @notice Function is used to redeem previously provided liquidity with interest, burning cpTokens
    /// @param currencyAmount Amount of currency to redeem (MaxUint256 to redeem maximal possible)
    function redeemCurrency(uint256 currencyAmount) external {
        _accrueInterest();

        uint256 exchangeRate = _storedExchangeRate();
        uint256 tokens;
        if (currencyAmount == type(uint256).max) {
            (tokens, currencyAmount) = _maxWithdrawable(exchangeRate);
        } else {
            tokens = currencyAmount.divDecimal(exchangeRate);
        }
        _redeem(tokens, currencyAmount);
    }

    /// @notice Function is used to borrow from the pool
    /// @param amount Amount of currency to borrow (MaxUint256 to borrow everything available)
    /// @param receiver Address where to transfer currency
    function borrow(uint256 amount, address receiver)
        external
        onlyManager
        onlyActiveAccrual
    {
        if (amount == type(uint256).max) {
            amount = _availableToBorrow(_info);
        } else {
            require(amount <= _availableToBorrow(_info), "NEL");
        }
        require(amount > 0, "CBZ");

        _info.principal += amount;
        _info.borrows += amount;
        _transferOut(receiver, amount);
        //currency.safeTransfer(receiver, amount);

        _checkUtilization();

        emit Borrowed(amount, receiver);
    }

    /// @notice Function is used to repay borrowed funds
    /// @param amount Amount to repay (MaxUint256 to repay all debt)
    /// @param closeNow True to close pool immedeately
    function repay(uint256 amount, bool closeNow)
        external
        onlyManager
        onlyActiveAccrual
    {
        if (amount == type(uint256).max) {
            amount = _info.borrows;
        } else {
            require(amount <= _info.borrows, "MTB");
        }

        _transferIn(msg.sender, amount);
        //currency.safeTransferFrom(msg.sender, address(this), amount);

        if (amount > _info.borrows - _info.principal) {
            _info.principal -= amount - (_info.borrows - _info.principal);
        }
        _info.borrows -= amount;

        _checkUtilization();

        emit Repaid(amount);

        if (closeNow) {
            require(_info.borrows == 0, "BNZ");
            _close();
        }
    }

    /// @notice Function is used to close pool
    function close() external {
        _accrueInterest();

        address governor = factory.owner();
        address debtOwner = ownerOfDebt();

        bool managerClosing = _info.borrows == 0 && msg.sender == manager;
        bool inactiveOverMax = _info.enteredZeroUtilization != 0 &&
            block.timestamp > _info.enteredZeroUtilization + maxInactivePeriod;
        bool governorClosing = msg.sender == governor &&
            (inactiveOverMax || debtOwner != address(0));
        bool ownerOfDebtClosing = msg.sender == debtOwner;

        require(managerClosing || governorClosing || ownerOfDebtClosing, "SCC");
        _close();
    }

    /// @notice Function is used to distribute insurance and close pool after period to start auction passed
    function allowWithdrawalAfterNoAuction() external {
        _accrueInterest();

        bool isDefaulting = _state(_info) == State.Default;
        bool auctionNotStarted = IAuction(factory.auction()).state(
            address(this)
        ) == IAuction.State.NotStarted;
        bool periodToStartPassed = block.timestamp >=
            _info.lastAccrual + periodToStartAuction;
        require(
            isDefaulting && auctionNotStarted && periodToStartPassed,
            "CDC"
        );
        _info.insurance = 0;
        debtClaimed = true;
        _close();
    }

    /// @notice Function is called by governor to transfer reserves to the treasury
    function transferReserves() external onlyGovernor {
        _accrueInterest();
        _transferReserves();
    }

    /// @notice Function is called by governor to force pool default (in case of default in other chain)
    function forceDefault() external onlyGovernor onlyActiveAccrual {
        _info.state = State.Default;
    }

    /// @notice Function is called by Auction contract when auction is started
    function processAuctionStart() external onlyAuction {
        _accrueInterest();
        _transferReserves();
        factory.burnStake();
    }

    /// @notice Function is called by Auction contract to process pool debt claim
    function processDebtClaim() external onlyAuction {
        _accrueInterest();
        _info.state = State.Default;

        address debtOwner = ownerOfDebt();
        if (_info.insurance > 0) {
            _transferOut(debtOwner, _info.insurance);
            //currency.safeTransfer(debtOwner, _info.insurance);
            _info.insurance = 0;
        }
        debtClaimed = true;
    }

    // INTERNAL FUNCTIONS

    /// @notice Internal function that processes providing liquidity for Pool in exchange for cpTokens
    /// @param currencyAmount Amount of currency token that user want to provide
    function _provide(uint256 currencyAmount) internal onlyActiveAccrual {
        uint256 exchangeRate = _storedExchangeRate();
        _transferIn(msg.sender, currencyAmount);
        //currency.safeTransferFrom(msg.sender, address(this), currencyAmount);
        uint256 tokens = currencyAmount.divDecimal(exchangeRate);
        _mint(msg.sender, tokens);
        _checkUtilization();

        emit Provided(msg.sender, currencyAmount, tokens);
    }

    /// @notice Internal function that processes token redemption
    /// @param tokensAmount Amount of tokens being redeemed
    /// @param currencyAmount Equivalent amount of currency
    function _redeem(uint256 tokensAmount, uint256 currencyAmount) internal {
        if (debtClaimed) {
            require(currencyAmount <= cash(), "NEC");
        } else {
            require(
                currencyAmount <= _availableToProviders(_info) &&
                    currencyAmount <= _availableProvisionalDefault(_info),
                "NEC"
            );
        }

        _burn(msg.sender, tokensAmount);
        _transferOut(msg.sender, currencyAmount);
        //currency.safeTransfer(msg.sender, currencyAmount);
        if (!debtClaimed) {
            _checkUtilization();
        }

        emit Redeemed(msg.sender, currencyAmount, tokensAmount);
    }

    /// @notice Internal function to transfer reserves to the treasury
    function _transferReserves() internal {
        _transferOut(factory.treasury(), _info.reserves);
        //currency.safeTransfer(factory.treasury(), _info.reserves);
        _info.reserves = 0;
    }

    /// @notice Internal function for closing pool
    function _close() internal {
        require(_info.state != State.Closed, "PIC");

        _info.state = State.Closed;
        _transferReserves();
        if (_info.insurance > 0) {
            _transferOut(manager, _info.insurance);
            //currency.safeTransfer(manager, _info.insurance);
            _info.insurance = 0;
        }
        factory.closePool();
        emit Closed();
    }

    /// @notice Internal function to accrue interest
    function _accrueInterest() internal {
        _info = _accrueInterestVirtual();
    }

    /// @notice Internal function that is called at each action to check for zero/warning/default utilization
    function _checkUtilization() internal {
        if (_info.borrows == 0) {
            _info.enteredProvisionalDefault = 0;
            if (_info.enteredZeroUtilization == 0) {
                _info.enteredZeroUtilization = block.timestamp;
            }
            return;
        }

        _info.enteredZeroUtilization = 0;

        if (_info.borrows >= _poolSize(_info).mulDecimal(warningUtilization)) {
            if (
                _info.enteredProvisionalDefault == 0 &&
                _info.borrows >=
                _poolSize(_info).mulDecimal(provisionalDefaultUtilization)
            ) {
                _info.enteredProvisionalDefault = block.timestamp;
            }
        } else {
            _info.enteredProvisionalDefault = 0;
        }
    }

    function _transferIn(address from, uint256 amount) internal virtual {
        currency.safeTransferFrom(from, address(this), amount);
    }

    function _transferOut(address to, uint256 amount) internal virtual {
        currency.safeTransfer(to, amount);
    }

    // PUBLIC VIEW

    /// @notice Function to get owner of the pool's debt
    /// @return Pool's debt owner
    function ownerOfDebt() public view returns (address) {
        return IAuction(factory.auction()).ownerOfDebt(address(this));
    }

    /// @notice Function returns cash amount (balance of currency in the pool)
    /// @return Cash amount
    function cash() public view virtual returns (uint256) {
        return currency.balanceOf(address(this));
    }

    // INTERNAL VIEW

    /// @notice Function to get current pool state
    /// @return Pool state as State enumerable
    function _state(BorrowInfo memory info) internal view returns (State) {
        if (info.state == State.Closed || info.state == State.Default) {
            return info.state;
        }
        if (info.enteredProvisionalDefault != 0) {
            if (
                block.timestamp >=
                info.enteredProvisionalDefault + warningGracePeriod
            ) {
                return State.Default;
            } else {
                return State.ProvisionalDefault;
            }
        }
        if (
            info.borrows > 0 &&
            info.borrows >= _poolSize(info).mulDecimal(warningUtilization)
        ) {
            return State.Warning;
        }
        return info.state;
    }

    /// @notice Function returns interest value for given borrow info
    /// @param info Borrow info struct
    /// @return Interest for given info
    function _interest(BorrowInfo memory info) internal pure returns (uint256) {
        return info.borrows - info.principal;
    }

    /// @notice Function returns amount of funds generally available for providers value for given borrow info
    /// @param info Borrow info struct
    /// @return Available to providers for given info
    function _availableToProviders(BorrowInfo memory info)
        internal
        view
        returns (uint256)
    {
        return cash() - info.reserves - info.insurance;
    }

    /// @notice Function returns available to borrow value for given borrow info
    /// @param info Borrow info struct
    /// @return Available to borrow for given info
    function _availableToBorrow(BorrowInfo memory info)
        internal
        view
        returns (uint256)
    {
        uint256 basicAvailable = _availableToProviders(info) - _interest(info);
        uint256 borrowsForWarning = _poolSize(info).mulDecimal(
            warningUtilization
        );
        if (borrowsForWarning > info.borrows) {
            return
                MathUpgradeable.min(
                    borrowsForWarning - info.borrows,
                    basicAvailable
                );
        } else {
            return 0;
        }
    }

    /// @notice Function returns pool size for given borrow info
    /// @param info Borrow info struct
    /// @return Pool size for given info
    function _poolSize(BorrowInfo memory info) internal view returns (uint256) {
        return _availableToProviders(info) + info.principal;
    }

    /// @notice Function returns funds available to be taken from pool before provisional default will be reached
    /// @param info Borrow info struct
    /// @return Pool size for given info
    function _availableProvisionalDefault(BorrowInfo memory info)
        internal
        view
        returns (uint256)
    {
        if (provisionalDefaultUtilization == 0) {
            return 0;
        }
        uint256 poolSizeForProvisionalDefault = info.borrows.divDecimal(
            provisionalDefaultUtilization
        );
        uint256 currentPoolSize = _poolSize(info);
        return
            currentPoolSize > poolSizeForProvisionalDefault
                ? currentPoolSize - poolSizeForProvisionalDefault
                : 0;
    }

    /// @notice Function returns maximal redeemable amount for given exchange rate
    /// @param exchangeRate Exchange rate of cp-tokens to currency
    /// @return tokensAmount Maximal redeemable amount of tokens
    /// @return currencyAmount Maximal redeemable amount of currency
    function _maxWithdrawable(uint256 exchangeRate)
        internal
        view
        returns (uint256 tokensAmount, uint256 currencyAmount)
    {
        currencyAmount = _availableToProviders(_info);
        if (!debtClaimed) {
            uint256 availableProvisionalDefault = _availableProvisionalDefault(
                _info
            );
            if (availableProvisionalDefault < currencyAmount) {
                currencyAmount = availableProvisionalDefault;
            }
        }
        tokensAmount = currencyAmount.divDecimal(exchangeRate);

        if (balanceOf(msg.sender) < tokensAmount) {
            tokensAmount = balanceOf(msg.sender);
            currencyAmount = tokensAmount.mulDecimal(exchangeRate);
        }
    }

    /// @notice Function returns stored (without accruing) exchange rate of cpTokens for currency tokens
    /// @return Stored exchange rate as 10-digits decimal
    function _storedExchangeRate() internal view returns (uint256) {
        if (totalSupply() == 0) {
            return Decimal.ONE;
        } else if (debtClaimed) {
            return cash().divDecimal(totalSupply());
        } else {
            return
                (_availableToProviders(_info) + _info.borrows).divDecimal(
                    totalSupply()
                );
        }
    }

    /// @notice Function returns timestamp when pool entered or will enter provisional default at given interest rate
    /// @param interestRate Borrows interest rate at current period
    /// @return Timestamp of entering provisional default (0 if won't ever enter)
    function _entranceOfProvisionalDefault(uint256 interestRate)
        internal
        view
        returns (uint256)
    {
        if (_info.enteredProvisionalDefault != 0) {
            return _info.enteredProvisionalDefault;
        }
        if (_info.borrows == 0 || interestRate == 0) {
            return 0;
        }

        // Consider:
        // IFPD - Interest for provisional default
        // PSPD = Pool size at provisional default
        // IRPD = Reserves & insurance at provisional default
        // IR = Current reserves and insurance
        // PDU = Provisional default utilization
        // We have: Borrows + IFPD = PDU * PSPD
        // => Borrows + IFPD = PDU * (Principal + Cash + IRPD)
        // => Borrows + IFPD = PDU * (Principal + Cash + IR + IFPD * (insuranceFactor + reserveFactor))
        // => IFPD * (1 + PDU * (reserveFactor + insuranceFactor)) = PDU * PoolSize - Borrows
        // => IFPD = (PDU * PoolSize - Borrows) / (1 + PDU * (reserveFactor + insuranceFactor))
        uint256 numerator = _poolSize(_info).mulDecimal(
            provisionalDefaultUtilization
        ) - _info.borrows;
        uint256 denominator = Decimal.ONE +
            provisionalDefaultUtilization.mulDecimal(
                reserveFactor + insuranceFactor
            );
        uint256 interestForProvisionalDefault = numerator.divDecimal(
            denominator
        );

        uint256 interestPerSec = _info.borrows * interestRate;
        // Time delta is calculated as interest for provisional default divided by interest per sec (rounded up)
        uint256 timeDelta = (interestForProvisionalDefault *
            Decimal.ONE +
            interestPerSec -
            1) / interestPerSec;
        uint256 entrance = _info.lastAccrual + timeDelta;
        return entrance <= block.timestamp ? entrance : 0;
    }

    /// @notice Function virtually accrues interest and returns updated borrow info struct
    /// @return Borrow info struct after accrual
    function _accrueInterestVirtual()
        internal
        view
        returns (BorrowInfo memory)
    {
        BorrowInfo memory newInfo = _info;

        if (
            block.timestamp == newInfo.lastAccrual ||
            newInfo.state == State.Default ||
            newInfo.state == State.Closed
        ) {
            return newInfo;
        }

        uint256 interestRate = interestRateModel.getBorrowRate(
            cash(),
            newInfo.borrows,
            newInfo.reserves + newInfo.insurance + _interest(newInfo)
        );

        newInfo.lastAccrual = block.timestamp;
        newInfo.enteredProvisionalDefault = _entranceOfProvisionalDefault(
            interestRate
        );
        if (
            newInfo.enteredProvisionalDefault != 0 &&
            newInfo.enteredProvisionalDefault + warningGracePeriod <
            newInfo.lastAccrual
        ) {
            newInfo.lastAccrual =
                newInfo.enteredProvisionalDefault +
                warningGracePeriod;
        }

        uint256 interestDelta = newInfo.borrows.mulDecimal(
            interestRate * (newInfo.lastAccrual - _info.lastAccrual)
        );
        uint256 reservesDelta = interestDelta.mulDecimal(reserveFactor);
        uint256 insuranceDelta = interestDelta.mulDecimal(insuranceFactor);

        if (
            newInfo.borrows + interestDelta + reservesDelta + insuranceDelta >
            _poolSize(newInfo)
        ) {
            interestDelta = (_poolSize(newInfo) - newInfo.borrows).divDecimal(
                Decimal.ONE + reserveFactor + insuranceFactor
            );
            uint256 interestPerSec = newInfo.borrows.mulDecimal(interestRate);
            if (interestPerSec > 0) {
                // Previous last accrual plus interest divided by interest speed (rounded up)
                newInfo.lastAccrual =
                    _info.lastAccrual +
                    (interestDelta + interestPerSec - 1) /
                    interestPerSec;
            }

            reservesDelta = interestDelta.mulDecimal(reserveFactor);
            insuranceDelta = interestDelta.mulDecimal(insuranceFactor);
            newInfo.state = State.Default;
        }

        newInfo.borrows += interestDelta;
        newInfo.reserves += reservesDelta;
        newInfo.insurance += insuranceDelta;

        return newInfo;
    }

    // MODIFIERS

    /// @notice Modifier to accrue interest and check that pool is currently active (possibly in warning)
    modifier onlyActiveAccrual() {
        _accrueInterest();
        State currentState = _state(_info);
        require(
            currentState == State.Active ||
                currentState == State.Warning ||
                currentState == State.ProvisionalDefault,
            "PIA"
        );
        _;
    }

    /// @notice Modifier for functions restricted to manager
    modifier onlyManager() {
        require(msg.sender == manager, "OM");
        _;
    }

    /// @notice Modifier for functions restricted to protocol governor
    modifier onlyGovernor() {
        require(msg.sender == factory.owner(), "OG");
        _;
    }

    /// @notice Modifier for functions restricted to auction contract
    modifier onlyAuction() {
        require(msg.sender == factory.auction(), "OA");
        _;
    }

    /// @notice Modifier for the functions restricted to factory
    modifier onlyFactory() {
        require(msg.sender == address(factory), "OF");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Decimal {
    /// @notice Number one as 18-digit decimal
    uint256 internal constant ONE = 1e18;

    /**
     * @notice Internal function for 10-digits decimal division
     * @param number Integer number
     * @param decimal Decimal number
     * @return Returns multiplied numbers
     */
    function mulDecimal(uint256 number, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        return (number * decimal) / ONE;
    }

    /**
     * @notice Internal function for 10-digits decimal multiplication
     * @param number Integer number
     * @param decimal Decimal number
     * @return Returns integer number divided by second
     */
    function divDecimal(uint256 number, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        return (number * ONE) / decimal;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IInterestRateModel.sol";

/// @notice This contract describes Pool's storage, events and initializer
abstract contract PoolBaseInfo is ERC20Upgradeable {
    /// @notice Address of the pool's manager
    address public manager;

    /// @notice Pool currency token
    IERC20Upgradeable public currency;

    /// @notice PoolFactory contract
    IPoolFactory public factory;

    /// @notice InterestRateModel contract address
    IInterestRateModel public interestRateModel;

    /// @notice Reserve factor as 18-digit decimal
    uint256 public reserveFactor;

    /// @notice Insurance factor as 18-digit decimal
    uint256 public insuranceFactor;

    /// @notice Pool utilization that leads to warning state (as 18-digit decimal)
    uint256 public warningUtilization;

    /// @notice Pool utilization that leads to provisional default (as 18-digit decimal)
    uint256 public provisionalDefaultUtilization;

    /// @notice Grace period for warning state before pool goes to default (in seconds)
    uint256 public warningGracePeriod;

    /// @notice Max period for which pool can stay not active before it can be closed by governor (in seconds)
    uint256 public maxInactivePeriod;

    /// @notice Period after default to start auction after which pool can be closed by anyone (in seconds)
    uint256 public periodToStartAuction;

    enum State {
        Active,
        Warning,
        ProvisionalDefault,
        Default,
        Closed
    }

    /// @notice Indicator if debt has been claimed
    bool public debtClaimed;

    /// @notice Structure describing all pool's borrows details
    struct BorrowInfo {
        uint256 principal;
        uint256 borrows;
        uint256 reserves;
        uint256 insurance;
        uint256 lastAccrual;
        uint256 enteredProvisionalDefault;
        uint256 enteredZeroUtilization;
        State state;
    }

    /// @notice Last updated borrow info
    BorrowInfo internal _info;

    /// @notice Pool's symbol
    string internal _symbol;

    // EVENTS

    /// @notice Event emitted when pool is closed
    event Closed();

    /// @notice Event emitted when liquidity is provided to the Pool
    /// @param provider Address who provided liquidity
    /// @param currencyAmount Amount of pool's currency provided
    /// @param tokens Amount of cp-tokens received by provider in response
    event Provided(
        address indexed provider,
        uint256 currencyAmount,
        uint256 tokens
    );

    /// @notice Event emitted when liquidity is redeemed from the Pool
    /// @param redeemer Address who redeems liquidity
    /// @param currencyAmount Amount of currency received by redeemer
    /// @param tokens Amount of given and burned cp-tokens
    event Redeemed(
        address indexed redeemer,
        uint256 currencyAmount,
        uint256 tokens
    );

    /// @notice Event emitted when manager assignes liquidity
    /// @param amount Amount of currency borrower
    /// @param receiver Address where borrow has been transferred
    event Borrowed(uint256 amount, address indexed receiver);

    /// @notice Event emitted when manager returns liquidity assignment
    /// @param amount Amount of currency repaid
    event Repaid(uint256 amount);

    // CONSTRUCTOR

    /// @notice Upgradeable contract constructor
    /// @param manager_ Address of the Pool's manager
    /// @param currency_ Address of the currency token
    function __PoolBaseInfo_init(address manager_, IERC20Upgradeable currency_)
        internal
        onlyInitializing
    {
        require(manager_ != address(0), "AIZ");
        require(address(currency_) != address(0), "AIZ");

        manager = manager_;
        currency = currency_;
        factory = IPoolFactory(msg.sender);

        interestRateModel = IInterestRateModel(factory.interestRateModel());
        reserveFactor = factory.reserveFactor();
        insuranceFactor = factory.insuranceFactor();
        warningUtilization = factory.warningUtilization();
        provisionalDefaultUtilization = factory.provisionalDefaultUtilization();
        warningGracePeriod = factory.warningGracePeriod();
        maxInactivePeriod = factory.maxInactivePeriod();
        periodToStartAuction = factory.periodToStartAuction();

        _symbol = factory.getPoolSymbol(address(currency), address(manager));
        __ERC20_init(string(bytes.concat(bytes("Pool "), bytes(_symbol))), "");

        _info.enteredZeroUtilization = block.timestamp;
        _info.lastAccrual = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAuction {
    function bid(address pool, uint256 amount) external;

    function ownerOfDebt(address pool) external view returns (address);

    /// @notice States of auction
    /// @dev None: A pool is not default and auction can't be started
    /// @dev NotStarted: A pool is default and auction can be started
    /// @dev Active: An auction is started
    /// @dev Finished: An auction is finished but NFT is not claimed
    /// @dev Closed: An auction is finished and NFT is claimed
    enum State {
        None,
        NotStarted,
        Active,
        Finished,
        Closed
    }

    function state(address pool) external view returns (State);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPoolFactory {
    function getPoolSymbol(address currency, address manager)
        external
        view
        returns (string memory);

    function isPool(address pool) external view returns (bool);

    function interestRateModel() external view returns (address);

    function auction() external view returns (address);

    function treasury() external view returns (address);

    function reserveFactor() external view returns (uint256);

    function insuranceFactor() external view returns (uint256);

    function warningUtilization() external view returns (uint256);

    function provisionalDefaultUtilization() external view returns (uint256);

    function warningGracePeriod() external view returns (uint256);

    function maxInactivePeriod() external view returns (uint256);

    function periodToStartAuction() external view returns (uint256);

    function owner() external view returns (address);

    function closePool() external;

    function burnStake() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IInterestRateModel {
    function getBorrowRate(
        uint256 balance,
        uint256 totalBorrows,
        uint256 totalReserves
    ) external view returns (uint256);

    function utilizationRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves
    ) external pure returns (uint256);

    function getSupplyRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view returns (uint256);
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}