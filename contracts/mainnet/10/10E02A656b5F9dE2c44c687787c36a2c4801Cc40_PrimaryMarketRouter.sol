// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "../fund/ShareStaking.sol";

import "../interfaces/IPrimaryMarketRouter.sol";
import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/ISwapRouter.sol";
import "../interfaces/IStableSwap.sol";
import "../interfaces/IWrappedERC20.sol";

contract PrimaryMarketRouter is IPrimaryMarketRouter, ITrancheIndexV2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IPrimaryMarketV3 public immutable primaryMarket;
    IFundV3 public immutable fund;
    IERC20 private immutable _tokenUnderlying;
    address private immutable _tokenB;

    constructor(address pm) public {
        primaryMarket = IPrimaryMarketV3(pm);
        IFundV3 fund_ = IFundV3(IPrimaryMarketV3(pm).fund());
        fund = fund_;
        _tokenUnderlying = IERC20(fund_.tokenUnderlying());
        _tokenB = fund_.tokenB();
    }

    /// @dev Get redemption with StableSwap getQuoteOut interface.
    function getQuoteOut(uint256 baseIn) external view override returns (uint256 quoteOut) {
        (quoteOut, ) = primaryMarket.getRedemption(baseIn);
    }

    /// @dev Get creation for QUEEN with StableSwap getQuoteIn interface.
    function getQuoteIn(uint256 baseOut) external view override returns (uint256 quoteIn) {
        quoteIn = primaryMarket.getCreationForQ(baseOut);
    }

    /// @dev Get creation with StableSwap getBaseOut interface.
    function getBaseOut(uint256 quoteIn) external view override returns (uint256 baseOut) {
        baseOut = primaryMarket.getCreation(quoteIn);
    }

    /// @dev Get redemption for underlying with StableSwap getBaseIn interface.
    function getBaseIn(uint256 quoteOut) external view override returns (uint256 baseIn) {
        baseIn = primaryMarket.getRedemptionForUnderlying(quoteOut);
    }

    /// @dev Create QUEEN with StableSwap buy interface.
    ///      Underlying should have already been sent to this contract
    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata
    ) external override returns (uint256 realBaseOut) {
        uint256 routerQuoteBalance = IERC20(_tokenUnderlying).balanceOf(address(this));
        IERC20(_tokenUnderlying).safeTransfer(address(primaryMarket), routerQuoteBalance);
        realBaseOut = primaryMarket.create(recipient, baseOut, version);
    }

    /// @dev Redeem QUEEN with StableSwap sell interface.
    ///      QUEEN should have already been sent to this contract
    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata
    ) external override returns (uint256 realQuoteOut) {
        uint256 routerBaseBalance = fund.trancheBalanceOf(TRANCHE_Q, address(this));
        realQuoteOut = primaryMarket.redeem(recipient, routerBaseBalance, quoteOut, version);
    }

    function create(
        address recipient,
        uint256 underlying,
        uint256 minOutQ,
        uint256 version
    ) public payable override returns (uint256 outQ) {
        if (msg.value > 0) {
            require(msg.value == underlying); // sanity check
            IWrappedERC20(address(_tokenUnderlying)).deposit{value: msg.value}();
            _tokenUnderlying.safeTransfer(address(primaryMarket), msg.value);
        } else {
            IERC20(_tokenUnderlying).safeTransferFrom(
                msg.sender,
                address(primaryMarket),
                underlying
            );
        }

        outQ = primaryMarket.create(recipient, minOutQ, version);
    }

    function createAndStake(
        uint256 underlying,
        uint256 minOutQ,
        address staking,
        uint256 version
    ) external payable override {
        // Create QUEEN
        uint256 outQ = create(staking, underlying, minOutQ, version);
        // Stake QUEEN
        ShareStaking(staking).deposit(TRANCHE_Q, outQ, msg.sender, version);
    }

    function createSplitAndStake(
        uint256 underlying,
        uint256 minOutQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) external payable override {
        // Create QUEEN
        uint256 outQ = create(address(this), underlying, minOutQ, version);
        _splitAndStake(outQ, router, quoteAddress, minLpOut, staking, version);
    }

    function splitAndStake(
        uint256 inQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) external override {
        fund.trancheTransferFrom(TRANCHE_Q, msg.sender, address(this), inQ, version);
        _splitAndStake(inQ, router, quoteAddress, minLpOut, staking, version);
    }

    function _splitAndStake(
        uint256 inQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) private {
        // Split QUEEN into BISHOP and ROOK
        uint256 outB = primaryMarket.split(address(this), inQ, version);
        // Add BISHOP to stable swap
        {
            IStableSwap swap = ISwapRouter(router).getSwap(_tokenB, quoteAddress);
            fund.trancheTransfer(TRANCHE_B, address(swap), outB, version);
            uint256 lpOut = swap.addLiquidity(version, msg.sender);
            require(lpOut >= minLpOut, "Insufficient output");
        }

        if (staking == address(0)) {
            fund.trancheTransfer(TRANCHE_R, msg.sender, outB, version);
        } else {
            // Stake rook
            fund.trancheTransfer(TRANCHE_R, staking, outB, version);
            ShareStaking(staking).deposit(TRANCHE_R, outB, msg.sender, version);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/CoreUtility.sol";

import "../interfaces/IFundV3.sol";
import "../interfaces/IChessController.sol";
import "../interfaces/IChessSchedule.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "../interfaces/IVotingEscrow.sol";

contract ShareStaking is ITrancheIndexV2, CoreUtility {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event Deposited(uint256 tranche, address account, uint256 amount);
    event Withdrawn(uint256 tranche, address account, uint256 amount);

    uint256 private constant MAX_ITERATIONS = 500;

    uint256 private constant REWARD_WEIGHT_B = 2;
    uint256 private constant REWARD_WEIGHT_R = 1;
    uint256 private constant REWARD_WEIGHT_Q = 3;
    uint256 private constant MAX_BOOSTING_FACTOR = 3e18;
    uint256 private constant MAX_BOOSTING_FACTOR_MINUS_ONE = MAX_BOOSTING_FACTOR - 1e18;

    IFundV3 public immutable fund;

    /// @notice The Chess release schedule contract.
    IChessSchedule public immutable chessSchedule;

    /// @notice The controller contract.
    IChessController public immutable chessController;

    IVotingEscrow private immutable _votingEscrow;

    /// @notice Timestamp when rewards start.
    uint256 public immutable rewardStartTimestamp;

    /// @dev Per-fund CHESS emission rate. The product of CHESS emission rate
    ///      and weekly percentage of the fund
    uint256 private _rate;

    /// @dev Total amount of user shares, i.e. sum of all entries in `_balances`.
    uint256[TRANCHE_COUNT] private _totalSupplies;

    /// @dev Rebalance version of `_totalSupplies`.
    uint256 private _totalSupplyVersion;

    /// @dev Amount of shares staked by each user.
    mapping(address => uint256[TRANCHE_COUNT]) private _balances;

    /// @dev Rebalance version mapping for `_balances`.
    mapping(address => uint256) private _balanceVersions;

    /// @dev Mapping of rebalance version => split ratio.
    mapping(uint256 => uint256) private _historicalSplitRatio;

    /// @dev 1e27 * ∫(rate(t) / totalWeight(t) dt) from the latest rebalance till checkpoint.
    uint256 private _invTotalWeightIntegral;

    /// @dev Final `_invTotalWeightIntegral` before each rebalance.
    ///      These values are accessed in a loop in `_userCheckpoint()` with bounds checking.
    ///      So we store them in a fixed-length array, in order to make compiler-generated
    ///      bounds checking on every access cheaper. The actual length of this array is stored in
    ///      `_historicalIntegralSize` and should be explicitly checked when necessary.
    uint256[65535] private _historicalIntegrals;

    /// @dev Actual length of the `_historicalIntegrals` array, which always equals to the number of
    ///      historical rebalances after `checkpoint()` is called.
    uint256 private _historicalIntegralSize;

    /// @dev Timestamp when checkpoint() is called.
    uint256 private _checkpointTimestamp;

    /// @dev Snapshot of `_invTotalWeightIntegral` per user.
    mapping(address => uint256) private _userIntegrals;

    /// @dev Mapping of account => claimable rewards.
    mapping(address => uint256) private _claimableRewards;

    uint256 private _workingSupply;
    mapping(address => uint256) private _workingBalances;

    constructor(
        address fund_,
        address chessSchedule_,
        address chessController_,
        address votingEscrow_,
        uint256 rewardStartTimestamp_
    ) public {
        fund = IFundV3(fund_);
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        _votingEscrow = IVotingEscrow(votingEscrow_);
        rewardStartTimestamp = rewardStartTimestamp_;
        _checkpointTimestamp = block.timestamp;
    }

    function getRate() external view returns (uint256) {
        return _rate / 1e18;
    }

    /// @notice Return weight of given balance with respect to rewards.
    /// @param amountQ Amount of QUEEN
    /// @param amountB Amount of BISHOP
    /// @param amountR Amount of ROOK
    /// @param splitRatio Split ratio
    /// @return Rewarding weight of the balance
    function weightedBalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 splitRatio
    ) public pure returns (uint256) {
        return
            amountQ
                .mul(REWARD_WEIGHT_Q)
                .multiplyDecimal(splitRatio)
                .add(amountB.mul(REWARD_WEIGHT_B))
                .add(amountR.mul(REWARD_WEIGHT_R))
                .div(REWARD_WEIGHT_Q);
    }

    function totalSupply(uint256 tranche) external view returns (uint256) {
        uint256 totalSupplyQ = _totalSupplies[TRANCHE_Q];
        uint256 totalSupplyB = _totalSupplies[TRANCHE_B];
        uint256 totalSupplyR = _totalSupplies[TRANCHE_R];

        uint256 version = _totalSupplyVersion;
        uint256 rebalanceSize = _fundRebalanceSize();
        if (version < rebalanceSize) {
            (totalSupplyQ, totalSupplyB, totalSupplyR) = _fundBatchRebalance(
                totalSupplyQ,
                totalSupplyB,
                totalSupplyR,
                version,
                rebalanceSize
            );
        }

        if (tranche == TRANCHE_Q) {
            return totalSupplyQ;
        } else if (tranche == TRANCHE_B) {
            return totalSupplyB;
        } else {
            return totalSupplyR;
        }
    }

    function trancheBalanceOf(uint256 tranche, address account) external view returns (uint256) {
        uint256 amountQ = _balances[account][TRANCHE_Q];
        uint256 amountB = _balances[account][TRANCHE_B];
        uint256 amountR = _balances[account][TRANCHE_R];

        if (tranche == TRANCHE_Q) {
            if (amountQ == 0 && amountB == 0 && amountR == 0) return 0;
        } else if (tranche == TRANCHE_B) {
            if (amountB == 0) return 0;
        } else {
            if (amountR == 0) return 0;
        }

        uint256 version = _balanceVersions[account];
        uint256 rebalanceSize = _fundRebalanceSize();
        if (version < rebalanceSize) {
            (amountQ, amountB, amountR) = _fundBatchRebalance(
                amountQ,
                amountB,
                amountR,
                version,
                rebalanceSize
            );
        }

        if (tranche == TRANCHE_Q) {
            return amountQ;
        } else if (tranche == TRANCHE_B) {
            return amountB;
        } else {
            return amountR;
        }
    }

    function balanceVersion(address account) external view returns (uint256) {
        return _balanceVersions[account];
    }

    function workingSupply() external view returns (uint256) {
        uint256 version = _totalSupplyVersion;
        uint256 rebalanceSize = _fundRebalanceSize();
        if (version < rebalanceSize) {
            (uint256 totalSupplyQ, uint256 totalSupplyB, uint256 totalSupplyR) =
                _fundBatchRebalance(
                    _totalSupplies[TRANCHE_Q],
                    _totalSupplies[TRANCHE_B],
                    _totalSupplies[TRANCHE_R],
                    version,
                    rebalanceSize
                );
            return weightedBalance(totalSupplyQ, totalSupplyB, totalSupplyR, fund.splitRatio());
        } else {
            return _workingSupply;
        }
    }

    function workingBalanceOf(address account) external view returns (uint256) {
        uint256 version = _balanceVersions[account];
        uint256 rebalanceSize = _fundRebalanceSize();
        uint256 workingBalance = _workingBalances[account]; // gas saver
        if (version < rebalanceSize || workingBalance == 0) {
            uint256[TRANCHE_COUNT] storage balance = _balances[account];
            uint256 amountQ = balance[TRANCHE_Q];
            uint256 amountB = balance[TRANCHE_B];
            uint256 amountR = balance[TRANCHE_R];
            if (version < rebalanceSize) {
                (amountQ, amountB, amountR) = _fundBatchRebalance(
                    amountQ,
                    amountB,
                    amountR,
                    version,
                    rebalanceSize
                );
            }
            return weightedBalance(amountQ, amountB, amountR, fund.splitRatio());
        } else {
            return workingBalance;
        }
    }

    function _fundRebalanceSize() internal view returns (uint256) {
        return fund.getRebalanceSize();
    }

    function _fundDoRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return fund.doRebalance(amountQ, amountB, amountR, index);
    }

    function _fundBatchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return fund.batchRebalance(amountQ, amountB, amountR, fromIndex, toIndex);
    }

    /// @dev Stake share tokens. A user could send QUEEN before deposit().
    ///      The contract first measures how much tranche share it has received,
    ///      then transfer the rest from the user
    /// @param tranche Tranche of the share
    /// @param amount The amount to deposit
    /// @param recipient Address that receives deposit
    /// @param version The current rebalance version
    function deposit(
        uint256 tranche,
        uint256 amount,
        address recipient,
        uint256 version
    ) external {
        _checkpoint(version);
        _userCheckpoint(recipient, version);
        _balances[recipient][tranche] = _balances[recipient][tranche].add(amount);
        uint256 oldTotalSupply = _totalSupplies[tranche];
        _totalSupplies[tranche] = oldTotalSupply.add(amount);
        _updateWorkingBalance(recipient, version);
        uint256 spareAmount = fund.trancheBalanceOf(tranche, address(this)).sub(oldTotalSupply);
        if (spareAmount < amount) {
            // Retain the rest of share token (version is checked by the fund)
            fund.trancheTransferFrom(
                tranche,
                msg.sender,
                address(this),
                amount - spareAmount,
                version
            );
        } else {
            require(version == _fundRebalanceSize(), "Invalid version");
        }
        emit Deposited(tranche, recipient, amount);
    }

    /// @notice Unstake tranche tokens.
    /// @param tranche Tranche of the share
    /// @param amount The amount to withdraw
    /// @param version The current rebalance version
    function withdraw(
        uint256 tranche,
        uint256 amount,
        uint256 version
    ) external {
        _checkpoint(version);
        _userCheckpoint(msg.sender, version);
        _balances[msg.sender][tranche] = _balances[msg.sender][tranche].sub(
            amount,
            "Insufficient balance to withdraw"
        );
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);
        _updateWorkingBalance(msg.sender, version);
        // version is checked by the fund
        fund.trancheTransfer(tranche, msg.sender, amount, version);
        emit Withdrawn(tranche, msg.sender, amount);
    }

    /// @notice Transform share balance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshBalance(address account, uint256 targetVersion) external {
        uint256 rebalanceSize = _fundRebalanceSize();
        if (targetVersion == 0) {
            targetVersion = rebalanceSize;
        } else {
            require(targetVersion <= rebalanceSize, "Target version out of bound");
        }
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, targetVersion);
    }

    /// @notice Return claimable rewards of an account till now.
    ///
    ///         This function should be call as a "view" function off-chain to get
    ///         the return value, e.g. using `contract.claimableRewards.call(account)` in web3
    ///         or `contract.callStatic.claimableRewards(account)` in ethers.js.
    /// @param account Address of an account
    /// @return Amount of claimable rewards
    function claimableRewards(address account) external returns (uint256) {
        uint256 rebalanceSize = _fundRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        return _claimableRewards[account];
    }

    /// @notice Claim the rewards for an account.
    /// @param account Account to claim its rewards
    function claimRewards(address account) external {
        uint256 rebalanceSize = _fundRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        uint256 amount = _claimableRewards[account];
        _claimableRewards[account] = 0;
        chessSchedule.mint(account, amount);
        _updateWorkingBalance(account, rebalanceSize);
    }

    /// @notice Synchronize an account's locked Chess with `VotingEscrow`
    ///         and update its working balance.
    /// @param account Address of the synchronized account
    function syncWithVotingEscrow(address account) external {
        uint256 rebalanceSize = _fundRebalanceSize();
        _checkpoint(rebalanceSize);
        _userCheckpoint(account, rebalanceSize);
        _updateWorkingBalance(account, rebalanceSize);
    }

    /// @dev Transform total supplies to the latest rebalance version and make a global reward checkpoint.
    /// @param rebalanceSize The number of existing rebalances. It must be the same as
    ///                       `fund.getRebalanceSize()`.
    function _checkpoint(uint256 rebalanceSize) private {
        uint256 timestamp = _checkpointTimestamp;
        if (timestamp >= block.timestamp) {
            return;
        }

        uint256 integral = _invTotalWeightIntegral;
        uint256 endWeek = _endOfWeek(timestamp);
        uint256 version = _totalSupplyVersion;
        uint256 rebalanceTimestamp;
        if (version < rebalanceSize) {
            rebalanceTimestamp = fund.getRebalanceTimestamp(version);
        } else {
            rebalanceTimestamp = type(uint256).max;
        }
        uint256 rate = _rate;
        uint256 totalSupplyQ = _totalSupplies[TRANCHE_Q];
        uint256 totalSupplyB = _totalSupplies[TRANCHE_B];
        uint256 totalSupplyR = _totalSupplies[TRANCHE_R];
        uint256 weight = _workingSupply;
        uint256 timestamp_ = timestamp; // avoid stack too deep

        for (uint256 i = 0; i < MAX_ITERATIONS && timestamp_ < block.timestamp; i++) {
            uint256 endTimestamp = rebalanceTimestamp.min(endWeek).min(block.timestamp);

            if (weight > 0 && endTimestamp > rewardStartTimestamp) {
                integral = integral.add(
                    rate
                        .mul(endTimestamp.sub(timestamp_.max(rewardStartTimestamp)))
                        .decimalToPreciseDecimal()
                        .div(weight)
                );
            }

            if (endTimestamp == rebalanceTimestamp) {
                uint256 oldSize = _historicalIntegralSize;
                _historicalIntegrals[oldSize] = integral;
                _historicalIntegralSize = oldSize + 1;

                integral = 0;
                (totalSupplyQ, totalSupplyB, totalSupplyR) = _fundDoRebalance(
                    totalSupplyQ,
                    totalSupplyB,
                    totalSupplyR,
                    version
                );

                version++;
                {
                    // Reset total weight boosting after the first rebalance
                    uint256 splitRatio = fund.historicalSplitRatio(version);
                    weight = weightedBalance(totalSupplyQ, totalSupplyB, totalSupplyR, splitRatio);
                    _historicalSplitRatio[version] = splitRatio;
                }

                if (version < rebalanceSize) {
                    rebalanceTimestamp = fund.getRebalanceTimestamp(version);
                } else {
                    rebalanceTimestamp = type(uint256).max;
                }
            }
            if (endTimestamp == endWeek) {
                rate = chessSchedule.getRate(endWeek).mul(
                    chessController.getFundRelativeWeight(address(this), endWeek)
                );
                if (endWeek < rewardStartTimestamp && endWeek + 1 weeks > rewardStartTimestamp) {
                    // Rewards start in the middle of the next week. We adjust the rate to
                    // compensate for the period between `endWeek` and `rewardStartTimestamp`.
                    rate = rate.mul(1 weeks).div(endWeek + 1 weeks - rewardStartTimestamp);
                }
                endWeek += 1 weeks;
            }

            timestamp_ = endTimestamp;
        }

        _checkpointTimestamp = block.timestamp;
        _invTotalWeightIntegral = integral;
        _rate = rate;
        if (_totalSupplyVersion != rebalanceSize) {
            _totalSupplies[TRANCHE_Q] = totalSupplyQ;
            _totalSupplies[TRANCHE_B] = totalSupplyB;
            _totalSupplies[TRANCHE_R] = totalSupplyR;
            _totalSupplyVersion = rebalanceSize;
            // Reset total working weight before any boosting if rebalance ever triggered
            _workingSupply = weight;
        }
    }

    /// @dev Transform a user's balance to a given rebalance version and update this user's rewards.
    ///
    ///      In most cases, the target version is the latest version and this function cumulates
    ///      rewards till now. When this function is called from `refreshBalance()`,
    ///      `targetVersion` can be an older version, in which case rewards are cumulated till
    ///      the end of that version (i.e. timestamp of the transaction triggering the rebalance
    ///      with index `targetVersion`).
    ///
    ///      This function should always be called after `_checkpoint()` is called, so that
    ///      the global reward checkpoint is guarenteed up to date.
    /// @param account Account to update
    /// @param targetVersion The target rebalance version
    function _userCheckpoint(address account, uint256 targetVersion) private {
        uint256 oldVersion = _balanceVersions[account];
        if (oldVersion > targetVersion) {
            return;
        }
        uint256 userIntegral = _userIntegrals[account];
        uint256 integral;
        // This scope is to avoid the "stack too deep" error.
        {
            // We assume that this function is always called immediately after `_checkpoint()`,
            // which guarantees that `_historicalIntegralSize` equals to the number of historical
            // rebalances.
            uint256 rebalanceSize = _historicalIntegralSize;
            integral = targetVersion == rebalanceSize
                ? _invTotalWeightIntegral
                : _historicalIntegrals[targetVersion];
        }
        if (userIntegral == integral && oldVersion == targetVersion) {
            // Return immediately when the user's rewards have already been updated to
            // the target version.
            return;
        }

        uint256 rewards = _claimableRewards[account];
        uint256[TRANCHE_COUNT] storage balance = _balances[account];
        uint256 weight = _workingBalances[account];
        uint256 balanceQ = balance[TRANCHE_Q];
        uint256 balanceB = balance[TRANCHE_B];
        uint256 balanceR = balance[TRANCHE_R];
        for (uint256 i = oldVersion; i < targetVersion; i++) {
            rewards = rewards.add(
                weight.multiplyDecimalPrecise(_historicalIntegrals[i].sub(userIntegral))
            );
            if (balanceQ != 0 || balanceB != 0 || balanceR != 0) {
                (balanceQ, balanceB, balanceR) = _fundDoRebalance(balanceQ, balanceB, balanceR, i);
            }
            userIntegral = 0;

            // Reset per-user weight boosting after the first rebalance
            weight = weightedBalance(balanceQ, balanceB, balanceR, _historicalSplitRatio[i + 1]);
        }
        rewards = rewards.add(weight.multiplyDecimalPrecise(integral.sub(userIntegral)));
        address account_ = account; // Fix the "stack too deep" error
        _claimableRewards[account_] = rewards;
        _userIntegrals[account_] = integral;

        if (oldVersion < targetVersion) {
            balance[TRANCHE_Q] = balanceQ;
            balance[TRANCHE_B] = balanceB;
            balance[TRANCHE_R] = balanceR;
            _balanceVersions[account_] = targetVersion;
            _workingBalances[account_] = weight;
        }
    }

    /// @dev Calculate working balance, which depends on the amount of staked tokens and veCHESS.
    ///      Before this function is called, both `_checkpoint()` and `_userCheckpoint(account)`
    ///      should be called to update `_workingSupply` and `_workingBalances[account]` to
    ///      the latest rebalance version.
    /// @param account User address
    /// @param rebalanceSize The number of existing rebalances. It must be the same as
    ///                       `fund.getRebalanceSize()`.
    function _updateWorkingBalance(address account, uint256 rebalanceSize) private {
        uint256 splitRatio = _historicalSplitRatio[rebalanceSize];
        if (splitRatio == 0) {
            // Read it from the fund in case that it's not initialized yet, e.g. when we reach here
            // for the first time and `rebalanceSize` is zero.
            splitRatio = fund.historicalSplitRatio(rebalanceSize);
            _historicalSplitRatio[rebalanceSize] = splitRatio;
        }
        uint256 weightedSupply =
            weightedBalance(
                _totalSupplies[TRANCHE_Q],
                _totalSupplies[TRANCHE_B],
                _totalSupplies[TRANCHE_R],
                splitRatio
            );
        uint256[TRANCHE_COUNT] storage balance = _balances[account];
        uint256 newWorkingBalance =
            weightedBalance(balance[TRANCHE_Q], balance[TRANCHE_B], balance[TRANCHE_R], splitRatio);
        uint256 veBalance = _votingEscrow.balanceOf(account);
        if (veBalance > 0) {
            uint256 veTotalSupply = _votingEscrow.totalSupply();
            uint256 maxWorkingBalance = newWorkingBalance.multiplyDecimal(MAX_BOOSTING_FACTOR);
            uint256 boostedWorkingBalance =
                newWorkingBalance.add(
                    weightedSupply
                        .mul(veBalance)
                        .multiplyDecimal(MAX_BOOSTING_FACTOR_MINUS_ONE)
                        .div(veTotalSupply)
                );
            newWorkingBalance = maxWorkingBalance.min(boostedWorkingBalance);
        }

        _workingSupply = _workingSupply.sub(_workingBalances[account]).add(newWorkingBalance);
        _workingBalances[account] = newWorkingBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IFundV3.sol";
import "../interfaces/IStableSwap.sol";

interface IPrimaryMarketRouter is IStableSwapCore {
    function create(
        address recipient,
        uint256 underlying,
        uint256 minOutQ,
        uint256 version
    ) external payable returns (uint256 outQ);

    function createAndStake(
        uint256 underlying,
        uint256 minOutQ,
        address staking,
        uint256 version
    ) external payable;

    function createSplitAndStake(
        uint256 underlying,
        uint256 minOutQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) external payable;

    function splitAndStake(
        uint256 inQ,
        address router,
        address quoteAddress,
        uint256 minLpOut,
        address staking,
        uint256 version
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IPrimaryMarketV3 {
    function fund() external view returns (address);

    function getCreation(uint256 underlying) external view returns (uint256 outQ);

    function getCreationForQ(uint256 minOutQ) external view returns (uint256 underlying);

    function getRedemption(uint256 inQ) external view returns (uint256 underlying, uint256 fee);

    function getRedemptionForUnderlying(uint256 minUnderlying) external view returns (uint256 inQ);

    function getSplit(uint256 inQ) external view returns (uint256 outB);

    function getSplitForB(uint256 minOutB) external view returns (uint256 inQ);

    function getMerge(uint256 inB) external view returns (uint256 outQ, uint256 feeQ);

    function getMergeForQ(uint256 minOutQ) external view returns (uint256 inB);

    function canBeRemovedFromFund() external view returns (bool);

    function create(
        address recipient,
        uint256 minOutQ,
        uint256 version
    ) external returns (uint256 outQ);

    function redeem(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external returns (uint256 underlying);

    function redeemAndUnwrap(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external returns (uint256 underlying);

    function queueRedemption(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external returns (uint256 underlying, uint256 index);

    function claimRedemptions(address account, uint256[] calldata indices)
        external
        returns (uint256 underlying);

    function claimRedemptionsAndUnwrap(address account, uint256[] calldata indices)
        external
        returns (uint256 underlying);

    function split(
        address recipient,
        uint256 inQ,
        uint256 version
    ) external returns (uint256 outB);

    function merge(
        address recipient,
        uint256 inB,
        uint256 version
    ) external returns (uint256 outQ);

    function settle(uint256 day) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./IStableSwap.sol";

interface ISwapRouter {
    function getSwap(address baseToken, address quoteToken) external view returns (IStableSwap);

    function getAmountsOut(uint256 amount, address[] memory path)
        external
        view
        returns (
            uint256[] memory amounts,
            IStableSwap[] memory swaps,
            bool[] memory isBuy
        );

    function getAmountsIn(uint256 amount, address[] memory path)
        external
        view
        returns (
            uint256[] memory amounts,
            IStableSwap[] memory swaps,
            bool[] memory isBuy
        );

    function addLiquidity(
        address baseToken,
        address quoteToken,
        uint256 baseDelta,
        uint256 quoteDelta,
        uint256 minMintAmount,
        uint256 version,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address recipient,
        address staking,
        uint256[] calldata versions,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 maxAmountIn,
        address[] calldata path,
        address recipient,
        address staking,
        uint256[] calldata versions,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensUnwrap(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address recipient,
        uint256[] calldata versions,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokensUnwrap(
        uint256 amountOut,
        uint256 maxAmountIn,
        address[] calldata path,
        address recipient,
        uint256[] calldata versions,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "../interfaces/IFundV3.sol";

interface IStableSwapCore {
    function getQuoteOut(uint256 baseIn) external view returns (uint256 quoteOut);

    function getQuoteIn(uint256 baseOut) external view returns (uint256 quoteIn);

    function getBaseOut(uint256 quoteIn) external view returns (uint256 baseOut);

    function getBaseIn(uint256 quoteOut) external view returns (uint256 baseIn);

    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realBaseOut);

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realQuoteOut);
}

interface IStableSwap is IStableSwapCore {
    function fund() external view returns (IFundV3);

    function baseTranche() external view returns (uint256);

    function baseAddress() external view returns (address);

    function quoteAddress() external view returns (address);

    function allBalances() external view returns (uint256, uint256);

    function getOraclePrice() external view returns (uint256);

    function getCurrentD() external view returns (uint256);

    function getCurrentPriceOverOracle() external view returns (uint256);

    function getCurrentPrice() external view returns (uint256);

    function getPriceOverOracleIntegral() external view returns (uint256);

    function addLiquidity(uint256 version, address recipient) external returns (uint256);

    function removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) external returns (uint256 baseOut, uint256 quoteOut);

    function removeLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) external returns (uint256 baseOut, uint256 quoteOut);

    function removeBaseLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut
    ) external returns (uint256 baseOut);

    function removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) external returns (uint256 quoteOut);

    function removeQuoteLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) external returns (uint256 quoteOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedERC20 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
//
// Copyright (c) 2019 Synthetix
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint256 private constant decimals = 18;
    uint256 private constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 private constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 private constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(UNIT);
    }

    function multiplyDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(PRECISE_UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    function divideDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(PRECISE_UNIT).div(y);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i.mul(10).div(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen = quotientTimesTen.add(10);
        }

        return quotientTimesTen.div(10);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, and the max value of
     * uint256 on overflow.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        return c / a != b ? type(uint256).max : c;
    }

    function saturatingMultiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return saturatingMul(x, y).div(UNIT);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract CoreUtility {
    using SafeMath for uint256;

    /// @dev UTC time of a day when the fund settles.
    uint256 internal constant SETTLEMENT_TIME = 14 hours;

    /// @dev Return end timestamp of the trading week containing a given timestamp.
    ///
    ///      A trading week starts at UTC time `SETTLEMENT_TIME` on a Thursday (inclusive)
    ///      and ends at the same time of the next Thursday (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading week.
    function _endOfWeek(uint256 timestamp) internal pure returns (uint256) {
        return ((timestamp.add(1 weeks) - SETTLEMENT_TIME) / 1 weeks) * 1 weeks + SETTLEMENT_TIME;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ITwapOracleV2.sol";

interface IFundV3 {
    /// @notice A linear transformation matrix that represents a rebalance.
    ///
    ///         ```
    ///             [        1        0        0 ]
    ///         R = [ ratioB2Q  ratioBR        0 ]
    ///             [ ratioR2Q        0  ratioBR ]
    ///         ```
    ///
    ///         Amounts of the three tranches `q`, `b` and `r` can be rebalanced by multiplying the matrix:
    ///
    ///         ```
    ///         [ q', b', r' ] = [ q, b, r ] * R
    ///         ```
    struct Rebalance {
        uint256 ratioB2Q;
        uint256 ratioR2Q;
        uint256 ratioBR;
        uint256 timestamp;
    }

    function tokenUnderlying() external view returns (address);

    function tokenQ() external view returns (address);

    function tokenB() external view returns (address);

    function tokenR() external view returns (address);

    function tokenShare(uint256 tranche) external view returns (address);

    function primaryMarket() external view returns (address);

    function primaryMarketUpdateProposal() external view returns (address, uint256);

    function strategy() external view returns (address);

    function strategyUpdateProposal() external view returns (address, uint256);

    function underlyingDecimalMultiplier() external view returns (uint256);

    function twapOracle() external view returns (ITwapOracleV2);

    function feeCollector() external view returns (address);

    function endOfDay(uint256 timestamp) external pure returns (uint256);

    function trancheTotalSupply(uint256 tranche) external view returns (uint256);

    function trancheBalanceOf(uint256 tranche, address account) external view returns (uint256);

    function trancheAllBalanceOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function trancheBalanceVersion(address account) external view returns (uint256);

    function trancheAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view returns (uint256);

    function trancheAllowanceVersion(address owner, address spender)
        external
        view
        returns (uint256);

    function trancheTransfer(
        uint256 tranche,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheTransferFrom(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheApprove(
        uint256 tranche,
        address spender,
        uint256 amount,
        uint256 version
    ) external;

    function getRebalanceSize() external view returns (uint256);

    function getRebalance(uint256 index) external view returns (Rebalance memory);

    function getRebalanceTimestamp(uint256 index) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function splitRatio() external view returns (uint256);

    function historicalSplitRatio(uint256 version) external view returns (uint256);

    function fundActivityStartTime() external view returns (uint256);

    function isFundActive(uint256 timestamp) external view returns (bool);

    function getEquivalentTotalB() external view returns (uint256);

    function getEquivalentTotalQ() external view returns (uint256);

    function historicalEquivalentTotalB(uint256 timestamp) external view returns (uint256);

    function historicalNavs(uint256 timestamp) external view returns (uint256 navB, uint256 navR);

    function extrapolateNav(uint256 price)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function doRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function batchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function refreshBalance(address account, uint256 targetVersion) external;

    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external;

    function shareTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function shareTransferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 newAllowance);

    function shareIncreaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (uint256 newAllowance);

    function shareDecreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (uint256 newAllowance);

    function shareApprove(
        address owner,
        address spender,
        uint256 amount
    ) external;

    function historicalUnderlying(uint256 timestamp) external view returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getStrategyUnderlying() external view returns (uint256);

    function getTotalDebt() external view returns (uint256);

    event RebalanceTriggered(
        uint256 indexed index,
        uint256 indexed day,
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 ratioB2Q,
        uint256 ratioR2Q,
        uint256 ratioBR
    );
    event Settled(uint256 indexed day, uint256 navB, uint256 navR, uint256 interestRate);
    event InterestRateUpdated(uint256 baseInterestRate, uint256 floatingInterestRate);
    event BalancesRebalanced(
        address indexed account,
        uint256 version,
        uint256 balanceQ,
        uint256 balanceB,
        uint256 balanceR
    );
    event AllowancesRebalanced(
        address indexed owner,
        address indexed spender,
        uint256 version,
        uint256 allowanceQ,
        uint256 allowanceB,
        uint256 allowanceR
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IChessController {
    function getFundRelativeWeight(address account, uint256 timestamp) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IChessSchedule {
    function getWeeklySupply(uint256 timestamp) external view returns (uint256);

    function getRate(uint256 timestamp) external view returns (uint256);

    function mint(address account, uint256 amount) external;

    function addMinter(address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

/// @notice Amounts of QUEEN, BISHOP and ROOK are sometimes stored in a `uint256[3]` array.
///         This contract defines index of each tranche in this array.
///
///         Solidity does not allow constants to be defined in interfaces. So this contract follows
///         the naming convention of interfaces but is implemented as an `abstract contract`.
abstract contract ITrancheIndexV2 {
    uint256 internal constant TRANCHE_Q = 0;
    uint256 internal constant TRANCHE_B = 1;
    uint256 internal constant TRANCHE_R = 2;

    uint256 internal constant TRANCHE_COUNT = 3;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

interface IAddressWhitelist {
    function check(address account) external view returns (bool);
}

interface IVotingEscrowCallback {
    function syncWithVotingEscrow(address account) external;
}

interface IVotingEscrow {
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    function token() external view returns (address);

    function maxTime() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function getTimestampDropBelow(address account, uint256 threshold)
        external
        view
        returns (uint256);

    function getLockedBalance(address account) external view returns (LockedBalance memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./ITwapOracle.sol";

interface ITwapOracleV2 is ITwapOracle {
    function getLatest() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface ITwapOracle {
    enum UpdateType {PRIMARY, SECONDARY, OWNER, CHAINLINK, UNISWAP_V2}

    function getTwap(uint256 timestamp) external view returns (uint256);
}