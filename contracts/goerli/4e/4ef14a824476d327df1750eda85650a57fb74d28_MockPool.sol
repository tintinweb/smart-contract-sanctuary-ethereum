// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "../Pool.sol";

contract MockPool is Pool {
    constructor(
        ITerm _term,
        IERC20 _token,
        uint256 _tradeFee,
        bytes32 _erc20ForwarderCodeHash,
        address _governanceContract,
        address _erc20ForwarderFactory
    )
        Pool(
            _term,
            _token,
            _tradeFee,
            _erc20ForwarderCodeHash,
            _governanceContract,
            _erc20ForwarderFactory
        )
    {}

    function setFees(
        uint256 poolId,
        uint128 feeShares,
        uint128 feeBond
    ) external {
        governanceFees[poolId] = CollectedFees(feeShares, feeBond);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./LP.sol";
import "./libraries/FixedPointMath.sol";
import "./libraries/YieldSpaceMath.sol";
import "./libraries/Authorizable.sol";
import "./libraries/TWAROracle.sol";
import "./interfaces/IMultiToken.sol";
import "./interfaces/ITerm.sol";

contract Pool is LP, Authorizable, TWAROracle {
    // Lets us use the fixed point math library as calls
    using FixedPointMath for uint256;

    // Constant Year in seconds, note there's no native support because of leap seconds
    uint256 internal constant _ONE_YEAR = 31536000;

    /// A percentage commission get charge on every trade & get distributed to LPs.
    /// It is in 18 decimals
    uint128 public tradeFee;
    /// The percentage of fees that can be transferred to governance
    uint128 public governanceFeePercent;
    /// Governance contract that allows to do some administrative operation.
    address public immutable governanceContract;

    /// Fees collected for governance
    struct CollectedFees {
        /// Fees in terms of shares.
        uint128 feesInShares;
        /// Fees in terms of bonds.
        uint128 feesInBonds;
    }

    /// Sub Pool specific details.
    struct SubPoolParameters {
        // The number of years to stretch time by, represented as 1000 times
        // the fraction. IE 4.181 = 4181 and 0.001 = 1
        uint32 timestretch;
        /// Price per share at the time of initialization in 18 point fixed
        uint224 mu;
    }

    /// Mapping to keep track of fee collection corresponds to `poolId`.
    mapping(uint256 => CollectedFees) public governanceFees;

    /// Sub pool parameters;
    mapping(uint256 => SubPoolParameters) public parameters;

    // ------------------------------ Events ------------------------------//

    /// Emitted when the pool reserves get updated.
    event Sync(
        uint256 indexed poolId,
        uint256 bondReserve,
        uint256 shareReserve
    );

    /// Emitted event when the bonds get traded.
    event BondsTraded(
        uint256 indexed poolId,
        address indexed receiver,
        bool indexed isBuy,
        uint256 amountIn,
        uint256 amountOut
    );

    /// Emitted when the YTs got purchased.
    event YtPurchased(
        uint256 indexed poolId,
        address indexed receiver,
        uint256 amountOfYtMinted,
        uint256 sharesIn
    );

    /// @notice Initialize the contract with below params.
    /// @param _term Address of the YieldAdapter whose PTs and YTs are supported with this Pool.
    /// @param _token The ERC20 token
    /// @param _tradeFee Percentage of fee get deducted during any trade, Should be in 18 decimals
    /// @param _erc20ForwarderCodeHash The hash of the erc20 forwarder contract deploy code.
    /// @param _governanceContract Governance contract address.
    /// @param _erc20ForwarderFactory The factory which is used to deploy the forwarder contracts.
    constructor(
        ITerm _term,
        IERC20 _token,
        uint256 _tradeFee,
        bytes32 _erc20ForwarderCodeHash,
        address _governanceContract,
        address _erc20ForwarderFactory
    )
        LP(_token, _term, _erc20ForwarderCodeHash, _erc20ForwarderFactory)
        TWAROracle()
        Authorizable()
    {
        // Should not be zero.
        require(_governanceContract != address(0), "todo nice errors");
        // Set the owner of this contract
        _authorize(_governanceContract);
        setOwner(_governanceContract);

        // approve the max allowance for the term contract to
        // transfer from the pool for depositUnlocked
        _token.approve(address(_term), type(uint256).max);

        //----------------Perform some sstore---------------------//
        tradeFee = uint128(_tradeFee);
        governanceContract = _governanceContract;
    }

    /// @notice Returns the name of the sub token i.e LP token supported
    ///         by this contract.
    /// @param poolId The id of the sub token to get the name of, will be the expiry
    /// @return Returns the name of this token
    function name(uint256 poolId)
        external
        view
        override
        returns (string memory)
    {
        return (string(abi.encodePacked("LP: ", term.name(poolId))));
    }

    /// @notice Returns the symbol of the sub token i.e LP token supported
    ///         by this contract.
    /// @param poolId The id of the sub token to get the name of, will be the expiry
    /// @return Returns the symbol of this token
    function symbol(uint256 poolId)
        external
        view
        override
        returns (string memory)
    {
        return (string(abi.encodePacked("LP: ", term.symbol(poolId))));
    }

    /// @notice Used to initialize the reserves of the pool for given poolIds.
    /// @param  poolId New poolId which will get supported by this pool, equal to bond expiry
    /// @param  underlyingIn Amount of tokens used to initialize the reserves.
    /// @param  timeStretch The fraction of a year to stretch by in 3 decimal ie [10.245 = 10245]
    /// @param  recipient Address which will receive the minted LP tokens.
    /// @param  maxTime The longest timestamp the oracle will hold, 0 and it will not be initialized
    /// @param  maxLength The most timestamps the oracle will hold
    /// @return mintedLpTokens No. of minted LP tokens amount for provided `poolIds`.
    function registerPoolId(
        uint256 poolId,
        uint256 underlyingIn,
        uint32 timeStretch,
        address recipient,
        uint16 maxTime,
        uint16 maxLength
    ) external returns (uint256 mintedLpTokens) {
        // Expired PTs are not supported.
        require(poolId > block.timestamp, "todo nice time errors");
        // Should not be already initialized.
        require(totalSupply[poolId] == uint256(0), "todo nice errors");
        // Make sure the timestretch is non-zero.
        require(timeStretch > uint32(0), "todo nice errors");
        // Make sure the provided bondsIn and amount are non-zero values.
        require(underlyingIn > 0, "todo nice errors");
        // Transfer tokens from the user
        token.transferFrom(msg.sender, address(this), underlyingIn);
        // Make a deposit to the unlocked shares in the term for the user
        // The implied initial share price [ie mu] can be calculated using this
        (uint256 value, uint256 sharesMinted) = term.depositUnlocked(
            underlyingIn,
            0,
            0,
            address(this)
        );
        // We want to store the mu as an 18 point fraction
        uint256 mu = (_normalize(value)).divDown(_normalize(sharesMinted));
        // Initialize the reserves.
        _update(poolId, uint128(0), uint128(sharesMinted));
        // Initialize the oracle if this pool needs one
        if (maxTime > 0 || maxLength > 0) {
            _initializeBuffer(poolId, maxTime, maxLength);
        }
        // Add the timestretch into the mapping corresponds to the poolId.
        parameters[poolId] = SubPoolParameters(timeStretch, uint224(mu));
        // Mint LP tokens to the recipient.
        _mint(poolId, recipient, sharesMinted);
        // Return the minted LP
        return (sharesMinted);
    }

    //----------------------------------------- Trading functionality ------------------------------------------//

    /// @notice Allows the user to buy and sell bonds (ie PT) at an interest rate set by yield space AMM invariant.
    /// @param  poolId Expiration timestamp of the bond (,i.e PT).
    /// @param  amount Represents the amount of asset user wants to send to the pool [token for BUY_PT, bond/PT for SELL_PT]
    /// @param  minAmountOut  Minimum expected returns user is willing to accept if the output is less it will revert.
    /// @param  receiver   Address which receives the output of the trade
    /// @param  isBuy True if the caller intends to buy bonds, false otherwise
    /// @return outputAmount The amount out the receiver gets
    function tradeBonds(
        uint256 poolId,
        uint256 amount,
        uint256 minAmountOut,
        address receiver,
        bool isBuy
    ) external returns (uint256 outputAmount) {
        // No trade after expiration
        require(poolId > block.timestamp, "Todo nice time error");

        // Read the cached reserves for the unlocked shares and bonds ,i.e. PT.
        Reserve memory cachedReserve = reserves[poolId];
        // Should check for the support with the pool.
        require(
            cachedReserve.shares != uint128(0) ||
                cachedReserve.bonds != uint128(0),
            "todo nice init error"
        );

        uint256 newShareReserve;
        uint256 newBondReserve;
        // Switch on buy vs sell case
        if (isBuy) {
            (newShareReserve, newBondReserve, outputAmount) = _buyBonds(
                poolId,
                amount,
                cachedReserve,
                receiver
            );
        } else {
            (newShareReserve, newBondReserve, outputAmount) = _sellBonds(
                poolId,
                amount,
                cachedReserve,
                receiver
            );
        }

        // Minimum amount check.
        require(outputAmount >= minAmountOut, "todo nice errors");

        // Updated reserves.
        _update(poolId, uint128(newBondReserve), uint128(newShareReserve));

        // Emit event for the offchain services.
        emit BondsTraded(poolId, receiver, isBuy, amount, outputAmount);
    }

    /// @notice Allows directly purchasing the yield token by having the AMM virtually sell PT
    ///         and locking shares to fulfill that trade.
    /// @param  poolId Expiration timestamp of the bond (,i.e PT) correspond to which YT got minted.
    /// @param  amount The number of PT to sell and the number of YT to expect out
    /// @param  recipient Destination at which newly minted YTs got transferred.
    /// @param  maxInput Maximum amount of underlying buyer wants to spend on this trade.
    function purchaseYt(
        uint256 poolId,
        uint256 amount,
        address recipient,
        uint256 maxInput
    ) external {
        // No trade after expiration
        require(poolId > block.timestamp, "Todo nice time error");
        // Load reserves
        Reserve memory cachedReserve = reserves[poolId];
        // Should check for the support with the pool.
        require(
            cachedReserve.shares != uint128(0) ||
                cachedReserve.bonds != uint128(0),
            "todo nice init error"
        );

        // Load the current price per share
        uint256 pricePerShare = term.unlockedSharePrice();

        // First we calculate how many shares would be outputted from selling 'amount' of PT
        (
            uint256 newShareReserve,
            uint256 newBondReserve,
            uint256 outputShares
        ) = _quoteSaleAndFees(poolId, amount, cachedReserve, pricePerShare);

        // Then we see how many underlying this would be worth, which is how many
        // PT would be minted if it was deposited
        uint256 saleUnderlying = (outputShares * pricePerShare) / _one;
        // Because of fees and slippage 'saleUnderlying' is not enough to mint PT for the user
        // they must pay the differential
        uint256 underlyingOwed = amount - saleUnderlying;
        // We check this is not more than the user slippage bound
        require(underlyingOwed <= maxInput, "todo: nice slippage error");
        // We transfer this amount from the user
        token.transferFrom(msg.sender, address(this), underlyingOwed);

        // Now to give the user their PT we create it from the unlocked shares in the pool
        // and from the amount sent from the user.
        uint256[] memory ids = new uint256[](1);
        ids[0] = _UNLOCKED_TERM_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = outputShares;
        (uint256 pt, uint256 yt) = term.lock(
            ids,
            amounts,
            underlyingOwed,
            false,
            // The caller's recipient gets the yield tokens and the amm gets the PT
            recipient,
            address(this),
            block.timestamp,
            poolId
        );
        // Make sure that the generated PTs are equal to
        /// TODO: The rounding errors might make this check fail
        require(pt == amount, "todo nice error");
        // Updated reserves.
        _update(poolId, uint128(newBondReserve), uint128(newShareReserve));
        // Todo update oracle
        emit YtPurchased(poolId, recipient, yt, underlyingOwed);
    }

    //----------------------------------------- Governance functionality ------------------------------------------//

    /// @notice Update the `tradeFee` using the governance contract.
    function updateTradeFee(uint128 newTradeFee) external onlyOwner {
        // change the state
        tradeFee = newTradeFee;
    }

    /// @notice Update the `governanceFeePercent` using the governance contract.
    function updateGovernanceFeePercent(uint128 newFeePercent)
        external
        onlyOwner
    {
        // change the state
        governanceFeePercent = newFeePercent;
    }

    /// @notice Governance can authorize an address to collect fees from the pools
    /// @param poolId The pool to collect the fees from
    /// @param destination The address to send the fees too
    function collectFees(uint256 poolId, address destination)
        external
        onlyAuthorized
    {
        // Load the fees for this pool
        CollectedFees memory fees = governanceFees[poolId];
        // Send the fees out to the destination
        // Note - the pool id for LP is the same as the PT id in term
        term.transferFrom(
            poolId,
            address(this),
            destination,
            uint256(fees.feesInBonds)
        );
        // Send shares out, we choose to not unwrap them so governance can
        // earn interest and unwrap many at once
        term.transferFrom(
            _UNLOCKED_TERM_ID,
            address(this),
            destination,
            uint256(fees.feesInShares)
        );
        // Reset the fees to be zero
        governanceFees[poolId] = CollectedFees(0, 0);
    }

    //----------------------------------------- Internal functionality ------------------------------------------//

    /// @dev Transfers from user, deposits into yield source, calculates trade, then
    ///      sends the output bonds to the user. Takes a fee on implied interest and gives
    ///      a percent of it to gov.
    /// @param  poolId The pool id for the trade
    /// @param  amount Amount of underlying asset (or base asset) provided to purchase the bonds.
    /// @param  cachedReserve Cached reserve at the time of trade.
    /// @param  receiver The address which gets the bonds
    /// @return The state of the reserve of shares after the trade
    /// @return The state of the bond reserve after the trade.
    /// @return The amount sent to the caller
    function _buyBonds(
        uint256 poolId,
        uint256 amount,
        Reserve memory cachedReserve,
        address receiver
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Transfer the funds to the contract
        token.transferFrom(msg.sender, address(this), amount);

        // We deposit into the unlocked position of the term in order to calculate
        // the price per share and therefore implied interest rate.
        // NOTE - valuePaid != amount because it's possible to pre-fund the deposit
        //        by transferring to the term contract.
        (uint256 valuePaid, uint256 addedShares) = term.depositUnlocked(
            amount,
            0,
            0,
            address(this)
        );

        // Calculate the normalized price per share
        uint256 normalizedPricePerShare = (_normalize(valuePaid)).divDown(
            _normalize(addedShares)
        );
        // Calculate the amount of bond tokens.
        uint256 changeInBonds = _tradeCalculation(
            poolId,
            _normalize(addedShares),
            _normalize(uint256(cachedReserve.shares)),
            _normalize(uint256(cachedReserve.bonds)),
            normalizedPricePerShare,
            true
        );

        // Calculate the implied yield fee as the interest earned
        uint256 impliedInterest = changeInBonds - valuePaid;
        // Get the fee for the LP
        // Note - Fee percent are stored as 18 point fractions
        uint256 totalFee = (impliedInterest * tradeFee) / FixedPointMath.ONE_18;
        // Calculate shares to gov
        uint256 govFee = (totalFee * governanceFeePercent) /
            FixedPointMath.ONE_18;
        // Set into state the fees paid
        governanceFees[poolId].feesInBonds += uint128(govFee);

        // Do the actual bond transfer
        term.transferFrom(
            poolId,
            address(this),
            receiver,
            changeInBonds - totalFee
        );

        // Calculate the new reserves
        // The new share reserve is the added shares plus current and
        uint256 newShareReserve = cachedReserve.shares + addedShares;
        // the new bonds reserve is the current - change + (totalFee - govFee)
        uint256 newBondReserve = cachedReserve.bonds -
            changeInBonds +
            (totalFee - govFee);

        // Update oracle
        _updateOracle(poolId, newShareReserve, newBondReserve);

        // The trade output is changeInBonds - total fee
        // Returns the new reserves and the trade output
        return (newShareReserve, newBondReserve, changeInBonds - totalFee);
    }

    /// @dev Facilitate the sell of bond tokens. Transfer from the user and then withdraw
    ///      the produced shares to their address
    /// @param  poolId The id for the pool which the trade is made in
    /// @param  amount Amount of bonds tokens user wants to sell in given trade.
    /// @param  cachedReserve Cached reserve at the time of trade.
    /// @param  receiver Address which would receive the underlying token.
    /// @return The share reserve after trade, the bond reserve after trade and shares output
    function _sellBonds(
        uint256 poolId,
        uint256 amount,
        Reserve memory cachedReserve,
        address receiver
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Transfer the bonds to the contract
        IMultiToken(address(term)).transferFrom(
            poolId,
            msg.sender,
            address(this),
            amount
        );
        // Load the unlocked price per share [ie c in modified yield space]
        uint256 pricePerShare = term.unlockedSharePrice();

        // Calls an internal function which quotes a sale and updates fees
        (
            uint256 newShareReserve,
            uint256 newBondReserve,
            uint256 outputShares
        ) = _quoteSaleAndFees(poolId, amount, cachedReserve, pricePerShare);

        // Updates the oracle
        _updateOracle(poolId, newShareReserve, newBondReserve);

        // The user amount is outputShares - shareFee and we withdraw to them
        // Create the arrays for a withdraw from term
        uint256[] memory ids = new uint256[](1);
        ids[0] = _UNLOCKED_TERM_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = outputShares;
        // Do the withdraw to user account
        uint256 valueSent = term.unlock(receiver, ids, amounts);

        return (newShareReserve, newBondReserve, valueSent);
    }

    /// @notice Helper function to calculate sale and fees for a sell, plus update the fee state.
    /// @dev Unlike the buy flow we use this logic in both 'buyYt' and '_sellBonds' and so abstract
    ///      it into a function.
    ///      WARN - Do not allow calling this function outside the context of a trade
    /// @param  poolId Pool Id supported for the trade.
    /// @param  amount Amount of bonds tokens user wants to sell in given trade.
    /// @param  cachedReserve Cached reserve at the time of trade.
    /// @param  pricePerShare The the ratio which converts shares to underlying
    /// @return (the new share reserve, the new bond reserve, shares produced)
    function _quoteSaleAndFees(
        uint256 poolId,
        uint256 amount,
        Reserve memory cachedReserve,
        uint256 pricePerShare
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Calculate the amount of bond tokens which are produced
        uint256 outputShares = _tradeCalculation(
            poolId,
            _normalize(amount),
            _normalize(uint256(cachedReserve.shares)),
            _normalize(uint256(cachedReserve.bonds)),
            _normalize(pricePerShare),
            false
        );

        // Charge a fee on the implied interest rate
        // First convert the shares to underlying value
        uint256 shareValue = (outputShares * pricePerShare) / _one;
        // Now the implied interest is the difference between shareValue
        // and bond face value
        uint256 impliedInterest = amount - shareValue;
        // Calculate total fee with the multiplier which is an 18 point fraction
        uint256 fee = (impliedInterest * uint256(tradeFee)) /
            FixedPointMath.ONE_18;
        // The fee in shares is the percent of share value that is fee times shares
        uint256 shareFee = (shareValue * fee) / shareValue;
        // The governance percent is the this times by the 18 point governance percent
        // fraction
        uint256 governanceFee = (shareFee * uint256(governanceFeePercent)) /
            FixedPointMath.ONE_18;
        // Change the state to account for this fee
        // WARN - Do not allow calling this function outside the context of a trade
        governanceFees[poolId].feesInShares += uint128(governanceFee);
        // The LP fee is the difference between what's paid in total and what's paid to gov
        uint256 lpFee = shareFee - governanceFee;

        // The updated share reserve is the current reserve minus the output plus the lp fee.
        // The new bond reserve is the current plus input.
        // Amount out is the amount the user got
        return (
            uint256(cachedReserve.shares) - outputShares + lpFee,
            uint256(cachedReserve.bonds) + amount,
            outputShares - shareFee
        );
    }

    /// @dev Update the reserves after the trade or whenever the LP is minted.
    /// @param  poolId The pool id of the pool's reserves to be updated
    /// @param  newBondBalance current holdings of the bond tokens,i.e. PTs of the contract.
    /// @param  newSharesBalance current holding of the shares tokens by the contract.
    function _update(
        uint256 poolId,
        uint128 newBondBalance,
        uint128 newSharesBalance
    ) internal {
        // Update the reserves.
        reserves[poolId].bonds = newBondBalance;
        reserves[poolId].shares = newSharesBalance;
        emit Sync(poolId, newBondBalance, newSharesBalance);
    }

    /// @dev Updates the oracle and calculates the correct ratio
    /// @param poolId the ID of which pool's oracle to update
    /// @param newShareReserve the new share reserve
    /// @param newBondReserve the new bond reserve
    function _updateOracle(
        uint256 poolId,
        uint256 newShareReserve,
        uint256 newBondReserve
    ) internal {
        // NOTE - While the oracle prevent updates to un-initialized buffers this logic makes several sloads
        //        so by checking the initialization before calling into the oracle we optimize for gas.
        if (_buffers[poolId].length != 0) {
            // normalize Shares
            uint256 normalizedShare = _normalize(newShareReserve);
            // Load mu, will be stored normalized so no need to update
            uint256 mu = uint256(parameters[poolId].mu);
            uint256 muTimesShares = mu.mulDown(normalizedShare);
            // Note - The additional total supply factor from the yield space paper, it redistributes
            //        the liquidity from the inaccessible part of the curve.
            uint256 adjustedNormalizedBonds = _normalize(newBondReserve) +
                _normalize(totalSupply[poolId]);
            // The pool ratio is (bonds)/(mu * shares)
            uint256 oracleRatio = adjustedNormalizedBonds.divDown(
                muTimesShares
            );

            _updateBuffer(poolId, uint224(oracleRatio));
        }
    }

    /// @dev In this function all inputs should be _normalized and the output will
    ///      be 18 point
    /// @param expiry the expiration time == pool ID for lp pool
    /// @param input Token or shares in terms of the decimals of the token
    /// @param shareReserve Shares currently help in terms of decimals of the token
    /// @param bondReserve Bonds (PT) held by the pool in terms of the token
    /// @param pricePerShare The output token for each input of a share
    /// @param isBondOut true if the input is shares, false if the input is bonds
    function _tradeCalculation(
        uint256 expiry,
        uint256 input,
        uint256 shareReserve,
        uint256 bondReserve,
        uint256 pricePerShare,
        bool isBondOut
    ) internal view returns (uint256) {
        // Load the mu and time stretch
        SubPoolParameters memory params = parameters[expiry];
        // Normalize the seconds till expiry into 18 point
        uint256 timeToExpiry = (expiry - block.timestamp) *
            FixedPointMath.ONE_18;
        // Express this as a fraction of seconds in year
        timeToExpiry = timeToExpiry / (_ONE_YEAR);
        // Get an 18 point fraction of 1/(time stretch)
        // Note - Because params.timestretch is in 3 point decimal
        //        we have to divide that out in the constant (10^18 * 10^3 = 10^21)
        uint256 timestretch = 1e21 / uint256(params.timestretch);
        // Calculate the total supply, and _normalize
        uint256 totalSupply = _normalize(totalSupply[expiry]);
        uint256 mu = uint256(params.mu);
        // We adjust the bond reserve by a factor of totalSupply*mu
        // This reserve adjustment works by increasing liquidity which interest rates are positive
        // so that when the reserve has zero bonds on (on init) the curve thinks it has equal bonds and
        // underlying.
        uint256 totalSupplyTimesMu = totalSupply.mulDown(mu);

        // Call our internal price library
        uint256 result = YieldSpaceMath.calculateOutGivenIn(
            shareReserve,
            bondReserve,
            totalSupplyTimesMu,
            input,
            timeToExpiry,
            timestretch,
            pricePerShare,
            mu,
            isBondOut
        );

        // Return the output
        return _denormalize(result);
    }

    function _normalize(uint256 input) internal view returns (uint256) {
        if (decimals < 18) {
            unchecked {
                uint256 adjustFactor = 10**(18 - decimals);
                return input * adjustFactor;
            }
        } else {
            return input;
        }
    }

    function _denormalize(uint256 input) internal view returns (uint256) {
        if (decimals < 18) {
            unchecked {
                uint256 adjustFactor = 10**(18 - decimals);
                return input / adjustFactor;
            }
        } else {
            return input;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./MultiToken.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITerm.sol";
import "./interfaces/IYieldAdapter.sol";

// LP is a multitoken [ie fake 1155] contract which accepts deposits and withdraws
// from the AMM.
contract LP is MultiToken {
    // The token standard indexes each token by an ID which for these LP
    // tokens will be the expiration time of the token which matures.
    // Deposits input the underlying asset and a proportion will be locked
    // till expiry to match the current ratio of the pool

    // Holds the reserve amounts in a gas friendly way
    struct Reserve {
        uint128 shares;
        uint128 bonds;
    }

    // Maps pool ID to the reserves for that term
    mapping(uint256 => Reserve) public reserves;
    // The term address cannot be changed after deploy.
    // All funds are held in the term contract.
    ITerm public immutable term;
    // The underlying token on which yield is earned
    IERC20 public immutable token;
    uint8 public immutable decimals;
    // one expressed in the native token math
    uint256 internal immutable _one;

    // The id for the unlocked deposit into the term, this is YT at expiry and start time 0
    uint256 internal constant _UNLOCKED_TERM_ID = 1 << 255;

    /// @notice Runs the initial deployment code
    /// @param _token The token which is deposited into this contract
    /// @param _term The term which locks and earns yield on token
    /// @param _linkerCodeHash The hash of the erc20 linker contract deploy code
    /// @param _factory The factory which is used to deploy the linking contracts
    constructor(
        IERC20 _token,
        ITerm _term,
        bytes32 _linkerCodeHash,
        address _factory
    ) MultiToken(_linkerCodeHash, _factory) {
        token = _token;
        uint8 _decimals = _token.decimals();
        decimals = _decimals;
        _one = 10**_decimals;
        term = _term;
    }

    /// @notice Accepts a deposit from an LP in terms of the underlying and deposit it into the yield
    ///         source then locks the correct proportion to match pool. The YT from the locked amount
    ///         is credited to the user. This is the main user friendly way of depositing.
    /// @param amount The amount of underlying tokens to deposit
    /// @param poolId The identifier of the LP pool to deposit into, in this version it's expiration time.
    /// @param destination The destination which gets credited with LP token.
    /// @param minOutput The call will revert if the caller does not receive at least this many LP token.
    /// @return The shares created.
    function depositUnderlying(
        uint256 amount,
        uint256 poolId,
        address destination,
        uint256 minOutput
    ) external returns (uint256) {
        // No minting after expiration
        require(poolId > block.timestamp, "Todo nice time error");
        // Transfer from the user
        token.transferFrom(msg.sender, address(this), amount);
        // We deposit into the unlocked position of the term in order to calculate
        // the price per share and therefore implied interest rate.
        // This is the step that deposits all value provided into the yield source
        // Note - we need a pointless storage to memory to convince the solidity type checker
        // to understand the type of []
        (uint256 valueDeposited, uint256 depositedShares) = term
            .depositUnlocked(amount, 0, 0, address(this));

        // Calculate the implicit price per share
        uint256 pricePerShare = (valueDeposited * _one) / depositedShares;
        // Call internal function to mint new lp from the new shares held by this contract
        uint256 newLpToken = _depositFromShares(
            poolId,
            uint256(reserves[poolId].shares),
            uint256(reserves[poolId].bonds),
            depositedShares,
            pricePerShare,
            destination
        );
        // Check enough has been made and return that amount
        require(newLpToken >= minOutput, "Todo nice errors");
        return (newLpToken);
    }

    /// @notice Allows a user to deposit an equal amount of bonds and yielding shares to match reserves.
    ///         Naturally unfriendly and should be called in weiroll bundle.
    /// @param poolId The identifier of the LP pool to deposit into, in this version it's expiration time.
    /// @param bondsDeposited The number of principal tokens deposited, this will set the ratio and
    ///                    the correct reserve matching percent of shares will be transferred from the user
    /// @param destination The address which will be credited with shares
    /// @param minLpOut This call will revert if the LP produced is not at least this much
    /// @return The shares created.
    function depositBonds(
        uint256 poolId,
        uint256 bondsDeposited,
        address destination,
        uint256 minLpOut
    ) external returns (uint256) {
        // No minting after expiration
        require(poolId > block.timestamp, "Todo nice time error");
        // Load the pool details
        uint256 loadedShares = uint256(reserves[poolId].shares);
        uint256 loadedBonds = uint256(reserves[poolId].bonds);
        // Transfer the pt from the user
        term.transferFrom(poolId, msg.sender, address(this), bondsDeposited);
        // Calculate ratio of the shares needed
        uint256 sharesNeeded = (loadedShares * bondsDeposited) / loadedBonds;
        // Transfer shares from user
        term.transferFrom(
            _UNLOCKED_TERM_ID,
            msg.sender,
            address(this),
            sharesNeeded
        );
        // Calculate Lp
        uint256 lpCreated = (totalSupply[poolId] * bondsDeposited) /
            loadedBonds;
        // Mint LP
        _mint(poolId, destination, lpCreated);
        // Update the reserve state
        reserves[poolId].shares = uint128(loadedShares + sharesNeeded);
        reserves[poolId].bonds = uint128(loadedBonds + bondsDeposited);
        // Check enough has been made and return that amount
        require(lpCreated >= minLpOut, "Todo nice errors");
        return (lpCreated);
    }

    /// @notice Withdraws LP from the pool, resulting in either a proportional withdraw before expiration
    ///         or a withdraw of only underlying afterwards.
    /// @param poolId The id of the LP token to withdraw
    /// @param amount The number of LP tokens to remove
    /// @param destination The address to credit the underlying to.
    function withdraw(
        uint256 poolId,
        uint256 amount,
        address destination
    ) external {
        // Burn lp token and free assets. Will also finalize the pool and so return
        // zero for the userBonds if it's after expiry time.
        (uint256 userShares, uint256 userBonds) = _withdrawToShares(
            poolId,
            amount,
            msg.sender
        );

        // We've turned the LP into constituent assets and so now we transfer them to the user
        // By withdrawing shares and then (optionally) transferring PT to them

        // Create the arrays for a withdraw from term
        uint256[] memory ids = new uint256[](1);
        ids[0] = _UNLOCKED_TERM_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = userShares;
        // Do the withdraw to user account
        term.unlock(destination, ids, amounts);

        // Now if there are also bonds [ie if the pool is not yet expired we transfer to the user]
        if (userBonds != 0) {
            // We transfer directly to them
            term.transferFrom(poolId, address(this), msg.sender, userBonds);
        }
    }

    /// @notice Allows a user to withdraw from an expired term and then deposit into a new _one in _one transaction
    /// @param fromPoolId The identifier of the LP token which will be burned by this call
    /// @param toPoolId The identifier of the to LP token which will be created by this call
    /// @param amount The number of LP tokens to burn from the user
    /// @param destination The address which will be credited with the output
    /// @param minOutput The minimum number of new LP tokens created, otherwise will revert.
    /// @return The number of LP token created
    function rollover(
        uint256 fromPoolId,
        uint256 toPoolId,
        uint256 amount,
        address destination,
        uint256 minOutput
    ) external returns (uint256) {
        // Only expired bonds can be rolled over
        require(
            fromPoolId < block.timestamp && toPoolId > block.timestamp,
            "Todo nice time error"
        );
        // Burn lp token and free assets. Will also finalize the pool and so return
        // zero for the userBonds if it's after expiry time.
        (uint256 userShares, ) = _withdrawToShares(
            fromPoolId,
            amount,
            msg.sender
        );
        // In this case we have no price per share information so we must ask the pool for it
        uint256 pricePerShare = term.unlockedSharePrice();
        // Now the freed shares are deposited
        uint256 newLpToken = _depositFromShares(
            toPoolId,
            uint256(reserves[toPoolId].shares),
            uint256(reserves[toPoolId].bonds),
            userShares,
            pricePerShare,
            destination
        );
        // Require that the output matches user expectations
        require(newLpToken >= minOutput, "Todo nice expectation error");
        return (newLpToken);
    }

    /// @notice Should be called after a user has yielding shares from the term and needs to put them into
    ///         a term, such as when they rollover or when they deposit single sided.
    /// @param poolId The pool the user is depositing into
    /// @param currentShares The number of shares in the LP pool which is deposited to
    /// @param currentBonds The number of bonds in the LP pool which is deposited to
    /// @param depositedShares The number of yielding shares which the user has deposited
    /// @param pricePerShare A multiplier which converts yielding shares to their net value.
    /// @param to The address to credit the LP token to.
    /// @return The number of LP tokens created by this action
    function _depositFromShares(
        uint256 poolId,
        uint256 currentShares,
        uint256 currentBonds,
        uint256 depositedShares,
        uint256 pricePerShare,
        address to
    ) internal returns (uint256) {
        // Must be initialized
        // NOTE - There's a strong requirement for trades to not be able to move the pool to
        //        have a reserve of exactly 0 in either asset
        require(
            currentShares != 0 && currentBonds != 0,
            "todo nice initialization error"
        );
        // No deposits after expiry
        require(poolId > block.timestamp, "Todo nice time error");
        // Calculate total reserve with conversion to underlying units
        // IE: amount_bonds + amountShares*underlyingPerShare
        uint256 totalValue = currentShares * pricePerShare + currentBonds;
        // Calculate the needed bonds as a percent of the value
        uint256 depositedAmount = (depositedShares * pricePerShare) / _one;
        uint256 neededBonds = (depositedAmount * currentBonds) / totalValue;
        // The bond value is in terms of purely the underlying so to figure out how many shares we lock
        // we divide it by our price per share to convert to share value and convert it to 18 point
        uint256 sharesToLock = (neededBonds * _one) / pricePerShare;
        //  Lock shares to PTs while sending the resulting YT to the user

        // Note need to declare dynamic memory types in this way even with _one element
        uint256[] memory ids = new uint256[](1);
        ids[0] = _UNLOCKED_TERM_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = sharesToLock;
        // then make the call
        term.lock(
            ids,
            amounts,
            0,
            false,
            to,
            address(this),
            block.timestamp,
            // Note Pools Ids come from their PT expiry time
            poolId
        );

        // Mint new LP in equal proportion to the increase in shares
        uint256 increaseInShares = depositedShares - sharesToLock;
        uint256 newLpToken = (totalSupply[poolId] * increaseInShares) /
            currentShares;
        _mint(poolId, to, newLpToken);
        // Now we have increased the amount of shares and we have increased the number of bonds an equal proportion
        // So we change their state in storage
        // todo non optimal state use
        reserves[poolId].shares += uint128(increaseInShares);
        reserves[poolId].bonds += uint128(neededBonds);
        // Return the LP produced
        return (newLpToken);
    }

    /// @notice Deletes LP tokens from a user and then returns how many yielding shares and bonds are released
    ///         Will also finalize [meaning convert bonds to shares] a pool if it is expired.
    /// @param poolId The id of the LP token which is deleted from
    /// @param amount The number of LP tokens to remove
    /// @param source The address who's tokens will be deleted.
    /// @return userShares The number of shares and bonds the user should receive
    function _withdrawToShares(
        uint256 poolId,
        uint256 amount,
        address source
    ) internal returns (uint256 userShares, uint256 userBonds) {
        // Load the reserves
        uint256 reserveBonds = uint256(reserves[poolId].bonds);
        uint256 reserveShares = uint256(reserves[poolId].shares);

        // Two different cases, either the pool is expired and the user can get out the underlying
        // or the pool is not expired and the user can withdraw only bonds and underlying
        // So if the pool is expired and has not withdrawn then we must withdraw
        // Leverage that the poolId == expiration
        if (block.timestamp >= poolId && reserveBonds != 0) {
            // Create new unlocked shares from the expired PT
            (, uint256 sharesCreated) = term.depositUnlocked(
                0,
                reserveBonds,
                poolId,
                address(this)
            );
            // Now we update the cached reserves
            reserveBonds = 0;
            reserveShares += sharesCreated;
        }

        // Cache the total supply for withdraws
        uint256 cachedTotalSupply = totalSupply[poolId];
        // We burn here prevent some edge case chance of reentrancy
        _burn(poolId, source, amount);

        // Calculate share percent
        userShares = (amount * reserveShares) / cachedTotalSupply;
        // Update the cached reserves
        reserveShares -= userShares;

        // The user gets out a pure percent of the total supply
        userBonds = (amount * reserveBonds) / cachedTotalSupply;
        // Update the cached reserves
        reserveBonds -= userBonds;

        // Finally we update the state about this pool
        reserves[poolId].bonds = uint128(reserveBonds);
        reserves[poolId].shares = uint128(reserveShares);
    }
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "contracts/libraries/Errors.sol";

/// @notice A fixed-point math library.
/// @author Element Finance
library FixedPointMath {
    int256 internal constant _ONE_18 = 1e18;
    uint256 public constant ONE_18 = 1e18;

    /// @dev Credit to Balancer (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol)
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    /// @dev Credit to Balancer (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol)
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    /// @dev Credit to Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(d != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(d)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the d.
            z := div(z, d)
        }
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (mulDivDown(a, b, 1e18));
    }

    /// @dev Credit to Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(d != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(d)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the d and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), d), 1))
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (mulDivDown(a, 1e18, b)); // Equivalent to (a * 1e18) / b rounded down.
    }

    /// @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
    /// @dev Partially inspired by Balancer LogExpMath library (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol)
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        // Using properties of logarithms we calculate x^y:
        // -> ln(x^y) = y * ln(x)
        // -> e^(y * ln(x)) = x^y

        int256 y_int256 = int256(y);

        // Compute y*ln(x)
        // Any overflow for x will be caught in _ln() in the initial bounds check
        int256 lnx = _ln(int256(x));
        int256 ylnx;
        assembly {
            ylnx := mul(y_int256, lnx)
        }
        ylnx /= _ONE_18;

        // Calculate exp(y * ln(x)) to get x^y
        return uint256(exp(ylnx));
    }

    // Computes e^x in 1e18 fixed point.
    // Credit to Remco (https://github.com/recmo/experiment-solexp/blob/main/src/FixedPointMathLib.sol)
    function exp(int256 x) internal pure returns (int256 r) {
        unchecked {
            // Input x is in fixed point format, with scale factor 1/1e18.

            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) {
                return 0;
            }

            // When the result is > (2**255 - 1) / 1e18 we can not represent it
            // as an int256. This happens when x >= floor(log((2**255 -1) / 1e18) * 1e18) ~ 135.
            _require(x < 135305999368893231589, Errors.INVALID_EXPONENT);

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers of two
            // such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >>
                96;
            x = x - k * 54916777467707473351141471128;
            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation
            // p is made monic, we will multiply by a scale factor later
            int256 p = x + 2772001395605857295435445496992;
            p = ((p * x) >> 96) + 44335888930127919016834873520032;
            p = ((p * x) >> 96) + 398888492587501845352592340339721;
            p = ((p * x) >> 96) + 1993839819670624470859228494792842;
            p = p * x + (4385272521454847904659076985693276 << 96);
            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // Evaluate using using Knuth's scheme from p. 491.
            int256 z = x + 750530180792738023273180420736;
            z = ((z * x) >> 96) + 32788456221302202726307501949080;
            int256 w = x - 2218138959503481824038194425854;
            w = ((w * z) >> 96) + 892943633302991980437332862907700;
            int256 q = z + w - 78174809823045304726920794422040;
            q = ((q * w) >> 96) + 4203224763890128580604056984195872;
            assembly {
                // Div in assembly because solidity adds a zero check despite the `unchecked`.
                // The q polynomial is known not to have zeros in the domain. (All roots are complex)
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }
            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by
            //  * the scale factor s = ~6.031367120...,
            //  * the 2**k factor from the range reduction, and
            //  * the 1e18 / 2**96 factor for base conversion.
            // We do all of this at once, with an intermediate result in 2**213 basis
            // so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) *
                    3822833074963236453042738258902158003155416615667) >>
                    uint256(195 - k)
            );
        }
    }

    /// @dev Computes ln(x) in 1e18 fixed point.
    /// @dev Reverts if x is negative
    /// @dev Credit to Remco (https://github.com/recmo/experiment-solexp/blob/main/src/FixedPointMathLib.sol)
    function ln(int256 x) internal pure returns (int256) {
        _require(x > 0, Errors.X_OUT_OF_BOUNDS);
        return _ln(x);
    }

    // Reverts if x is negative, but we allow ln(0)=0
    function _ln(int256 x) private pure returns (int256 r) {
        unchecked {
            // Intentionally allowing ln(0) to pass bc the function will return 0
            // to pow() so that pow(0,1)=0 without a branch
            _require(x >= 0, Errors.X_OUT_OF_BOUNDS);

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18.
            // But since ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            // Note: inlining ilog2 saves 8 gas.
            int256 k = int256(_ilog2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation
            // p is made monic, we will multiply by a scale factor later
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);
            //emit log_named_int("p", p);
            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the `unchecked`.
                // The q polynomial is known not to have zeros in the domain. (All roots are complex)
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }
            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78
            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r +=
                16597577552685614221487285958193947469193820559219878177908093499208371 *
                k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    // Integer log2
    // @returns floor(log2(x)) if x is nonzero, otherwise 0. This is the same
    //          as the location of the highest set bit.
    // Credit to Remco (https://github.com/recmo/experiment-solexp/blob/main/src/FixedPointMathLib.sol)
    function _ilog2(uint256 x) private pure returns (uint256 r) {
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "contracts/libraries/Errors.sol";
import "contracts/libraries/FixedPointMath.sol";

/// @notice YieldSpace math library.
/// @author Element Finance
library YieldSpaceMath {
    using FixedPointMath for uint256;

    /// Calculates the amount of bond a user would get for given amount of shares.
    /// @param shareReserves yield bearing vault shares reserve amount, unit is shares
    /// @param bondReserves bond reserves amount, unit is the face value in underlying
    /// @param bondReserveAdjustment An optional adjustment to the reserve which MUST have units of underlying.
    /// @param amountIn amount to be traded, if bonds in the unit is underlying, if shares in the unit is shares
    /// @param t time till maturity in seconds
    /// @param s time stretch coefficient.  e.g. 25 years in seconds
    /// @param c price of shares in terms of their base
    /// @param mu Normalization factor -- starts as c at initialization
    /// @param isBondOut determines if the output is bond or shares
    /// @return result the amount of shares a user would get for given amount of bond
    function calculateOutGivenIn(
        uint256 shareReserves,
        uint256 bondReserves,
        uint256 bondReserveAdjustment,
        uint256 amountIn,
        uint256 t,
        uint256 s,
        uint256 c,
        uint256 mu,
        bool isBondOut
    ) internal pure returns (uint256 result) {
        uint256 outReserves;
        uint256 rhs;
        // Notes: 1 >= 1-st >= 0
        uint256 oneMinusT = FixedPointMath.ONE_18.sub(s.mulDown(t));
        // c/mu
        uint256 cDivMu = c.divDown(mu);
        // Adjust the bond reserve, optionally shifts the curve around the inflection point
        uint256 modifiedBondReserves = bondReserves.add(bondReserveAdjustment);
        // c/mu * (mu*shareReserves)^(1-t) + bondReserves^(1-t)
        uint256 k = cDivMu
            .mulDown(mu.mulDown(shareReserves).pow(oneMinusT))
            .add(modifiedBondReserves.pow(oneMinusT));

        if (isBondOut) {
            // bondOut = bondReserves - ( c/mu * (mu*shareReserves)^(1-t) + bondReserves^(1-t) - c/mu * (mu*(shareReserves + shareIn))^(1-t) )^(1 / (1 - t))
            outReserves = modifiedBondReserves;
            // (mu*(shareReserves + amountIn))^(1-t)
            uint256 newScaledShareReserves = mu
                .mulDown(shareReserves.add(amountIn))
                .pow(oneMinusT);
            // c/mu * (mu*(shareReserves + amountIn))^(1-t)
            newScaledShareReserves = cDivMu.mulDown(newScaledShareReserves);
            // Notes: k - newScaledShareReserves >= 0 to avoid a complex number
            // ( c/mu * (mu*shareReserves)^(1-t) + bondReserves^(1-t) - c/mu * (mu*(shareReserves + amountIn))^(1-t) )^(1 / (1 - t))
            rhs = k.sub(newScaledShareReserves).pow(
                FixedPointMath.ONE_18.divDown(oneMinusT)
            );
        } else {
            // shareOut = shareReserves - [ ( c/mu * (mu * shareReserves)^(1-t) + bondReserves^(1-t) - (bondReserves + bondIn)^(1-t) ) / c/u  ]^(1 / (1 - t)) / mu
            outReserves = shareReserves;
            // (bondReserves + bondIn)^(1-t)
            uint256 newScaledBondReserves = modifiedBondReserves
                .add(amountIn)
                .pow(oneMinusT);
            // Notes: k - newScaledBondReserves >= 0 to avoid a complex number
            // [( (mu * shareReserves)^(1-t) + bondReserves^(1-t) - (bondReserves + bondIn)^(1-t) ) / c/u ]^(1 / (1 - t))
            rhs = k.sub(newScaledBondReserves).divDown(cDivMu).pow(
                FixedPointMath.ONE_18.divDown(oneMinusT)
            );
            // [( (mu * shareReserves)^(1-t) + bondReserves^(1-t) - (bondReserves + bondIn)^(1-t) ) / c/u ]^(1 / (1 - t)) / mu
            rhs = rhs.divDown(mu);
        }
        // Notes: outReserves - rhs >= 0, but i think avoiding a complex number in the step above ensures this never happens
        result = outReserves.sub(rhs);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

/// @notice A Time Weighted Average Rate Oracle to calculate the value over a given time period.
/// @dev Stores values in customizable circular buffers.  Values are stored as the cumulative sum
/// where cumSum = value * timeDelta + prevCumSum.  The time delta is the time that has elapsed
/// since the previous update.
contract TWAROracle {
    mapping(uint256 => uint256[]) internal _buffers;

    event UpdateBuffer(uint256 value, uint256 metadata);

    /// @dev An initialization function for the buffer.  During initialization, the maxLength is
    /// set to the value passed in, minTimeStep and timeStamp are set to values for the current block.
    /// 0 when the first item is added.
    /// @param bufferId The ID of the buffer to initialize.
    /// @param maxTime The maximum time in seconds the buffer will provide history for.  This cannot
    /// be unset.
    /// @param maxLength The maximum number of items in the buffer.  This cannot be unset.
    function _initializeBuffer(
        uint256 bufferId,
        uint16 maxTime,
        uint16 maxLength
    ) internal {
        // maxLength of zero indicates a buffer has not been initialized.  Upper value for
        // maxLength checked by the fact that it is uint16.
        require(maxLength > 1, "min length is 1");

        (, , , uint16 _maxLength, ) = readMetadataParsed(bufferId);
        require(_maxLength == 0, "buffer already initialized");

        // The minimum time required to pass before an update will be made to a buffer.
        uint32 minTimeStep = uint32(maxTime) / uint32(maxLength);
        // This is more of a sanity check.  Note that minimum time steps that are less time than a
        // block can lead to dangerous side effects.
        require(minTimeStep >= 1, "minimum time step is 1");

        uint256 metadata = _combineMetadata(
            minTimeStep,
            uint32(block.timestamp),
            0,
            maxLength,
            0
        );

        // Get a reference to the buffer we want to initialize and save the initial metadata.
        uint256[] storage buffer = _buffers[bufferId];
        assembly {
            // length is stored at position 0 for dynamic arrays
            // we are overloading this to store metadata to be more efficient
            sstore(buffer.slot, metadata)
        }
    }

    /// @dev Gets the parsed metadata for the buffer which includes headIndex, maxLength and
    /// bufferLength.
    /// @param bufferId The ID of the buffer to read metadata from.
    /// @return minTimeStep timeStamp headIndex maxLength bufferLength as a tuple of uint16's
    function readMetadataParsed(uint256 bufferId)
        public
        view
        returns (
            uint32 minTimeStep,
            uint32 timeStamp,
            uint16 headIndex,
            uint16 maxLength,
            uint16 bufferLength
        )
    {
        uint256[] storage buffer = _buffers[bufferId];
        uint256 metadata = buffer.length;

        bufferLength = uint16(metadata);
        // 16
        maxLength = uint16(metadata >> 16);
        // 16 + 16
        headIndex = uint16(metadata >> 32);
        // 16 + 16 + 16
        timeStamp = uint32(metadata >> 48);
        // 16 + 16 + 16 + 32
        minTimeStep = uint32(metadata >> 80);
    }

    /// @dev An internal function to update a buffer.  Takes a value, calculates the cumulative
    /// sum, then records it along with the timeStamp in the following manner:
    /// [uint32 timeStamp][uint224 cumulativeSum]
    /// @param bufferId The ID of the buffer to update.
    /// @param value The value to add to the buffer.
    function _updateBuffer(uint256 bufferId, uint224 value) internal {
        (
            uint32 minTimeStep,
            uint32 previousTimeStamp,
            uint16 headIndex,
            uint16 maxLength,
            uint16 bufferLength
        ) = readMetadataParsed(bufferId);

        uint32 timeStep = uint32(block.timestamp) - previousTimeStamp;
        // Fail silently if enough time has not passed.  We don't reject here because we want
        // calling contracts to try to update often without reverting. Also, if the buffer is
        // uninitialized, don't allow updates.
        if (timeStep < minTimeStep || maxLength == 0) {
            return;
        }

        // Grab the previous sum (if available).
        uint224 previousSum;
        uint256[] storage buffer = _buffers[bufferId];
        if (bufferLength != 0) {
            // Cast to uint224 to drop the upper 32 bits that hold the timestamp.
            previousSum = uint224(buffer[headIndex]);
        }

        // The time between now and the previous update.
        uint224 timeDelta = uint224(
            uint32(block.timestamp) - previousTimeStamp
        );

        // cumulative sum = value * time + previous sum
        uint224 cumulativeSum = value * timeDelta + previousSum;

        // Pack the timeStamp and cumulativeSum together.
        uint256 sumAndTimeStamp = (uint256(block.timestamp) << 224) |
            uint256(cumulativeSum);

        // Don't increment headIndex if this is the first value added.
        // Otherwise, increment the index and rollover to zero if we pass maxLength.
        if (bufferLength == 0) {
            headIndex = 0;
        } else {
            headIndex = (headIndex + 1) % maxLength;
        }

        // We continue to increase the buffer length until we hit the max length, at which point
        // the buffer length remains maxed out and the oldest item will be overwritten.
        if (bufferLength < maxLength) {
            bufferLength++;
        }

        uint256 metadata = _combineMetadata(
            minTimeStep,
            uint32(block.timestamp),
            headIndex,
            maxLength,
            bufferLength
        );

        // update the metadata
        assembly {
            // length is stored at position 0 for dynamic arrays.
            // We are overloading this to store metadata for gas savings.
            sstore(buffer.slot, metadata)
        }

        buffer[headIndex] = sumAndTimeStamp;

        emit UpdateBuffer(sumAndTimeStamp, metadata);
    }

    /// @dev A public function to read the timeStamp&sum value from the specified index and buffer.
    /// @param bufferId The ID of the buffer to initialize.
    /// @param index The index to read a value at.
    /// @return timeStamp cumulativeSum 32bit timeStamp and 224bit sum
    function readSumAndTimeStampForPool(uint256 bufferId, uint16 index)
        public
        view
        returns (uint32 timeStamp, uint224 cumulativeSum)
    {
        (, , , , uint16 bufferLength) = readMetadataParsed(bufferId);

        // Because we use the length prop for metadata, we need to specifically check the index.
        require(index < bufferLength, "index out of bounds");

        uint256 value = _buffers[bufferId][index];
        cumulativeSum = uint224(value);
        timeStamp = uint32(value >> 224);
    }

    /// @dev A public function to calculate the average weighted value over a timePeriod between
    /// now and timeInSeconds earlier.  This is accomplished via an iterative approach by working
    /// backwards in time until we find the update who's timeStamp is older than the requested
    /// time, subtracting that previous sum and any partial sum if the requested time falls between
    /// two timestamps in the buffer.
    /// @param bufferId The ID of the buffer to initialize.
    /// @param timeInSeconds Amount of time previous to now to average the value over.
    /// @return averageWeightedValue Value averaged over time range, weighted by time period for
    /// each value.  The time period for each value is the time from the previous update to the
    /// current block's time stamp.
    function calculateAverageWeightedValue(
        uint256 bufferId,
        uint32 timeInSeconds
    ) public view returns (uint256 averageWeightedValue) {
        (
            ,
            ,
            uint16 headIndex,
            uint16 maxLength,
            uint16 bufferLength
        ) = readMetadataParsed(bufferId);

        // We can't calculate the value from just one element since there is no previous timeStamp.
        require(bufferLength > 1, "not enough elements");

        // If the buffer is full, the oldest index is the next index, otherwise its the first
        // element in the array.
        uint16 oldestIndex = bufferLength == maxLength
            ? (headIndex + 1) % maxLength
            : 0;

        // Keep track of these for later calculations.
        uint32 endTime = uint32(block.timestamp);
        uint224 currentSum;

        // The point in time we work back to.
        uint256 requestedTimeStamp = block.timestamp - uint256(timeInSeconds);

        // Get initial values for currentTimeStamp, cumulativeSum and index for the while loop.
        (
            uint32 currentTimeStamp,
            uint224 cumulativeSum
        ) = readSumAndTimeStampForPool(bufferId, headIndex);
        uint16 index = headIndex;

        // Edge case:
        // If the requested time doesn't reach far enough back, then we just return the last value.
        // To get the value we basically undo the cumulative sum:
        // cumulativeSum = value * time + previousSum
        // value = (cumulativeSum - previousSum) / (currentTimeStamp - previousTimeStamp)
        if (requestedTimeStamp > currentTimeStamp) {
            uint16 previousIndex = index == 0 ? maxLength - 1 : index - 1;
            (
                uint32 previousTimeStamp,
                uint224 previousSum
            ) = readSumAndTimeStampForPool(bufferId, previousIndex);

            averageWeightedValue =
                (cumulativeSum - previousSum) /
                (currentTimeStamp - previousTimeStamp);
            return averageWeightedValue;
        }

        // Normal case:
        // Work our way backwards to requestedTimeStamp.  Because the buffer keeps track of
        // cumulative sum, we don't need to add anything up, just find the first element that is
        // older than the requestedTimeStamp.
        while (currentTimeStamp >= requestedTimeStamp && index != oldestIndex) {
            // Decrement index or rollback to end of buffer if we need to until we pass the
            // the requestedTimeStamp.
            index = index == 0 ? maxLength - 1 : index - 1;
            (currentTimeStamp, currentSum) = readSumAndTimeStampForPool(
                bufferId,
                index
            );
        }

        // Edge case:
        // If we've reached the oldest value in the buffer, then we just take the cumulativeSum
        // divided by the time to get the average weighted value.
        if (index == oldestIndex) {
            // Note The currentSum involves the value between currentTimeStamp and the
            // previousTimeStamp. Since there is no previousTimeStamp for the oldest sum
            // we have to drop the oldest sum.
            averageWeightedValue =
                (cumulativeSum - currentSum) / // currentSum is the oldest sum.
                (endTime - currentTimeStamp);

            // Normal case:
            // Otherwise, we need to subtract the sums outside time range, add a partial sum if
            // time requested is between two timeStamps, and divide by the total time to get
            // average weighted value.
        } else {
            uint16 nextIndex = (index + 1) % maxLength;
            (
                uint32 currentTimePlusOne,
                uint224 currentSumPlusOne
            ) = readSumAndTimeStampForPool(bufferId, nextIndex);

            // Get the sum between the two timeStamps around the requested time.
            uint256 sumDuringRequestedTime = uint256(currentSumPlusOne) -
                uint256(currentSum);

            // partialSum = sumDuringRequestedTime * partialTime
            // because the denominator of partialTime is always >= the numerator, we can't
            // calculate partialTime first otherwise it would always be zero.  So, we multiply by
            // the numerator first, the divide by the denominator:
            // uint256 partialTime = (currentTimePlusOne) - requestedTimeStamp) /
            //                       (currentTimePlusOne - currentTimeStamp);
            uint256 partialSum = sumDuringRequestedTime *
                (uint256(currentTimePlusOne) - uint256(requestedTimeStamp));
            partialSum =
                partialSum /
                (uint256(currentTimePlusOne) - uint256(currentTimeStamp));

            averageWeightedValue =
                (uint256(cumulativeSum) -
                    uint256(currentSumPlusOne) +
                    partialSum) /
                (uint256(endTime) - uint256(requestedTimeStamp));
        }
    }

    /// @dev An internal method to combine all metadata parts into a uint256 value.
    /// @param headIndex The index of the last item added to the buffer.
    /// @param maxLength The maximum length of the buffer.
    /// @param bufferLength The current length of the buffer.
    /// @return metadata Metadata encoded in a uint256 value.
    // [u144 unused][uint32 minTimeStep][uint32 timeStamp][u16 headIndex][u16 maxLength][u16 length]
    function _combineMetadata(
        uint32 minTimeStep,
        uint32 timeStamp,
        uint16 headIndex,
        uint16 maxLength,
        uint16 bufferLength
    ) internal pure returns (uint256 metadata) {
        metadata =
            // 16 + 16 + 16 + 32
            (uint256(minTimeStep) << 80) |
            // 16 + 16 + 16
            (uint256(timeStamp) << 48) |
            // 16 + 16
            (uint256(headIndex) << 32) |
            // 16
            (uint256(maxLength) << 16) |
            uint256(bufferLength);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

interface IMultiToken {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    function name(uint256 id) external view returns (string memory);

    function symbol(uint256 id) external view returns (string memory);

    function isApprovedForAll(address owner, address spender)
        external
        view
        returns (bool);

    function perTokenApprovals(
        uint256 tokenId,
        address owner,
        address spender
    ) external view returns (uint256);

    function balanceOf(uint256 tokenId, address owner)
        external
        view
        returns (uint256);

    function transferFrom(
        uint256 tokenID,
        address from,
        address to,
        uint256 amount
    ) external;

    function transferFromBridge(
        uint256 tokenID,
        address from,
        address to,
        uint256 amount,
        address caller
    ) external;

    function setApproval(
        uint256 tokenID,
        address operator,
        uint256 amount
    ) external;

    function setApprovalBridge(
        uint256 tokenID,
        address operator,
        uint256 amount,
        address caller
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./IMultiToken.sol";
import "./IERC20.sol";

interface ITerm is IMultiToken {
    /// @notice sums inputs to create new PTs and YTs from the deposit amount
    /// @param internalAmount how much of each asset to burn
    /// @param internalAssets an array of token IDs
    /// @param expiration the expiration timestamp
    /// @return a tuple of the number of PTs and YTs created
    function lock(
        uint256[] memory internalAmount,
        uint256[] memory internalAssets,
        uint256 underlyingAmount,
        bool hasPreFunding,
        address ytDestination,
        address ptDestination,
        uint256 ytBeginDate,
        uint256 expiration
    ) external returns (uint256, uint256);

    function depositUnlocked(
        uint256 underlyingAmount,
        uint256 ptAmount,
        uint256 ptId,
        address destination
    ) external returns (uint256, uint256);

    /// @notice removes all PTs and YTS input
    /// @param destination the address to send unlocked tokens to
    /// @param tokenIDs the IDs of the tokens to unlock
    /// @param amount the amount to unlock
    /// @return the total value of the tokens that have been unlocked
    function unlock(
        address destination,
        uint256[] memory tokenIDs,
        uint256[] memory amount
    ) external returns (uint256);

    function unlockedSharePrice() external view returns (uint256);

    function token() external view returns (IERC20);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./interfaces/IMultiToken.sol";

// A lite version of a semi fungible, which removes some methods and so
// is not technically a 1155 compliant multi-token semi fungible, but almost
// follows the standard.
// NOTE - We remove on transfer callbacks and safe transfer because of the
//        risk of external calls to untrusted code.

contract MultiToken is IMultiToken {
    // TOOD - Choose to change names to perfect match the 1155 ie adding 'safe',
    //        choose whether to support the batch methods, and to support token uris
    //        or names

    // Allows loading of each balance
    mapping(uint256 => mapping(address => uint256)) public override balanceOf;
    // Allows loading of each total supply
    mapping(uint256 => uint256) public totalSupply;
    // Uniform approval for all tokens
    mapping(address => mapping(address => bool))
        public
        override isApprovedForAll;
    // Additional optional per token approvals
    // Note - non standard for erc1150 but we want to replicate erc20 interface
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        public
        override perTokenApprovals;
    // Sub Token Name and Symbol, created by inheriting contracts
    mapping(uint256 => string) internal _name;
    mapping(uint256 => string) internal _symbol;

    // Error triggered when the create2 verification fails
    error NonLinkerCaller();

    // The contract which deployed this one
    address public immutable factory;
    // The bytecode hash of the contract which forwards purely erc20 calls
    // to this contract
    bytes32 public immutable linkerCodeHash;

    // EIP712
    // DOMAIN_SEPARATOR changes based on token name
    bytes32 public DOMAIN_SEPARATOR;
    // PERMIT_TYPEHASH changes based on function inputs
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "PermitForAll(address owner,address spender,bool _approved,uint256 nonce,uint256 deadline"
        );

    // A mapping to track the permitForAll signature nonces
    mapping(address => uint256) public nonces;

    /// @notice Runs the initial deployment code
    /// @param _linkerCodeHash The hash of the erc20 linker contract deploy code
    /// @param _factory The factory which is used to deploy the linking contracts
    constructor(bytes32 _linkerCodeHash, address _factory) {
        // Set the immutables
        factory = _factory;
        linkerCodeHash = _linkerCodeHash;

        // Computes the EIP 712 domain separator which prevents user signed messages for
        // this contract to be replayed in other contracts.
        // https://eips.ethereum.org/EIPS/eip-712
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    //  Our architecture maintains ERC20 compatibility by allowing the option
    //  of the factory deploying ERC20 compatibility bridges which forward ERC20 calls
    //  to this contract. To maintain trustless deployment they are create2 deployed
    //  with tokenID as salt by the factory, and can be verified by the pre image of
    //  the address.

    /// @notice This modifier checks the caller is the create2 validated ERC20 bridge
    /// @param tokenID The internal token identifier
    modifier onlyLinker(uint256 tokenID) {
        // If the caller does not match the address hash, we revert because it is not
        // allowed to access permission-ed methods.
        if (msg.sender != _deriveForwarderAddress(tokenID)) {
            revert NonLinkerCaller();
        }
        // Execute the following function
        _;
    }

    /// @notice Derive the ERC20 forwarder address for a provided `tokenId`.
    /// @param tokenId Token Id of the token whose forwader contract address need to drived.
    /// @return Address of the ERC20 forwarder contract.
    function _deriveForwarderAddress(uint256 tokenId)
        internal
        view
        returns (address)
    {
        // Get the salt which is used by the deploying contract
        bytes32 salt = keccak256(abi.encode(address(this), tokenId));
        // Preform the hash which determines the address of a create2 deployment
        bytes32 addressBytes = keccak256(
            abi.encodePacked(bytes1(0xff), factory, salt, linkerCodeHash)
        );
        return address(uint160(uint256(addressBytes)));
    }

    /// @notice Returns the name of the sub token i.e PTs or YTs token supported
    ///         by this contract.
    /// @param id The pool id to load the name of
    /// @return Returns the name of this token
    function name(uint256 id)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _name[id];
    }

    /// @notice Returns the symbol of the sub token i.e PTs or YTs token supported
    ///         by this contract.
    /// @param id The pool id to load the name of
    /// @return Returns the symbol of this token
    function symbol(uint256 id)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _symbol[id];
    }

    /// @notice Transfers an amount of assets from the source to the destination
    /// @param tokenID The token identifier
    /// @param from The address who's balance will be reduced
    /// @param to The address who's balance will be increased
    /// @param amount The amount of token to move
    function transferFrom(
        uint256 tokenID,
        address from,
        address to,
        uint256 amount
    ) external override {
        // Forward to our internal version
        _transferFrom(tokenID, from, to, amount, msg.sender);
    }

    /// @notice Permission-ed transfer for the bridge to access, only callable by
    ///         the ERC20 linking bridge
    /// @param tokenID The token identifier
    /// @param from The address who's balance will be reduced
    /// @param to The address who's balance will be increased
    /// @param amount The amount of token to move
    /// @param caller The msg.sender from the bridge
    function transferFromBridge(
        uint256 tokenID,
        address from,
        address to,
        uint256 amount,
        address caller
    ) external override onlyLinker(tokenID) {
        // Route to our internal transfer
        _transferFrom(tokenID, from, to, amount, caller);
    }

    /// @notice Preforms the actual transfer logic
    /// @param tokenID The token identifier
    /// @param from The address who's balance will be reduced
    /// @param to The address who's balance will be increased
    /// @param amount The amount of token to move
    /// @param caller The msg.sender either here or in the compatibility link contract
    function _transferFrom(
        uint256 tokenID,
        address from,
        address to,
        uint256 amount,
        address caller
    ) internal {
        // If ethereum transaction sender is calling no need for further validation
        if (caller != from) {
            // Or if the transaction sender can access all user assets, no need for
            // more validation
            if (!isApprovedForAll[from][caller]) {
                // Finally we load the per asset approval
                uint256 approved = perTokenApprovals[tokenID][from][caller];
                // If it is not an infinite approval
                if (approved != type(uint256).max) {
                    // Then we subtract the amount the caller wants to use
                    // from how much they can use, reverting on underflow.
                    // NOTE - This reverts without message for unapproved callers when
                    //         debugging that's the likely source of any mystery reverts
                    perTokenApprovals[tokenID][from][caller] -= amount;
                }
            }
        }

        // Reaching this point implies the transfer is authorized so we remove
        // from the source and add to the destination.
        balanceOf[tokenID][from] -= amount;
        balanceOf[tokenID][to] += amount;
        emit TransferSingle(caller, from, to, tokenID, amount);
    }

    /// @notice Allows a user to approve an operator to use all of their assets
    /// @param operator The eth address which can access the caller's assets
    /// @param approved True to approve, false to remove approval
    function setApprovalForAll(address operator, bool approved) public {
        // set the appropriate state
        isApprovedForAll[msg.sender][operator] = approved;
        // Emit an event to track approval
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Allows a user to set an approval for an individual asset with specific amount.
    /// @param tokenID The asset to approve the use of
    /// @param operator The address who will be able to use the tokens
    /// @param amount The max tokens the approved person can use, setting to uint256.max
    ///               will cause the value to never decrement [saving gas on transfer]
    function setApproval(
        uint256 tokenID,
        address operator,
        uint256 amount
    ) external override {
        _setApproval(tokenID, operator, amount, msg.sender);
    }

    /// @notice Allows the compatibility linking contract to forward calls to set asset approvals
    /// @param tokenID The asset to approve the use of
    /// @param operator The address who will be able to use the tokens
    /// @param amount The max tokens the approved person can use, setting to uint256.max
    ///               will cause the value to never decrement [saving gas on transfer]
    /// @param caller The eth address which called the linking contract
    function setApprovalBridge(
        uint256 tokenID,
        address operator,
        uint256 amount,
        address caller
    ) external override onlyLinker(tokenID) {
        _setApproval(tokenID, operator, amount, caller);
    }

    /// @notice internal function to change approvals
    /// @param tokenID The asset to approve the use of
    /// @param operator The address who will be able to use the tokens
    /// @param amount The max tokens the approved person can use, setting to uint256.max
    ///               will cause the value to never decrement [saving gas on transfer]
    /// @param caller The eth address which initiated the approval call
    function _setApproval(
        uint256 tokenID,
        address operator,
        uint256 amount,
        address caller
    ) internal {
        perTokenApprovals[tokenID][caller][operator] = amount;
        // Emit an event to track approval
        emit Approval(caller, operator, amount);
    }

    /// @notice Minting function to create tokens
    /// @param tokenID The asset type to create
    /// @param to The address who's balance to increase
    /// @param amount The number of tokens to create
    /// @dev Must be used from inheriting contracts
    function _mint(
        uint256 tokenID,
        address to,
        uint256 amount
    ) internal {
        balanceOf[tokenID][to] += amount;
        totalSupply[tokenID] += amount;
        // Emit an event to track minting
        emit TransferSingle(msg.sender, address(0), to, tokenID, amount);
    }

    /// @notice Burning function to remove tokens
    /// @param tokenID The asset type to remove
    /// @param from The address who's balance to decrease
    /// @param amount The number of tokens to remove
    /// @dev Must be used from inheriting contracts
    function _burn(
        uint256 tokenID,
        address from,
        uint256 amount
    ) internal {
        // Decrement from the source and supply
        balanceOf[tokenID][from] -= amount;
        totalSupply[tokenID] -= amount;
        // Emit an event to track burning
        emit TransferSingle(msg.sender, from, address(0), tokenID, amount);
    }

    /// @notice Transfers several assets from one account to another
    /// @param from the source account
    /// @param to the destination account
    /// @param ids The array of token ids of the asset to transfer
    /// @param values The amount of each token to transfer
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external {
        // Checks for inconsistent addresses
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        // Check for inconsistent length
        require(ids.length == values.length, "ids and values length mismatch");
        // Call internal transfer for each asset
        for (uint256 i = 0; i < ids.length; i++) {
            _transferFrom(ids[i], from, to, values[i], msg.sender);
        }
    }

    /// @notice Allows a caller who is not the owner of an account to execute
    ///         the functionality of 'approve' for all assets with the owners signature.
    /// @param owner the owner of the account which is having the new approval set
    /// @param spender the address which will be allowed to spend owner's tokens
    /// @param _approved a boolean of the approval status to set to
    /// @param deadline the timestamp which the signature must be submitted by to be valid
    /// @param v Extra ECDSA data which allows public key recovery from signature assumed to be 27 or 28
    /// @param r The r component of the ECDSA signature
    /// @param s The s component of the ECDSA signature
    /// @dev The signature for this function follows EIP 712 standard and should be generated with the
    ///      eth_signTypedData JSON RPC call instead of the eth_sign JSON RPC call. If using out of date
    ///      parity signing libraries the v component may need to be adjusted. Also it is very rare but possible
    ///      for v to be other values, those values are not supported.
    function permitForAll(
        address owner,
        address spender,
        bool _approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Require that the signature is not expired
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
        // Require that the owner is not zero
        require(owner != address(0), "ERC20: invalid-address-0");

        bytes32 structHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        _approved,
                        nonces[owner],
                        deadline
                    )
                )
            )
        );

        // Check that the signature is valid
        address signer = ecrecover(structHash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        // Increment the signature nonce
        nonces[owner]++;
        // set the state
        isApprovedForAll[owner][spender] = _approved;
        // Emit an event to track approval
        emit ApprovalForAll(owner, spender, _approved);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./ITerm.sol";

abstract contract IYieldAdapter is ITerm {
    /// Yield sources should have two share types, easily withdrawable unlocked shares and
    /// possibly hard to withdraw yield sources [only redeemed at expiry]
    enum ShareState {
        Locked,
        Unlocked
    }

    /// Deposits based on funds available in the contract.
    /// @return tuple (shares minted, amount underlying used)
    function _deposit(ShareState) internal virtual returns (uint256, uint256);

    /// Turns unlocked shares into locked shares and vice versa
    function _convert(ShareState, uint256) internal virtual returns (uint256);

    /// @return the amount produced
    function _withdraw(
        uint256,
        address,
        ShareState
    ) internal virtual returns (uint256);

    /// @return The amount of underlying the input is worth
    function _underlying(uint256, ShareState)
        internal
        view
        virtual
        returns (uint256);
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

// solhint-disable

// Code was adapted from Balancer (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol)

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) {
        _revert(errorCode);
    }
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'ELF#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly ("memory-safe") {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "ELF#" part is a known constant
        // (0x454c4623): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(
            200,
            add(
                0x454c4623000000,
                add(add(units, shl(8, tenths)), shl(16, hundreds))
            )
        )

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(
            0x0,
            0x08c379a000000000000000000000000000000000000000000000000000000000
        )
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(
            0x04,
            0x0000000000000000000000000000000000000000000000000000000000000020
        )
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;
}