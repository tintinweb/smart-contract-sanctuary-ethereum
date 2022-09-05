//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

// Libraries
import "./synthetix/SafeDecimalMath.sol";

// Interfaces
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IOptionMarket.sol";
import "./interfaces/ILiquidityCertificate.sol";
import "./interfaces/IPoolHedger.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IShortCollateral.sol";
import "./interfaces/ILendingPool.sol";


/**
 * @title LiquidityPool
 * @author Ozilla
 * @dev Holds funds from LPs, which are used for the following purposes:
 * 1. Collateralizing options sold by the OptionMarket.
 * 2. Buying options from users.
 * 3. Delta hedging the LPs.
 * 4. Storing funds for expired in the money options(both quote and base).
 */
contract LiquidityPool is ILiquidityPool, Ownable {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using SafeERC20 for IERC20;

    ////
    // Constants
    ////
    IOzillaGlobals internal globals;
    IOptionMarket internal optionMarket;
    ILiquidityCertificate internal liquidityCertificate;
    IShortCollateral internal shortCollateral;
    IPoolHedger internal poolHedger;
    IERC20 internal quoteAsset;
    IERC20 internal baseAsset;
    uint internal constant INITIAL_RATE = 1e18;

    ////
    // Variables
    ////
    mapping(uint => string) internal errorMessages;

    bool public initialized = false;
    uint24 public constant poolFee = 3000;

    /// @dev Amount of collateral locked for outstanding calls and puts sold to users
    Collateral public override lockedCollateral;
    /**
     * @dev Total amount of quoteAsset held to pay out users who have locked/waited for their tokens to be burnable. As
   * well as keeping track of all settled option's usd value.
   */
    uint internal totalQuoteAmountReserved;
    /// @dev Total number of tokens that will be removed from the totalTokenSupply at the end of the round.
    uint internal totalBaseAmountReserved;
    /// @dev Total number of tokens that will be removed from the totalTokenSupply at the end of the round.
    uint internal tokensBurnableForRound;
    /// @dev Funds entering the pool in the next round.
    uint public override queuedQuoteFunds;
    /// @dev Total amount of tokens that represents the total amount of pool shares
    uint internal totalTokenSupply;
    /// @dev Counter for reentrancy guard.
    uint internal counter = 1;

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    /**
     * @dev Mapping of timestamps to conversion rates of liquidity to tokens. To get the token value of a certificate;
   * `certificate.liquidity / expiryToTokenValue[certificate.enteredAt]`
   */
    mapping(uint => uint) public override expiryToTokenValue;

    constructor() {}

    /**
     * @dev Initialize the contract.
   *
   * @param _optionMarket OptionMarket address
   * @param _liquidityCertificate LiquidityCertificate address
   * @param _quoteAsset Quote Asset address
   * @param _poolHedger PoolHedger address
   */
    function init(
        IOzillaGlobals _globals,
        IOptionMarket _optionMarket,
        ILiquidityCertificate _liquidityCertificate,
        IPoolHedger _poolHedger,
        IShortCollateral _shortCollateral,
        IERC20 _quoteAsset,
        IERC20 _baseAsset,
        string[] memory _errorMessages
    ) external {
        require(!initialized, "already initialized");
        globals = _globals;
        optionMarket = _optionMarket;
        liquidityCertificate = _liquidityCertificate;
        shortCollateral = _shortCollateral;
        poolHedger = _poolHedger;
        quoteAsset = _quoteAsset;
        baseAsset = _baseAsset;
        require(_errorMessages.length == uint(Error.Last), "error msg count");
        for (uint i = 0; i < _errorMessages.length; i++) {
            errorMessages[i] = _errorMessages[i];
        }
        initialized = true;
    }

    ////////////////////////////////////////////////////////////////
    // Dealing with providing liquidity and withdrawing liquidity //
    ////////////////////////////////////////////////////////////////

    /**
     * @dev Deposits liquidity to the pool. This assumes users have authorised access to the quote ERC20 token. Will add
   * any deposited amount to the queuedQuoteFunds until the next round begins.
   *
   * @param beneficiary The account that will receive the liquidity certificate.
   * @param amount The amount of quoteAsset to deposit.
   */
    function deposit(address beneficiary, uint amount) external override returns (uint) {
        // Assume we have the allowance to take the amount they are depositing
        queuedQuoteFunds = queuedQuoteFunds.add(amount);
        uint certificateId = liquidityCertificate.mint(beneficiary, amount, optionMarket.maxExpiryTimestamp());
        emit Deposit(beneficiary, certificateId, amount);
        _require(quoteAsset.transferFrom(msg.sender, address(this), amount), Error.QuoteTransferFailed);
        return certificateId;
    }

    /**
     * @notice Signals withdraw of liquidity from the pool.
   * @dev It is not possible to withdraw during a round, thus a user can signal to withdraw at the time the round ends.
   *
   * @param certificateId The id of the LiquidityCertificate.
   */
    function signalWithdrawal(uint certificateId) external override {
        ILiquidityCertificate.CertificateData memory certificateData = liquidityCertificate.certificateData(certificateId);
        uint maxExpiryTimestamp = optionMarket.maxExpiryTimestamp();

        _require(certificateData.burnableAt == 0, Error.AlreadySignalledWithdrawal);
        _require(
            certificateData.enteredAt != maxExpiryTimestamp && expiryToTokenValue[maxExpiryTimestamp] == 0,
            Error.SignallingBetweenRounds
        );

        if (certificateData.enteredAt == 0) {
            // Dividing by INITIAL_RATE is redundant as initial rate is 1 unit
            tokensBurnableForRound = tokensBurnableForRound.add(certificateData.liquidity);
        } else {
            tokensBurnableForRound = tokensBurnableForRound.add(
                certificateData.liquidity.divideDecimal(expiryToTokenValue[certificateData.enteredAt])
            );
        }

        liquidityCertificate.setBurnableAt(msg.sender, certificateId, maxExpiryTimestamp);

        emit WithdrawSignaled(certificateId, tokensBurnableForRound);
    }

    /**
     * @dev Undo a previously signalled withdraw. Certificate owner must have signalled withdraw to call this function,
   * and cannot unsignal if the token is already burnable or burnt.
   *
   * @param certificateId The id of the LiquidityCertificate.
   */
    function unSignalWithdrawal(uint certificateId) external override {
        ILiquidityCertificate.CertificateData memory certificateData = liquidityCertificate.certificateData(certificateId);

        // Cannot unsignal withdrawal if the token is burnable/hasn't signalled exit
        _require(certificateData.burnableAt != 0, Error.UnSignalMustSignalFirst);
        _require(expiryToTokenValue[certificateData.burnableAt] == 0, Error.UnSignalAlreadyBurnable);

        liquidityCertificate.setBurnableAt(msg.sender, certificateId, 0);

        if (certificateData.enteredAt == 0) {
            // Dividing by INITIAL_RATE is redundant as initial rate is 1 unit
            tokensBurnableForRound = tokensBurnableForRound.sub(certificateData.liquidity);
        } else {
            tokensBurnableForRound = tokensBurnableForRound.sub(
                certificateData.liquidity.divideDecimal(expiryToTokenValue[certificateData.enteredAt])
            );
        }

        emit WithdrawUnSignaled(certificateId, tokensBurnableForRound);
    }

    /**
     * @dev Withdraws liquidity from the pool.
   *
   * This requires tokens to have been locked until the round ending at the burnableAt timestamp has been ended.
   * This will burn the liquidityCertificates and have the quote asset equivalent at the time be reserved for the users.
   *
   * @param beneficiary The account that will receive the withdrawn funds.
   * @param certificateId The id of the LiquidityCertificate.
   */
    function withdraw(address beneficiary, uint certificateId) external override returns (uint value) {
        ILiquidityCertificate.CertificateData memory certificateData = liquidityCertificate.certificateData(certificateId);
        uint maxExpiryTimestamp = optionMarket.maxExpiryTimestamp();

        // We allow people to withdraw if their funds haven't entered the system
        if (certificateData.enteredAt == maxExpiryTimestamp) {
            queuedQuoteFunds = queuedQuoteFunds.sub(certificateData.liquidity);
            liquidityCertificate.burn(msg.sender, certificateId);
            emit Withdraw(beneficiary, certificateId, certificateData.liquidity, totalQuoteAmountReserved, totalBaseAmountReserved);
            _require(quoteAsset.transfer(beneficiary, certificateData.liquidity), Error.QuoteTransferFailed);
            return certificateData.liquidity;
        }

        uint enterValue = certificateData.enteredAt == 0 ? INITIAL_RATE : expiryToTokenValue[certificateData.enteredAt];

        // expiryToTokenValue will only be set if the previous round has ended, and the next has not started
        uint currentRoundValue = expiryToTokenValue[maxExpiryTimestamp];

        // If they haven't signaled withdrawal, and it is between rounds
        if (certificateData.burnableAt == 0 && currentRoundValue != 0) {
            uint tokenAmt = certificateData.liquidity.divideDecimal(enterValue);
            totalTokenSupply = totalTokenSupply.sub(tokenAmt);
            value = tokenAmt.multiplyDecimal(currentRoundValue);
            liquidityCertificate.burn(msg.sender, certificateId);
            emit Withdraw(beneficiary, certificateId, value, totalQuoteAmountReserved, totalBaseAmountReserved);
            _require(quoteAsset.transfer(beneficiary, value), Error.QuoteTransferFailed);
            return value;
        }

        uint exitValue = expiryToTokenValue[certificateData.burnableAt];

        _require(certificateData.burnableAt != 0 && exitValue != 0, Error.WithdrawNotBurnable);

        value = certificateData.liquidity.multiplyDecimal(exitValue).divideDecimal(enterValue);

        // We can allow a 0 expiry for options created before any boards exist
        liquidityCertificate.burn(msg.sender, certificateId);

        totalQuoteAmountReserved = totalQuoteAmountReserved.sub(value);
        emit Withdraw(beneficiary, certificateId, value, totalQuoteAmountReserved, totalBaseAmountReserved);
        _require(quoteAsset.transfer(beneficiary, value), Error.QuoteTransferFailed);
        return value;
    }

    /**
 * @dev Return Token value.
   *
   * This token price is only accurate within the period between rounds.
   */
    function tokenPriceQuote() public view override returns (uint) {
        IOzillaGlobals.ExchangeGlobals memory exchangeGlobals = globals.getExchangeGlobals(address(optionMarket));

        if (totalTokenSupply == 0) {
            return INITIAL_RATE;
        }

        uint poolValue =
        getTotalPoolValueQuote(
            exchangeGlobals.spotPrice,
            poolHedger.getValueQuote(exchangeGlobals.lendingPool, exchangeGlobals.spotPrice)
        );
        return poolValue.divideDecimal(totalTokenSupply);
    }

    //////////////////////////////////////////////
    // Dealing with locking and expiry rollover //
    //////////////////////////////////////////////

    /**
     * @notice Ends a round.
   * @dev Should only be called after all boards have been liquidated.
   */
    function endRound() external override {
        // Round can only be ended if all boards have been liquidated, and can only be called once.
        uint maxExpiryTimestamp = optionMarket.maxExpiryTimestamp();
        // We must ensure all boards have been expired
        _require(optionMarket.getLiveBoards().length == 0, Error.EndRoundWithLiveBoards);
        // We can only end the round once
        _require(expiryToTokenValue[maxExpiryTimestamp] == 0, Error.EndRoundAlreadyEnded);
        // We want to make sure all base collateral has been exchanged
        _require(baseAsset.balanceOf(address(this)).sub(totalBaseAmountReserved) == 0, Error.EndRoundMustExchangeBase);
        // We want to make sure there is no outstanding poolHedger balance. If there is collateral left in the poolHedger
        // it will not affect calculations.
        // _require(poolHedger.getCurrentHedgedNetDelta() == 0, Error.EndRoundMustHedgeDelta);

        // mock here
        uint pricePerToken = tokenPriceQuote();

        // Store the value for the tokens that are burnable for this round
        expiryToTokenValue[maxExpiryTimestamp] = pricePerToken;

        // Reserve the amount of quote we need for the tokens that are burnable
        totalQuoteAmountReserved = totalQuoteAmountReserved.add(tokensBurnableForRound.multiplyDecimal(pricePerToken));
        emit QuoteReserved(tokensBurnableForRound.multiplyDecimal(pricePerToken), totalQuoteAmountReserved);

        totalTokenSupply = totalTokenSupply.sub(tokensBurnableForRound);
        emit RoundEnded(maxExpiryTimestamp, pricePerToken, totalQuoteAmountReserved, totalBaseAmountReserved, tokensBurnableForRound);
        tokensBurnableForRound = 0;
    }

    /**
     * @dev Starts a round. Can only be called by optionMarket contract when adding a board.
   *
   * @param lastMaxExpiryTimestamp The time at which the previous round ended.
   * @param newMaxExpiryTimestamp The time which funds will be locked until.
   */
    function startRound(uint lastMaxExpiryTimestamp, uint newMaxExpiryTimestamp) external override onlyOptionMarket {
        // As the value is never reset, this is when the first board is added
        if (lastMaxExpiryTimestamp == 0) {
            totalTokenSupply = queuedQuoteFunds;
        } else {
            _require(expiryToTokenValue[lastMaxExpiryTimestamp] != 0, Error.StartRoundMustEndRound);
            totalTokenSupply = totalTokenSupply.add(
                queuedQuoteFunds.divideDecimal(expiryToTokenValue[lastMaxExpiryTimestamp])
            );
        }
        queuedQuoteFunds = 0;

        emit RoundStarted(
            lastMaxExpiryTimestamp,
            newMaxExpiryTimestamp,
            totalTokenSupply,
            lastMaxExpiryTimestamp == 0 ? SafeDecimalMath.UNIT : expiryToTokenValue[lastMaxExpiryTimestamp]
        );
    }

    /////////////////////////////////////////
    // Dealing with collateral for options //
    /////////////////////////////////////////

    /**
    * @dev external override function that will bring the base balance of this contract to match locked.base. This cannot be done
   * in the same transaction as locking the base, as exchanging on synthetix is too costly gas-wise.
   */
    function exchangeBaseWithZerox(address sellToken, address spender, address payable swapTarget, bytes calldata swapCallData)
    external
    override
    payable
    onlyOwner
    reentrancyGuard {
        IERC20 st = IERC20(sellToken);
        st.safeApprove(spender, 0);
        require(st.approve(spender, type(uint256).max));
        (bool success,) = swapTarget.call{value : msg.value}(swapCallData);
        require(success, 'SWAP_CALL_FAILED');
        // msg.sender.transfer(address(this).balance);
    }

    /**
  * @dev function to get how much we want to swap via 0x.
   * 1: we have base asset to sell
   * 2: we have base asset to buy and we have enough quote asset to pay for it
   * 3: we have base asset to buy and we don't have enough quote asset to pay for it
    */
    function getAmountToSwap() external override returns (uint8, uint256) {
        uint currentBaseBalance = baseAsset.balanceOf(address(this));
        // Add this additional check to prevent any soft locks at round end, as the base balance must be 0 to end the round.
        if (optionMarket.getLiveBoards().length == 0) {
            lockedCollateral.base = 0;
        }
        IOzillaGlobals.ExchangeGlobals memory exchangeGlobals = globals.getExchangeGlobals(address(optionMarket));
        // Approve baseAsset and QuoteAsset to Uniswap Address
        if (currentBaseBalance - totalBaseAmountReserved > lockedCollateral.base) {
            // we have excess amount of base asset to swap
            return (1, currentBaseBalance - totalBaseAmountReserved - lockedCollateral.base);
        } else if (lockedCollateral.base > currentBaseBalance - totalBaseAmountReserved) {
            // Buy required amount of baseAsset
            uint quoteToSpend = (lockedCollateral.base - (currentBaseBalance - totalBaseAmountReserved))
            .divideDecimalRound(SafeDecimalMath.UNIT.sub(exchangeGlobals.swapFee))
            .multiplyDecimalRound(exchangeGlobals.spotPrice);
            uint totalQuoteAvailable =
            quoteAsset.balanceOf(address(this)).sub(totalQuoteAmountReserved).sub(lockedCollateral.quote).sub(queuedQuoteFunds);
            if (totalQuoteAvailable > quoteToSpend) {
                // we have enough funds so that we can use swapOutput to buy exact tokens we want.
                return (2, lockedCollateral.base + totalBaseAmountReserved - currentBaseBalance);
            } else {
                return (3, totalQuoteAvailable);
            }
        }
        return (0, 0);
    }

    /**
     * @dev external override function that will bring the base balance of this contract to match locked.base. This cannot be done
   * in the same transaction as locking the base, as exchanging on synthetix is too costly gas-wise.
   */
    function exchangeBase() external override reentrancyGuard {
        uint currentBaseBalance = baseAsset.balanceOf(address(this));

        // Add this additional check to prevent any soft locks at round end, as the base balance must be 0 to end the round.
        if (optionMarket.getLiveBoards().length == 0) {
            lockedCollateral.base = 0;
        }

        IOzillaGlobals.ExchangeGlobals memory exchangeGlobals = globals.getExchangeGlobals(address(optionMarket));
        // Approve baseAsset and QuoteAsset to Uniswap Address
        baseAsset.approve(address(exchangeGlobals.swapRouter), type(uint).max);
        quoteAsset.approve(address(exchangeGlobals.swapRouter), type(uint).max);

        if (currentBaseBalance - totalBaseAmountReserved > lockedCollateral.base) {
            // Sell excess baseAsset
            uint amount = currentBaseBalance - totalBaseAmountReserved - lockedCollateral.base;

            ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
            path : abi.encodePacked(exchangeGlobals.baseAddress, poolFee, exchangeGlobals.quoteAddress),
            recipient : address(this),
            deadline : block.timestamp + 3600,
            amountIn : amount,
            amountOutMinimum : 1
            });
            // Swap baseAsset to quoteAsset
            uint amountQuoteReceived = exchangeGlobals.swapRouter.exactInput(params);
            emit BaseSold(msg.sender, amount, amountQuoteReceived);
        } else if (lockedCollateral.base > currentBaseBalance - totalBaseAmountReserved) {
            // Buy required amount of baseAsset
            uint quoteToSpend =
            (lockedCollateral.base - (currentBaseBalance - totalBaseAmountReserved))
            .divideDecimalRound(SafeDecimalMath.UNIT.sub(exchangeGlobals.swapFee))
            .multiplyDecimalRound(exchangeGlobals.spotPrice);
            uint totalQuoteAvailable =
            quoteAsset.balanceOf(address(this)).sub(totalQuoteAmountReserved).sub(lockedCollateral.quote).sub(queuedQuoteFunds);
            if (totalQuoteAvailable > quoteToSpend) {
                // we have enough funds so that we can use swapOutput to buy exact tokens we want.
                ISwapRouter.ExactOutputParams memory params =
                ISwapRouter.ExactOutputParams({
                path : abi.encodePacked(exchangeGlobals.quoteAddress, poolFee, exchangeGlobals.baseAddress),
                recipient : address(this),
                deadline : block.timestamp + 3600,
                amountOut : lockedCollateral.base + totalBaseAmountReserved - currentBaseBalance,
                amountInMaximum : type(uint).max
                });
                // Swap quoteAsset to baseAsset
                uint amountQuoteSpent = exchangeGlobals.swapRouter.exactOutput(params);
                emit BasePurchased(msg.sender, amountQuoteSpent, lockedCollateral.base + totalBaseAmountReserved - currentBaseBalance);
            } else {
                // we do not have enough funds so that we can only buy as much as we can.
                ISwapRouter.ExactInputParams memory params =
                ISwapRouter.ExactInputParams({
                path : abi.encodePacked(exchangeGlobals.quoteAddress, poolFee, exchangeGlobals.baseAddress),
                recipient : address(this),
                deadline : block.timestamp + 3600,
                amountIn : totalQuoteAvailable,
                amountOutMinimum : 1
                });
                // Swap quoteAsset to baseAsset
                uint amountBaseReceived = exchangeGlobals.swapRouter.exactInput(params);
                emit BasePurchased(msg.sender, totalQuoteAvailable, amountBaseReceived);
            }

        }
    }

    /**
     * @notice Locks quote when the system sells a put option.
   *
   * @param amount The amount of quote to lock.
   * @param freeCollatLiq The amount of free collateral that can be locked.
   */
    function lockQuote(uint amount, uint freeCollatLiq) external override onlyOptionMarket {
        _require(amount <= freeCollatLiq, Error.LockingMoreQuoteThanIsFree);
        lockedCollateral.quote = lockedCollateral.quote.add(amount);
        emit QuoteLocked(amount, lockedCollateral.quote);
    }

    /**
     * @notice Purchases and locks base when the system sells a call option.
   *
   * @param amount The amount of baseAsset to purchase and lock.
   * @param exchangeGlobals The exchangeGlobals.
   * @param liquidity Free and used liquidity amounts.
   */
    function lockBase(
        uint amount,
        IOzillaGlobals.ExchangeGlobals memory exchangeGlobals,
        Liquidity memory liquidity
    ) external override onlyOptionMarket {
        uint currentBaseBal = baseAsset.balanceOf(address(this));

        uint desiredBase;
        uint availableQuote = liquidity.freeCollatLiquidity;

        if (lockedCollateral.base >= currentBaseBal) {
            uint outstanding = lockedCollateral.base - currentBaseBal;
            // We need to ignore any base we haven't purchased yet from our availableQuote
            availableQuote = availableQuote.add(outstanding.multiplyDecimal(exchangeGlobals.spotPrice));
            // But we want to make sure we will have enough quote to cover the debt owed on top of new base we want to lock
            desiredBase = amount.add(outstanding);
        } else {
            // We actually need to buy less, or none, if we already have excess balance
            uint excess = currentBaseBal - lockedCollateral.base;
            if (excess >= amount) {
                desiredBase = 0;
            } else {
                desiredBase = amount.sub(excess);
            }
        }

        // 流动性代币：WETH-DAI： 0x8B22F85d0c844Cf793690F6D9DFE9F11Ddb35449
        uint quoteToSpend = desiredBase.divideDecimalRound(SafeDecimalMath.UNIT.sub(exchangeGlobals.swapFee)).multiplyDecimalRound(exchangeGlobals.spotPrice);
        _require(availableQuote >= quoteToSpend, Error.LockingMoreBaseThanCanBeExchanged);

        lockedCollateral.base = lockedCollateral.base.add(amount);
        emit BaseLocked(amount, lockedCollateral.base);
    }

    /**
     * @notice Frees quote when the system buys back a put from the user.
   *
   * @param amount The amount of quote to free.
   */
    function freeQuoteCollateral(uint amount) external override onlyOptionMarket {
        _freeQuoteCollateral(amount);
    }

    /**
     * @notice Frees quote when the system buys back a put from the user.
   *
   * @param amount The amount of quote to free.
   */
    function _freeQuoteCollateral(uint amount) internal {
        // Handle rounding errors by returning the full amount when the requested amount is greater
        if (amount > lockedCollateral.quote) {
            amount = lockedCollateral.quote;
        }
        lockedCollateral.quote = lockedCollateral.quote.sub(amount);
        emit QuoteFreed(amount, lockedCollateral.quote);
    }

    /**
     * @notice Sells base and frees the proceeds of the sale.
   *
   * @param amountBase The amount of base to sell.
   */
    function freeBase(uint amountBase) external override onlyOptionMarket {
        _require(amountBase <= lockedCollateral.base, Error.FreeingMoreBaseThanLocked);
        lockedCollateral.base = lockedCollateral.base.sub(amountBase);
        emit BaseFreed(amountBase, lockedCollateral.base);
    }

    /**
     * @notice Sends the premium to a user who is selling an option to the pool.
   * @dev The caller must be the OptionMarket.
   *
   * @param recipient The address of the recipient.
   * @param amount The amount to transfer.
   * @param freeCollatLiq The amount of free collateral liquidity.
   */
    function sendPremium(
        address recipient,
        uint amount,
        uint freeCollatLiq
    ) external override onlyOptionMarket reentrancyGuard {
        _require(freeCollatLiq >= amount, Error.SendPremiumNotEnoughCollateral);
        _require(quoteAsset.transfer(recipient, amount), Error.QuoteTransferFailed);

        emit CollateralQuoteTransferred(recipient, amount);
    }

    //////////////////////////////////////////
    // Dealing with expired option premiums //
    //////////////////////////////////////////

    /**
     * @notice Manages collateral at the time of board liquidation, also converting base sent here from the OptionMarket.
   *
   * @param amountQuoteFreed Total amount of base to convert to quote, including profits from short calls.
   * @param amountQuoteReserved Total amount of base to convert to quote, including profits from short calls.
   * @param amountBaseFreed Total amount of collateral to liquidate.
   */
    function boardLiquidation(
        uint amountQuoteFreed,
        uint amountQuoteReserved,
        uint amountBaseFreed,
        uint amountBaseReserved
    ) external override onlyOptionMarket {
        _freeQuoteCollateral(amountQuoteFreed);

        totalQuoteAmountReserved = totalQuoteAmountReserved.add(amountQuoteReserved);
        emit QuoteReserved(amountQuoteReserved, totalQuoteAmountReserved);

        lockedCollateral.base = lockedCollateral.base.sub(amountBaseFreed);
        emit BaseFreed(amountBaseFreed, lockedCollateral.base);

        totalBaseAmountReserved = totalBaseAmountReserved.add(amountBaseReserved);
        emit BaseReserved(amountBaseReserved, totalBaseAmountReserved);
    }

    /**
     * @dev Transfers reserved quote. Sends `amount` of reserved quoteAsset to `user`.
   *
   * Requirements:
   *
   * - the caller must be `OptionMarket`.
   *
   * @param user The address of the user to send the quote.
   * @param amount The amount of quote to send.
   */
    function sendReservedQuote(address user, uint amount) external override onlyShortCollateral reentrancyGuard {
        // Should never happen, but added to prevent any potential rounding errors
        if (amount > totalQuoteAmountReserved) {
            amount = totalQuoteAmountReserved;
        }
        totalQuoteAmountReserved = totalQuoteAmountReserved.sub(amount);
        _require(quoteAsset.transfer(user, amount), Error.QuoteTransferFailed);

        emit ReservedQuoteSent(user, amount, totalQuoteAmountReserved);
    }

    /**
 * @dev Transfers reserved base. Sends `amount` of reserved baseAsset to `user`.
   *
   * Requirements:
   *
   * - the caller must be `OptionMarket`.
   *
   * @param user The address of the user to send the base.
   * @param amount The amount of base to send.
   */
    function sendReservedBase(address user, uint amount) external override onlyShortCollateral reentrancyGuard {
        // Should never happen, but added to prevent any potential rounding errors
        if (amount > totalBaseAmountReserved) {
            amount = totalBaseAmountReserved;
        }
        totalBaseAmountReserved = totalBaseAmountReserved.sub(amount);
        _require(baseAsset.transfer(user, amount), Error.BaseTransferFailed);

        emit ReservedQuoteSent(user, amount, totalQuoteAmountReserved);
    }


    ////////////////////////////
    // Getting Pool Liquidity //
    ////////////////////////////

    /**
     * @notice Returns the total pool value in quoteAsset.
   *
   * @param basePrice The price of the baseAsset.
   * @param usedDeltaLiquidity The amout of delta liquidity that has been used for hedging.
   */
    function getTotalPoolValueQuote(uint basePrice, uint usedDeltaLiquidity) public view override returns (uint) {
        return
        quoteAsset
        .balanceOf(address(this))
        .add(baseAsset.balanceOf(address(this)).multiplyDecimal(basePrice))
        .add(usedDeltaLiquidity)
        .sub(totalQuoteAmountReserved)
        .sub(totalBaseAmountReserved.multiplyDecimal(basePrice))
        .sub(queuedQuoteFunds);
    }

    /**
     * @notice Returns the used and free amounts for collateral and delta liquidity.
   *
   * @param basePrice The price of the base asset.
   */
    function getLiquidity(uint basePrice, ILendingPool lendingPool) public view override returns (Liquidity memory) {
        Liquidity memory liquidity;
        liquidity.usedDeltaLiquidity = poolHedger.getValueQuote(lendingPool, basePrice);
        liquidity.usedCollatLiquidity = lockedCollateral.quote.add(lockedCollateral.base.multiplyDecimal(basePrice));

        uint totalLiquidity = getTotalPoolValueQuote(basePrice, liquidity.usedDeltaLiquidity);
        uint collatPortion = (totalLiquidity * 2) / 3;
        uint deltaPortion = totalLiquidity.sub(collatPortion);
        if (liquidity.usedCollatLiquidity > collatPortion) {
            collatPortion = liquidity.usedCollatLiquidity;
            deltaPortion = totalLiquidity.sub(collatPortion);
        } else if (liquidity.usedDeltaLiquidity > deltaPortion) {
            deltaPortion = liquidity.usedDeltaLiquidity;
            collatPortion = totalLiquidity.sub(deltaPortion);
        }

        liquidity.freeDeltaLiquidity = deltaPortion.sub(liquidity.usedDeltaLiquidity);
        liquidity.freeCollatLiquidity = collatPortion.sub(liquidity.usedCollatLiquidity);

        return liquidity;
    }

    //////////
    // Misc //
    //////////

    /**
     * @notice Sends quoteAsset to the PoolHedger.
   * @dev This function will transfer whatever free delta liquidity is available.
   * The hedger must determine what to do with the amount received.
   *
   * @param exchangeGlobals The exchangeGlobals.
   * @param amount The amount requested by the PoolHedger.
   */
    function transferQuoteToHedge(IOzillaGlobals.ExchangeGlobals memory exchangeGlobals, uint amount)
    external
    override
    onlyPoolHedger
    reentrancyGuard
    returns (uint)
    {
        Liquidity memory liquidity = getLiquidity(exchangeGlobals.spotPrice, exchangeGlobals.lendingPool);

        uint available = liquidity.freeDeltaLiquidity;
        if (available < amount) {
            amount = available;
        }
        _require(quoteAsset.transfer(address(poolHedger), amount), Error.QuoteTransferFailed);

        emit DeltaQuoteTransferredToPoolHedger(amount);

        return amount;
    }

    function _require(bool pass, Error error) internal view {
        require(pass, errorMessages[uint(error)]);
    }

    /**
 * @notice Sends baseAsset to the PoolHedger.
   * @dev This function will transfer whatever free delta liquidity is available.
   * The hedger must determine what to do with the amount received.
   *
   * @param amount The amount requested by the PoolHedger.
   */
    function transferBaseToHedge(uint amount)
    external
    override
    onlyPoolHedger
    reentrancyGuard
    returns (uint)
    {
        // all the liquidity in baseAsset can be delta hedge.
        _require(baseAsset.transfer(address(poolHedger), amount), Error.QuoteTransferFailed);
        emit DeltaBaseTransferredToPoolHedger(amount);
        return amount;
    }

    /**
* @notice Sends baseAsset to the PoolHedger.
   * @dev This function retrieve totalQuoteAmountReserved.
   */
    function getTotalQuoteAmountReserved()
    external
    view
    override
    onlyPoolHedger
    returns (uint)
    {return totalQuoteAmountReserved;
    }

    /**
* @notice Sends baseAsset to the PoolHedger.
   * @dev This function retrieve totalBaseAmountReserved.
   */
    function getTotalBaseAmountReserved()
    external
    override
    view
    onlyPoolHedger
    returns (uint)
    {return totalBaseAmountReserved;
    }


    ///////////////
    // Modifiers //
    ///////////////

    modifier onlyPoolHedger virtual {
        _require(msg.sender == address(poolHedger), Error.OnlyPoolHedger);
        _;
    }

    modifier onlyOptionMarket virtual {
        _require(msg.sender == address(optionMarket), Error.OnlyOptionMarket);
        _;
    }

    modifier onlyShortCollateral virtual {
        _require(msg.sender == address(shortCollateral), Error.OnlyShortCollateral);
        _;
    }

    modifier reentrancyGuard virtual {
        counter = counter.add(1);
        // counter adds 1 to the existing 1 so becomes 2
        uint guard = counter;
        // assigns 2 to the "guard" variable
        _;
        _require(guard == counter, Error.ReentrancyDetected);
    }

    /**
     * @dev Emitted when liquidity is deposited.
   */
    event Deposit(address indexed beneficiary, uint indexed certificateId, uint amount);
    /**
     * @dev Emitted when withdrawal is signaled.
   */
    event WithdrawSignaled(uint indexed certificateId, uint tokensBurnableForRound);
    /**
     * @dev Emitted when a withdrawal is unsignaled.
   */
    event WithdrawUnSignaled(uint indexed certificateId, uint tokensBurnableForRound);
    /**
     * @dev Emitted when liquidity is withdrawn.
   */
    event Withdraw(address indexed beneficiary, uint indexed certificateId, uint value, uint totalQuoteAmountReserved, uint totalBaseAmountReserved);
    /**
     * @dev Emitted when a round ends.
   */
    event RoundEnded(
        uint indexed maxExpiryTimestamp,
        uint pricePerToken,
        uint totalQuoteAmountReserved,
        uint totalBaseAmountReserved,
        uint tokensBurnableForRound
    );
    /**
     * @dev Emitted when a round starts.
   */
    event RoundStarted(
        uint indexed lastMaxExpiryTimestamp,
        uint indexed newMaxExpiryTimestamp,
        uint totalTokenSupply,
        uint tokenValue
    );
    /**
     * @dev Emitted when quote is locked.
   */
    event QuoteLocked(uint quoteLocked, uint lockedCollateralQuote);
    /**
     * @dev Emitted when base is locked.
   */
    event BaseLocked(uint baseLocked, uint lockedCollateralBase);
    /**
     * @dev Emitted when quote is freed.
   */
    event QuoteFreed(uint quoteFreed, uint lockedCollateralQuote);
    /**
     * @dev Emitted when base is freed.
   */
    event BaseFreed(uint baseFreed, uint lockedCollateralBase);
    /**
     * @dev Emitted when base is purchased.
   */
    event BasePurchased(address indexed caller, uint quoteSpent, uint amountPurchased);
    /**
     * @dev Emitted when base is sold.
   */
    event BaseSold(address indexed caller, uint amountSold, uint amountQuoteReceived);
    /**
     * @dev Emitted when collateral is liquidated. This combines LP profit from short calls and freeing base collateral
   */
    event CollateralLiquidated(
        uint totalAmountToLiquidate,
        uint baseFreed,
        uint quoteReceived,
        uint lockedCollateralBase
    );
    /**
     * @dev Emitted when quote is reserved.
   */
    event QuoteReserved(uint amountQuoteReserved, uint totalQuoteAmountReserved);
    /**
 * @dev Emitted when base is reserved.
   */
    event BaseReserved(uint amountBaseReserved, uint totalBaseAmountReserved);
    /**
     * @dev Emitted when reserved quote is sent.
   */
    event ReservedQuoteSent(address indexed user, uint amount, uint totalQuoteAmountReserved);
    /**
     * @dev Emitted when collatQuote is transferred.
   */
    event CollateralQuoteTransferred(address indexed recipient, uint amount);
    /**
     * @dev Emitted when quote is transferred to hedge.
   */
    event DeltaQuoteTransferredToPoolHedger(uint amount);

    event DeltaBaseTransferredToPoolHedger(uint amount);

    event Addresses(address baseAddress, address quoteAddress);
}

