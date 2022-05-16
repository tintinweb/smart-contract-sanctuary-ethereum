// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./AaveLibraries.sol";
import "./AaveInterfaces.sol";
import "../BaseStrategyUpgradeable.sol";
import "./ComputeProfitability.sol";

/// @title AaveFlashloanStrategy
/// @author Yearn Finance (https://etherscan.io/address/0xd4E94061183b2DBF24473F28A3559cf4dE4459Db#code)
/// but heavily reviewed and modified by Angle Core Team
/// @notice This strategy is used to optimize lending yield on Aave by taking some form or recursivity that is to say
/// by borrowing to maximize Aave rewards
/// @dev Angle strategies computes the optimal collateral ratio based on AAVE rewards for deposits and borrows
// solhint-disable-next-line max-states-count
contract AaveFlashloanStrategy is BaseStrategyUpgradeable, IERC3156FlashBorrower {
    using SafeERC20 for IERC20;
    using Address for address;

    // =========================== Constant Addresses ==============================

    /// @notice Router used for swaps
    address private constant _oneInch = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    /// @notice Chainlink oracle used to fetch data
    AggregatorV3Interface private constant _chainlinkOracle =
        AggregatorV3Interface(0x547a514d5e3769680Ce22B2361c10Ea13619e8a9);

    // ========================== Aave Protocol Addresses ==========================

    IAaveIncentivesController private constant _incentivesController =
        IAaveIncentivesController(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
    ILendingPool private constant _lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IProtocolDataProvider private constant _protocolDataProvider =
        IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    // ============================== Token Addresses ==============================

    address private constant _aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    IStakedAave private constant _stkAave = IStakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    address private constant _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant _dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // ============================== Ops Constants ================================

    uint256 private constant _DEFAULT_COLLAT_TARGET_MARGIN = 0.02 ether;
    uint256 private constant _DEFAULT_COLLAT_MAX_MARGIN = 0.005 ether;
    uint256 private constant _LIQUIDATION_WARNING_THRESHOLD = 0.01 ether;
    uint256 private constant _BPS_WAD_RATIO = 1e14;
    uint256 private constant _COLLATERAL_RATIO_PRECISION = 1 ether;
    uint16 private constant _referral = 0;

    // ========================= Aave Protocol Parameters ==========================

    IReserveInterestRateStrategy private _interestRateStrategyAddress;
    uint256 public cooldownSeconds;
    uint256 public unstakeWindow;
    int256 public reserveFactor;
    int256 public slope1;
    int256 public slope2;
    int256 public r0;
    int256 public uOptimal;

    // =============================== Parameters and Variables ====================

    /// @notice Maximum the Aave protocol will let us borrow
    uint256 public maxBorrowCollatRatio;
    /// @notice LTV the strategy is going to lever up to
    uint256 public targetCollatRatio;
    /// @notice Closest to liquidation we'll risk
    uint256 public maxCollatRatio;
    /// @notice Parameter used for flash mints
    uint256 public daiBorrowCollatRatio;
    /// @notice Minimum amount to be moved before a deposit or a borrow
    uint256 public minWant;
    /// @notice Minimum gap between the collat ratio and the target collat ratio before
    /// rectifying it
    uint256 public minRatio;
    /// @notice Discount factor applied to the StkAAVE price
    uint256 public discountFactor;
    /// @notice Max number of iterations possible for the computation of the optimal lever
    uint8 public maxIterations;

    struct BoolParams {
        // Whether collateral ratio will be automatically computed
        bool automaticallyComputeCollatRatio;
        // Whether Flash mint is active
        bool isFlashMintActive;
        // Whether we should check withdrawals
        bool withdrawCheck;
        // Whether StkAAVE should be sent to cooldown or simply swapped for Aave all the time
        bool cooldownStkAave;
    }
    /// @notice Struct with some boolean parameters of the contract
    /// These parameters are packed in a struct for efficiency of SLOAD operations
    BoolParams public boolParams;

    // ========================= Supply and Borrow Tokens ==========================

    IAToken private _aToken;
    IVariableDebtToken private _debtToken;

    // ================================== Errors ===================================

    error ErrorSwap();
    error InvalidSender();
    error InvalidSetOfParameters();
    error InvalidWithdrawCheck();
    error TooSmallAmountOut();
    error TooHighParameterValue();

    // ============================ Initializer ====================================

    /// @notice Constructor of the `Strategy`
    /// @param _poolManager Address of the `PoolManager` lending to this strategy
    /// @param interestRateStrategyAddress_ Address of the `InterestRateStrategy` defining borrow rates for the collateral
    /// @param governor Governor address of the protocol
    /// @param guardian Address of the guardian
    /// @param keepers List of the addresses with keeper privilege
    function initialize(
        address _poolManager,
        IReserveInterestRateStrategy interestRateStrategyAddress_,
        address governor,
        address guardian,
        address[] memory keepers
    ) external {
        _initialize(_poolManager, governor, guardian, keepers);

        // Then initializing operational state
        maxIterations = 6;
        // Setting mins
        minWant = 100;
        minRatio = 0.005 ether;
        discountFactor = 9000;

        boolParams = BoolParams({
            automaticallyComputeCollatRatio: true,
            isFlashMintActive: true,
            withdrawCheck: false,
            cooldownStkAave: true
        });

        _interestRateStrategyAddress = interestRateStrategyAddress_;
        // Setting reward params
        _setAavePoolVariables();

        // Set AAVE tokens
        (address aToken_, , address debtToken_) = _protocolDataProvider.getReserveTokensAddresses(address(want));
        _aToken = IAToken(aToken_);
        _debtToken = IVariableDebtToken(debtToken_);

        // Let collateral targets
        (uint256 ltv, uint256 liquidationThreshold) = _getProtocolCollatRatios(address(want));
        targetCollatRatio = liquidationThreshold - _DEFAULT_COLLAT_TARGET_MARGIN;
        maxCollatRatio = liquidationThreshold - _DEFAULT_COLLAT_MAX_MARGIN;
        maxBorrowCollatRatio = ltv - _DEFAULT_COLLAT_MAX_MARGIN;
        (uint256 daiLtv, ) = _getProtocolCollatRatios(_dai);
        daiBorrowCollatRatio = daiLtv - _DEFAULT_COLLAT_MAX_MARGIN;

        // Performing all the different approvals possible
        _approveMaxSpend(address(want), address(_lendingPool));
        _approveMaxSpend(aToken_, address(_lendingPool));
        // Approve flashloan spend
        _approveMaxSpend(_dai, FlashMintLib.LENDER);
        // Approve swap router spend
        _approveMaxSpend(address(_stkAave), _oneInch);
        _approveMaxSpend(_aave, _oneInch);
        if (address(want) != _dai) {
            _approveMaxSpend(_dai, address(_lendingPool));
        }
    }

    // ======================= Helper View Functions ===============================

    /// @notice Estimates the total assets controlled by the strategy
    /// @dev It sums the effective deposit amount to the rewards accumulated
    function estimatedTotalAssets() public view override returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        return
            _balanceOfWant() +
            deposits -
            borrows +
            _estimatedStkAaveToWant(
                _balanceOfStkAave() +
                    _balanceOfAave() +
                    _incentivesController.getRewardsBalance(_getAaveAssets(), address(this))
            );
    }

    /// @notice Get the current position of the strategy: that is to say the amount deposited
    /// and the amount borrowed on Aave
    /// @dev The actual amount brought is `deposits - borrows`
    function getCurrentPosition() public view returns (uint256 deposits, uint256 borrows) {
        deposits = _balanceOfAToken();
        borrows = _balanceOfDebtToken();
    }

    // ====================== Internal Strategy Functions ==========================

    /// @notice Frees up profit plus `_debtOutstanding`.
    /// @param _debtOutstanding Amount to withdraw
    /// @return _profit Profit freed by the call
    /// @return _loss Loss discovered by the call
    /// @return _debtPayment Amount freed to reimburse the debt
    /// @dev If `_debtOutstanding` is more than we can free we get as much as possible.
    function _prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // account for profit / losses
        uint256 totalDebt = poolManager.strategies(address(this)).totalStrategyDebt;

        // Assets immediately convertible to want only
        uint256 amountAvailable = _balanceOfWant();
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        uint256 totalAssets = amountAvailable + deposits - borrows;

        if (totalDebt > totalAssets) {
            // we have losses
            _loss = totalDebt - totalAssets;
        } else {
            // we have profit
            _profit = totalAssets - totalDebt;
        }

        // free funds to repay debt + profit to the strategy
        uint256 amountRequired = _debtOutstanding + _profit;

        if (amountRequired > amountAvailable) {
            // we need to free funds
            // we dismiss losses here, they cannot be generated from withdrawal
            // but it is possible for the strategy to unwind full position
            (amountAvailable, ) = _liquidatePosition(amountRequired, amountAvailable, deposits, borrows);

            if (amountAvailable >= amountRequired) {
                _debtPayment = _debtOutstanding;
                // profit remains unchanged unless there is not enough to pay it
                if (amountRequired - _debtPayment < _profit) {
                    _profit = amountRequired - _debtPayment;
                }
            } else {
                // we were not able to free enough funds
                if (amountAvailable < _debtOutstanding) {
                    // available funds are lower than the repayment that we need to do
                    _profit = 0;
                    _debtPayment = amountAvailable;
                    // we dont report losses here as the strategy might not be able to return in this harvest
                    // but it will still be there for the next harvest
                } else {
                    // NOTE: amountRequired is always equal or greater than _debtOutstanding
                    // important to use amountRequired just in case amountAvailable is > amountAvailable
                    _debtPayment = _debtOutstanding;
                    _profit = amountAvailable - _debtPayment;
                }
            }
        } else {
            _debtPayment = _debtOutstanding;
            // profit remains unchanged unless there is not enough to pay it
            if (amountRequired - _debtPayment < _profit) {
                _profit = amountRequired - _debtPayment;
            }
        }
    }

    /// @notice Function called by _harvest()
    function _adjustPosition() internal override {
        _adjustPosition(type(uint256).max);
    }

    /// @notice Function called by _adjustPosition()
    /// @param guessedBorrow First guess to the borrow amount to maximise revenue
    /// @dev It computes the optimal collateral ratio and adjusts deposits/borrows accordingly
    function _adjustPosition(uint256 guessedBorrow) internal override {
        uint256 _debtOutstanding = poolManager.debtOutstanding();

        uint256 wantBalance = _balanceOfWant();
        // deposit available want as collateral
        if (wantBalance > _debtOutstanding && wantBalance - _debtOutstanding > minWant) {
            _depositCollateral(wantBalance - _debtOutstanding);
            // Updating the `wantBalance` value
            wantBalance = _balanceOfWant();
        }

        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        guessedBorrow = (guessedBorrow == type(uint256).max) ? borrows : guessedBorrow;
        uint256 _targetCollatRatio;
        if (boolParams.automaticallyComputeCollatRatio) {
            _targetCollatRatio = _computeOptimalCollatRatio(
                wantBalance + deposits - borrows,
                deposits,
                borrows,
                guessedBorrow
            );
        } else {
            _targetCollatRatio = targetCollatRatio;
        }

        // check current position
        uint256 currentCollatRatio = _getCollatRatio(deposits, borrows);

        // Either we need to free some funds OR we want to be max levered
        if (_debtOutstanding > wantBalance) {
            // we should free funds
            uint256 amountRequired = _debtOutstanding - wantBalance;

            // NOTE: vault will take free funds during the next harvest
            _freeFunds(amountRequired, deposits, borrows);
        } else if (currentCollatRatio < _targetCollatRatio) {
            // we should lever up
            if (_targetCollatRatio - currentCollatRatio > minRatio) {
                // we only act on relevant differences
                _leverMax(deposits, borrows);
            }
        } else if (currentCollatRatio > _targetCollatRatio) {
            if (currentCollatRatio - _targetCollatRatio > minRatio) {
                uint256 newBorrow = _getBorrowFromSupply(deposits - borrows, _targetCollatRatio);
                _leverDownTo(newBorrow, deposits, borrows);
            }
        }
    }

    /// @notice Liquidates `_amountNeeded` from a position
    /// @dev For gas efficiency this function calls another internal function
    function _liquidatePosition(uint256 _amountNeeded) internal override returns (uint256, uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        return _liquidatePosition(_amountNeeded, _balanceOfWant(), deposits, borrows);
    }

    /// @notice Withdraws `_amountNeeded` of `want` from Aave
    /// @param _amountNeeded Amount of `want` to free
    /// @return _liquidatedAmount Amount of `want` available
    /// @return _loss Difference between `_amountNeeded` and what is actually available
    function _liquidatePosition(
        uint256 _amountNeeded,
        uint256 wantBalance,
        uint256 deposits,
        uint256 borrows
    ) internal returns (uint256 _liquidatedAmount, uint256 _loss) {
        // NOTE: Maintain invariant `want.balanceOf(this) >= _liquidatedAmount`
        // NOTE: Maintain invariant `_liquidatedAmount + _loss <= _amountNeeded`
        if (wantBalance > _amountNeeded) {
            // if there is enough free want, let's use it
            return (_amountNeeded, 0);
        }

        // we need to free funds
        uint256 amountRequired = _amountNeeded - wantBalance;
        _freeFunds(amountRequired, deposits, borrows);
        // Updating the `wantBalance` variable
        wantBalance = _balanceOfWant();
        if (_amountNeeded > wantBalance) {
            _liquidatedAmount = wantBalance;
            uint256 diff = _amountNeeded - _liquidatedAmount;
            if (diff <= minWant) {
                _loss = diff;
            }
        } else {
            _liquidatedAmount = _amountNeeded;
        }

        if (boolParams.withdrawCheck) {
            if (_amountNeeded != _liquidatedAmount + _loss) revert InvalidWithdrawCheck(); // dev: withdraw safety check
        }
    }

    /// @notice Withdraw as much as we can from Aave
    /// @return _amountFreed Amount successfully freed
    function _liquidateAllPositions() internal override returns (uint256 _amountFreed) {
        (_amountFreed, ) = _liquidatePosition(type(uint256).max);
    }

    function _protectedTokens() internal view override returns (address[] memory) {}

    // ============================== Setters ======================================

    /// @notice Sets collateral targets and value for collateral ratio
    function setCollateralTargets(
        uint256 _targetCollatRatio,
        uint256 _maxCollatRatio,
        uint256 _maxBorrowCollatRatio,
        uint256 _daiBorrowCollatRatio
    ) external onlyRole(GUARDIAN_ROLE) {
        (uint256 ltv, uint256 liquidationThreshold) = _getProtocolCollatRatios(address(want));
        (uint256 daiLtv, ) = _getProtocolCollatRatios(_dai);
        if (
            _targetCollatRatio >= liquidationThreshold ||
            _maxCollatRatio >= liquidationThreshold ||
            _targetCollatRatio >= _maxCollatRatio ||
            _maxBorrowCollatRatio >= ltv ||
            _daiBorrowCollatRatio >= daiLtv
        ) revert InvalidSetOfParameters();

        targetCollatRatio = _targetCollatRatio;
        maxCollatRatio = _maxCollatRatio;
        maxBorrowCollatRatio = _maxBorrowCollatRatio;
        daiBorrowCollatRatio = _daiBorrowCollatRatio;
    }

    /// @notice Sets `minWant`, `minRatio` and `maxItrations` values
    function setMinsAndMaxs(
        uint256 _minWant,
        uint256 _minRatio,
        uint8 _maxIterations
    ) external onlyRole(GUARDIAN_ROLE) {
        if (_minRatio >= maxBorrowCollatRatio || _maxIterations == 0 || _maxIterations >= 16)
            revert InvalidSetOfParameters();
        minWant = _minWant;
        minRatio = _minRatio;
        maxIterations = _maxIterations;
    }

    /// @notice Sets all boolean parameters related to cooldown, withdraw check, flash loan and so on
    function setBoolParams(BoolParams memory _boolParams) external onlyRole(GUARDIAN_ROLE) {
        boolParams = _boolParams;
    }

    /// @notice Sets the discount factor for the StkAAVE price
    function setDiscountFactor(uint256 _discountFactor) external onlyRole(GUARDIAN_ROLE) {
        if (_discountFactor > 10000) revert TooHighParameterValue();
        discountFactor = _discountFactor;
    }

    /// @notice Retrieves lending pool variables for `want`. Those variables are mostly used in the function
    /// to compute the optimal borrow amount
    /// @dev No access control needed because they fetch the values from Aave directly.
    /// If it changes there, it will need to be updated here too
    /// @dev We expect the values concerned not to be often modified
    function setAavePoolVariables() external {
        _setAavePoolVariables();
    }

    // ========================== External Actions =================================

    /// @notice Emergency function that we can use to deleverage manually if something is broken
    /// @param amount Amount of `want` to withdraw/repay
    function manualDeleverage(uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        _withdrawCollateral(amount);
        _repayWant(amount);
    }

    /// @notice Emergency function that we can use to deleverage manually if something is broken
    /// @param amount Amount of `want` to withdraw
    function manualReleaseWant(uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        _withdrawCollateral(amount);
    }

    /// @notice Adds a new guardian address
    /// @param _guardian New guardian address
    function addGuardian(address _guardian) external override onlyRole(POOLMANAGER_ROLE) {
        // Granting the new role
        // Access control for this contract
        _grantRole(GUARDIAN_ROLE, _guardian);
    }

    /// @notice Revokes the guardian role
    /// @param guardian Old guardian address to revoke
    function revokeGuardian(address guardian) external override onlyRole(POOLMANAGER_ROLE) {
        _revokeRole(GUARDIAN_ROLE, guardian);
    }

    /// @notice Swap earned stkAave or Aave for `want` through 1Inch
    /// @param minAmountOut Minimum amount of `want` to receive for the swap to happen
    /// @param payload Bytes needed for 1Inch API. Tokens swapped should be: stkAave -> `want` or Aave -> `want`
    function sellRewards(uint256 minAmountOut, bytes memory payload) external onlyRole(KEEPER_ROLE) {
        //solhint-disable-next-line
        (bool success, bytes memory result) = _oneInch.call(payload);
        if (!success) _revertBytes(result);

        uint256 amountOut = abi.decode(result, (uint256));
        if (amountOut < minAmountOut) revert TooSmallAmountOut();
    }

    /// @notice Flashload callback, as defined by EIP-3156
    /// @notice We check that the call is coming from the DAI lender and then execute the load logic
    /// @dev If everything went smoothly, will return `keccak256("ERC3156FlashBorrower.onFlashLoan")`
    function onFlashLoan(
        address initiator,
        address,
        uint256 amount,
        uint256,
        bytes calldata data
    ) external override returns (bytes32) {
        if (msg.sender != FlashMintLib.LENDER || initiator != address(this)) revert InvalidSender();
        (bool deficit, uint256 amountWant) = abi.decode(data, (bool, uint256));

        return FlashMintLib.loanLogic(deficit, amountWant, amount, address(want));
    }

    // ========================== Internal Actions =================================

    /// @notice Claim earned stkAAVE (only called at `harvest`)
    /// @dev stkAAVE require a "cooldown" period of 10 days before being claimed
    function _claimRewards() internal returns (uint256 stkAaveBalance) {
        stkAaveBalance = _balanceOfStkAave();
        // If it's the claim period claim
        if (stkAaveBalance > 0 && _checkCooldown() == 1) {
            // redeem AAVE from stkAave
            _stkAave.claimRewards(address(this), type(uint256).max);
            _stkAave.redeem(address(this), stkAaveBalance);
        }

        // claim stkAave from lending and borrowing, this will reset the cooldown
        _incentivesController.claimRewards(_getAaveAssets(), type(uint256).max, address(this));

        stkAaveBalance = _balanceOfStkAave();

        // request start of cooldown period, if there's no cooldown in progress
        if (boolParams.cooldownStkAave && stkAaveBalance > 0 && _checkCooldown() == 0) {
            _stkAave.cooldown();
        }
    }

    function claimRewards() external onlyRole(KEEPER_ROLE) {
        _claimRewards();
    }

    function cooldown() external onlyRole(KEEPER_ROLE) {
        _stkAave.cooldown();
    }

    /// @notice Reduce exposure by withdrawing funds and repaying debt
    /// @param amountToFree Amount of `want` to withdraw/repay
    /// @return balance Current balance of `want`
    /// @dev `deposits` and `borrows` are always computed prior to the call
    function _freeFunds(
        uint256 amountToFree,
        uint256 deposits,
        uint256 borrows
    ) internal returns (uint256) {
        if (amountToFree == 0) return 0;

        uint256 realAssets = deposits - borrows;
        uint256 newBorrow = _getBorrowFromSupply(realAssets - Math.min(amountToFree, realAssets), targetCollatRatio);

        // repay required amount
        _leverDownTo(newBorrow, deposits, borrows);

        return _balanceOfWant();
    }

    /// @notice Get exposure up to `targetCollatRatio`
    function _leverMax(uint256 deposits, uint256 borrows) internal {
        uint256 totalAmountToBorrow = _getBorrowFromSupply(deposits - borrows, targetCollatRatio) - borrows;

        if (boolParams.isFlashMintActive) {
            // The best approach is to lever up using regular method, then finish with flash loan
            totalAmountToBorrow = totalAmountToBorrow - _leverUpStep(totalAmountToBorrow, deposits, borrows);

            if (totalAmountToBorrow > minWant) {
                totalAmountToBorrow = totalAmountToBorrow - _leverUpFlashLoan(totalAmountToBorrow);
            }
        } else {
            for (uint8 i = 0; i < maxIterations && totalAmountToBorrow > minWant; i++) {
                totalAmountToBorrow = totalAmountToBorrow - _leverUpStep(totalAmountToBorrow, deposits, borrows);
                deposits = 0;
                borrows = 0;
            }
        }
    }

    /// @notice Use a flashloan to increase our exposure in `want` on Aave
    /// @param amount Amount we will deposit and borrow on Aave
    /// @return amount Actual amount deposited/borrowed
    /// @dev Amount returned should equal `amount` but can be lower if we try to flashloan more than `maxFlashLoan` authorized
    function _leverUpFlashLoan(uint256 amount) internal returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        uint256 depositsToMeetLtv = _getDepositFromBorrow(borrows, maxBorrowCollatRatio, deposits);
        uint256 depositsDeficitToMeetLtv = 0;
        if (depositsToMeetLtv > deposits) {
            depositsDeficitToMeetLtv = depositsToMeetLtv - deposits;
        }
        return FlashMintLib.doFlashMint(false, amount, address(want), daiBorrowCollatRatio, depositsDeficitToMeetLtv);
    }

    /// @notice Increase exposure in `want`
    /// @param amount Amount of `want` to borrow
    /// @return amount Amount of `want` that was borrowed
    function _leverUpStep(
        uint256 amount,
        uint256 deposits,
        uint256 borrows
    ) internal returns (uint256) {
        if (deposits == 0 && borrows == 0) (deposits, borrows) = getCurrentPosition();

        uint256 wantBalance = _balanceOfWant();

        uint256 canBorrow = _getBorrowFromDeposit(deposits + wantBalance, maxBorrowCollatRatio);

        if (canBorrow <= borrows) {
            return 0;
        }
        canBorrow = canBorrow - borrows;

        if (canBorrow < amount) {
            amount = canBorrow;
        }

        _depositCollateral(wantBalance);
        _borrowWant(amount);
        _depositCollateral(amount);

        return amount;
    }

    /// @notice Reduce our exposure to `want` on Aave
    /// @param newAmountBorrowed Total amount we want to be borrowing
    /// @param deposits Amount currently lent
    /// @param currentBorrowed Amount currently borrowed
    function _leverDownTo(
        uint256 newAmountBorrowed,
        uint256 deposits,
        uint256 currentBorrowed
    ) internal {
        if (currentBorrowed > newAmountBorrowed) {
            uint256 totalRepayAmount = currentBorrowed - newAmountBorrowed;

            if (boolParams.isFlashMintActive) {
                totalRepayAmount = totalRepayAmount - _leverDownFlashLoan(totalRepayAmount, currentBorrowed);
            }

            uint256 _maxCollatRatio = maxCollatRatio;

            // in case the flashloan didn't repay the entire amount we have to repay it "manually"
            // by withdrawing a bit of collateral and then repaying the debt with it
            for (uint8 i = 0; i < maxIterations && totalRepayAmount > minWant; i++) {
                _withdrawExcessCollateral(_maxCollatRatio, 0, 0);
                uint256 toRepay = totalRepayAmount;
                uint256 wantBalance = _balanceOfWant();
                if (toRepay > wantBalance) {
                    toRepay = wantBalance;
                }
                uint256 repaid = _repayWant(toRepay);
                totalRepayAmount = totalRepayAmount - repaid;
            }
            (deposits, currentBorrowed) = getCurrentPosition();
        }

        // Deposit back to get `targetCollatRatio` (we always need to leave this in this ratio)
        uint256 _targetCollatRatio = targetCollatRatio;
        uint256 targetDeposit = _getDepositFromBorrow(currentBorrowed, _targetCollatRatio, deposits);
        if (targetDeposit > deposits) {
            uint256 toDeposit = targetDeposit - deposits;
            if (toDeposit > minWant) {
                _depositCollateral(Math.min(toDeposit, _balanceOfWant()));
            }
        } else {
            if (deposits - targetDeposit > minWant) {
                _withdrawExcessCollateral(_targetCollatRatio, deposits, currentBorrowed);
            }
        }
    }

    /// @notice Use a flashloan to reduce our exposure in `want` on Aave
    /// @param amount Amount we will need to withdraw and repay to Aave
    /// @return amount Actual amount repaid
    /// @dev Amount returned should equal `amount` but can be lower if we try to flashloan more than `maxFlashLoan` authorized
    /// @dev `amount` will be withdrawn from deposits and then used to repay borrows
    function _leverDownFlashLoan(uint256 amount, uint256 borrows) internal returns (uint256) {
        if (amount <= minWant) return 0;
        if (amount > borrows) {
            amount = borrows;
        }
        return FlashMintLib.doFlashMint(true, amount, address(want), daiBorrowCollatRatio, 0);
    }

    /// @notice Adjusts the deposits based on the wanted collateral ratio (does not touch the borrow)
    /// @param collatRatio Collateral ratio to target
    function _withdrawExcessCollateral(
        uint256 collatRatio,
        uint256 deposits,
        uint256 borrows
    ) internal returns (uint256 amount) {
        if (deposits == 0 && borrows == 0) (deposits, borrows) = getCurrentPosition();
        uint256 theoDeposits = _getDepositFromBorrow(borrows, collatRatio, deposits);
        if (deposits > theoDeposits) {
            uint256 toWithdraw = deposits - theoDeposits;
            return _withdrawCollateral(toWithdraw);
        }
    }

    /// @notice Deposit `want` tokens in Aave and start earning interests
    /// @param amount Amount to be deposited
    /// @return amount The amount deposited
    function _depositCollateral(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        _lendingPool.deposit(address(want), amount, address(this), _referral);
        return amount;
    }

    /// @notice Withdraw `want` tokens from Aave
    /// @param amount Amount to be withdrawn
    /// @return amount The amount withdrawn
    function _withdrawCollateral(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        _lendingPool.withdraw(address(want), amount, address(this));
        return amount;
    }

    /// @notice Repay what we borrowed of `want` from Aave
    /// @param amount Amount to repay
    /// @return amount The amount repaid
    /// @dev `interestRateMode` is set to variable rate (2)
    function _repayWant(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        return _lendingPool.repay(address(want), amount, 2, address(this));
    }

    /// @notice Borrow `want` from Aave
    /// @param amount Amount of `want` we are borrowing
    /// @return amount The amount borrowed
    /// @dev The third variable is the `interestRateMode`
    /// @dev set at 2 which means we will get a variable interest rate on our borrowed tokens
    function _borrowWant(uint256 amount) internal returns (uint256) {
        _lendingPool.borrow(address(want), amount, 2, _referral, address(this));
        return amount;
    }

    /// @notice Computes the optimal collateral ratio based on current interests and incentives on Aave
    /// @notice It modifies the state by updating the `targetCollatRatio`
    function _computeOptimalCollatRatio(
        uint256 balanceExcludingRewards,
        uint256 deposits,
        uint256 currentBorrowed,
        uint256 guessedBorrow
    ) internal returns (uint256) {
        uint256 borrow = _computeMostProfitableBorrow(
            balanceExcludingRewards,
            deposits,
            currentBorrowed,
            guessedBorrow
        );
        uint256 _collatRatio = _getCollatRatio(balanceExcludingRewards + borrow, borrow);
        uint256 _maxCollatRatio = maxCollatRatio;
        if (_collatRatio > _maxCollatRatio) {
            _collatRatio = _maxCollatRatio;
        }
        targetCollatRatio = _collatRatio;
        return _collatRatio;
    }

    /// @notice Approve `spender` maxuint of `token`
    /// @param token Address of token to approve
    /// @param spender Address of spender to approve
    function _approveMaxSpend(address token, address spender) internal {
        IERC20(token).safeApprove(spender, type(uint256).max);
    }

    /// @notice Internal version of the `_setAavePoolVariables`
    function _setAavePoolVariables() internal {
        (, , , , uint256 reserveFactor_, , , , , ) = _protocolDataProvider.getReserveConfigurationData(address(want));
        cooldownSeconds = IStakedAave(_stkAave).COOLDOWN_SECONDS();
        unstakeWindow = IStakedAave(_stkAave).UNSTAKE_WINDOW();
        reserveFactor = int256(reserveFactor_ * 10**23);
        slope1 = int256(_interestRateStrategyAddress.variableRateSlope1());
        slope2 = int256(_interestRateStrategyAddress.variableRateSlope2());
        r0 = int256(_interestRateStrategyAddress.baseVariableBorrowRate());
        uOptimal = int256(_interestRateStrategyAddress.OPTIMAL_UTILIZATION_RATE());
    }

    // ========================= Internal View Functions ===========================

    /// @notice Computes the optimal amounts to borrow based on current interest rates and incentives
    /// @dev Returns optimal `borrow` amount in base of `want`
    function _computeMostProfitableBorrow(
        uint256 balanceExcludingRewards,
        uint256 deposits,
        uint256 currentBorrow,
        uint256 guessedBorrow
    ) internal view returns (uint256 borrow) {
        // This works if `wantBase < 10**27` which we should expect to be very the case for the strategies we are
        // launching at the moment
        uint256 normalizationFactor = 10**27 / wantBase;

        ComputeProfitability.SCalculateBorrow memory parameters;

        {
            (
                uint256 availableLiquidity,
                uint256 totalStableDebt,
                uint256 totalVariableDebt,
                ,
                ,
                ,
                uint256 averageStableBorrowRate,
                ,
                ,

            ) = _protocolDataProvider.getReserveData(address(want));

            parameters = ComputeProfitability.SCalculateBorrow({
                reserveFactor: reserveFactor,
                totalStableDebt: int256(totalStableDebt * normalizationFactor),
                totalVariableDebt: int256((totalVariableDebt - currentBorrow) * normalizationFactor),
                totalDeposits: int256(
                    (availableLiquidity +
                        totalStableDebt +
                        totalVariableDebt +
                        // to adapt to our future balance
                        // add the wantBalance and remove the currentBorrowed from the optimisation
                        balanceExcludingRewards -
                        deposits) * normalizationFactor
                ),
                stableBorrowRate: int256(averageStableBorrowRate),
                rewardDeposit: 0,
                rewardBorrow: 0,
                strategyAssets: int256(balanceExcludingRewards * normalizationFactor),
                guessedBorrowAssets: int256(guessedBorrow * normalizationFactor),
                slope1: slope1,
                slope2: slope2,
                r0: r0,
                uOptimal: uOptimal
            });
        }

        {
            uint256 stkAavePriceInWant = _estimatedStkAaveToWant(1 ether);

            (uint256 emissionPerSecondAToken, , ) = _incentivesController.assets(address(_aToken));
            (uint256 emissionPerSecondDebtToken, , ) = _incentivesController.assets(address(_debtToken));

            parameters.rewardDeposit = int256(
                (emissionPerSecondAToken * 86400 * 365 * stkAavePriceInWant * 10**9) / wantBase
            );
            parameters.rewardBorrow = int256(
                (emissionPerSecondDebtToken * 86400 * 365 * stkAavePriceInWant * 10**9) / wantBase
            );
        }

        borrow = uint256(ComputeProfitability.computeProfitability(parameters)) / normalizationFactor;
    }

    function estimatedAPR() public view returns (uint256) {
        (
            ,
            ,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            ,
            ,
            ,
            ,

        ) = _protocolDataProvider.getReserveData(address(want));

        uint256 _totalAssets = _balanceOfWant() + _balanceOfAToken() - _balanceOfDebtToken();
        if (_totalAssets == 0 || totalVariableDebt == 0 || _aToken.totalSupply() == 0) return 0;

        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        uint256 yearlyRewardsATokenInUSD;
        uint256 yearlyRewardsDebtTokenInUSD;
        {
            uint256 stkAavePriceInWant = _estimatedStkAaveToWant(1 ether);
            (uint256 emissionPerSecondAToken, , ) = (_aToken.getIncentivesController()).assets(address(_aToken));
            (uint256 emissionPerSecondDebtToken, , ) = (_debtToken.getIncentivesController()).assets(
                address(_debtToken)
            );

            uint256 yearlyEmissionsAToken = emissionPerSecondAToken * 60 * 60 * 24 * 365; // BASE: 18
            uint256 yearlyEmissionsDebtToken = emissionPerSecondDebtToken * 60 * 60 * 24 * 365; // BASE: 18
            yearlyRewardsATokenInUSD =
                ((deposits * yearlyEmissionsAToken) / _aToken.totalSupply()) *
                stkAavePriceInWant; // BASE 18 + want
            yearlyRewardsDebtTokenInUSD =
                ((borrows * yearlyEmissionsDebtToken) / totalVariableDebt) *
                stkAavePriceInWant; // BASE 18 + want
        }

        return
            ((liquidityRate * deposits) /
                10**9 +
                yearlyRewardsATokenInUSD +
                yearlyRewardsDebtTokenInUSD -
                (variableBorrowRate * borrows) /
                10**9) / _totalAssets; // BASE 18
    }

    /// @notice Returns the `want` balance
    function _balanceOfWant() internal view returns (uint256) {
        return want.balanceOf(address(this));
    }

    /// @notice Returns the `aToken` balance
    function _balanceOfAToken() internal view returns (uint256) {
        return _aToken.balanceOf(address(this));
    }

    /// @notice Returns the `debtToken` balance
    function _balanceOfDebtToken() internal view returns (uint256) {
        return _debtToken.balanceOf(address(this));
    }

    /// @notice Returns the `AAVE` balance
    function _balanceOfAave() internal view returns (uint256) {
        return IERC20(_aave).balanceOf(address(this));
    }

    /// @notice Returns the `StkAAVE` balance
    function _balanceOfStkAave() internal view returns (uint256) {
        return IERC20(address(_stkAave)).balanceOf(address(this));
    }

    /// @notice Estimate the amount of `want` we will get out by swapping it for AAVE
    /// @param amount Amount of AAVE we want to exchange (in base 18)
    /// @return amount Amount of `want` we are getting. We include a discount to account for slippage equal to 9000
    /// @dev Uses Chainlink spot price. Return value will be in base of `want` (6 for USDC)
    function _estimatedStkAaveToWant(uint256 amount) internal view returns (uint256) {
        (, int256 aavePriceUSD, , , ) = _chainlinkOracle.latestRoundData(); // stkAavePriceUSD is in base 8
        // `aavePriceUSD` is in base 8, and the discount factor is in base 4, so ultimately we need to divide
        // by `1e(18+8+4)
        return (uint256(aavePriceUSD) * amount * wantBase * discountFactor) / 1e30;
    }

    /// @notice Verifies the cooldown status for earned stkAAVE
    /// @return cooldownStatus Status of the coolDown: if it is 0 then there is no cooldown Status, if it is 1 then
    /// the strategy should claim
    function _checkCooldown() internal view returns (uint256 cooldownStatus) {
        uint256 cooldownStartTimestamp = IStakedAave(_stkAave).stakersCooldowns(address(this));
        uint256 nextClaimStartTimestamp = cooldownStartTimestamp + cooldownSeconds;
        if (cooldownStartTimestamp == 0) {
            return 0;
        }
        if (block.timestamp > nextClaimStartTimestamp && block.timestamp <= nextClaimStartTimestamp + unstakeWindow) {
            return 1;
        }
        if (block.timestamp < nextClaimStartTimestamp) {
            return 2;
        }
    }

    /// @notice Get the deposit and debt token for our `want` token
    function _getAaveAssets() internal view returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = address(_aToken);
        assets[1] = address(_debtToken);
    }

    /// @notice Get Aave ratios for a token in order to compute later our collateral ratio
    /// @param token Address of the token for which to check the ratios (usually `want` token)
    /// @dev `getReserveConfigurationData` returns values in base 4. So here `ltv` and `liquidationThreshold` are returned in base 18
    function _getProtocolCollatRatios(address token) internal view returns (uint256 ltv, uint256 liquidationThreshold) {
        (, ltv, liquidationThreshold, , , , , , , ) = _protocolDataProvider.getReserveConfigurationData(token);
        // convert bps to wad
        ltv = ltv * _BPS_WAD_RATIO;
        liquidationThreshold = liquidationThreshold * _BPS_WAD_RATIO;
    }

    // ========================= Internal Pure Functions ===========================

    /// @notice Get target borrow amount based on deposit and collateral ratio
    /// @param deposit Current total deposited on Aave
    /// @param collatRatio Collateral ratio to target
    function _getBorrowFromDeposit(uint256 deposit, uint256 collatRatio) internal pure returns (uint256) {
        return (deposit * collatRatio) / _COLLATERAL_RATIO_PRECISION;
    }

    /// @notice Get target deposit amount based on borrow and collateral ratio
    /// @param borrow Current total borrowed on Aave
    /// @param collatRatio Collateral ratio to target
    /// @param deposits Current deposit amount: this is what the function should return if the `collatRatio` is null
    function _getDepositFromBorrow(
        uint256 borrow,
        uint256 collatRatio,
        uint256 deposits
    ) internal pure returns (uint256) {
        if (collatRatio > 0) return (borrow * _COLLATERAL_RATIO_PRECISION) / collatRatio;
        else return deposits;
    }

    /// @notice Get target borrow amount based on supply (deposits - borrow) and collateral ratio
    /// @param supply = deposits - borrows. The supply is what is "actually" deposited in Aave
    /// @param collatRatio Collateral ratio to target
    function _getBorrowFromSupply(uint256 supply, uint256 collatRatio) internal pure returns (uint256) {
        return (supply * collatRatio) / (_COLLATERAL_RATIO_PRECISION - collatRatio);
    }

    /// @notice Computes the position collateral ratio from deposits and borrows
    function _getCollatRatio(uint256 deposits, uint256 borrows) internal pure returns (uint256 currentCollatRatio) {
        if (deposits > 0) {
            currentCollatRatio = (borrows * _COLLATERAL_RATIO_PRECISION) / deposits;
        }
    }

    /// @notice Processes 1Inch revert messages
    function _revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            //solhint-disable-next-line
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }
        revert ErrorSwap();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import { IAToken, IProtocolDataProvider, IProtocolDataProvider, ILendingPool, IPriceOracle, IOptionalERC20 } from "./AaveInterfaces.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

