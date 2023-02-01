//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.6;

import {ISilicaVault} from "./interfaces/ISilicaVault.sol";
import {SVStorage} from "./storage/SilicaVaultStorage.sol";
import {SVGetters} from "./impl/SVGetters.sol";

import {ShareMath} from "./libraries/ShareMath.sol";

import {SVTypes} from "./libraries/SilicaVaultTypes.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {SilicaV2_1} from "@alkimiya/v2.1-core/contracts/SilicaV2_1.sol";
import {IOracleRegistry} from "@alkimiya/v2.1-core/contracts/interfaces/oracle/IOracleRegistry.sol";
import {Oracle} from "@alkimiya/v2.1-core/contracts/Oracle.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import {IContractTrader} from "./interfaces/IContractTrader.sol";

/// @title SilicaVault
abstract contract AbstractSilicaVault is ERC20, ISilicaVault, SVStorage, SVGetters, Ownable, ReentrancyGuard {
    uint32 public constant SETTLEMENT_DAYS = 2;
    uint256 public constant MAX_DEPOSIT_AMOUNT = 2 * (10 ** 12); // 2mil USDC max
    uint256 public constant MIN_DEPOSIT_THRESHOLD = 2 * (10 ** 11); // 200k USDC

    uint256 public constant FEE_PERCENT = 1e15;

    /*///////////////////////////////////////////////////////////////
                                ADMIN: ROLLOVER
    //////////////////////////////////////////////////////////////*/

    /// @notice Process all pending withdraw requests from the previous round
    /// @dev This is the first step in rollover to next round
    function processWithdraws() external override onlyOwner nonReentrant returns (uint256 paymentLockup, uint256 rewardLockup) {
        SVTypes.State memory stateCopy = state;
        require(getOracleDay() >= stateCopy.lastDayForSettlements, "not ready");
        require(stateCopy.numSilicasActive == 0, "all silicas must be settled");
        require(withdrawalsOpen, "Withdraws already processed");

        //No SW between PW and SNR
        withdrawalsOpen = false;

        uint256 paymentHeld = totalPaymentHeld();
        uint256 rewardHeld = totalRewardHeld();
        uint256 sharesToWithdraw = sharesWithdrawnPerRound[stateCopy.currentRound];
        uint256 shares = totalShares();

        // Store balances for when withdraws are settled
        pTokenWithdrawnPerRound[stateCopy.currentRound] = paymentHeld;
        rTokenWithdrawnPerRound[stateCopy.currentRound] = rewardHeld;

        // Lock up withdraw amounts
        paymentLockup = ShareMath.convertToAsset(sharesToWithdraw, paymentHeld, shares);
        rewardLockup = ShareMath.convertToAsset(sharesToWithdraw, rewardHeld, shares);

        pTokenLocked += paymentLockup;
        rTokenLocked += rewardLockup;
        sharesPendingBurn += sharesToWithdraw;

        emit ProcessWithdraws(paymentLockup, rewardLockup);
    }

    function swap(
        address contractTrader,
        uint256 rewardAmount,
        bytes calldata data
    ) external override onlyOwner nonReentrant returns (uint256 rewardTraded, uint256 paymentTraded) {
        require(rewardAmount <= totalRewardHeld(), "insufficient balance");
        (int24 amt, uint256 estimatePaymentTraded) = _estimateAmountOut(rewardAmount, 3000, 420);
        uint256 rewardStartingBalance = IERC20(rewardToken).balanceOf(address(this));
        uint256 paymentStartingBalance = IERC20(paymentToken).balanceOf(address(this));
        IERC20(rewardToken).approve(contractTrader, rewardAmount);
        IContractTrader(contractTrader).trade(address(this), address(rewardToken), address(paymentToken), rewardAmount, data);

        rewardTraded = rewardStartingBalance - rewardToken.balanceOf(address(this));
        paymentTraded = paymentToken.balanceOf(address(this)) - paymentStartingBalance;

        require(paymentTraded >= (estimatePaymentTraded * 95) / 100, "UOE");
        emit Swap(rewardTraded, paymentTraded);
    }

    function _estimateAmountOut(
        uint256 amountIn,
        uint24 fee,
        uint32 secondsAgo
    ) internal view virtual returns (int24 tick, uint256 amountOut) {
        address _pool = IUniswapV3Factory(swapRouter).getPool(address(rewardToken), address(paymentToken), fee);
        require(_pool != address(0), "pool doesn't exist");

        (tick, ) = OracleLibrary.consult(_pool, secondsAgo);

        amountOut = OracleLibrary.getQuoteAtTick(tick, uint128(amountIn), address(rewardToken), address(paymentToken));
    }

    ///@notice Processes all pending deposits and kicks off next epoch
    ///@dev Must be last step after processing withdraws and swapping
    function startNextRound(uint256 epochDuration) external override onlyOwner nonReentrant returns (uint256 mintedShares) {
        require(epochDuration > 0, "Epoch duration cannot be 0");
        SVTypes.State memory stateCopy = state;

        if (sharesWithdrawnPerRound[stateCopy.currentRound] != 0) {
            require(
                pTokenWithdrawnPerRound[stateCopy.currentRound] != 0 || rTokenWithdrawnPerRound[stateCopy.currentRound] != 0,
                "needs PW"
            );
        }

        // Check all silicas settled
        require(stateCopy.numSilicasActive == 0, "all silicas must be settled");

        // Require all reward tokens be swapped
        require(totalRewardHeld() == 0, "swap rewards");

        // Require admin to wait until settlement period is over
        // @ATTN: Replace with lastDayOfSettlement
        uint32 oracleDay = getOracleDay();
        require(oracleDay >= stateCopy.lastDayForSettlements, "not ready");

        // Set aside mgment fee on all new investments
        uint256 mgmtFees = (pendingDeposits * FEE_PERCENT) / 1e18;

        uint256 paymentHeld = totalPaymentHeld();
        uint256 shareSupply = totalShares();

        pendingDeposits -= mgmtFees;
        mintedShares = ShareMath.convertToShares(pendingDeposits, paymentHeld, shareSupply);
        _mint(address(this), mintedShares);

        uint16 nextRound = stateCopy.currentRound + 1;

        // Transfer mgmt fees to admin
        SafeERC20.safeTransfer(paymentToken, owner(), mgmtFees);

        // Store round deposit amount
        roundSize[nextRound] = paymentHeld + pendingDeposits;
        // Store share balance
        shareBalancePerRound[nextRound] = mintedShares + shareSupply;

        // Clear pending deposits
        pendingDeposits = 0;

        // Start next round
        state.currentRound = nextRound;

        state.currentRoundEndDay = oracleDay + uint32(epochDuration);
        state.lastDayForSettlements = oracleDay + uint32(epochDuration) + SETTLEMENT_DAYS;

        //New round, SW are now open again
        withdrawalsOpen = true;

        emit StartNextRound(state.currentRound, state.currentRoundEndDay, mintedShares);
    }

    function terminate() external override onlyOwner nonReentrant {
        SVTypes.State memory stateCopy = state;

        // Require processWithdraws
        if (sharesWithdrawnPerRound[stateCopy.currentRound] != 0) {
            require(
                pTokenWithdrawnPerRound[stateCopy.currentRound] != 0 || rTokenWithdrawnPerRound[stateCopy.currentRound] != 0,
                "needs PW"
            );
        }

        require(getOracleDay() >= stateCopy.lastDayForSettlements, "not ready");

        require(stateCopy.numSilicasActive == 0, "all silicas must be settled");

        // Require swapping all remaining rTokens
        require(totalRewardHeld() == 0, "swap rewards");

        uint256 pTokenHeld = totalPaymentHeld();

        // Admin cannot terminate vault in less than 3 rounds unless vault has insufficient funds
        if (stateCopy.currentRound < 3) {
            require(pTokenHeld < MIN_DEPOSIT_THRESHOLD, "roundSize too large");
        }

        //Vault terminated, SW are now open again
        withdrawalsOpen = true;

        state.terminated = true;
    }

    /*////////////////////////////////////////////////////////
                    SILICA PURCHASE/SETTLE
    ////////////////////////////////////////////////////////*/

    /// @notice Admin calls this function purchase as of Vault
    /// @param silicaAddress address of Silica to purchase
    /// @param amount amount of payment token to exchange for Silica
    function purchaseSilica(address silicaAddress, uint256 amount) external override nonReentrant returns (uint256 silicaMinted) {
        require(address(msg.sender) == owner() || msg.sender == swapProxy, "Unauthorized caller");
        require(amount <= totalPaymentHeld(), "AvailableBalance to low");
        SilicaV2_1 silica = SilicaV2_1(silicaAddress);
        require(address(silica.rewardToken()) == address(rewardToken), "RewardTokens don't match");
        require(silica.getLastDueDay() <= state.currentRoundEndDay, "Silica ends after the current round");
        require(silica.getCommodityType() == getSilicaType(), "Wrong silica type");

        SafeERC20.safeApprove(paymentToken, address(silica), amount);

        if (silica.balanceOf(address(this)) == 0) {
            state.numSilicasActive += 1;
        }

        silicaMinted = silica.deposit(amount);

        emit PurchaseSilica(silicaAddress, amount, silicaMinted);
    }

    /// @notice Settle a Silica that has defaulted
    /// @param silicaAddress Address of Silica to settle
    function settleDefaultedSilica(
        address silicaAddress
    ) external override onlyOwner nonReentrant returns (uint256 rewardPayout, uint256 paymentPayout) {
        SilicaV2_1 silica = SilicaV2_1(silicaAddress);
        uint256 silicaBalance = silica.balanceOf(address(this));
        state.numSilicasActive -= 1;
        (rewardPayout, paymentPayout) = silica.buyerCollectPayoutOnDefault();

        emit SettleDefaultedSilica(silicaAddress, silicaBalance, rewardPayout, paymentPayout);
    }

    /// @notice Settle a Silica that has finished
    /// @param silicaAddress Address of Silica to settle.
    function settleFinishedSilica(address silicaAddress) external override onlyOwner nonReentrant returns (uint256 rewardPayout) {
        SilicaV2_1 silica = SilicaV2_1(silicaAddress);
        uint256 silicaBalance = silica.balanceOf(address(this));
        state.numSilicasActive -= 1;
        rewardPayout = silica.buyerCollectPayout();

        emit SettleFinishedSilica(silicaAddress, rewardPayout, silicaBalance);
    }

    /*////////////////////////////////////////////////////////
                          DEPOSIT
    ////////////////////////////////////////////////////////*/

    /// @notice Deposit `amount` in payment tokens to vault
    /// @param amount Amount in payment tokens to deposit
    function deposit(uint256 amount) external override nonReentrant {
        require(amount > 0 && amount * FEE_PERCENT > 1e18, "invalid amount");
        require(pendingDeposits + amount <= MAX_DEPOSIT_AMOUNT, "amount exceeds max deposit");
        require(!state.terminated, "vault is terminated");

        uint256 currentRound = state.currentRound;

        SVTypes.DepositorInfo storage depositorInfo = depositorInfos[msg.sender];

        // Charge management fee on each deposit
        uint256 fees = (amount * FEE_PERCENT) / 1e18;
        uint256 actualDepositAmount = amount - fees;

        if (currentRound == depositorInfo.prevDepositRound) {
            // Add deposit amount to existing value
            depositorInfo.prevDepositAmount += uint112(actualDepositAmount);
        } else {
            // Sync deposits from previous rounds
            syncUnredeemedShares(msg.sender, currentRound);
            // Then record new deposit
            depositorInfo.prevDepositRound = uint16(currentRound);
            depositorInfo.prevDepositAmount = uint112(actualDepositAmount);
        }

        pendingDeposits += amount;
        SafeERC20.safeTransferFrom(paymentToken, msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount);
    }

    function cancelDeposit() external override nonReentrant {
        SVTypes.DepositorInfo memory depositorInfo = depositorInfos[msg.sender];
        require(depositorInfo.prevDepositRound == state.currentRound, "invalid round");
        require(depositorInfo.prevDepositAmount > 0, "no deposit to cancel");

        uint256 originalDepositAmount = (depositorInfo.prevDepositAmount * 1e18) / (1e18 - FEE_PERCENT);
        SafeERC20.safeTransfer(paymentToken, msg.sender, originalDepositAmount);

        pendingDeposits -= originalDepositAmount;

        depositorInfos[msg.sender].prevDepositAmount = 0;
        depositorInfos[msg.sender].prevDepositRound = 0;

        emit CancelDeposit(msg.sender, depositorInfo.prevDepositAmount);
    }

    /*////////////////////////////////////////////////////////
                          REDEEM
    ////////////////////////////////////////////////////////*/

    ///@notice Redeem `numShares` shares
    ///@param shares Shares to redeem
    function redeem(uint256 shares) external override nonReentrant {
        require(shares > 0, "invalid");

        _redeem(shares, msg.sender);

        emit Redeem(msg.sender, shares);
    }

    function redeemMax() external nonReentrant {
        uint256 redeemedShares = _redeemMax(msg.sender);

        emit Redeem(msg.sender, redeemedShares);
    }

    ///@notice Redeem and transfer `shares` to shareOwner
    ///@param shares Shares to redeem
    ///@param depositor Address of depositor
    function _redeem(uint256 shares, address depositor) internal {
        uint256 currentRound = state.currentRound;

        // Process deposits from previous rounds (catch up deposit status)
        syncUnredeemedShares(depositor, currentRound);

        // Check that depositor has enough shares to redeem
        require(depositorInfos[depositor].unredeemedShares >= shares, "not enough shares");

        // Drain unredeemed shares
        depositorInfos[depositor].unredeemedShares -= uint128(shares);

        // Transfer vault tokens
        _transfer(address(this), depositor, shares);
    }

    function _redeemMax(address depositor) internal returns (uint256) {
        uint256 currentRound = state.currentRound;

        // Process deposits from previous rounds (catch up deposit status)
        syncUnredeemedShares(depositor, currentRound);

        uint256 sharesToRedeem = depositorInfos[depositor].unredeemedShares;

        // Drain unredeemed shares
        depositorInfos[depositor].unredeemedShares = 0;

        // Transfer svTokens
        _transfer(address(this), depositor, sharesToRedeem);

        return sharesToRedeem;
    }

    /*////////////////////////////////////////////////////////
                          WITHDRAW
    ////////////////////////////////////////////////////////*/

    /// @notice Schedules a withdrawal of `shares` svTokens that can be processed once the round completes
    /// @param shares Shares to withdraw
    function scheduleWithdraw(uint256 shares) external override nonReentrant returns (uint256) {
        require(withdrawalsOpen, "no SW after PW");
        require(shares > 0, "invalid");
        uint256 currentRound = state.currentRound;
        require(currentRound > 0, "cannot withdraw before first round starts");

        address depositor = msg.sender;

        // Transfers any unredeemed shares to depositor
        _redeemMax(depositor);

        uint256 availableShares = balanceOf(depositor);

        SVTypes.WithdrawalReceipt storage withdrawalReceipt = withdrawalReceipts[depositor];

        if (withdrawalReceipt.round == 0) {
            withdrawalReceipt.round = uint16(currentRound);
        }

        // Require withdraw requests from previous rounds to be processed
        if (withdrawalReceipt.round < currentRound) {
            revert("process withdraw first");
        }

        uint128 totalSharesRequestedForWithdraw = uint128(shares) + withdrawalReceipt.shares;
        // Verify that depositor have sufficient shares to withdraw (including shares requested earlier)
        require(availableShares >= totalSharesRequestedForWithdraw, "not enough shares");

        withdrawalReceipt.shares = totalSharesRequestedForWithdraw;

        // Add shares to pool of shares pending withdrawal
        sharesWithdrawnPerRound[currentRound] += shares;

        emit ScheduleWithdraw(depositor, shares, sharesPendingBurn, sharesWithdrawnPerRound[currentRound]);

        return totalSharesRequestedForWithdraw;
    }

    /// @notice Processes a scheduled withdrawal from a previous round. Redeem reward and payment tokens
    function redeemWithdrawRequest() external override nonReentrant returns (uint256 paymentPayout, uint256 rewardPayout) {
        SVTypes.WithdrawalReceipt storage withdrawalReceipt = withdrawalReceipts[msg.sender];

        uint256 sharesToWithdraw = withdrawalReceipt.shares;
        require(sharesToWithdraw > 0, "no shares to withdraw");

        uint256 withdrawalRound = withdrawalReceipt.round;
        require(withdrawalRound < state.currentRound || state.terminated == true, "withdraw not available");

        // Reset withdrawal receipt
        withdrawalReceipt.shares = 0;
        withdrawalReceipt.round = 0;

        // Remove processed shares from shares pending burn
        sharesPendingBurn -= sharesToWithdraw;
        // Then burn shares
        _burn(address(msg.sender), sharesToWithdraw);

        // Use historic data to calculate depositor payout
        paymentPayout = ShareMath.convertToAsset(
            sharesToWithdraw,
            pTokenWithdrawnPerRound[withdrawalRound],
            shareBalancePerRound[withdrawalRound]
        );
        rewardPayout = ShareMath.convertToAsset(
            sharesToWithdraw,
            rTokenWithdrawnPerRound[withdrawalRound],
            shareBalancePerRound[withdrawalRound]
        );

        // Remove payouts from vault debt
        pTokenLocked -= paymentPayout;
        rTokenLocked -= rewardPayout;

        SafeERC20.safeTransfer(paymentToken, msg.sender, paymentPayout);
        SafeERC20.safeTransfer(rewardToken, msg.sender, rewardPayout);

        emit RedeemWithdrawRequest(msg.sender, sharesToWithdraw, paymentPayout, rewardPayout);
    }

    function previewProcessScheduledWithdraw() external view override returns (uint256 pTokenPayout, uint256 rTokenPayout) {
        SVTypes.WithdrawalReceipt memory withdrawalReceipt = withdrawalReceipts[msg.sender];

        pTokenPayout = ShareMath.convertToAsset(
            withdrawalReceipt.shares,
            pTokenWithdrawnPerRound[withdrawalReceipt.round],
            shareBalancePerRound[withdrawalReceipt.round]
        );

        rTokenPayout = ShareMath.convertToAsset(
            withdrawalReceipt.shares,
            rTokenWithdrawnPerRound[withdrawalReceipt.round],
            shareBalancePerRound[withdrawalReceipt.round]
        );
    }

    /*////////////////////////////////////////////////////////
                      Vault Assets
    ////////////////////////////////////////////////////////*/

    /// @notice Returns payment tokens held by the vault
    /// @dev Excludes outstanding debt in payment tokens and pending payment deposits
    function totalPaymentHeld() public view returns (uint256) {
        return paymentToken.balanceOf(address(this)) - pTokenLocked - pendingDeposits;
    }

    /// @notice Returns reward tokens held by the vault
    /// @dev Excludes outstanding debt in reward tokens
    function totalRewardHeld() public view returns (uint256) {
        return rewardToken.balanceOf(address(this)) - rTokenLocked;
    }

    /// @notice Return shares active in
    /// @dev Returns outstanding shares subtracted by shares pending burn
    function totalShares() internal view returns (uint256) {
        return totalSupply() - sharesPendingBurn; //@TODO: RENAME TO PENDING BURN
    }

    function getOracleDay() internal view returns (uint32) {
        Oracle oracle = Oracle(oracleRegistry.getOracleAddress(address(rewardToken), getSilicaType()));
        return oracle.getLastIndexedDay();
    }

    /// @notice Syncs unredeemed shares. Pre-requisite for scheduleWithdraw/redeem/deposit
    // Sync unredeemedShares from previous round deposits.
    // 1) case 1: No previous deposits: no-op.
    // 2) case 2: Most recent deposit is from this round. No op.
    // 3) case 3: Most receent deposit is from previous round. Calculate shares and add to unredeemedShares
    function syncUnredeemedShares(address depositor, uint256 currentRound) internal returns (uint256 sharesFromRound) {
        (, sharesFromRound) = _previewSyncShares(depositor, currentRound);
        if (sharesFromRound > 0) {
            depositorInfos[depositor].unredeemedShares += uint128(sharesFromRound);
            depositorInfos[depositor].prevDepositAmount = 0;
            depositorInfos[depositor].prevDepositRound = 0;
        }
    }

    function _previewSyncShares(
        address depositor,
        uint256 currentRound
    ) internal view returns (uint256 unredeemedShares, uint256 newlySyncedShares) {
        SVTypes.DepositorInfo memory depositorInfo = depositorInfos[depositor];
        if (depositorInfo.prevDepositAmount != 0) {
            // Process deposits from earlier rounds
            if (depositorInfo.prevDepositRound < currentRound) {
                newlySyncedShares = ShareMath.convertToShares(
                    depositorInfo.prevDepositAmount,
                    // Calculate shares using payment/share balance from the round after the last deposit
                    roundSize[depositorInfo.prevDepositRound + 1],
                    shareBalancePerRound[depositorInfo.prevDepositRound + 1]
                );
                unredeemedShares = depositorInfo.unredeemedShares + uint128(newlySyncedShares);
            } else {
                unredeemedShares = depositorInfo.unredeemedShares;
            }
        } else {
            unredeemedShares = depositorInfo.unredeemedShares;
        }
    }

    function previewSyncShares(address depositor) external view returns (uint256 unredeemedShares, uint256 newlySyncedShares) {
        (unredeemedShares, newlySyncedShares) = _previewSyncShares(depositor, state.currentRound);
    }

    function getAdmin() external view override returns (address) {
        return owner();
    }

    function getRewardToken() external view override returns (address) {
        return address(rewardToken);
    }

    function getPaymentToken() external view override returns (address) {
        return address(paymentToken);
    }

    function getSilicaType() public view virtual returns (uint16) {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.6;

import {IContractTrader} from "./interfaces/IContractTrader.sol";
import "./AbstractSilicaVault.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/// @title SilicaVault
contract SilicaVault is AbstractSilicaVault {
    constructor(
        address _paymentToken,
        address _rewardToken,
        address _oracleRegistry,
        address _swapProxy,
        address _swapRouter //@TODO: REMOVE router
    ) ERC20("SilicaVault", "SV") {
        paymentToken = ERC20(_paymentToken);
        rewardToken = ERC20(_rewardToken);
        oracleRegistry = IOracleRegistry(_oracleRegistry);
        swapProxy = _swapProxy;
        swapRouter = _swapRouter;
        state.currentRoundEndDay = getOracleDay();
    }

    function getSilicaType() public view override returns (uint16) {
        return 0;
    }
}

pragma solidity >=0.8.6;

import {SVTypes} from "../libraries/SilicaVaultTypes.sol";
import {SVStorage} from "../storage/SilicaVaultStorage.sol";

/**
 * @title SVGetters
 * @author Alkimiya
 *
 * @notice Read-only getters for HV Contracts
 */

contract SVGetters is SVStorage {
    // STATE
    function getCurrentRound() external view returns (uint16) {
        return state.currentRound;
    }

    function getCurrentRoundEndDay() external view returns (uint32) {
        return state.currentRoundEndDay;
    }

    function getSharesPendingBurn() external view returns (uint256) {
        return sharesPendingBurn;
    }

    function getPTokenLocked() external view returns (uint256) {
        return pTokenLocked;
    }

    function getRTokenLocked() external view returns (uint256) {
        return rTokenLocked;
    }

    function getPendingDeposits() external view returns (uint256) {
        return pendingDeposits;
    }

    function getNumSilicasActive() external view returns (uint16) {
        return state.numSilicasActive;
    }

    function getLastDayForSettlements() external view returns (uint32) {
        return state.lastDayForSettlements;
    }

    function isTerminated() external view returns (bool) {
        return state.terminated;
    }

    function getWithdrawalsOpen() external view returns (bool) {
        return withdrawalsOpen;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.6;

interface IContractTrader {
    function trade(
        address client,
        address rToken,
        address pToken,
        uint256 rewardAmount,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.6;

/// @title interface design for SilicaVault
interface ISilicaVault {
    /*///////////////////////////////////////////////////////////////
                                 Events
    //////////////////////////////////////////////////////////////*/

    event ProcessWithdraws(uint256 paymentLockup, uint256 rewardLockup);
    event Swap(uint256 amountOfRewardTokenSwaped, uint256 amountOfPaymentTokenReceived);
    event StartNextRound(uint256 currentRound, uint256 currentRoundEndDay, uint256 mintedShares);
    event PurchaseSilica(address silicaAddress, uint256 amount, uint256 silicaMinted);
    event SettleDefaultedSilica(address silicaAddress, uint256 silicaAmount, uint256 rewardPayout, uint256 paymentPayout);
    event SettleFinishedSilica(address silicaAddress, uint256 rewardPayout, uint256 silicaAmount);
    event Deposit(address depositor, uint256 amount);
    event CancelDeposit(address depositor, uint256 amount);
    event Redeem(address redeemer, uint256 shares);
    event ScheduleWithdraw(
        address withdrawer,
        uint256 scheduledToWithdraw,
        uint256 totalPendingWithdrawShares,
        uint256 pendingWithdrawSharesThisRound
    );
    event RedeemWithdrawRequest(address withdrawer, uint256 sharesToWithdraw, uint256 paymentPayout, uint256 rewardPayout);

    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal 
    ////////////////////////////////////////////////////////*/
    /// @notice Mints `shares` Vault shares to msg.sender by depositing exactly `amount` in payment
    function deposit(uint256 amount) external;

    function cancelDeposit() external;

    /// @notice Schedules a withdrawal of `shares` Vault shares that can be processed once the round completes
    function scheduleWithdraw(uint256 shares) external returns (uint256);

    /// @notice Processes a scheduled withdrawal from a previous round. Uses finalized pps for the round
    function redeemWithdrawRequest() external returns (uint256 rewardPayout, uint256 paymentPayout);

    function previewProcessScheduledWithdraw() external view returns (uint256 pTokenPayout, uint256 rTokenPayout);

    /// @notice
    function redeem(uint256 numShares) external;

    function terminate() external;

    /*////////////////////////////////////////////////////////
                      Admin
    ////////////////////////////////////////////////////////*/

    function processWithdraws() external returns (uint256 paymentLockup, uint256 rewardLockup);

    function swap(
        address contractTrader,
        uint256 rewardAmount,
        bytes calldata data
    ) external returns (uint256 rewardTraded, uint256 paymentTraded);

    function startNextRound(uint256 epochDuration) external returns (uint256 mintedShares);

    /*////////////////////////////////////////////////////////
                          Strategy
    ////////////////////////////////////////////////////////*/

    function settleDefaultedSilica(address silicaAddress) external returns (uint256 rewardPayout, uint256 paymentPayout);

    function settleFinishedSilica(address silicaAddress) external returns (uint256 rewardPayout);

    function purchaseSilica(address silicaAddress, uint256 amount) external returns (uint256 silicaMinted);

    function getAdmin() external view returns (address);

    function getRewardToken() external view returns (address);

    function getPaymentToken() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.6;

import "../../lib/solmate/src/utils/FixedPointMathLib.sol";

/// @title Methods for math
library ShareMath {
    function convertToShares(uint256 amount, uint256 tokenBalance, uint256 shareBalance) internal pure returns (uint256) {
        if (shareBalance == 0) return amount;
        return FixedPointMathLib.mulDivUp(amount, shareBalance, tokenBalance);
    }

    /// @notice
    function convertToAsset(uint256 shares, uint256 assets, uint256 shareSupply) internal pure returns (uint256) {
        return FixedPointMathLib.mulDivDown(shares, assets, shareSupply);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.6;

/// @title Types used throughout SilicaVault
library SVTypes {
    struct DepositorInfo {
        uint16 prevDepositRound;
        uint112 prevDepositAmount;
        uint128 unredeemedShares;
    }

    struct WithdrawalReceipt {
        uint16 round;
        uint128 shares;
    }

    struct State {
        uint16 currentRound;
        uint16 numSilicasActive;
        uint32 currentRoundEndDay;
        uint32 lastDayForSettlements;
        bool terminated;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.6;

import {SVTypes} from "../libraries/SilicaVaultTypes.sol";
import "@alkimiya/v2.1-core/contracts/interfaces/oracle/IOracleRegistry.sol";
import "../interfaces/ISilicaVault.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title SilicaVault storage layout
abstract contract SVStorage {
    SVTypes.State public state;

    mapping(address => SVTypes.DepositorInfo) public depositorInfos;
    mapping(address => SVTypes.WithdrawalReceipt) public withdrawalReceipts;

    mapping(uint256 => uint256) public sharesWithdrawnPerRound;

    mapping(uint256 => uint256) public roundSize;
    mapping(uint256 => uint256) public shareBalancePerRound;

    mapping(uint256 => uint256) public pTokenWithdrawnPerRound;
    mapping(uint256 => uint256) public rTokenWithdrawnPerRound;

    IOracleRegistry public oracleRegistry;
    ERC20 public paymentToken;
    ERC20 public rewardToken;
    address public swapProxy;
    address public swapRouter;

    uint256 sharesPendingBurn; //move these out
    uint256 pTokenLocked;
    uint256 rTokenLocked;
    uint256 pendingDeposits;
    bool withdrawalsOpen;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ISilicaV2_1} from "./interfaces/silica/ISilicaV2_1.sol";
import {SilicaV2_1Storage} from "./storage/SilicaV2_1Storage.sol";
import {SilicaV2_1Types} from "./libraries/SilicaV2_1Types.sol";

import "./libraries/math/PayoutMath.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract AbstractSilicaV2_1 is ERC20, Initializable, ISilicaV2_1, SilicaV2_1Storage {
    /*///////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of days between deploymentDay and firstDueDay
    uint8 internal constant DAYS_BETWEEN_DD_AND_FDD = 2;

    /*///////////////////////////////////////////////////////////////
                                 Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyBuyers() {
        require(balanceOf(msg.sender) != 0, "Not Buyer");
        _;
    }

    modifier onlyOpen() {
        require(isOpen(), "Not Open");
        _;
    }

    modifier onlyExpired() {
        require(isExpired(), "Not Expired");
        _;
    }

    modifier onlyDefaulted() {
        if (defaultDay == 0) {
            tryDefaultContract();
        }
        _;
    }

    modifier onlyFinished() {
        if (finishDay == 0) {
            tryFinishContract();
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyOnePayout() {
        require(!didSellerCollectPayout, "Payout already collected");
        didSellerCollectPayout = true;
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                 Initializer
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize a new SilicaV2_1
    function initialize(InitializeData calldata initializeData) external override initializer {
        _initializeAddresses(
            initializeData.rewardTokenAddress,
            initializeData.paymentTokenAddress,
            initializeData.oracleRegistry,
            initializeData.sellerAddress
        );
        _initializeSilicaState(initializeData.dayOfDeployment, initializeData.lastDueDay);

        resourceAmount = initializeData.resourceAmount;

        reservedPrice = calculateReservedPrice(
            initializeData.unitPrice,
            initializeData.lastDueDay - initializeData.dayOfDeployment - 1,
            decimals(),
            initializeData.resourceAmount
        );
        require(reservedPrice > 0, "reservedPrice = 0");

        initialCollateral = initializeData.collateralAmount;
    }

    /// @notice Set the reward token address, payment token address, oracle Registery address and
    ///         seller address in this Silica
    /// @notice Owner of this silica is the seller
    function _initializeAddresses(
        address rewardTokenAddress,
        address paymentTokenAddress,
        address oracleRegistryAddress,
        address sellerAddress
    ) internal {
        require(
            rewardTokenAddress != address(0) &&
                paymentTokenAddress != address(0) &&
                oracleRegistryAddress != address(0) &&
                sellerAddress != address(0),
            "Invalid Address"
        );

        rewardToken = rewardTokenAddress;
        paymentToken = paymentTokenAddress;
        oracleRegistry = oracleRegistryAddress;
        owner = sellerAddress;
    }

    /// @notice Set last due day and first due day of the Silica contract when contract starts
    /// @dev last due day should always be after first due day
    function _initializeSilicaState(uint256 dayOfDeployment, uint256 _lastDueDay) internal {
        require(_lastDueDay >= dayOfDeployment + DAYS_BETWEEN_DD_AND_FDD, "Invalid lastDueDay");

        lastDueDay = uint32(_lastDueDay);
        firstDueDay = uint32(dayOfDeployment + DAYS_BETWEEN_DD_AND_FDD);
    }

    /// @notice Calculate the Reserved Price of the silica
    function calculateReservedPrice(
        uint256 unitPrice,
        uint256 numDeposits,
        uint256 _decimals,
        uint256 _resourceAmount
    ) internal pure returns (uint256) {
        return (unitPrice * _resourceAmount * numDeposits) / (10**_decimals);
    }

    /*///////////////////////////////////////////////////////////////
                                 Contract states
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the status of the contract
    function getStatus() public view override returns (SilicaV2_1Types.Status) {
        if (isOpen()) {
            return SilicaV2_1Types.Status.Open;
        } else if (isExpired()) {
            return SilicaV2_1Types.Status.Expired;
        } else if (isRunning()) {
            return SilicaV2_1Types.Status.Running;
        } else if (finishDay > 0 || isFinished()) {
            return SilicaV2_1Types.Status.Finished;
        } else if (defaultDay > 0 || isDefaulted()) {
            return SilicaV2_1Types.Status.Defaulted;
        }
    }

    /// @notice Check if contract is in open state
    function isOpen() public view override returns (bool) {
        return (getLastIndexedDay() == firstDueDay - DAYS_BETWEEN_DD_AND_FDD);
    }

    /// @notice Check if contract is in expired state
    function isExpired() public view override returns (bool) {
        return (defaultDay == 0 && finishDay == 0 && totalSupply() == 0 && getLastIndexedDay() >= firstDueDay - 1);
    }

    /// @notice Check if contract is in defaulted state
    function isDefaulted() public view override returns (bool) {
        return (getDayOfDefault() > 0);
    }

    /// @notice Returns the day of default. If X is returned, then the contract has paid X - firstDueDay payments.
    function getDayOfDefault() public view override returns (uint256) {
        if (defaultDay > 0) return defaultDay;

        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, getLastIndexedDay());
        uint256 numDaysRequired = lastDayContractOwesReward < firstDueDayMem ? 0 : lastDayContractOwesReward + 1 - firstDueDayMem;

        // Contract hasn't progressed enough to default
        if (numDaysRequired == 0) return 0;

        (uint256 numDays, ) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        // The rewardBalance is insufficient to cover numDaysRequired, hence defaulted
        if (numDays < numDaysRequired) {
            return firstDueDayMem + numDays;
        } else {
            return 0;
        }
    }

    /// @notice Function to set a contract as default
    ///         If the contract is not defaulted, revert
    function tryDefaultContract() internal {
        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, getLastIndexedDay());
        uint256 numDaysRequired = lastDayContractOwesReward < firstDueDayMem ? 0 : lastDayContractOwesReward + 1 - firstDueDayMem;

        // Contract hasn't progressed enough to default
        require(numDaysRequired > 0, "Not Defaulted");

        (uint256 numDays, uint256 totalRewardDelivered) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        // The rewardBalance is insufficient to cover numDaysRequired, hence defaulted
        if (numDays < numDaysRequired) {
            uint256 dayOfDefaultMem = firstDueDayMem + numDays;
            defaultContract(dayOfDefaultMem, IERC20(rewardToken).balanceOf(address(this)), totalRewardDelivered);
        } else {
            revert("Not Defaulted");
        }
    }

    /// @notice Snapshots variables necessary to perform default settlements.
    /// @dev This tx should only happen once in the Silica's lifetime.
    function defaultContract(
        uint256 _dayOfDefault,
        uint256 silicaRewardBalance,
        uint256 _totalRewardDelivered
    ) internal {
        if (silicaRewardBalance > _totalRewardDelivered) {
            rewardExcess = silicaRewardBalance - _totalRewardDelivered;
        }
        defaultDay = uint32(_dayOfDefault);
        rewardDelivered = _totalRewardDelivered;
        resourceAmount = totalSupply();
        totalUpfrontPayment = IERC20(paymentToken).balanceOf(address(this));

        emit StatusChanged(SilicaV2_1Types.Status.Defaulted);
    }

    /// @notice Check if the contract is in running state
    function isRunning() public view override returns (bool) {
        if (!isOpen() && !isExpired() && defaultDay == 0 && finishDay == 0) {
            uint256 firstDueDayMem = firstDueDay;
            uint256 lastDueDayMem = lastDueDay;
            uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, getLastIndexedDay());

            if (lastDayContractOwesReward < firstDueDayMem) return true;

            (uint256 numDays, ) = getDaysAndRewardFulfilled(
                IERC20(rewardToken).balanceOf(address(this)),
                firstDueDayMem,
                lastDayContractOwesReward
            );

            uint256 contractDurationDays = lastDayContractOwesReward + 1 - firstDueDayMem;
            uint256 maxContractDurationDays = lastDueDayMem + 1 - firstDueDayMem;

            // For contracts that progressed GE firstDueDay
            // Contract is running if it's progressed as far as it can, but not finished
            return numDays == contractDurationDays && numDays != maxContractDurationDays;
        } else {
            return false;
        }
    }

    /// @notice Check if contract is in finished state
    function isFinished() public view override returns (bool) {
        if (finishDay != 0) return true;

        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, getLastIndexedDay());

        (uint256 numDays, ) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        if (numDays == lastDueDayMem + 1 - firstDueDayMem) {
            return true;
        }
        return false;
    }

    /// @notice Function to set a contract status as Finished
    /// @dev If the contract hasn't finished, revert
    function tryFinishContract() internal {
        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, getLastIndexedDay());

        (uint256 numDays, uint256 totalRewardDelivered) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        if (numDays == lastDueDayMem + 1 - firstDueDayMem) {
            // Set finishDay to non-zero value. Subsequent calls to onlyFinished functions should skip this function all together
            finishContract(lastDueDayMem, IERC20(rewardToken).balanceOf(address(this)), totalRewardDelivered);
        } else {
            revert("Not Finished");
        }
    }

    /// @notice Snapshots variables necessary to perform settlements.
    /// @dev This tx should only happen once in the Silica's lifetime.
    function finishContract(
        uint256 _finishDay,
        uint256 silicaRewardBalance,
        uint256 _totalRewardDelivered
    ) internal {
        if (silicaRewardBalance > _totalRewardDelivered) {
            rewardExcess = silicaRewardBalance - _totalRewardDelivered;
        }

        finishDay = uint32(_finishDay);
        rewardDelivered = _totalRewardDelivered;
        resourceAmount = totalSupply();

        emit StatusChanged(SilicaV2_1Types.Status.Finished);
    }

    function getDaysAndRewardFulfilled() external view returns (uint256 lastDayFulfilled, uint256 rewardDelivered) {
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastIndexedDayMem = getLastIndexedDay();
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, lastIndexedDayMem);

        uint256 rewardFulfilled = rewardDelivered == 0 ? IERC20(rewardToken).balanceOf(address(this)) : rewardDelivered;
        return getDaysAndRewardFulfilled(rewardFulfilled, firstDueDay, lastDayContractOwesReward);
    }

    /// @notice Returns the number of days N fulfilled by this contract, as well as the reward delivered for all N days
    function getDaysAndRewardFulfilled(
        uint256 _rewardBalance,
        uint256 _firstDueDay,
        uint256 _lastDayContractOwesReward
    ) internal view returns (uint256 lastDayFulfilled, uint256 rewardDelivered) {
        if (_lastDayContractOwesReward < _firstDueDay) {
            return (0, 0); //@ATTN: include collateral
        }

        uint256 totalDue;

        uint256[] memory rewardDueArray = getRewardDueInRange(_firstDueDay, _lastDayContractOwesReward);
        for (uint256 i = 0; i < rewardDueArray.length; i++) {
            uint256 curDay = _firstDueDay + i;

            if (_rewardBalance < totalDue + rewardDueArray[i] + getCollateralLocked(curDay)) {
                return (i, totalDue + getCollateralLocked(curDay));
            }
            totalDue += rewardDueArray[i];
        }

        // Otherwise, contract delivered up to last day that it owes reward
        return (rewardDueArray.length, totalDue + getCollateralLocked(_lastDayContractOwesReward));
    }

    /*///////////////////////////////////////////////////////////////
                            Contract settlement and updates
    //////////////////////////////////////////////////////////////*/

    /// @notice Function returns the accumulative rewards delivered
    function getRewardDeliveredSoFar() external view override returns (uint256) {
        if (rewardDelivered == 0) {
            (, uint256 totalRewardDelivered) = getDaysAndRewardFulfilled(
                IERC20(rewardToken).balanceOf(address(this)),
                firstDueDay,
                getLastDayContractOwesReward(lastDueDay, getLastIndexedDay())
            );
            return totalRewardDelivered;
        } else {
            return rewardDelivered;
        }
    }

    /// @notice Function returns the last day contract needs to deliver rewards
    function getLastDayContractOwesReward(uint256 _lastDueDay, uint256 lastIndexedDay) public pure override returns (uint256) {
        // Silica always owes up to DayX-1 in rewards
        return lastIndexedDay - 1 <= _lastDueDay ? lastIndexedDay - 1 : _lastDueDay;
    }

    /// @notice Function returns the Collateral Locked on the day inputed
    function getCollateralLocked(uint256 day) internal view returns (uint256) {
        uint256 firstDueDayMem = firstDueDay;
        uint256 initialCollateralAfterRelease = getInitialCollateralAfterRelease();
        if (day <= firstDueDayMem) {
            return initialCollateralAfterRelease;
        }

        (uint256 initCollateralReleaseDay, uint256 finalCollateralReleaseDay) = getCollateralUnlockDays(firstDueDayMem);

        if (day >= finalCollateralReleaseDay) {
            return (0);
        }
        if (day >= initCollateralReleaseDay) {
            return ((initialCollateralAfterRelease * 3) / 4);
        }
        return (initialCollateralAfterRelease);
    }

    /// @notice Function that calculate the collateral based on purchased amount after contract starts
    function getInitialCollateralAfterRelease() internal view returns (uint256) {
        return ((totalSupply() * initialCollateral) / resourceAmount);
    }

    /// @notice Function that calculates the dates collateral gets partial release
    function getCollateralUnlockDays(uint256 _firstDueDay)
        internal
        view
        returns (uint256 initCollateralReleaseDay, uint256 finalCollateralReleaseDay)
    {
        uint256 numDeposits = lastDueDay + 1 - _firstDueDay;

        initCollateralReleaseDay = numDeposits % 4 > 0 ? _firstDueDay + 1 + (numDeposits / 4) : _firstDueDay + (numDeposits / 4);
        finalCollateralReleaseDay = numDeposits % 2 > 0 ? _firstDueDay + 1 + (numDeposits / 2) : _firstDueDay + (numDeposits / 2);

        if (numDeposits == 2) {
            finalCollateralReleaseDay += 1;
        }
    }

    /// @notice Function returns the rewards amount the seller needs deliver for next Oracle update
    function getRewardDueNextOracleUpdate() external view override returns (uint256 rewardDueNextOracleUpdate) {
        uint256 nextIndexedDay = getLastIndexedDay() + 1;
        uint256 firstDueDayMem = firstDueDay;
        if (nextIndexedDay < firstDueDayMem) {
            return (0);
        }
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, nextIndexedDay);
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        uint256[] memory rewardDueArray = getRewardDueInRange(firstDueDayMem, lastDayContractOwesReward);
        uint256 totalDue;
        uint256 balanceNeeded;

        for (uint256 i = 0; i < rewardDueArray.length; i++) {
            uint256 curDay = firstDueDayMem + i;
            totalDue += rewardDueArray[i];

            if (balanceNeeded < totalDue + getCollateralLocked(curDay)) {
                balanceNeeded = totalDue + getCollateralLocked(curDay);
            }
        }

        if (balanceNeeded <= rewardBalance) {
            return 0;
        } else {
            return (balanceNeeded - rewardBalance);
        }
    }

    /**
     * @notice Processes a buyer's upfront payment to purchase hashpower/staking using paymentTokens.
     * Silica is minted proportional to purchaseAmount and transfered to buyer.
     * @dev confirms the buyer's payment, mint the Silicas and transfer the tokens.
     */
    function deposit(uint256 amountSpecified) external override onlyOpen returns (uint256 mintAmount) {
        require(amountSpecified > 0, "Invalid Value");

        mintAmount = _deposit(msg.sender, msg.sender, totalSupply(), amountSpecified);
        _mint(msg.sender, mintAmount);
    }

    /**
     * @notice Processes a buyer's upfront payment to purchase hashpower/staking using paymentTokens.
     * Silica is minted proportional to purchaseAmount and transfered to the address specified _to.
     * @dev confirms the buyer's payment, mint the Silicas and transfer the tokens.
     */
    function proxyDeposit(address _to, uint256 amountSpecified) external override onlyOpen returns (uint256 mintAmount) {
        require(_to != address(0), "Invalid Address");
        require(amountSpecified > 0, "Invalid Value");

        mintAmount = _deposit(msg.sender, _to, totalSupply(), amountSpecified);
        _mint(_to, mintAmount);
    }

    /// @notice Internal function to process buyer's deposit
    function _deposit(
        address from,
        address to,
        uint256 _totalSupply,
        uint256 amountSpecified
    ) internal returns (uint256 mintAmount) {
        mintAmount = getMintAmount(resourceAmount, amountSpecified, reservedPrice);

        require(_totalSupply + mintAmount <= resourceAmount, "Insufficient Supply");

        emit Deposit(to, amountSpecified, mintAmount);

        _transferPaymentTokenFrom(from, address(this), amountSpecified);
    }

    /// @notice Function that returns the minted Silica amount from purchase amount
    function getMintAmount(
        uint256 consensusResource,
        uint256 purchaseAmount,
        uint256 _reservedPrice
    ) internal pure returns (uint256) {
        return (consensusResource * purchaseAmount) / _reservedPrice;
    }

    /// @notice Internal function to safely transfer payment token
    function _transferPaymentTokenFrom(
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(paymentToken), from, to, amount);
    }

    /// @notice Function that buyer calls to collect reward when silica is finished
    function buyerCollectPayout() external override onlyFinished onlyBuyers returns (uint256 rewardPayout) {
        uint256 buyerBalance = balanceOf(msg.sender);

        _burn(msg.sender, buyerBalance);

        return _transferBuyerPayoutOnFinish(msg.sender, buyerBalance);
    }

    /// @notice Internal function to process rewards to Buyer when contract is Finished
    function _transferBuyerPayoutOnFinish(address buyerAddress, uint256 buyerBalance) internal returns (uint256 rewardPayout) {
        rewardPayout = PayoutMath.getBuyerRewardPayout(rewardDelivered, buyerBalance, resourceAmount);

        emit BuyerCollectPayout(rewardPayout, 0, buyerAddress, buyerBalance);

        _transferRewardToken(buyerAddress, rewardPayout);
    }

    /// @notice Internal function to safely transfer rewards to Buyer
    function _transferRewardToken(address to, uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(rewardToken), to, amount);
    }

    /// @notice Function that buyer calls to settle defaulted contract
    function buyerCollectPayoutOnDefault()
        external
        override
        onlyDefaulted
        onlyBuyers
        returns (uint256 rewardPayout, uint256 paymentPayout)
    {
        uint256 buyerBalance = balanceOf(msg.sender);

        _burn(msg.sender, buyerBalance);

        return _transferBuyerPayoutOnDefault(msg.sender, buyerBalance);
    }

    /// @notice Internal funtion to process rewards and payment return to Buyer when contract is default
    function _transferBuyerPayoutOnDefault(address buyerAddress, uint256 buyerBalance)
        internal
        returns (uint256 rewardPayout, uint256 paymentPayout)
    {
        rewardPayout = PayoutMath.getRewardTokenPayoutToBuyerOnDefault(buyerBalance, rewardDelivered, resourceAmount); //rewardDelivered in the case of a default represents the rewardTokenBalance of the contract at default

        uint256 firstDueDayMem = firstDueDay;
        uint256 numOfDepositsRequired = lastDueDay + 1 - firstDueDayMem;

        paymentPayout = PayoutMath.getPaymentTokenPayoutToBuyerOnDefault(
            buyerBalance,
            totalUpfrontPayment,
            resourceAmount,
            PayoutMath.getHaircut(defaultDay - firstDueDayMem, numOfDepositsRequired)
        );

        emit BuyerCollectPayout(rewardPayout, paymentPayout, buyerAddress, buyerBalance);

        _transferRewardToken(buyerAddress, rewardPayout);

        if (paymentPayout > 0) {
            _transferPaymentToken(buyerAddress, paymentPayout);
        }
    }

    /// @notice Internal funtion to safely transfer payment return to Buyer
    function _transferPaymentToken(address to, uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(paymentToken), to, amount);
    }

    /// @notice Gets the owner of silica
    function getOwner() external view override returns (address) {
        return owner;
    }

    /// @notice Gets reward type
    function getRewardToken() external view override returns (address) {
        return address(rewardToken);
    }

    /// @notice Gets the Payment type
    function getPaymentToken() external view override returns (address) {
        return address(paymentToken);
    }

    /// @notice Returns the last day of reward the seller is selling with this contract
    /// @return The last day of reward the seller is selling with this contract
    function getLastDueDay() external view override returns (uint32) {
        return lastDueDay;
    }

    /// @notice Function seller calls to settle finished silica
    function sellerCollectPayout()
        external
        override
        onlyOwner
        onlyFinished
        onlyOnePayout
        returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess)
    {
        paymentTokenPayout = IERC20(paymentToken).balanceOf(address(this));
        rewardTokenExcess = rewardExcess;

        emit SellerCollectPayout(paymentTokenPayout, rewardTokenExcess);
        _transferPaymentToSeller(paymentTokenPayout);
        if (rewardTokenExcess > 0) {
            _transferRewardToSeller(rewardTokenExcess);
        }
    }

    /// @notice Function seller calls to settle default contract
    function sellerCollectPayoutDefault()
        external
        override
        onlyOwner
        onlyDefaulted
        onlyOnePayout
        returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess)
    {
        uint256 firstDueDayMem = firstDueDay;
        uint256 numOfDepositsRequired = lastDueDay + 1 - firstDueDayMem;
        uint256 haircut = PayoutMath.getHaircut(defaultDay - firstDueDayMem, numOfDepositsRequired);
        paymentTokenPayout = PayoutMath.getRewardPayoutToSellerOnDefault(totalUpfrontPayment, haircut);
        rewardTokenExcess = rewardExcess;

        emit SellerCollectPayout(paymentTokenPayout, rewardTokenExcess);
        _transferPaymentToSeller(paymentTokenPayout);
        if (rewardTokenExcess > 0) {
            _transferRewardToSeller(rewardTokenExcess);
        }
    }

    /// @notice Function seller calls to settle when contract is
    function sellerCollectPayoutExpired() external override onlyExpired onlyOwner returns (uint256 rewardTokenPayout) {
        rewardTokenPayout = IERC20(rewardToken).balanceOf(address(this));

        _transferRewardToSeller(rewardTokenPayout);
        emit SellerCollectPayout(0, rewardTokenPayout);
    }

    /// @notice Internal funtion to safely transfer payment to Seller
    function _transferPaymentToSeller(uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(paymentToken), owner, amount);
    }

    /// @notice Internal funtion to safely transfer excess reward to Seller
    function _transferRewardToSeller(uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(rewardToken), owner, amount);
    }

    /// @notice Function to return the reward due on a given day
    function getRewardDueOnDay(uint256 _day) internal view virtual returns (uint256);

    /// @notice Function to return the last day silica is synced with Oracle
    function getLastIndexedDay() internal view virtual returns (uint32);

    /// @notice Function to return total rewards due between _firstday (inclusive) and _lastday (inclusive)
    function getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view virtual returns (uint256[] memory);

    /// @notice Function to return contract reserved price
    function getReservedPrice() external view override returns (uint256) {
        return reservedPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/oracle/IOracle.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Alkimiya Oracle
 * @author Alkimiya Team
 */
contract Oracle is AccessControl, IOracle {
    // Constants
    int8 public constant VERSION = 1;
    uint32 public lastIndexedDay;

    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");
    bytes32 public constant CALCULATOR_ROLE = keccak256("CALCULATOR_ROLE");

    mapping(uint256 => AlkimiyaIndex) private index;

    string public name;

    struct AlkimiyaIndex {
        uint32 referenceBlock;
        uint32 timestamp;
        uint128 hashrate;
        uint64 difficulty;
        uint256 reward;
        uint256 fees;
    }

    constructor(string memory _name) {
        _setupRole(PUBLISHER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        name = _name;
    }

    /// @notice Function to update Oracle Index
    function updateIndex(
        uint256 _referenceDay,
        uint256 _referenceBlock,
        uint256 _hashrate,
        uint256 _reward,
        uint256 _fees,
        uint256 _difficulty,
        bytes memory signature
    ) public override returns (bool) {
        require(_hashrate <= type(uint128).max, "Hashrate cannot exceed max val");
        require(_difficulty <= type(uint64).max, "Difficulty cannot exceed max val");
        require(_referenceBlock <= type(uint32).max, "Reference block cannot exceed max val");

        require(hasRole(PUBLISHER_ROLE, msg.sender), "Update not allowed to everyone");

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(_referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty))
            )
        );

        require(hasRole(CALCULATOR_ROLE, ECDSA.recover(messageHash, signature)), "Invalid signature");

        require(index[_referenceDay].timestamp == 0, "Information cannot be updated.");

        index[_referenceDay].timestamp = uint32(block.timestamp);
        index[_referenceDay].difficulty = uint64(_difficulty);
        index[_referenceDay].referenceBlock = uint32(_referenceBlock);
        index[_referenceDay].hashrate = uint128(_hashrate);
        index[_referenceDay].reward = _reward;
        index[_referenceDay].fees = _fees;

        if (_referenceDay > lastIndexedDay) {
            lastIndexedDay = uint32(_referenceDay);
        }

        emit OracleUpdate(msg.sender, _referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty, block.timestamp);

        return true;
    }

    /// @notice Function to return Oracle index on given day
    function get(uint256 _referenceDay)
        external
        view
        override
        returns (
            uint256 referenceDay,
            uint256 referenceBlock,
            uint256 hashrate,
            uint256 reward,
            uint256 fees,
            uint256 difficulty,
            uint256 timestamp
        )
    {
        require(index[_referenceDay].timestamp != 0, "Date not yet indexed");

        return (
            _referenceDay,
            index[_referenceDay].referenceBlock,
            index[_referenceDay].hashrate,
            index[_referenceDay].reward,
            index[_referenceDay].fees,
            index[_referenceDay].difficulty,
            index[_referenceDay].timestamp
        );
    }

    /// @notice Function to return array of oracle data between firstday and lastday (inclusive)
    function getInRange(uint256 _firstDay, uint256 _lastDay)
        external
        view
        override
        returns (uint256[] memory hashrateArray, uint256[] memory rewardArray)
    {
        uint256 numElements = _lastDay + 1 - _firstDay;

        rewardArray = new uint256[](numElements);
        hashrateArray = new uint256[](numElements);

        for (uint256 i = 0; i < numElements; i++) {
            AlkimiyaIndex memory indexCopy = index[_firstDay + i];
            rewardArray[i] = indexCopy.reward;
            hashrateArray[i] = indexCopy.hashrate;
        }
    }

    /// @notice Function to check if Oracle is updated on a given day
    function isDayIndexed(uint256 _referenceDay) external view override returns (bool) {
        return index[_referenceDay].timestamp != 0;
    }

    /// @notice Functino to return the latest day on which the Oracle is updated
    function getLastIndexedDay() external view override returns (uint32) {
        return lastIndexedDay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {AbstractSilicaV2_1} from "./AbstractSilicaV2_1.sol";

import "./interfaces/oracle/IOracle.sol";
import "./interfaces/oracle/IOracleRegistry.sol";
import "./libraries/math/RewardMath.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SilicaV2_1 is AbstractSilicaV2_1 {
    uint8 internal constant COMMODITY_TYPE = 0;

    function decimals() public pure override returns (uint8) {
        return 15;
    }

    constructor() ERC20("Silica", "SLC") {}

    /// @notice Function to return the last day silica is synced with Oracle
    function getLastIndexedDay() internal view override returns (uint32) {
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE));
        uint32 lastIndexedDayMem = oracle.getLastIndexedDay();
        require(lastIndexedDayMem != 0, "Invalid State");

        return lastIndexedDayMem;
    }

    /// @notice Function to return the amount of rewards due by the seller to the contract on day inputed
    function getRewardDueOnDay(uint256 _day) internal view override returns (uint256) {
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE));
        (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(_day);

        return RewardMath.getMiningRewardDue(totalSupply(), networkReward, networkHashrate);
    }

    /// @notice Function to return an array with the amount of rewards due by the seller to the contract on days in range inputed
    function getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view override returns (uint256[] memory) {
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE));
        (uint256[] memory hashrateArray, uint256[] memory rewardArray) = oracle.getInRange(_firstDay, _lastDay);

        uint256[] memory rewardDueArray = new uint256[](hashrateArray.length);

        uint256 totalSupplyCopy = totalSupply();
        for (uint256 i = 0; i < hashrateArray.length; i++) {
            rewardDueArray[i] = RewardMath.getMiningRewardDue(totalSupplyCopy, rewardArray[i], hashrateArray[i]);
        }

        return rewardDueArray;
    }

    /// @notice Returns the commodity type the seller is selling with this contract
    /// @return The commodity type the seller is selling with this contract
    function getCommodityType() external pure override returns (uint8) {
        return COMMODITY_TYPE;
    }

    /// @notice Returns decimals of the contract
    function getDecimals() external pure override returns (uint8) {
        return decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Alkimiya Oracle
 * @author Alkimiya Team
 * @notice Main interface for Oracle contracts
 */
interface IOracle {
    event OracleUpdate(
        address indexed caller,
        uint256 indexed referenceDay,
        uint256 indexed referenceBlock,
        uint256 hashrate,
        uint256 reward,
        uint256 fees,
        uint256 difficulty,
        uint256 timestamp
    );

    /**
     * @notice Return the Network data on a given day
     */
    function get(uint256 _day)
        external
        view
        returns (
            uint256 date,
            uint256 referenceBlock,
            uint256 hashrate,
            uint256 reward,
            uint256 fees,
            uint256 difficulty,
            uint256 timestamp
        );

    function getInRange(uint256 _firstDay, uint256 _lastDay)
        external
        view
        returns (uint256[] memory hashrateArray, uint256[] memory rewardArray);

    /**
     * @notice Return the Network data on a given day is updated to Oracle
     */
    function isDayIndexed(uint256 _referenceDay) external view returns (bool);

    /**
     * @notice Return the last day on which the Oracle is updated
     */
    function getLastIndexedDay() external view returns (uint32);

    /**
     * @notice Update the Alkimiya Index on Oracle for a given day
     */
    function updateIndex(
        uint256 _referenceDay,
        uint256 _referenceBlock,
        uint256 _hashrate,
        uint256 _reward,
        uint256 _fees,
        uint256 _difficulty,
        bytes memory signature
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Alkimiya Oracle Addresses
 * @author Alkimiya Team
 * */
interface IOracleRegistry {
    event OracleRegistered(address token, uint256 oracleType, address oracleAddr);

    function getOracleAddress(address _token, uint256 _oracleType) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

/**
 * @title The interface for Silica
 * @author Alkimiya Team
 * @notice A Silica contract lists hashrate for sale
 * @dev The Silica interface is broken up into smaller interfaces
 */
interface ISilicaV2_1 {
    /*///////////////////////////////////////////////////////////////
                                 Events
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed buyer, uint256 purchaseAmount, uint256 mintedTokens);
    event BuyerCollectPayout(uint256 rewardTokenPayout, uint256 paymentTokenPayout, address buyerAddress, uint256 burntAmount);
    event SellerCollectPayout(uint256 paymentTokenPayout, uint256 rewardTokenExcess);
    event StatusChanged(SilicaV2_1Types.Status status);

    struct InitializeData {
        address rewardTokenAddress;
        address paymentTokenAddress;
        address oracleRegistry;
        address sellerAddress;
        uint256 dayOfDeployment;
        uint256 lastDueDay;
        uint256 unitPrice;
        uint256 resourceAmount;
        uint256 collateralAmount;
    }

    /// @notice Returns the amount of rewards the seller must have delivered before next update
    /// @return rewardDueNextOracleUpdate amount of rewards the seller must have delivered before next update
    function getRewardDueNextOracleUpdate() external view returns (uint256);

    /// @notice Initializes the contract
    /// @param initializeData is the address of the token the seller is selling
    function initialize(InitializeData memory initializeData) external;

    /// @notice Function called by buyer to deposit payment token in the contract in exchange for Silica tokens
    /// @param amountSpecified is the amount that the buyer wants to deposit in exchange for Silica tokens
    function deposit(uint256 amountSpecified) external returns (uint256);

    /// @notice Called by the swapProxy to make a deposit in the name of a buyer
    /// @param _to the address who should receive the Silica Tokens
    /// @param amountSpecified is the amount the swapProxy is depositing for the buyer in exchange for Silica tokens
    function proxyDeposit(address _to, uint256 amountSpecified) external returns (uint256);

    /// @notice Function the buyer calls to collect payout when the contract status is Finished
    function buyerCollectPayout() external returns (uint256 rewardTokenPayout);

    /// @notice Function the buyer calls to collect payout when the contract status is Defaulted
    function buyerCollectPayoutOnDefault() external returns (uint256 rewardTokenPayout, uint256 paymentTokenPayout);

    /// @notice Function the seller calls to collect payout when the contract status is Finised
    function sellerCollectPayout() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);

    /// @notice Function the seller calls to collect payout when the contract status is Defaulted
    function sellerCollectPayoutDefault() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);

    /// @notice Function the seller calls to collect payout when the contract status is Expired
    function sellerCollectPayoutExpired() external returns (uint256 rewardTokenPayout);

    /// @notice Returns the owner of this Silica
    /// @return address: owner address
    function getOwner() external view returns (address);

    /// @notice Returns the Payment Token accepted in this Silica
    /// @return Address: Token Address
    function getPaymentToken() external view returns (address);

    /// @notice Returns the rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling
    /// @return The rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling
    function getRewardToken() external view returns (address);

    /// @notice Returns the last day of reward the seller is selling with this contract
    /// @return The last day of reward the seller is selling with this contract
    function getLastDueDay() external view returns (uint32);

    /// @notice Returns the commodity type the seller is selling with this contract
    /// @return The commodity type the seller is selling with this contract
    function getCommodityType() external pure returns (uint8);

    /// @notice Get the current status of the contract
    /// @return status: The current status of the contract
    function getStatus() external view returns (SilicaV2_1Types.Status);

    /// @notice Returns the day of default.
    /// @return day: The day the contract defaults
    function getDayOfDefault() external view returns (uint256);

    /// @notice Returns true if contract is in Open status
    function isOpen() external view returns (bool);

    /// @notice Returns true if contract is in Running status
    function isRunning() external view returns (bool);

    /// @notice Returns true if contract is in Expired status
    function isExpired() external view returns (bool);

    /// @notice Returns true if contract is in Defaulted status
    function isDefaulted() external view returns (bool);

    /// @notice Returns true if contract is in Finished status
    function isFinished() external view returns (bool);

    /// @notice Returns amount of rewards delivered so far by contract
    function getRewardDeliveredSoFar() external view returns (uint256);

    /// @notice Returns the most recent day the contract owes in rewards
    /// @dev The returned value does not indicate rewards have been fulfilled up to that day
    /// This only returns the most recent day the contract should deliver rewards
    function getLastDayContractOwesReward(uint256 lastDueDay, uint256 lastIndexedDay) external view returns (uint256);

    /// @notice Returns the reserved price of the contract
    function getReservedPrice() external view returns (uint256);

    /// @notice Returns decimals of the contract
    function getDecimals() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SilicaV2_1Types {
    enum Status {
        Open,
        Running,
        Expired,
        Defaulted,
        Finished
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Calculations for when buyer initiates default
 * @author Alkimiya Team
 */
library PayoutMath {
    uint256 internal constant SCALING_FACTOR = 1e8;

    //Contract Constants
    uint128 internal constant FIXED_POINT_SCALE_VALUE = 10**14;
    uint128 internal constant FIXED_POINT_BASE = 10**6;
    uint32 internal constant HAIRCUT_BASE_PCT = 80;

    /**
     * @notice Returns haircut in fixed-point (base = 100000000 = 1).
     * @dev Granting 6 decimals precision. 1 - (0.8) * (day/contract)^3
     */
    function getHaircut(uint256 _numDepositsCompleted, uint256 _contractNumberOfDeposits) internal pure returns (uint256) {
        uint256 contractNumberOfDepositsCubed = uint256(_contractNumberOfDeposits)**3;
        uint256 multiplier = ((_numDepositsCompleted**3) * FIXED_POINT_SCALE_VALUE) / (contractNumberOfDepositsCubed);
        uint256 result = (HAIRCUT_BASE_PCT * multiplier) / (100 * FIXED_POINT_BASE);
        return (FIXED_POINT_BASE * 100) - result;
    }

    /**
     * @notice Calculates reward given to buyer when contract defaults.
     * @dev result = tokenBalance * (totalReward / hashrate)
     */
    function getRewardTokenPayoutToBuyerOnDefault(
        uint256 _buyerTokenBalance,
        uint256 _totalRewardDelivered,
        uint256 _totalSilicaMinted
    ) internal pure returns (uint256) {
        return (_buyerTokenBalance * _totalRewardDelivered) / _totalSilicaMinted;
    }

    /**
     * @notice  Calculates payment returned to buyer when contract defaults.
     * @dev result =  haircut * totalpayment tokenBalance / hashrateSold
     */
    function getPaymentTokenPayoutToBuyerOnDefault(
        uint256 _buyerTokenBalance,
        uint256 _totalUpfrontPayment,
        uint256 _totalSilicaMinted,
        uint256 _haircut
    ) internal pure returns (uint256) {
        return (_buyerTokenBalance * _totalUpfrontPayment * _haircut) / (_totalSilicaMinted * SCALING_FACTOR);
    }

    function getRewardPayoutToSellerOnDefault(uint256 _totalUpfrontPayment, uint256 _haircutPct) internal pure returns (uint256) {
        require(_haircutPct <= 100000000, "Scaled haircut PCT cannot be greater than 100000000");
        uint256 haircutPctRemainder = uint256(100000000) - _haircutPct;
        return (haircutPctRemainder * _totalUpfrontPayment) / 100000000;
    }

    function calculateReservedPrice(
        uint256 unitPrice,
        uint256 resourceAmount,
        uint256 numDeposits,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (unitPrice * resourceAmount * numDeposits) / (10**decimals);
    }

    function getBuyerRewardPayout(
        uint256 rewardDelivered,
        uint256 buyerBalance,
        uint256 resourceAmount
    ) internal pure returns (uint256) {
        return (rewardDelivered * buyerBalance) / resourceAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Calculations for when buyer initiates default
 * @author Alkimiya Team
 */
library RewardMath {
    function getMiningRewardDue(
        uint256 _hashrate,
        uint256 _networkReward,
        uint256 _networkHashrate
    ) internal pure returns (uint256) {
        return (_hashrate * _networkReward) / _networkHashrate;
    }

    function getEthStakingRewardDue(
        uint256 _stakedAmount,
        uint256 _baseRewardPerIncrementPerDay,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (_stakedAmount * _baseRewardPerIncrementPerDay) / (10**decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {SilicaV2_1Types} from "../libraries/SilicaV2_1Types.sol";

abstract contract SilicaV2_1Storage {
    uint32 public finishDay;
    bool public didSellerCollectPayout;
    address public rewardToken;
    address public paymentToken;
    address public oracleRegistry;
    address public silicaFactory;
    address public owner;

    uint32 public firstDueDay;
    uint32 public lastDueDay;
    uint32 public defaultDay;

    uint256 public initialCollateral;
    uint256 public resourceAmount;
    uint256 public reservedPrice;
    uint256 public rewardDelivered;
    uint256 public totalUpfrontPayment; //@review: why is it set to 1 as default in silicaV2
    uint256 public rewardExcess;
    SilicaV2_1Types.Status status;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.9.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, 'BP');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) = IUniswapV3Pool(pool)
            .observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[1] -
            secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(pool).observations(
            (observationIndex + 1) % observationCardinality
        );

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        unchecked {
            secondsAgo = uint32(block.timestamp) - observationTimestamp;
        }
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (
            uint32 observationTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,

        ) = IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - int56(uint56(prevTickCumulative))) / int56(uint56(delta)));
        uint128 liquidity = uint128(
            (uint192(delta) * type(uint160).max) /
                (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
        );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(uint256(weightedTickData[i].weight));
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, 'DL');
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i] ? syntheticTick += ticks[i - 1] : syntheticTick -= ticks[i - 1];
        }
    }
}