//SPDX-License-Identifier: MIT
//
//Copyright (c) 2019 Synthetix
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

pragma solidity ^0.8.0;

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/SafeDecimalMath/
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10 ** uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10 ** uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
   */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
   */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
   * decimals.
   *
   * @dev A unit factor is divided out after the product of x and y is evaluated,
   * so that product must be less than 2**256. As this is an integer division,
   * the internal division always rounds down. This helps save on gas. Rounding
   * is more expensive on gas.
   */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of the specified precision unit.
   *
   * @dev The operands should be in the form of a the specified unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a precise unit.
   *
   * @dev The operands should be in the precise unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a standard unit.
   *
   * @dev The operands should be in the standard unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
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
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
   * decimal in the precision unit specified in the parameter.
   *
   * @dev y is divided after the product of x and the specified precision unit
   * is evaluated, so the product of x and the specified precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
   * standard precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and the standard precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
   * high precision decimal.
   *
   * @dev y is divided after the product of x and the high precision unit
   * is evaluated, so the product of x and the high precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
   */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
   */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./IOzillaGlobals.sol";
import "./ILiquidityPool.sol";

interface IOptionMarket {
  struct OptionListing {
    uint id;
    uint strike;
    uint skew;
    uint longCall;
    uint shortCall;
    uint longPut;
    uint shortPut;
    uint boardId;
  }