library FlashMintLib {
    event Leverage(
        uint256 amountRequested,
        uint256 amountUsed,
        uint256 requiredDAI,
        uint256 amountToCloseLTVGap,
        bool deficit,
        address flashLoan
    );

    address public constant LENDER = 0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853;
    uint256 private constant _DAI_DECIMALS = 1e18;
    uint256 private constant _COLLAT_RATIO_PRECISION = 1 ether;
    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant _DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IAToken public constant ADAI = IAToken(0x028171bCA77440897B824Ca71D1c56caC55b68A3);
    IProtocolDataProvider private constant _protocolDataProvider =
        IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    ILendingPool private constant _lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    uint16 private constant _referral = 0; // TODO: get our own referral code

    uint256 private constant _RAY = 10**27;

    function doFlashMint(
        bool deficit,
        uint256 amountDesired,
        address token,
        uint256 collatRatioDAI,
        uint256 depositToCloseLTVGap
    ) public returns (uint256 amount) {
        if (amountDesired == 0) {
            return 0;
        }
        amount = amountDesired;
        address dai = _DAI;

        // calculate amount of dai we need
        uint256 requiredDAI;
        {
            requiredDAI = (toDAI(amount, token) * _COLLAT_RATIO_PRECISION) / collatRatioDAI;

            uint256 requiredDAIToCloseLTVGap = 0;
            if (depositToCloseLTVGap > 0) {
                requiredDAIToCloseLTVGap = toDAI(depositToCloseLTVGap, token);
                requiredDAI = requiredDAI + requiredDAIToCloseLTVGap;
            }

            uint256 _maxLiquidity = maxLiquidity();

            /*
            When depositing/withdrawing in the `lendingPool` the amounts are scaled by a `liquidityIndex` and rounded with the functions rayDiv and rayMul (in the aDAI contract)
            Weirdly, 2 different indexes are used: `liquidityIndex` is used when depositing and `getReserveNormalizedIncome` when withdrawing
            Therefore, we need to round `requiredDAI`, or we may get some rounding errors and revert
            because the amount we try to withdraw (to pay back the flashloan) is not equal to the amount deposited
            */
            uint256 liquidityIndex = _lendingPool.getReserveData(dai).liquidityIndex;
            uint256 getReserveNormalizedIncome = _lendingPool.getReserveNormalizedIncome(dai);
            uint256 rayDiv = ((requiredDAI * _RAY + liquidityIndex / 2) / liquidityIndex);
            requiredDAI = (rayDiv * getReserveNormalizedIncome + (_RAY / 2)) / _RAY;

            if (requiredDAI > _maxLiquidity) {
                requiredDAI = (_maxLiquidity * _RAY - (_RAY / 2)) / getReserveNormalizedIncome;
                requiredDAI = (requiredDAI * liquidityIndex - liquidityIndex / 2) / _RAY;

                // NOTE: if we cap amountDAI, we reduce amountToken we are taking too
                amount =
                    (fromDAI(requiredDAI - requiredDAIToCloseLTVGap, token) * collatRatioDAI) /
                    _COLLAT_RATIO_PRECISION;
            }
        }

        bytes memory data = abi.encode(deficit, amount);
        uint256 _fee = IERC3156FlashLender(LENDER).flashFee(dai, requiredDAI);
        // Check that fees have not been increased without us knowing
        require(_fee == 0);
        uint256 _allowance = IERC20(dai).allowance(address(this), address(LENDER));
        if (_allowance < requiredDAI) {
            IERC20(dai).approve(address(LENDER), 0);
            IERC20(dai).approve(address(LENDER), type(uint256).max);
        }

        IERC3156FlashLender(LENDER).flashLoan(IERC3156FlashBorrower(address(this)), dai, requiredDAI, data);

        emit Leverage(amountDesired, amount, requiredDAI, depositToCloseLTVGap, deficit, LENDER);

        return amount; // we need to return the amount of Token we have changed our position in
    }

    function loanLogic(
        bool deficit,
        uint256 amount,
        uint256 amountFlashmint,
        address want
    ) public returns (bytes32) {
        address dai = _DAI;
        bool isDai = (want == dai);

        ILendingPool lp = _lendingPool;

        if (isDai) {
            if (deficit) {
                lp.deposit(dai, amountFlashmint - amount, address(this), _referral);
                lp.repay(dai, IERC20(dai).balanceOf(address(this)), 2, address(this));
                lp.withdraw(dai, amountFlashmint, address(this));
            } else {
                lp.deposit(dai, IERC20(dai).balanceOf(address(this)), address(this), _referral);
                lp.borrow(dai, amount, 2, _referral, address(this));
                lp.withdraw(dai, amountFlashmint - amount, address(this));
            }
        } else {
            // 1. Deposit DAI in Aave as collateral
            lp.deposit(dai, amountFlashmint, address(this), _referral);

            if (deficit) {
                // 2a. if in deficit withdraw amount and repay it
                lp.withdraw(want, amount, address(this));
                lp.repay(want, IERC20(want).balanceOf(address(this)), 2, address(this));
            } else {
                // 2b. if levering up borrow and deposit
                lp.borrow(want, amount, 2, _referral, address(this));
                lp.deposit(want, IERC20(want).balanceOf(address(this)), address(this), _referral);
            }
            // 3. Withdraw DAI
            lp.withdraw(dai, amountFlashmint, address(this));
        }

        return CALLBACK_SUCCESS;
    }

    function priceOracle() internal view returns (IPriceOracle) {
        return IPriceOracle(_protocolDataProvider.ADDRESSES_PROVIDER().getPriceOracle());
    }

    function toDAI(uint256 _amount, address asset) internal view returns (uint256) {
        address dai = _DAI;
        if (_amount == 0 || _amount == type(uint256).max || asset == dai) {
            return _amount;
        }

        if (asset == _WETH) {
            return
                (_amount * (uint256(10)**uint256(IOptionalERC20(dai).decimals()))) / priceOracle().getAssetPrice(dai);
        }

        address[] memory tokens = new address[](2);
        tokens[0] = asset;
        tokens[1] = dai;
        uint256[] memory prices = priceOracle().getAssetsPrices(tokens);

        uint256 ethPrice = (_amount * prices[0]) / (uint256(10)**uint256(IOptionalERC20(asset).decimals()));
        return (ethPrice * _DAI_DECIMALS) / prices[1];
    }

    function fromDAI(uint256 _amount, address asset) internal view returns (uint256) {
        address dai = _DAI;
        if (_amount == 0 || _amount == type(uint256).max || asset == dai) {
            return _amount;
        }

        if (asset == _WETH) {
            return
                (_amount * priceOracle().getAssetPrice(dai)) / (uint256(10)**uint256(IOptionalERC20(dai).decimals()));
        }

        address[] memory tokens = new address[](2);
        tokens[0] = asset;
        tokens[1] = dai;
        uint256[] memory prices = priceOracle().getAssetsPrices(tokens);

        uint256 ethPrice = (_amount * prices[1]) / _DAI_DECIMALS;

        return (ethPrice * (uint256(10)**uint256(IOptionalERC20(asset).decimals()))) / prices[0];
    }

    function maxLiquidity() public view returns (uint256) {
        return IERC3156FlashLender(LENDER).maxFlashLoan(_DAI);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import { DataTypes } from "./AaveLibraries.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAaveIncentivesController {
    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    //solhint-disable-next-line
    function REWARD_TOKEN() external view returns (address);

    function getDistributionEnd() external view returns (uint256);

    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function assets(address asset)
        external
        view
        returns (
            uint256 emissionPerSecond,
            uint256 index,
            uint256 lastUpdateTimestamp
        );

    function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;
}

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

interface IProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    //solhint-disable-next-line
    function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

    function getAllReservesTokens() external view returns (TokenData[] memory);

    function getAllATokens() external view returns (TokenData[] memory);

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

interface IScaledBalanceToken {
    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IERC20, IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param onBehalfOf The address of the user on which behalf minting has been performed
     * @param value The amount to be minted
     * @param index The last index of the reserve
     **/
    event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

    /**
     * @dev Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return `true` if the the previous balance of the user is 0
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted when variable debt is burnt
     * @param user The user which debt has been burned
     * @param amount The amount of debt being burned
     * @param index The index of the user
     **/
    event Burn(address indexed user, uint256 amount, uint256 index);

    /**
     * @dev Burns user variable debt
     * @param user The user which debt is burnt
     * @param index The variable debt index of the reserve
     **/
    function burn(
        address user,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController() external view returns (IAaveIncentivesController);
}

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

interface IOptionalERC20 {
    function decimals() external view returns (uint8);
}

interface IPriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata _assets) external view returns (uint256[] memory);

    function getSourceOfAsset(address _asset) external view returns (address);

    function getFallbackOracle() external view returns (address);
}

