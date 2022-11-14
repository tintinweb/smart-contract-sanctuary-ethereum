// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";
import "erc3156/contracts/interfaces/IERC3156FlashLender.sol";
import "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import "./interfaces/IStrategy.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU128I128.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256U128.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/TransferHelper.sol";
import "@yield-protocol/vault-v2/contracts/interfaces/ICauldron.sol";
import "@yield-protocol/vault-v2/contracts/interfaces/ILadle.sol";
import "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import "@yield-protocol/vault-v2/contracts/utils/Giver.sol";

error FlashLoanFailure();
error SlippageFailure();
error OnlyBorrow();
error OnlyRedeem();
error OnlyRepayOrClose();

/// @notice This contracts allows a user to 'lever up' their StrategyToken position.
///     Levering up happens as follows:
///     1. FlashBorrow fyToken
///     2. Sell fyToken to get base (USDC/DAI/ETH)
///     3. Mint LP token & deposit to strategy
///     4. Mint strategy token
///     5. Put strategy token as a collateral to borrow fyToken to repay flash loan
///
///     To get out of the levered position depending on whether we are past maturity the following happens:
///     1. Before maturity
///         A. Repay
///             i. FlashBorrow fyToken
///             ii. Payback the debt to get back the underlying
///             iii. Burn the strategy token to get LP
///             iv. Burn LP to get base & fyToken
///             v. Buy fyToken using the base to repay the flash loan
///         B. Close
///             i. FlashBorrow base
///             ii. Close the debt position using the base
///             iii. Burn the strategy token received from closing the position to get LP token
///             iv. Burn LP token to obtain base to repay the flash loan
///     2. After maturity
//          i. Payback debt to get back the underlying
//          ii. Burn Strategy Tokens and send LP token to the pool
//          iii. Burn LP token to obtain base to repay the flash loan, redeem the fyToken
/// @notice For leveringup we could flash borrow base instead of fyToken as well
/// @author iamsahu & alcueca
contract YieldStrategyLever is IERC3156FlashBorrower {
    using TransferHelper for IERC20;
    using TransferHelper for IFYToken;
    using CastU128I128 for uint128;
    using CastU256U128 for uint256;

    /// @notice The operation to execute in the flash loan.
    ///     - BORROW: Invest
    ///     - REPAY: Unwind before maturity, if pool rates are high
    ///     - CLOSE: Unwind before maturity, if pool rates are low
    ///     - REDEEM: Unwind after maturity
    enum Operation {
        BORROW,
        REPAY,
        CLOSE,
        REDEEM
    }

    /// @notice By IERC3156, the flash loan should return this constant.
    bytes32 public constant FLASH_LOAN_RETURN =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    bytes6 constant ASSET_ID_MASK = 0xFFFF00000000;

    /// @notice The Yield Cauldron, handles debt and collateral balances.
    ICauldron public constant CAULDRON =
        ICauldron(0xc88191F8cb8e6D4a668B047c1C8503432c3Ca867);

    /// @notice The Yield Ladle, the primary entry point for most high-level
    ///     operations.
    ILadle public constant LADLE =
        ILadle(0x6cB18fF2A33e981D1e38A663Ca056c0a5265066A);

    /// @notice The Giver contract can give vaults on behalf on a user who gave
    ///     permission.
    Giver public immutable giver;

    event Invested(
        bytes12 indexed vaultId,
        bytes6 seriesId,
        address indexed investor,
        uint256 investment,
        uint256 debt
    );

    event Divested(
        Operation indexed operation,
        bytes12 indexed vaultId,
        bytes6 seriesId,
        address indexed investor,
        uint256 profit,
        uint256 debt
    );

    constructor(Giver giver_) {
        giver = giver_;
    }

    /// @notice Invest by creating a levered vault. The basic structure is
    ///     always the same. We borrow FyToken for the series and convert it to
    ///     the yield-bearing token that is used as collateral.
    /// @param operation In can only be BORROW
    /// @param seriesId The series to invest in. This series doesn't usually
    ///     have the ilkId as base, but the asset the yield bearing token is
    ///     based on. For example: 0x303030370000 (WEth) instead of WStEth.
    /// @param strategyId The strategyId to invest in. This is often a yield-bearing
    ///     token, for example 0x303400000000 (WStEth).
    /// @param amountToInvest The amount of the base to invest. This is denoted
    ///     in terms of the base asset: USDC, DAI, etc.
    /// @param borrowAmount The amount to borrow. This is denoted in terms of
    ///     debt at maturity (and will thus be less before maturity).
    /// @param fyTokenToBuy The amount of fyToken to be bought from the base
    /// @param minCollateral Used for countering slippage. This is the minimum
    ///     amount of collateral that should be locked. The debt is always
    ///     equal to the borrowAmount plus flash loan fees.
    function invest(
        Operation operation,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 amountToInvest,
        uint256 borrowAmount,
        uint256 fyTokenToBuy,
        uint256 minCollateral
    ) external returns (bytes12 vaultId) {
        if (operation != Operation.BORROW) revert OnlyBorrow();
        IPool pool = IPool(LADLE.pools(seriesId));
        pool.base().safeTransferFrom(
            msg.sender,
            address(pool),
            amountToInvest
        );
        // Build the vault
        (vaultId, ) = LADLE.build(seriesId, strategyId, 0);

        bytes memory data = bytes.concat(
            bytes1(uint8(uint256(operation))), //[0]
            seriesId, //[1:7]
            vaultId, //[7:19]
            strategyId, //[19:25]
            bytes32(fyTokenToBuy), //[25:57]
            bytes20(msg.sender) //[57:77]
        );
        address fyToken = address(pool.fyToken());

        bool success = IERC3156FlashLender(fyToken).flashLoan(
            this, // Loan Receiver
            fyToken, // Loan Token
            borrowAmount, // Loan Amount
            data
        );

        if (!success) revert FlashLoanFailure();

        DataTypes.Balances memory balances = CAULDRON.balances(vaultId);

        // This is the amount to deposit, so we check for slippage here. As
        // long as we end up with the desired amount, it doesn't matter what
        // slippage occurred where.
        if (balances.ink < minCollateral)
            revert SlippageFailure();

        giver.give(vaultId, msg.sender);

        emit Invested(vaultId, seriesId, msg.sender, balances.ink, balances.art);
    }

    /// @notice Divest, either before or after maturity.
    /// @param operation REPAY, CLOSE or REDEEM
    /// @param vaultId The vault to divest from.
    /// @param seriesId The series to divest from.
    /// @param strategyId The strategyId to invest in. This is often a yield-bearing
    /// @param ink The amount of collateral to recover.
    /// @param art The amount of debt to repay.
    /// @param minBaseOut Used to minimize slippage. The transaction will revert
    ///     if we don't obtain at least this much of the base asset.
    function divest(
        Operation operation,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 ink,
        uint256 art,
        uint256 minBaseOut
    ) external {
        // Test that the caller is the owner of the vault.
        // This is important as we will take the vault from the user.
        require(CAULDRON.vaults(vaultId).owner == msg.sender);

        // Give the vault to the contract
        giver.seize(vaultId, address(this));

        IPool pool = IPool(LADLE.pools(seriesId));
        IERC20 baseAsset = IERC20(pool.base());

        bytes memory data = bytes.concat(
            bytes1(bytes1(uint8(uint256(operation)))), // [0:1]
            seriesId, // [1:7]
            vaultId, // [7:19]
            strategyId, // [19:25]
            bytes32(ink), // [25:57]
            bytes32(art) // [57:89]
        );

        // Check if we're pre or post maturity.
        bool success;
        if (uint32(block.timestamp) > CAULDRON.series(seriesId).maturity) {
            if (operation != Operation.REDEEM) revert OnlyRedeem();
            address join = address(LADLE.joins(seriesId & ASSET_ID_MASK));

            // Redeem:
            // Series is past maturity, borrow and move directly to collateral pool.
            // We have a debt in terms of fyToken, but should pay back in base.
            uint128 base = CAULDRON.debtToBase(seriesId, art.u128());
            success = IERC3156FlashLender(join).flashLoan(
                this, // Loan Receiver
                address(baseAsset), // Loan Token
                base, // Loan Amount
                data
            );
        } else {
            if (operation == Operation.REPAY) {
                IMaturingToken fyToken = pool.fyToken();

                // Repay:
                // Series is not past maturity.
                // Borrow to repay debt, move directly to the pool.
                success = IERC3156FlashLender(address(fyToken)).flashLoan(
                    this, // Loan Receiver
                    address(fyToken), // Loan Token
                    art, // Loan Amount: borrow exactly the debt to repay.
                    data
                );
                // Selling off leftover fyToken to get base in return
                if(fyToken.balanceOf(address(this)) > 0){
                    fyToken.transfer(address(pool), fyToken.balanceOf(address(this)));
                    pool.sellFYToken(address(this), 0);
                }
            } else if (operation == Operation.CLOSE) {
                address join = address(LADLE.joins(seriesId & ASSET_ID_MASK));

                // Close:
                // Series is not past maturity, borrow and move directly to collateral pool.
                // We have a debt in terms of fyToken, but should pay back in base.
                uint128 base = CAULDRON.debtToBase(seriesId, art.u128());
                success = IERC3156FlashLender(join).flashLoan(
                    this, // Loan Receiver
                    address(baseAsset), // Loan Token
                    base, // Loan Amount
                    data
                );                
            } else revert OnlyRepayOrClose();

        }
        if (!success) revert FlashLoanFailure();

        // Give the vault back to the sender, just in case there is anything left
        giver.give(vaultId, msg.sender);
        uint256 assetBalance = baseAsset.balanceOf(address(this));
        if (assetBalance < minBaseOut) revert SlippageFailure();
        // Transferring the leftover to the user
        if(assetBalance > 0)
            IERC20(baseAsset).safeTransfer(msg.sender, assetBalance);

        emit Divested(operation, vaultId, seriesId, msg.sender, assetBalance, art);
    }

    /// @notice Called by a flash lender. The primary purpose is to check
    ///     conditions and route to the correct internal function.
    ///
    ///     This function reverts if not called through a flashloan initiated
    ///     by this contract.
    /// @param initiator The initator of the flash loan, must be `address(this)`.
    /// @param borrowAmount The amount of fyTokens received.
    /// @param fee The fee that is subtracted in addition to the borrowed
    ///     amount when repaying.
    /// @param data The data we encoded for the functions. Here, we only check
    ///     the first byte for the router.
    function onFlashLoan(
        address initiator,
        address token,
        uint256 borrowAmount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32 returnValue) {
        returnValue = FLASH_LOAN_RETURN;
        Operation status = Operation(uint256(uint8(data[0])));
        bytes6 seriesId = bytes6(data[1:7]);
        bytes12 vaultId = bytes12(data[7:19]);
        bytes6 ilkId = bytes6(data[19:25]);

        // Test that the lender is either a fyToken contract or the join.
        if (
            msg.sender != address(IPool(LADLE.pools(seriesId)).fyToken()) &&
            msg.sender != address(LADLE.joins(seriesId & ASSET_ID_MASK))
        ) revert FlashLoanFailure();
        // We trust the lender, so now we can check that we were the initiator.
        if (initiator != address(this)) revert FlashLoanFailure();

        // Now that we trust the lender, we approve the flash loan repayment
        IERC20(token).safeApprove(msg.sender, borrowAmount + fee);

        // Decode the operation to execute and then call that function.
        if (status == Operation.BORROW) {
            uint256 fyTokenToBuy = uint256(bytes32(data[25:57]));
            address borrower = address(bytes20(data[57:77]));
            _borrow(vaultId, seriesId, ilkId, borrowAmount, fee, fyTokenToBuy,borrower);
        } else {
            uint256 ink = uint256(bytes32(data[25:57]));
            uint256 art = uint256(bytes32(data[57:89]));
            if (status == Operation.REPAY) {
                _repay(vaultId, seriesId, ilkId, (borrowAmount + fee), ink, art);
            } else if (status == Operation.CLOSE) {
                _close(IERC20(token), vaultId, seriesId, ilkId, borrowAmount, ink, art);
            } else if (status == Operation.REDEEM) {
                _redeem(IERC20(token), vaultId, seriesId, ilkId, borrowAmount, ink, art);
            }
        }
    }

    /// @notice The function does the following to create a leveraged position:
    ///         1. Sells the flash loaned fyToken to get base
    ///         2. Add the base as liquidity to obtain LP tokens
    ///         3. Deposit LP tokens in strategy to obtain strategy token
    ///         4. Finally use the Strategy tokens to borrow fyToken to repay the flash loan
    /// @param vaultId The vault id to put collateral into and borrow from.
    /// @param seriesId The pool (and thereby series) to borrow from.
    /// @param ilkId The id of the ilk being borrowed.
    /// @param borrowAmount The amount of FYTOKEN borrowed in the flash loan.
    /// @param fee The fee that will be issued by the flash loan.
    /// @param fyTokenToBuy the amount of fyTokenToBuy from the base.
    /// @param borrower the user who borrow.
    function _borrow(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId,
        uint256 borrowAmount,
        uint256 fee,
        uint256 fyTokenToBuy,
        address borrower
    ) internal {
        // We have borrowed FyTokens, so sell those
        IPool pool = IPool(LADLE.pools(seriesId));
        IERC20 fyToken = IERC20(address(pool.fyToken()));
        fyToken.safeTransfer(address(pool), borrowAmount - fee);
        pool.sellFYToken(address(pool), 0); // Sell fyToken to get USDC/DAI/ETH
        address strategyAddress = CAULDRON.assets(ilkId);
        // Mint LP token & deposit to strategy
        pool.mintWithBase(
            strategyAddress,
            borrower,
            fyTokenToBuy,
            0,
            type(uint256).max
        );

        // Mint strategy token
        uint256 tokensMinted = IStrategy(strategyAddress).mint(
            address(LADLE.joins(ilkId))
        );

        // Borrow fyToken to repay the flash loan
        LADLE.pour(
            vaultId,
            address(this),
            tokensMinted.u128().i128(),
            borrowAmount.u128().i128()
        );
    }

    /// @notice Unwind position and repay using fyToken
    /// @param vaultId The vault to repay.
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param strategyId The id of the strategy being invested.
    /// @param borrowAmountPlusFee The amount of fyToken that we have borrowed,
    ///     plus the fee. This should be our final balance.
    /// @param ink The amount of collateral to retake.
    /// @param art The debt to repay.
    ///     slippage.
    function _repay(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 borrowAmountPlusFee,
        uint256 ink,
        uint256 art
    ) internal {
        IPool pool = IPool(LADLE.pools(seriesId));
        address fyToken = address(pool.fyToken());
        address strategy = CAULDRON.assets(strategyId);

        // Payback debt to get back the underlying
        IERC20(fyToken).transfer(fyToken, art);
        LADLE.pour(vaultId, strategy, -ink.u128().i128(), -art.u128().i128());

        // Burn strat token to get LP
        IStrategy(strategy).burn(address(pool));

        // Burn LP to get base & fyToken
        (, , uint256 fyTokens) = pool.burn(
            address(this),
            address(this),
            0,
            type(uint256).max
        );

        // Buy fyToken to repay the flash loan
        if (borrowAmountPlusFee > fyTokens) {
            uint128 fyTokenToBuy = (borrowAmountPlusFee - fyTokens).u128();
            pool.base().transfer(address(pool), pool.buyFYTokenPreview(fyTokenToBuy));
            pool.buyFYToken(
                address(this),
                fyTokenToBuy,
                0
            );
        }
    }

    /// @notice Unwind position using the base asset and redeeming any fyToken
    /// @param baseAsset The base asset used for repayment
    /// @param vaultId The ID of the vault to close.
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param strategyId The id of the strategy.
    /// @param debtInBase The amount of debt in base terms.
    /// @param ink The collateral to take from the vault.
    /// @param art The debt to repay. This is denominated in fyTokens
    function _close(
        IERC20 baseAsset,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 debtInBase,
        uint256 ink,
        uint256 art
    ) internal {
        address strategy = CAULDRON.assets(strategyId);
        address pool = LADLE.pools(seriesId);
        address baseJoin = address(LADLE.joins(CAULDRON.series(seriesId).baseId));

        // Payback debt to get back the underlying
        baseAsset.safeTransfer(baseJoin, debtInBase);
        LADLE.close(vaultId, strategy, -ink.u128().i128(), -art.u128().i128());

        // Burn Strategy Tokens and send LP token to the pool
        IStrategy(strategy).burn(address(pool));

        // Burn LP token to obtain base to repay the flash loan
        IPool(pool).burnForBase(address(this), 0, type(uint256).max);
    }


    /// @notice Unwind position using the base asset and redeeming any fyToken
    /// @param baseAsset The base asset used for repayment
    /// @param vaultId The ID of the vault to close.
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param strategyId The id of the strategy.
    /// @param debtInBase The amount of debt in base terms.
    /// @param ink The collateral to take from the vault.
    /// @param art The debt to repay. This is denominated in fyTokens
    function _redeem(
        IERC20 baseAsset,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 debtInBase,
        uint256 ink,
        uint256 art
    ) internal {
        address strategy = CAULDRON.assets(strategyId);
        address pool = LADLE.pools(seriesId);
        address fyToken = address(IPool(pool).fyToken());
        address baseJoin = address(LADLE.joins(CAULDRON.series(seriesId).baseId));

        // Payback debt to get back the underlying
        baseAsset.safeTransfer(baseJoin, debtInBase);
        LADLE.close(vaultId, strategy, -ink.u128().i128(), -art.u128().i128());

        // Burn Strategy Tokens and send LP token to the pool
        IStrategy(strategy).burn(pool);

        // Burn LP token to obtain base to repay the flash loan, redeem the fyToken
        (,, uint256 fyTokens) = IPool(pool).burn(address(this), fyToken, 0, type(uint256).max);
        IFYToken(fyToken).redeem(address(this), fyTokens);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;


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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU128I128 {
    /// @dev Safely cast an uint128 to an int128
    function i128(uint128 x) internal pure returns (int128 y) {
        require (x <= uint128(type(int128).max), "Cast overflow");
        y = int128(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import {IMaturingToken} from "./IMaturingToken.sol";
import {IERC20Metadata} from  "@yield-protocol/utils-v2/contracts/token/ERC20.sol";

interface IPool is IERC20, IERC2612 {
    function baseToken() external view returns(IERC20Metadata);
    function base() external view returns(IERC20);
    function burn(address baseTo, address fyTokenTo, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256);
    function buyBase(address to, uint128 baseOut, uint128 max) external returns(uint128);
    function buyBasePreview(uint128 baseOut) external view returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function currentCumulativeRatio() external view returns (uint256 currentCumulativeRatio_, uint256 blockTimestampCurrent);
    function cumulativeRatioLast() external view returns (uint256);
    function fyToken() external view returns(IMaturingToken);
    function g1() external view returns(int128);
    function g2() external view returns(int128);
    function getC() external view returns (int128);
    function getCurrentSharePrice() external view returns (uint256);
    function getCache() external view returns (uint104 baseCached, uint104 fyTokenCached, uint32 blockTimestampLast, uint16 g1Fee_);
    function getBaseBalance() external view returns(uint128);
    function getFYTokenBalance() external view returns(uint128);
    function getSharesBalance() external view returns(uint128);
    function init(address to) external returns (uint256, uint256, uint256);
    function maturity() external view returns(uint32);
    function mint(address to, address remainder, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function mu() external view returns (int128);
    function mintWithBase(address to, address remainder, uint256 fyTokenToBuy, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function retrieveBase(address to) external returns(uint128 retrieved);
    function retrieveFYToken(address to) external returns(uint128 retrieved);
    function retrieveShares(address to) external returns(uint128 retrieved);
    function scaleFactor() external view returns(uint96);
    function sellBase(address to, uint128 min) external returns(uint128);
    function sellBasePreview(uint128 baseIn) external view returns(uint128);
    function sellFYToken(address to, uint128 min) external returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function setFees(uint16 g1Fee_) external;
    function sharesToken() external view returns(IERC20Metadata);
    function ts() external view returns(int128);
    function wrap(address receiver) external returns (uint256 shares);
    function wrapPreview(uint256 assets) external view returns (uint256 shares);
    function unwrap(address receiver) external returns (uint256 assets);
    function unwrapPreview(uint256 shares) external view returns (uint256 assets);
    /// Returns the max amount of FYTokens that can be sold to the pool
    function maxFYTokenIn() external view returns (uint128) ;
    /// Returns the max amount of FYTokens that can be bought from the pool
    function maxFYTokenOut() external view returns (uint128) ;
    /// Returns the max amount of Base that can be sold to the pool
    function maxBaseIn() external view returns (uint128) ;
    /// Returns the max amount of Base that can be bought from the pool
    function maxBaseOut() external view returns (uint128);
    /// Returns the result of the total supply invariant function
    function invariant() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/RevertMsgExtractor.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
// USDT is a well known token that returns nothing for its transfer, transferFrom, and approve functions
// and part of the reason this library exists
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && _returnTrueOrNothing(data))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Approves a spender to transfer tokens from msg.sender
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be approved
    /// @param spender The approved spender
    /// @param value The value of the allowance
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.approve.selector, spender, value));
        if (!(success && _returnTrueOrNothing(data))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        if (!(success && _returnTrueOrNothing(data))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address payable to, uint256 value) internal {
        (bool success, bytes memory data) = to.call{value: value}(new bytes(0));
        if (!success) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    function _returnTrueOrNothing(bytes memory data) internal pure returns(bool) {
        return (data.length == 0 || abi.decode(data, (bool)));
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";
import "./DataTypes.sol";

interface ICauldron {
    /// @dev Variable rate lending oracle for an underlying
    function lendingOracles(bytes6 baseId) external view returns (IOracle);

    /// @dev An user can own one or more Vaults, with each vault being able to borrow from a single series.
    function vaults(bytes12 vault)
        external
        view
        returns (DataTypes.Vault memory);

    /// @dev Series available in Cauldron.
    function series(bytes6 seriesId)
        external
        view
        returns (DataTypes.Series memory);

    /// @dev Assets available in Cauldron.
    function assets(bytes6 assetsId) external view returns (address);

    /// @dev Each vault records debt and collateral balances_.
    function balances(bytes12 vault)
        external
        view
        returns (DataTypes.Balances memory);

    /// @dev Max, min and sum of debt per underlying and collateral.
    function debt(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.Debt memory);

    // @dev Spot price oracle addresses and collateralization ratios
    function spotOracles(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.SpotOracle memory);

    /// @dev Create a new vault, linked to a series (and therefore underlying) and up to 5 collateral types
    function build(
        address owner,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vault) external;

    /// @dev Change a vault series and/or collateral types.
    function tweak(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId, address receiver)
        external
        returns (DataTypes.Vault memory);

    /// @dev Move collateral and debt between vaults.
    function stir(
        bytes12 from,
        bytes12 to,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory, DataTypes.Balances memory);

    /// @dev Manipulate a vault debt and collateral.
    function pour(
        bytes12 vaultId,
        int128 ink,
        int128 art
    ) external returns (DataTypes.Balances memory);

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(
        bytes12 vaultId,
        bytes6 seriesId,
        int128 art
    ) external returns (DataTypes.Vault memory, DataTypes.Balances memory);

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    function slurp(
        bytes12 vaultId,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory);

    // ==== Helpers ====

    /// @dev Convert a debt amount for a series from base to fyToken terms.
    /// @notice Think about rounding if using, since we are dividing.
    function debtFromBase(bytes6 seriesId, uint128 base)
        external
        returns (uint128 art);

    /// @dev Convert a debt amount for a series from fyToken to base terms
    function debtToBase(bytes6 seriesId, uint128 art)
        external
        returns (uint128 base);

    // ==== Accounting ====

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId) external;

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId) external returns (uint256);

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function level(bytes12 vaultId) external returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IJoin.sol";
import "./ICauldron.sol";

interface ILadle {
    function joins(bytes6) external view returns (IJoin);

    function pools(bytes6) external view returns (address);

    function cauldron() external view returns (ICauldron);

    function build(
        bytes6 seriesId,
        bytes6 ilkId,
        uint8 salt
    ) external returns (bytes12 vaultId, DataTypes.Vault memory vault);

    function destroy(bytes12 vaultId) external;

    function pour(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external payable;

    function serve(
        bytes12 vaultId,
        address to,
        uint128 ink,
        uint128 base,
        uint128 max
    ) external payable returns (uint128 art);

    function close(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC5095.sol";
import "./IJoin.sol";
import "./IOracle.sol";

interface IFYToken is IERC5095 {

    /// @dev Oracle for the savings rate.
    function oracle() view external returns (IOracle);

    /// @dev Source of redemption funds.
    function join() view external returns (IJoin); 

    /// @dev Asset to be paid out on redemption.
    function underlying() view external returns (address);

    /// @dev Yield id of the asset to be paid out on redemption.
    function underlyingId() view external returns (bytes6);

    /// @dev Time at which redemptions are enabled.
    function maturity() view external returns (uint256);

    /// @dev Spot price (exchange rate) between the base and an interest accruing token at maturity, set to 2^256-1 before maturity
    function chiAtMaturity() view external returns (uint256);
    
    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Mint fyToken providing an equal amount of underlying to the protocol
    function mintWithUnderlying(address to, uint256 amount) external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";

interface IStrategy {
    function mint(address to) external returns (uint256 minted);

    function burn(address to) external returns (uint256 withdrawal);

    function burnForBase(address to) external returns (uint256 withdrawal);

    function pool() external returns (IPool pool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "../interfaces/ICauldron.sol";
import "../interfaces/DataTypes.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";

/// @title A contract that allows owner of a vault to give the vault
contract Giver is AccessControl {
    ICauldron public immutable cauldron;
    mapping(bytes6 => bool) public bannedIlks;

    /// @notice Event emitted after an ilk is banned
    /// @param ilkId Ilkid to be banned
    event IlkBanned(bytes6 ilkId);

    constructor(ICauldron cauldron_) {
        cauldron = cauldron_;
    }

    /// @notice Function to ban
    /// @param ilkId the ilkId to be banned
    /// @param set bool value to ban/unban an ilk
    function banIlk(bytes6 ilkId, bool set) external auth {
        bannedIlks[ilkId] = set;
        emit IlkBanned(ilkId);
    }

    /// @notice A give function which allows the owner of vault to give the vault to another address
    /// @param vaultId The vaultId of the vault to be given
    /// @param receiver The address to which the vault is being given to
    /// @return vault The vault which has been given
    function give(bytes12 vaultId, address receiver) external returns (DataTypes.Vault memory vault) {
        vault = cauldron.vaults(vaultId);
        require(vault.owner == msg.sender, "msg.sender is not the owner");
        require(!bannedIlks[vault.ilkId], "ilk is banned");
        vault = cauldron.give(vaultId, receiver);
    }

    /// @notice A give function which allows the authenticated address to give the vault of any user to another address
    /// @param vaultId The vaultId of the vault to be given
    /// @param receiver The address to which the vault is being given to
    /// @return vault The vault which has been given
    function seize(bytes12 vaultId, address receiver) external auth returns (DataTypes.Vault memory vault) {
        vault = cauldron.vaults(vaultId);
        require(!bannedIlks[vault.ilkId], "ilk is banned");
        vault = cauldron.give(vaultId, receiver);
    }
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * 
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IMaturingToken is IERC20 {
    function maturity() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/contracts/BoringBatchable.sol

pragma solidity >=0.6.0;


library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";

library DataTypes {
    // ======== Cauldron data types ========
    struct Series {
        IFYToken fyToken; // Redeemable token for the series.
        bytes6 baseId; // Asset received on redemption.
        uint32 maturity; // Unix time at which redemption becomes possible.
        // bytes2 free
    }

    struct Debt {
        uint96 max; // Maximum debt accepted for a given underlying, across all series
        uint24 min; // Minimum debt accepted for a given underlying, across all series
        uint8 dec; // Multiplying factor (10**dec) for max and min
        uint128 sum; // Current debt for a given underlying, across all series
    }

    struct SpotOracle {
        IOracle oracle; // Address for the spot price oracle
        uint32 ratio; // Collateralization ratio to multiply the price for
        // bytes8 free
    }

    struct Vault {
        address owner;
        bytes6 seriesId; // Each vault is related to only one series, which also determines the underlying.
        bytes6 ilkId; // Asset accepted as collateral
    }

    struct Balances {
        uint128 art; // Debt amount
        uint128 ink; // Collateral amount
    }

    // ======== Witch data types ========
    struct Auction {
        address owner;
        uint32 start;
        bytes6 baseId; // We cache the baseId here
        uint128 ink;
        uint128 art;
        address auctioneer;
        bytes6 ilkId; // We cache the ilkId here
        bytes6 seriesId; // We cache the seriesId here
    }

    struct Line {
        uint32 duration; // Time that auctions take to go to minimal price and stay there
        uint64 vaultProportion; // Proportion of the vault that is available each auction (1e18 = 100%)
        uint64 collateralProportion; // Proportion of collateral that is sold at auction start (1e18 = 100%)
    }

    struct Limits {
        uint128 max; // Maximum concurrent auctioned collateral
        uint128 sum; // Current concurrent auctioned collateral
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev amount of assets held by this contract
    function storedBalance() external view returns (uint256);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);

    /// @dev Retrieve any tokens other than the `asset`. Useful for airdropped tokens.
    function retrieve(IERC20 token, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IERC5095 is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address underlyingAddress);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256 timestamp);

    /// @dev Converts a specified amount of principal to underlying
    function convertToUnderlying(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Converts a specified amount of underlying to principal
    function convertToPrincipal(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Gives the maximum amount an address holder can redeem in terms of the principal
    function maxRedeem(address holder) external view returns (uint256 maxPrincipalAmount);

    /// @dev Gives the amount in terms of underlying that the princiapl amount can be redeemed for plus accrual
    function previewRedeem(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Burn fyToken after maturity for an amount of principal.
    function redeem(uint256 principalAmount, address to, address from) external returns (uint256 underlyingAmount);

    /// @dev Gives the maximum amount an address holder can withdraw in terms of the underlying
    function maxWithdraw(address holder) external returns (uint256 maxUnderlyingAmount);

    /// @dev Gives the amount in terms of principal that the underlying amount can be withdrawn for plus accrual
    function previewWithdraw(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function withdraw(uint256 underlyingAmount, address to, address from) external returns (uint256 principalAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant ROOT4146650865 = 0x00000000; // Collision protection for ROOT, test with ROOT12007226833()
    bytes4 public constant LOCK = 0xFFFFFFFF;           // Used to disable further permissioning of a function
    bytes4 public constant LOCK8605463013 = 0xFFFFFFFF; // Collision protection for LOCK, test with LOCK10462387368()

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
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
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
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
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
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
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}