  struct OptionBoard {
    uint id;
    uint expiry;
    uint iv;
    bool frozen;
    uint[] listingIds;
  }

  struct Trade {
    bool isBuy;
    uint amount;
    uint vol;
    uint expiry;
    ILiquidityPool.Liquidity liquidity;
  }

  enum TradeType {LONG_CALL, SHORT_CALL, LONG_PUT, SHORT_PUT}

  enum Error {
    TransferOwnerToZero,
    InvalidBoardId,
    InvalidBoardIdOrNotFrozen,
    InvalidListingIdOrNotFrozen,
    StrikeSkewLengthMismatch,
    BoardMaxExpiryReached,
    CannotStartNewRoundWhenBoardsExist,
    ZeroAmountOrInvalidTradeType,
    BoardFrozenOrTradingCutoffReached,
    QuoteTransferFailed,
    BaseTransferFailed,
    BoardNotExpired,
    BoardAlreadyLiquidated,
    UnableToHedge,
    OnlyOwner,
    Last
  }

  function maxExpiryTimestamp() external view returns (uint);

  function optionBoards(uint)
  external
  view
  returns (
    uint id,
    uint expiry,
    uint iv,
    bool frozen
  );

  function optionListings(uint)
  external
  view
  returns (
    uint id,
    uint strike,
    uint skew,
    uint longCall,
    uint shortCall,
    uint longPut,
    uint shortPut,
    uint boardId
  );