interface IStakedAave is IERC20 {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;

    function getTotalRewardsBalance(address) external view returns (uint256);

    //solhint-disable-next-line
    function COOLDOWN_SECONDS() external view returns (uint256);

    function stakersCooldowns(address) external view returns (uint256);

    //solhint-disable-next-line
    function UNSTAKE_WINDOW() external view returns (uint256);
}

/**
 * @title IInitializableAToken
 * @notice Interface for the initialize function on AToken
 * @author Aave
 **/
interface IInitializableAToken {
    /**
     * @dev Emitted when an aToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated lending pool
     * @param treasury The address of the treasury
     * @param incentivesController The address of the incentives controller for this aToken
     * @param aTokenDecimals the decimals of the underlying
     * @param aTokenName the name of the aToken
     * @param aTokenSymbol the symbol of the aToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        address incentivesController,
        uint8 aTokenDecimals,
        string aTokenName,
        string aTokenSymbol,
        bytes params
    );

    /**
     * @dev Initializes the aToken
     * @param pool The address of the lending pool where this aToken will be used
     * @param treasury The address of the Aave treasury, receiving the fees on this aToken
     * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
     * @param aTokenName The name of the aToken
     * @param aTokenSymbol The symbol of the aToken
     */
    function initialize(
        ILendingPool pool,
        address treasury,
        address underlyingAsset,
        IAaveIncentivesController incentivesController,
        uint8 aTokenDecimals,
        string calldata aTokenName,
        string calldata aTokenSymbol,
        bytes calldata params
    ) external;
}

interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Mints aTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the underlying
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

    /**
     * @dev Invoked to execute actions on the aToken side after a repayment.
     * @param user The user executing the repayment
     * @param amount The amount getting repaid
     **/
    function handleRepayment(address user, uint256 amount) external;

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController() external view returns (IAaveIncentivesController);

    /**
     * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
     **/
    //solhint-disable-next-line
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

/**
 * @title IReserveInterestRateStrategyInterface interface
 * @dev Interface for the calculation of the interest rates
 * @author Aave
 */
interface IReserveInterestRateStrategy {
    function baseVariableBorrowRate() external view returns (uint256);

    function getMaxVariableBorrowRate() external view returns (uint256);

    function stableRateSlope1() external view returns (uint256);

    function stableRateSlope2() external view returns (uint256);

    function variableRateSlope1() external view returns (uint256);

    function variableRateSlope2() external view returns (uint256);

    //solhint-disable-next-line
    function OPTIMAL_UTILIZATION_RATE() external view returns (uint256);

    function calculateInterestRates(
        address reserve,
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    )
        external
        view
        returns (
            uint256 liquidityRate,
            uint256 stableBorrowRate,
            uint256 variableBorrowRate
        );

    function calculateInterestRates(
        address reserve,
        address aToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    )
        external
        view
        returns (
            uint256 liquidityRate,
            uint256 stableBorrowRate,
            uint256 variableBorrowRate
        );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./BaseStrategyEvents.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title BaseStrategyUpgradeable
/// @author Forked from https://github.com/yearn/yearn-managers/blob/master/contracts/BaseStrategy.sol
/// @notice `BaseStrategyUpgradeable` implements all of the required functionalities to interoperate
/// with the `PoolManager` Contract.
/// @dev This contract should be inherited and the abstract methods implemented to adapt the `Strategy`
/// to the particular needs it has to create a return.
abstract contract BaseStrategyUpgradeable is BaseStrategyEvents, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    uint256 public constant BASE = 10**18;
    uint256 public constant SECONDSPERYEAR = 31556952;

    /// @notice Role for `PoolManager` only
    bytes32 public constant POOLMANAGER_ROLE = keccak256("POOLMANAGER_ROLE");
    /// @notice Role for guardians and governors
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    /// @notice Role for keepers
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    // ======================== References to contracts ============================

    /// @notice Reference to the protocol's collateral `PoolManager`
    IPoolManager public poolManager;

    /// @notice Reference to the ERC20 farmed by this strategy
    IERC20 public want;

    /// @notice Base of the ERC20 token farmed by this strategy
    uint256 public wantBase;

    // ============================ Parameters =====================================

    /// @notice Use this to adjust the threshold at which running a debt causes a
    /// harvest trigger. See `setDebtThreshold()` for more details
    uint256 public debtThreshold;

    /// @notice See note on `setEmergencyExit()`
    bool public emergencyExit;

    // ============================ Errors =========================================

    error InvalidToken();
    error ZeroAddress();

    // ============================ Constructor ====================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Constructor of the `BaseStrategyUpgradeable`
    /// @param _poolManager Address of the `PoolManager` lending collateral to this strategy
    /// @param governor Governor address of the protocol
    /// @param guardian Address of the guardian
    function _initialize(
        address _poolManager,
        address governor,
        address guardian,
        address[] memory keepers
    ) internal initializer {
        poolManager = IPoolManager(_poolManager);
        want = IERC20(poolManager.token());
        wantBase = 10**(IERC20Metadata(address(want)).decimals());
        if (guardian == address(0) || governor == address(0) || governor == guardian) revert ZeroAddress();
        // AccessControl
        // Governor is guardian so no need for a governor role
        _setupRole(GUARDIAN_ROLE, guardian);
        _setupRole(GUARDIAN_ROLE, governor);
        _setupRole(POOLMANAGER_ROLE, address(_poolManager));
        _setRoleAdmin(POOLMANAGER_ROLE, POOLMANAGER_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, POOLMANAGER_ROLE);

        // Initializing roles first
        for (uint256 i = 0; i < keepers.length; i++) {
            if (keepers[i] == address(0)) revert ZeroAddress();
            _setupRole(KEEPER_ROLE, keepers[i]);
        }
        _setRoleAdmin(KEEPER_ROLE, GUARDIAN_ROLE);

        debtThreshold = 100 * BASE;
        emergencyExit = false;
        // Give `PoolManager` unlimited access (might save gas)
        want.safeIncreaseAllowance(address(poolManager), type(uint256).max);
    }