  function boardToPriceAtExpiry(uint) external view returns (uint);

  function listingToBaseReturnedRatio(uint) external view returns (uint);

  function transferOwnership(address newOwner) external;

  function setBoardFrozen(uint boardId, bool frozen) external;

  function setBoardBaseIv(uint boardId, uint baseIv) external;

  function setListingSkew(uint listingId, uint skew) external;

  function createOptionBoard(
    uint expiry,
    uint baseIV,
    uint[] memory strikes,
    uint[] memory skews
  ) external returns (uint);

  function addListingToBoard(
    uint boardId,
    uint strike,
    uint skew
  ) external;

  function getLiveBoards() external view returns (uint[] memory _liveBoards);

  function getBoardListings(uint boardId) external view returns (uint[] memory);

  function openPosition(
    uint _listingId,
    TradeType tradeType,
    uint amount
  ) external returns (uint totalCost);

  function closePosition(
    uint _listingId,
    TradeType tradeType,
    uint amount
  ) external returns (uint totalCost);

  function liquidateExpiredBoard(uint boardId) external;

  function settleOptions(uint listingId, TradeType tradeType) external;
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

interface ILiquidityCertificate {
    struct CertificateData {
        uint liquidity;
        uint enteredAt;
        uint burnableAt;
    }

    function MIN_LIQUIDITY() external view returns (uint);