    // ========================== Core functions ===================================

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting
    /// the Strategy's position.
    function harvest() external {
        _report();
        // Check if free returns are left, and re-invest them
        _adjustPosition();
    }

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting
    /// the Strategy's position.
    /// @param borrowInit Approximate optimal borrows to have faster convergence on the NR method
    function harvest(uint256 borrowInit) external onlyRole(KEEPER_ROLE) {
        _report();
        // Check if free returns are left, and re-invest them, gives an hint on the borrow amount to the NR method
        // to maximise revenue
        _adjustPosition(borrowInit);
    }

    /// @notice Withdraws `_amountNeeded` to `poolManager`.
    /// @param _amountNeeded How much `want` to withdraw.
    /// @return amountFreed How much `want` withdrawn.
    /// @return _loss Any realized losses
    /// @dev This may only be called by the `PoolManager`
    function withdraw(uint256 _amountNeeded)
        external
        onlyRole(POOLMANAGER_ROLE)
        returns (uint256 amountFreed, uint256 _loss)
    {
        // Liquidate as much as possible `want` (up to `_amountNeeded`)
        (amountFreed, _loss) = _liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    // ============================ View functions =================================

    /// @notice Provides an accurate estimate for the total amount of assets
    /// (principle + return) that this Strategy is currently managing,
    /// denominated in terms of `want` tokens.
    /// This total should be "realizable" e.g. the total value that could
    /// *actually* be obtained from this Strategy if it were to divest its
    /// entire position based on current on-chain conditions.
    /// @return The estimated total assets in this Strategy.
    /// @dev Care must be taken in using this function, since it relies on external
    /// systems, which could be manipulated by the attacker to give an inflated
    /// (or reduced) value produced by this function, based on current on-chain
    /// conditions (e.g. this function is possible to influence through
    /// flashloan attacks, oracle manipulations, or other DeFi attack
    /// mechanisms).
    function estimatedTotalAssets() public view virtual returns (uint256);

    /// @notice Provides an indication of whether this strategy is currently "active"
    /// in that it is managing an active position, or will manage a position in
    /// the future. This should correlate to `harvest()` activity, so that Harvest
    /// events can be tracked externally by indexing agents.
    /// @return True if the strategy is actively managing a position.
    function isActive() public view returns (bool) {
        return estimatedTotalAssets() > 0;
    }

    // ============================ Internal Functions =============================

    /// @notice PrepareReturn the Strategy, recognizing any profits or losses
    /// @dev In the rare case the Strategy is in emergency shutdown, this will exit
    /// the Strategy's position.
    /// @dev  When `_report()` is called, the Strategy reports to the Manager (via
    /// `poolManager.report()`), so in some cases `harvest()` must be called in order
    /// to take in profits, to borrow newly available funds from the Manager, or
    /// otherwise adjust its position. In other cases `harvest()` must be
    /// called to report to the Manager on the Strategy's position, especially if
    /// any losses have occurred.
    /// @dev As keepers may directly profit from this function, there may be front-running problems with miners bots,
    /// we may have to put an access control logic for this function to only allow white-listed addresses to act
    /// as keepers for the protocol
    function _report() internal {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = poolManager.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = _liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding - amountFreed;
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed - debtOutstanding;
            }
            debtPayment = debtOutstanding - loss;
        } else {
            // Free up returns for Manager to pull
            (profit, loss, debtPayment) = _prepareReturn(debtOutstanding);
        }
        emit Harvested(profit, loss, debtPayment, debtOutstanding);

        // Allows Manager to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Manager.
        poolManager.report(profit, loss, debtPayment);
    }

    /// @notice Performs any Strategy unwinding or other calls necessary to capture the
    /// "free return" this Strategy has generated since the last time its core
    /// position(s) were adjusted. Examples include unwrapping extra rewards.
    /// This call is only used during "normal operation" of a Strategy, and
    /// should be optimized to minimize losses as much as possible.
    ///
    /// This method returns any realized profits and/or realized losses
    /// incurred, and should return the total amounts of profits/losses/debt
    /// payments (in `want` tokens) for the Manager's accounting (e.g.
    /// `want.balanceOf(this) >= _debtPayment + _profit`).
    ///
    /// `_debtOutstanding` will be 0 if the Strategy is not past the configured
    /// debt limit, otherwise its value will be how far past the debt limit
    /// the Strategy is. The Strategy's debt limit is configured in the Manager.
    ///
    /// NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
    ///       It is okay for it to be less than `_debtOutstanding`, as that
    ///       should only used as a guide for how much is left to pay back.
    ///       Payments should be made to minimize loss from slippage, debt,
    ///       withdrawal fees, etc.
    ///
    /// See `poolManager.debtOutstanding()`.
    function _prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /// @notice Performs any adjustments to the core position(s) of this Strategy given
    /// what change the Manager made in the "investable capital" available to the
    /// Strategy. Note that all "free capital" in the Strategy after the report
    /// was made is available for reinvestment. Also note that this number
    /// could be 0, and you should handle that scenario accordingly.
    function _adjustPosition() internal virtual;

    /// @notice same as _adjustPosition but with an initial parameters
    function _adjustPosition(uint256) internal virtual;

    /// @notice Liquidates up to `_amountNeeded` of `want` of this strategy's positions,
    /// irregardless of slippage. Any excess will be re-invested with `_adjustPosition()`.
    /// This function should return the amount of `want` tokens made available by the
    /// liquidation. If there is a difference between them, `_loss` indicates whether the
    /// difference is due to a realized loss, or if there is some other sitution at play
    /// (e.g. locked funds) where the amount made available is less than what is needed.
    ///
    /// NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
    function _liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 _liquidatedAmount, uint256 _loss);

    /// @notice Liquidates everything and returns the amount that got freed.
    /// This function is used during emergency exit instead of `_prepareReturn()` to
    /// liquidate all of the Strategy's positions back to the Manager.
    function _liquidateAllPositions() internal virtual returns (uint256 _amountFreed);

    /// @notice Override this to add all tokens/tokenized positions this contract
    /// manages on a *persistent* basis (e.g. not just for swapping back to
    /// want ephemerally).
    ///
    /// NOTE: Do *not* include `want`, already included in `sweep` below.
    ///
    /// Example:
    /// ```
    ///    function _protectedTokens() internal override view returns (address[] memory) {
    ///      address[] memory protected = new address[](3);
    ///      protected[0] = tokenA;
    ///      protected[1] = tokenB;
    ///      protected[2] = tokenC;
    ///      return protected;
    ///    }
    /// ```
    function _protectedTokens() internal view virtual returns (address[] memory);

    // ============================== Governance ===================================

    /// @notice Activates emergency exit. Once activated, the Strategy will exit its
    /// position upon the next harvest, depositing all funds into the Manager as
    /// quickly as is reasonable given on-chain conditions.
    /// @dev This may only be called by the `PoolManager`, because when calling this the `PoolManager` should at the same
    /// time update the debt ratio
    /// @dev This function can only be called once by the `PoolManager` contract
    /// @dev See `poolManager.setEmergencyExit()` and `harvest()` for further details.
    function setEmergencyExit() external onlyRole(POOLMANAGER_ROLE) {
        emergencyExit = true;
        emit EmergencyExitActivated();
    }

    /// @notice Sets how far the Strategy can go into loss without a harvest and report
    /// being required.
    /// @param _debtThreshold How big of a loss this Strategy may carry without
    /// @dev By default this is 0, meaning any losses would cause a harvest which
    /// will subsequently report the loss to the Manager for tracking.
    function setDebtThreshold(uint256 _debtThreshold) external onlyRole(GUARDIAN_ROLE) {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    /// @notice Removes tokens from this Strategy that are not the type of tokens
    /// managed by this Strategy. This may be used in case of accidentally
    /// sending the wrong kind of token to this Strategy.
    ///
    /// Tokens will be sent to `governance()`.
    ///
    /// This will fail if an attempt is made to sweep `want`, or any tokens
    /// that are protected by this Strategy.
    ///
    /// This may only be called by governance.
    /// @param _token The token to transfer out of this `PoolManager`.
    /// @param to Address to send the tokens to.
    /// @dev
    /// Implement `_protectedTokens()` to specify any additional tokens that
    /// should be protected from sweeping in addition to `want`.
    function sweep(address _token, address to) external onlyRole(GUARDIAN_ROLE) {
        if (_token == address(want)) revert InvalidToken();

        address[] memory __protectedTokens = _protectedTokens();
        for (uint256 i = 0; i < __protectedTokens.length; i++)
            // In the strategy we use so far, the only protectedToken is the want token
            // and this has been checked above
            if (_token == __protectedTokens[i]) revert InvalidToken();

        IERC20(_token).safeTransfer(to, IERC20(_token).balanceOf(address(this)));
    }

    // ============================ Manager functions ==============================

    /// @notice Adds a new guardian address and echoes the change to the contracts
    /// that interact with this collateral `PoolManager`
    /// @param _guardian New guardian address
    /// @dev This internal function has to be put in this file because Access Control is not defined
    /// in PoolManagerInternal
    function addGuardian(address _guardian) external virtual;

    /// @notice Revokes the guardian role and propagates the change to other contracts
    /// @param guardian Old guardian address to revoke
    function revokeGuardian(address guardian) external virtual;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

/// @title ComputeProfitability
/// @author Angle Core Team
/// @notice Helper contract to get the optimal borrow amount from a set of provided parameters from Aave
library ComputeProfitability {
    struct SCalculateBorrow {
        int256 reserveFactor;
        int256 totalStableDebt;
        int256 totalVariableDebt;
        int256 totalDeposits;
        int256 stableBorrowRate;
        int256 rewardDeposit;
        int256 rewardBorrow;
        int256 strategyAssets;
        int256 guessedBorrowAssets;
        int256 slope1;
        int256 slope2;
        int256 r0;
        int256 uOptimal;
    }

    int256 private constant _BASE_RAY = 10**27;

    /// @notice Computes the Aave utilization ratio
    function _computeUtilization(int256 borrow, SCalculateBorrow memory parameters) internal pure returns (int256) {
        return
            ((parameters.totalStableDebt + parameters.totalVariableDebt + borrow) * _BASE_RAY) /
            (parameters.totalDeposits + borrow);
    }

    /// @notice Computes the derivative of the utilization ratio with respect to the amount borrowed
    function _computeUprime(int256 borrow, SCalculateBorrow memory parameters) internal pure returns (int256) {
        return
            ((parameters.totalDeposits - parameters.totalStableDebt - parameters.totalVariableDebt) * _BASE_RAY) /
            (parameters.totalDeposits + borrow);
    }

    /// @notice Computes the value of the interest rate, its first and second order derivatives
    /// @dev The returned value is in `_BASE_RAY`
    function _calculateInterestPrimes(int256 borrow, SCalculateBorrow memory parameters)
        internal
        pure
        returns (
            int256 interest,
            int256 interestPrime,
            int256 interestPrime2
        )
    {
        int256 newUtilization = _computeUtilization(borrow, parameters);
        int256 denomUPrime = (parameters.totalDeposits + borrow);
        int256 uprime = _computeUprime(borrow, parameters);
        uprime = (uprime * _BASE_RAY) / denomUPrime;
        int256 uprime2nd = -2 * uprime;
        uprime2nd = (uprime2nd * _BASE_RAY) / denomUPrime;
        if (newUtilization < parameters.uOptimal) {
            interest = parameters.r0 + (parameters.slope1 * newUtilization) / parameters.uOptimal;
            interestPrime = (parameters.slope1 * uprime) / parameters.uOptimal;
            interestPrime2 = (parameters.slope1 * uprime2nd) / parameters.uOptimal;
        } else {
            interest =
                parameters.r0 +
                parameters.slope1 +
                (parameters.slope2 * (newUtilization - parameters.uOptimal)) /
                (_BASE_RAY - parameters.uOptimal);
            interestPrime = (parameters.slope2 * uprime) / (_BASE_RAY - parameters.uOptimal);
            interestPrime2 = (parameters.slope2 * uprime2nd) / (_BASE_RAY - parameters.uOptimal);
        }
    }

    /// @notice Computes the value of the revenue, as well as its first and second order derivatives
    function _revenuePrimes(
        int256 borrow,
        SCalculateBorrow memory parameters,
        bool onlyRevenue
    )
        internal
        pure
        returns (
            int256 revenue,
            int256 revenuePrime,
            int256 revenuePrime2nd
        )
    {
        (int256 newRate, int256 newRatePrime, int256 newRatePrime2) = _calculateInterestPrimes(borrow, parameters);

        // 0 order derivative
        int256 proportionStrat = ((borrow + parameters.strategyAssets) * (_BASE_RAY - parameters.reserveFactor)) /
            (borrow + parameters.totalDeposits);
        int256 poolYearlyRevenue = (parameters.totalStableDebt *
            parameters.stableBorrowRate +
            (borrow + parameters.totalVariableDebt) *
            newRate) / _BASE_RAY;

        revenue =
            (proportionStrat * poolYearlyRevenue) /
            _BASE_RAY +
            (borrow * parameters.rewardBorrow) /
            (borrow + parameters.totalVariableDebt) +
            ((borrow + parameters.strategyAssets) * parameters.rewardDeposit) /
            (borrow + parameters.totalDeposits) -
            (borrow * newRate) /
            _BASE_RAY;

        if (!onlyRevenue) {
            // 1st order derivative
            {
                // Computing block per block to avoid stack too deep errors
                int256 proportionStratPrime = ((parameters.totalDeposits - parameters.strategyAssets) *
                    (_BASE_RAY - parameters.reserveFactor)) / (borrow + parameters.totalDeposits);
                proportionStratPrime = (proportionStratPrime * _BASE_RAY) / (borrow + parameters.totalDeposits);
                int256 poolYearlyRevenuePrime = (newRate *
                    _BASE_RAY +
                    (borrow + parameters.totalVariableDebt) *
                    newRatePrime) / _BASE_RAY;

                revenuePrime = ((proportionStratPrime * poolYearlyRevenue + poolYearlyRevenuePrime * proportionStrat) /
                    _BASE_RAY);

                {
                    int256 proportionStratPrime2nd = (-2 * (proportionStratPrime * (_BASE_RAY))) /
                        ((borrow + parameters.totalDeposits));
                    revenuePrime2nd =
                        2 *
                        proportionStratPrime *
                        poolYearlyRevenuePrime +
                        proportionStratPrime2nd *
                        poolYearlyRevenue;
                }
                poolYearlyRevenuePrime =
                    (2 * newRatePrime * _BASE_RAY + (borrow + parameters.totalVariableDebt) * newRatePrime2) /
                    _BASE_RAY;

                revenuePrime2nd = (revenuePrime2nd + poolYearlyRevenuePrime * proportionStrat) / _BASE_RAY;
            }

            int256 costPrime = (newRate * _BASE_RAY + borrow * newRatePrime) / _BASE_RAY;
            int256 rewardBorrowPrime = (parameters.rewardBorrow * (parameters.totalVariableDebt)) /
                (borrow + parameters.totalVariableDebt);
            rewardBorrowPrime = (rewardBorrowPrime * _BASE_RAY) / (borrow + parameters.totalVariableDebt);
            int256 rewardDepositPrime = (parameters.rewardDeposit *
                (parameters.totalDeposits - parameters.strategyAssets)) / (borrow + parameters.totalDeposits);
            rewardDepositPrime = (rewardDepositPrime * _BASE_RAY) / (borrow + parameters.totalDeposits);

            revenuePrime += rewardBorrowPrime + rewardDepositPrime - costPrime;

            // 2nd order derivative
            // Reusing variables for the stack too deep issue
            costPrime = ((2 * newRatePrime * _BASE_RAY) + borrow * newRatePrime2) / _BASE_RAY;
            rewardBorrowPrime = (-2 * rewardBorrowPrime * _BASE_RAY) / (borrow + parameters.totalVariableDebt);
            rewardDepositPrime = (-2 * rewardDepositPrime * _BASE_RAY) / (borrow + parameters.totalDeposits);

            revenuePrime2nd += (rewardBorrowPrime + rewardDepositPrime) - costPrime;
        }
    }

    /// @notice Returns the absolute value of an integer
    function _abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    /// @notice Computes the optimal borrow amount of the strategy depending on Aave protocol parameters
    /// to maximize folding revenues
    /// @dev Performs a newton Raphson approximation to get the zero point of the derivative of the
    /// revenue function of the protocol depending on the amount borrowed
    function computeProfitability(SCalculateBorrow memory parameters) internal pure returns (int256 borrow) {
        (int256 y, , ) = _revenuePrimes(0, parameters, true);
        (int256 revenueWithBorrow, , ) = _revenuePrimes(_BASE_RAY, parameters, true);

        if (revenueWithBorrow <= y) {
            return 0;
        }
        uint256 count;
        int256 borrowInit;
        int256 grad;
        int256 grad2nd;
        borrow = parameters.guessedBorrowAssets;
        // Tolerance is 1% in this method: indeed we're stopping: `_abs(borrowInit - borrow)/ borrowInit < 10**(-2)`
        while (count < 10 && (count == 0 || _abs(borrowInit - borrow) * (10**2 / 5) > borrowInit)) {
            (, grad, grad2nd) = _revenuePrimes(borrow, parameters, false);
            borrowInit = borrow;
            borrow = borrowInit - (grad * _BASE_RAY) / grad2nd;
            count += 1;
        }

        (int256 x, , ) = _revenuePrimes(borrow, parameters, true);
        if (x <= y) {
            borrow = 0;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../external/AccessControl.sol";
import "../external/AccessControlUpgradeable.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IPoolManager.sol";

/// @title BaseStrategyEvents
/// @author Angle Core Team
/// @notice Events used in the abstract `BaseStrategy` contract
contract BaseStrategyEvents {
    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedMinReportDelayed(uint256 delay);

    event UpdatedMaxReportDelayed(uint256 delay);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event UpdatedRewards(address rewards);

    event UpdatedIsRewardActivated(bool activated);

    event UpdatedRewardAmountAndMinimumAmountMoved(uint256 _rewardAmount, uint256 _minimumAmountMoved);

    event EmergencyExitActivated();
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IAccessControl.sol";

/**
 * @dev This contract is fully forked from OpenZeppelin `AccessControl`.
 * The only difference is the removal of the ERC165 implementation as it's not
 * needed in Angle.
 *
 * Contract module that allows children to implement role-based access
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
abstract contract AccessControl is Context, IAccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
    function grantRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) external override {
        require(account == _msgSender(), "71");

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
     */
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAccessControl.sol";

/**
 * @dev This contract is fully forked from OpenZeppelin `AccessControlUpgradeable`.
 * The only difference is the removal of the ERC165 implementation as it's not
 * needed in Angle.
 *
 * Contract module that allows children to implement role-based access
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
abstract contract AccessControlUpgradeable is Initializable, IAccessControl {
    function __AccessControl_init() internal initializer {
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {}

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function grantRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) external override {
        require(account == msg.sender, "71");

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
     */
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./IAccessControl.sol";

/// @title IStrategy
/// @author Inspired by Yearn with slight changes from Angle Core Team
/// @notice Interface for yield farming strategies
interface IStrategy is IAccessControl {
    function estimatedAPR() external view returns (uint256);

    function poolManager() external view returns (address);

    function want() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    function withdraw(uint256 _amountNeeded) external returns (uint256 amountFreed, uint256 _loss);

    function setEmergencyExit() external;

    function addGuardian(address _guardian) external;

    function revokeGuardian(address _guardian) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

// Struct for the parameters associated to a strategy interacting with a collateral `PoolManager`
// contract
struct StrategyParams {
    // Timestamp of last report made by this strategy
    // It is also used to check if a strategy has been initialized
    uint256 lastReport;
    // Total amount the strategy is expected to have
    uint256 totalStrategyDebt;
    // The share of the total assets in the `PoolManager` contract that the `strategy` can access to.
    uint256 debtRatio;
}

/// @title IPoolManagerFunctions
/// @author Angle Core Team
/// @notice Interface for the collateral poolManager contracts handling each one type of collateral for
/// a given stablecoin
/// @dev Only the functions used in other contracts of the protocol are left here
interface IPoolManagerFunctions {
    // ============================ Yield Farming ==================================

    function creditAvailable() external view returns (uint256);

    function debtOutstanding() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external;

    // ============================= Getters =======================================

    function getBalance() external view returns (uint256);

    function getTotalAsset() external view returns (uint256);
}

/// @title IPoolManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
/// @dev Used in other contracts of the protocol
interface IPoolManager is IPoolManagerFunctions {
    function stableMaster() external view returns (address);

    function perpetualManager() external view returns (address);

    function token() external view returns (address);

    function totalDebt() external view returns (uint256);

    function strategies(address _strategy) external view returns (StrategyParams memory);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IAccessControl
/// @author Forked from OpenZeppelin
/// @notice Interface for `AccessControl` contracts
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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