    function liquidityPool() external view returns (address);

    function certificates(address owner) external view returns (uint[] memory);

    function liquidity(uint certificateId) external view returns (uint);

    function enteredAt(uint certificateId) external view returns (uint);

    function burnableAt(uint certificateId) external view returns (uint);

    function certificateData(uint certificateId) external view returns (CertificateData memory);

    function mint(
        address owner,
        uint liquidityAmount,
        uint expiryAtCreation
    ) external returns (uint);

    function setBurnableAt(
        address spender,
        uint certificateId,
        uint timestamp
    ) external;

    function burn(address spender, uint certificateId) external;

    function split(uint certificateId, uint percentageSplit) external returns (uint);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./ILendingPool.sol";

interface IPoolHedger {

    struct Debts {
        uint debtBaseToLiquidityPool;
        uint debtQuoteToLiquidityPool;
        uint debtBaseToShortCollateral;
        uint debtQuoteToShortCollateral;
    }

    function shortingInitialized() external view returns (bool);

    function shortId() external view returns (uint);

    function lastInteraction() external view returns (uint);

    function interactionDelay() external view returns (uint);

    function setInteractionDelay(uint newInteractionDelay) external;

    function hedgeDelta() external;

    function estimateHedge(ILendingPool lendingPool) external view returns (bool);

    function getValueQuote(ILendingPool lendingPool, uint spotPrice) external view returns (uint);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint amountOut);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountIn The amount of the received token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint amountIn);

}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./IOptionMarket.sol";

interface IShortCollateral {
    function sendQuoteCollateral(address recipient, uint amount) external;

    function sendBaseCollateral(address recipient, uint amount) external;

    function sendToLP(uint amountBase, uint amountQuote) external;

    function processSettle(
        uint listingId,
        address receiver,
        IOptionMarket.TradeType tradeType,
        uint amount,
        uint strike,
        uint priceAtExpiry,
        uint listingToShortCallEthReturned
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

interface ILendingPool {
    //    /**
    //     * @dev Emitted on deposit()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address initiating the deposit
    //   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
    //   * @param amount The amount deposited
    //   * @param referral The referral code used
    //   **/
    //    event Deposit(
    //        address indexed reserve,
    //        address user,
    //        address indexed onBehalfOf,
    //        uint256 amount,
    //        uint16 indexed referral
    //    );
    //
    //    /**
    //     * @dev Emitted on withdraw()
    //   * @param reserve The address of the underlyng asset being withdrawn
    //   * @param user The address initiating the withdrawal, owner of aTokens
    //   * @param to Address that will receive the underlying
    //   * @param amount The amount to be withdrawn
    //   **/
    //    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);
    //
    //    /**
    //     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
    //   * @param reserve The address of the underlying asset being borrowed
    //   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
    //   * initiator of the transaction on flashLoan()
    //   * @param onBehalfOf The address that will be getting the debt
    //   * @param amount The amount borrowed out
    //   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
    //   * @param borrowRate The numeric rate at which the user has borrowed
    //   * @param referral The referral code used
    //   **/
    //    event Borrow(
    //        address indexed reserve,
    //        address user,
    //        address indexed onBehalfOf,
    //        uint256 amount,
    //        uint256 borrowRateMode,
    //        uint256 borrowRate,
    //        uint16 indexed referral
    //    );
    //
    //    /**
    //     * @dev Emitted on repay()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The beneficiary of the repayment, getting his debt reduced
    //   * @param repayer The address of the user initiating the repay(), providing the funds
    //   * @param amount The amount repaid
    //   **/
    //    event Repay(
    //        address indexed reserve,
    //        address indexed user,
    //        address indexed repayer,
    //        uint256 amount
    //    );
    //
    //    /**
    //     * @dev Emitted on swapBorrowRateMode()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address of the user swapping his rate mode
    //   * @param rateMode The rate mode that the user wants to swap to
    //   **/
    //    event Swap(address indexed reserve, address indexed user, uint256 rateMode);
    //
    //    /**
    //     * @dev Emitted on setUserUseReserveAsCollateral()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address of the user enabling the usage as collateral
    //   **/
    //    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
    //
    //    /**
    //     * @dev Emitted on setUserUseReserveAsCollateral()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address of the user enabling the usage as collateral
    //   **/
    //    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
    //
    //    /**
    //     * @dev Emitted on rebalanceStableBorrowRate()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address of the user for which the rebalance has been executed
    //   **/
    //    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);
    //
    //    /**
    //     * @dev Emitted on flashLoan()
    //   * @param target The address of the flash loan receiver contract
    //   * @param initiator The address initiating the flash loan
    //   * @param asset The address of the asset being flash borrowed
    //   * @param amount The amount flash borrowed
    //   * @param premium The fee flash borrowed
    //   * @param referralCode The referral code used
    //   **/
    //    event FlashLoan(
    //        address indexed target,
    //        address indexed initiator,
    //        address indexed asset,
    //        uint256 amount,
    //        uint256 premium,
    //        uint16 referralCode
    //    );
    //
    //    /**
    //     * @dev Emitted when the pause is triggered.
    //   */
    //    event Paused();
    //
    //    /**
    //     * @dev Emitted when the pause is lifted.
    //   */
    //    event Unpaused();
    //
    //    /**
    //     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
    //   * LendingPoolCollateral manager using a DELEGATECALL
    //   * This allows to have the events in the generated ABI for LendingPool.
    //   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
    //   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
    //   * @param user The address of the borrower getting liquidated
    //   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
    //   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
    //   * @param liquidator The address of the liquidator
    //   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
    //   * to receive the underlying collateral asset directly
    //   **/
    //    event LiquidationCall(
    //        address indexed collateralAsset,
    //        address indexed debtAsset,
    //        address indexed user,
    //        uint256 debtToCover,
    //        uint256 liquidatedCollateralAmount,
    //        address liquidator,
    //        bool receiveAToken
    //    );
    //
    //    /**
    //     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
    //   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
    //   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
    //   * gets added to the LendingPool ABI
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param liquidityRate The new liquidity rate
    //   * @param stableBorrowRate The new stable borrow rate
    //   * @param variableBorrowRate The new variable borrow rate
    //   * @param liquidityIndex The new liquidity index
    //   * @param variableBorrowIndex The new variable borrow index
    //   **/
    //    event ReserveDataUpdated(
    //        address indexed reserve,
    //        uint256 liquidityRate,
    //        uint256 stableBorrowRate,
    //        uint256 variableBorrowRate,
    //        uint256 liquidityIndex,
    //        uint256 variableBorrowIndex
    //    );
    //
    //    /**
    //     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    //   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
    //   * @param asset The address of the underlying asset to deposit
    //   * @param amount The amount to be deposited
    //   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    //   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    //   *   is a different wallet
    //   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    //   *   0 if the action is executed directly by the user, without any middle-man
    //   **/
    //    function deposit(
    //        address asset,
    //        uint256 amount,
    //        address onBehalfOf,
    //        uint16 referralCode
    //    ) external;
    //
    //    /**
    //     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    //   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    //   * @param asset The address of the underlying asset to withdraw
    //   * @param amount The underlying amount to be withdrawn
    //   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    //   * @param to Address that will receive the underlying, same as msg.sender if the user
    //   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    //   *   different wallet
    //   * @return The final amount withdrawn
    //   **/
    //    function withdraw(
    //        address asset,
    //        uint256 amount,
    //        address to
    //    ) external returns (uint256);
    //
    //    /**
    //     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
    //   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
    //   * corresponding debt token (StableDebtToken or VariableDebtToken)
    //   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
    //   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
    //   * @param asset The address of the underlying asset to borrow
    //   * @param amount The amount to be borrowed
    //   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
    //   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    //   *   0 if the action is executed directly by the user, without any middle-man
    //   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
    //   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
    //   * if he has been given credit delegation allowance
    //   **/
    //    function borrow(
    //        address asset,
    //        uint256 amount,
    //        uint256 interestRateMode,
    //        uint16 referralCode,
    //        address onBehalfOf
    //    ) external;
    //
    //    /**
    //     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
    //   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
    //   * @param asset The address of the borrowed underlying asset previously borrowed
    //   * @param amount The amount to repay
    //   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
    //   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
    //   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
    //   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
    //   * other borrower whose debt should be removed
    //   * @return The final amount repaid
    //   **/
    //    function repay(
    //        address asset,
    //        uint256 amount,
    //        uint256 rateMode,
    //        address onBehalfOf
    //    ) external returns (uint256);
    //
    //    /**
    //     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
    //   * @param asset The address of the underlying asset borrowed
    //   * @param rateMode The rate mode that the user wants to swap to
    //   **/
    //    function swapBorrowRateMode(address asset, uint256 rateMode) external;
    //
    //    /**
    //     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
    //   * - Users can be rebalanced if the following conditions are satisfied:
    //   *     1. Usage ratio is above 95%
    //   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
    //   *        borrowed at a stable rate and depositors are not earning enough
    //   * @param asset The address of the underlying asset borrowed
    //   * @param user The address of the user to be rebalanced
    //   **/
    //    function rebalanceStableBorrowRate(address asset, address user) external;
    //
    //    /**
    //     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
    //   * @param asset The address of the underlying asset deposited
    //   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
    //   **/
    //    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
    //
    //    /**
    //     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
    //   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
    //   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
    //   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
    //   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
    //   * @param user The address of the borrower getting liquidated
    //   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
    //   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
    //   * to receive the underlying collateral asset directly
    //   **/
    //    function liquidationCall(
    //        address collateralAsset,
    //        address debtAsset,
    //        address user,
    //        uint256 debtToCover,
    //        bool receiveAToken
    //    ) external;
    //
    //    /**
    //     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
    //   * as long as the amount taken plus a fee is returned.
    //   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
    //   * For further details please visit https://developers.aave.com
    //   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
    //   * @param assets The addresses of the assets being flash-borrowed
    //   * @param amounts The amounts amounts being flash-borrowed
    //   * @param modes Types of the debt to open if the flash loan is not returned:
    //   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
    //   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
    //   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
    //   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
    //   * @param params Variadic packed params to pass to the receiver as extra information
    //   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    //   *   0 if the action is executed directly by the user, without any middle-man
    //   **/
    //    function flashLoan(
    //        address receiverAddress,
    //        address[] calldata assets,
    //        uint256[] calldata amounts,
    //        uint256[] calldata modes,
    //        address onBehalfOf,
    //        bytes calldata params,
    //        uint16 referralCode
    //    ) external;
    //
    //    /**
    //     * @dev Returns the user account data across all the reserves
    //   * @param user The address of the user
    //   * @return totalCollateralETH the total collateral in ETH of the user
    //   * @return totalDebtETH the total debt in ETH of the user
    //   * @return availableBorrowsETH the borrowing power left of the user
    //   * @return currentLiquidationThreshold the liquidation threshold of the user
    //   * @return ltv the loan to value of the user
    //   * @return healthFactor the current health factor of the user
    //   **/
    //    function getUserAccountData(address user)
    //    external
    //    view
    //    returns (
    //        uint256 totalCollateralETH,
    //        uint256 totalDebtETH,
    //        uint256 availableBorrowsETH,
    //        uint256 currentLiquidationThreshold,
    //        uint256 ltv,
    //        uint256 healthFactor
    //    );
    //
    //    function initReserve(
    //        address reserve,
    //        address aTokenAddress,
    //        address stableDebtAddress,
    //        address variableDebtAddress,
    //        address interestRateStrategyAddress
    //    ) external;
    //
    //    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    //    external;
    //
    //    function setConfiguration(address reserve, uint256 configuration) external;
    //
    //    /**
    //     * @dev Returns the normalized income normalized income of the reserve
    //   * @param asset The address of the underlying asset of the reserve
    //   * @return The reserve's normalized income
    //   */
    //    function getReserveNormalizedIncome(address asset) external view returns (uint256);
    //
    //    /**
    //     * @dev Returns the normalized variable debt per unit of asset
    //   * @param asset The address of the underlying asset of the reserve
    //   * @return The reserve normalized variable debt
    //   */
    //    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);
    //
    //    function finalizeTransfer(
    //        address asset,
    //        address from,
    //        address to,
    //        uint256 amount,
    //        uint256 balanceFromAfter,
    //        uint256 balanceToBefore
    //    ) external;
    //
    //    function getReservesList() external view returns (address[] memory);
    //
    //    function setPause(bool val) external;
    //
    //    function paused() external view returns (bool);

    function lend(uint amount) external returns (uint);

    function repay() external returns (uint);

    function getShortPosition() external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./ICollateralShort.sol";
import "./IExchangeRates.sol";
import "./IExchanger.sol";
import "./IUniswapV2Pair.sol";
import "./ILendingPool.sol";
import "./ISwapRouter.sol";

interface IOzillaGlobals {
    enum ExchangeType {BASE_QUOTE, QUOTE_BASE, ALL}

    /**
     * @dev Structs to help reduce the number of calls between other contracts and this one
   * Grouped in usage for a particular contract/use case
   */
    struct ExchangeGlobals {
        uint spotPrice;
        uint swapFee;
        address quoteAddress;
        address baseAddress;
        ISwapRouter swapRouter;
        ILendingPool lendingPool;
    }

    struct GreekCacheGlobals {
        int rateAndCarry;
        uint spotPrice;
    }

    struct PricingGlobals {
        uint optionPriceFeeCoefficient;
        uint spotPriceFeeCoefficient;
        uint vegaFeeCoefficient;
        uint vegaNormFactor;
        uint standardSize;
        uint skewAdjustmentFactor;
        int rateAndCarry;
        int minDelta;
        uint volatilityCutoff;
        uint spotPrice;
    }

    function swapRouter() external view returns (ISwapRouter);

    function exchanger() external view returns (IExchanger);

    function exchangeRates() external view returns (IExchangeRates);

    function lendingPool() external view returns (ILendingPool);

    function isPaused() external view returns (bool);

    function tradingCutoff(address) external view returns (uint);

    function swapFee(address) external view returns (uint);

    function optionPriceFeeCoefficient(address) external view returns (uint);

    function spotPriceFeeCoefficient(address) external view returns (uint);

    function vegaFeeCoefficient(address) external view returns (uint);

    function vegaNormFactor(address) external view returns (uint);

    function standardSize(address) external view returns (uint);

    function skewAdjustmentFactor(address) external view returns (uint);

    function rateAndCarry(address) external view returns (int);

    function minDelta(address) external view returns (int);

    function volatilityCutoff(address) external view returns (uint);

    function quoteMessage(address) external view returns (address);

    function baseMessage(address) external view returns (address);

    function setGlobals(ISwapRouter _swapRouter, ILendingPool _lendingPool) external;

    function setGlobalsForContract(
        address _contractAddress,
        uint _tradingCutoff,
        uint _swapFee,
        PricingGlobals memory pricingGlobals,
        address _quoteAddress,
        address _baseAddress
    ) external;

    function setPaused(bool _isPaused) external;

    function setTradingCutoff(address _contractAddress, uint _tradingCutoff) external;

    function setSwapFee(address _contractAddress, uint _swapFee) external;

    function setOptionPriceFeeCoefficient(address _contractAddress, uint _optionPriceFeeCoefficient) external;

    function setSpotPriceFeeCoefficient(address _contractAddress, uint _spotPriceFeeCoefficient) external;

    function setVegaFeeCoefficient(address _contractAddress, uint _vegaFeeCoefficient) external;

    function setVegaNormFactor(address _contractAddress, uint _vegaNormFactor) external;

    function setStandardSize(address _contractAddress, uint _standardSize) external;

    function setSkewAdjustmentFactor(address _contractAddress, uint _skewAdjustmentFactor) external;

    function setRateAndCarry(address _contractAddress, int _rateAndCarry) external;

    function setMinDelta(address _contractAddress, int _minDelta) external;

    function setVolatilityCutoff(address _contractAddress, uint _volatilityCutoff) external;

    function setQuoteMessage(address _contractAddress, address _quoteAddress) external;

    function setBaseMessage(address _contractAddress, address _baseAddress) external;

    function getSpotPriceForMarket(address _contractAddress) external view returns (uint);

    function getSpotPrice(address to) external view returns (uint256);

    function getPricingGlobals(address _contractAddress) external view returns (PricingGlobals memory);

    function getGreekCacheGlobals(address _contractAddress) external view returns (GreekCacheGlobals memory);

    function getExchangeGlobals(address _contractAddress) external view returns (ExchangeGlobals memory exchangeGlobals);

    function getGlobalsForOptionTrade(address _contractAddress)
    external
    view
    returns (
        PricingGlobals memory pricingGlobals,
        ExchangeGlobals memory exchangeGlobals,
        uint tradeCutoff
    );
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./IOzillaGlobals.sol";

interface ILiquidityPool {
    struct Collateral {
        uint quote;
        uint base;
    }

    /// @dev These are all in quoteAsset amounts.
    struct Liquidity {
        uint freeCollatLiquidity;
        uint usedCollatLiquidity;
        uint freeDeltaLiquidity;
        uint usedDeltaLiquidity;
    }

    enum Error {
        QuoteTransferFailed,
        BaseTransferFailed,
        AlreadySignalledWithdrawal,
        SignallingBetweenRounds,
        UnSignalMustSignalFirst,
        UnSignalAlreadyBurnable,
        WithdrawNotBurnable,
        EndRoundWithLiveBoards,
        EndRoundAlreadyEnded,
        EndRoundMustExchangeBase,
        EndRoundMustHedgeDelta,
        StartRoundMustEndRound,
        ReceivedZeroFromBaseQuoteExchange,
        ReceivedZeroFromQuoteBaseExchange,
        LockingMoreQuoteThanIsFree,
        LockingMoreBaseThanCanBeExchanged,
        FreeingMoreBaseThanLocked,
        SendPremiumNotEnoughCollateral,
        OnlyPoolHedger,
        OnlyOptionMarket,
        OnlyShortCollateral,
        ReentrancyDetected,
        Last
    }

    function lockedCollateral() external view returns (uint, uint);

    function queuedQuoteFunds() external view returns (uint);

    function expiryToTokenValue(uint) external view returns (uint);

    function deposit(address beneficiary, uint amount) external returns (uint);

    function signalWithdrawal(uint certificateId) external;

    function unSignalWithdrawal(uint certificateId) external;

    function withdraw(address beneficiary, uint certificateId) external returns (uint value);

    function tokenPriceQuote() external view returns (uint);

    function endRound() external;

    function startRound(uint lastMaxExpiryTimestamp, uint newMaxExpiryTimestamp) external;

    function exchangeBase() external;

    function exchangeBaseWithZerox(address sellToken, address spender, address payable swapTarget, bytes calldata swapCallData) payable external;

    function getAmountToSwap() external returns (uint8, uint256);

    function lockQuote(uint amount, uint freeCollatLiq) external;

    function lockBase(
        uint amount,
        IOzillaGlobals.ExchangeGlobals memory exchangeGlobals,
        Liquidity memory liquidity
    ) external;

    function freeQuoteCollateral(uint amount) external;

    function freeBase(uint amountBase) external;

    function sendPremium(
        address recipient,
        uint amount,
        uint freeCollatLiq
    ) external;

    function boardLiquidation(
        uint amountQuoteFreed,
        uint amountQuoteReserved,
        uint amountBaseFreed,
        uint amountBaseReserved
    ) external;

    function sendReservedQuote(address user, uint amount) external;

    function sendReservedBase(address user, uint amount) external;

    function getTotalPoolValueQuote(uint basePrice, uint usedDeltaLiquidity) external view returns (uint);

    function getLiquidity(uint basePrice, ILendingPool lendingPool) external view returns (Liquidity memory);

    function transferQuoteToHedge(IOzillaGlobals.ExchangeGlobals memory exchangeGlobals, uint amount)
    external
    returns (uint);

    function transferBaseToHedge(uint amount)
    external
    returns (uint);

    function getTotalQuoteAmountReserved() external view returns (uint);

    function getTotalBaseAmountReserved() external returns (uint);
}

//SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

interface ICollateralShort {
    struct Loan {
        // ID for the loan
        uint id;
        //  Account that created the loan
        address account;
        //  Amount of collateral deposited
        uint collateral;
        // The synth that was borrowed
        address currency;
        //  Amount of synths borrowed
        uint amount;
        // Indicates if the position was short sold
        bool short;
        // interest amounts accrued
        uint accruedInterest;
        // last interest index
        uint interestIndex;
        // time of last interaction.
        uint lastInteraction;
    }

    function loans(uint id)
    external
    returns (
        uint,
        address,
        uint,
        address,
        uint,
        bool,
        uint,
        uint,
        uint
    );

    function minCratio() external returns (uint);

    function minCollateral() external returns (uint);

    function issueFeeRate() external returns (uint);

    function open(
        uint collateral,
        uint amount,
        address currency
    ) external returns (uint id);

    function repay(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint short, uint collateral);

    function repayWithCollateral(uint id, uint repayAmount) external returns (uint short, uint collateral);

    function draw(uint id, uint amount) external returns (uint short, uint collateral);

    // Same as before
    function deposit(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint short, uint collateral);

    // Same as before
    function withdraw(uint id, uint amount) external returns (uint short, uint collateral);

    // function to return the loan details in one call, without needing to know about the collateralstate
    function getShortAndCollateral(address account, uint id) external view returns (uint short, uint collateral);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
    external
    view
    returns (uint exchangeFeeRate);
}

/**
 *Submitted for verification at Etherscan.io on 2020-05-05
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}