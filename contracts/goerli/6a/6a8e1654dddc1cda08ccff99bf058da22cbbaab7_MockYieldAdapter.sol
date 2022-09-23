// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "../interfaces/IYieldAdapter.sol";
import "./MockERC20YearnVault.sol";
import "../Term.sol";

contract MockYieldAdapter is IYieldAdapter, Term {
    MockERC20YearnVault public immutable vault;

    constructor(
        address mockYearnVault,
        address governance,
        bytes32 _linkerCodeHash,
        address _factory,
        IERC20 _token
    ) Term(_linkerCodeHash, _factory, _token, governance) {
        vault = MockERC20YearnVault(mockYearnVault);
        token.approve(address(vault), type(uint256).max);
    }

    function mint(
        uint256 tokenID,
        address to,
        uint256 amount
    ) public {
        _mint(tokenID, to, amount);
        uint256 expiry = uint256(uint128(tokenID));
        sharesPerExpiry[expiry] += amount;
    }

    function setSharesPerExpiry(uint256 expiry, uint256 amount) public {
        sharesPerExpiry[expiry] = amount;
    }

    /// Deposits based on funds available in the contract.
    /// @return tuple (shares minted, amount underlying used)
    function _deposit(ShareState state)
        internal
        override
        returns (uint256, uint256)
    {
        uint256 amount = token.balanceOf(address(this));
        uint256 shares;
        if (amount > 0) {
            shares = vault.deposit(amount, address(this));
        }

        uint256 returnShares = state == ShareState.Unlocked
            ? shares * 2
            : shares;

        return (returnShares, amount);
    }

    /// Turns unlocked shares into locked shares and vice versa
    function _convert(ShareState state, uint256 shares)
        internal
        pure
        override
        returns (uint256)
    {
        uint256 conversion = state == ShareState.Unlocked
            ? shares * 2
            : shares / 2;
        return conversion;
    }

    /// @return the amount produced
    function _withdraw(
        uint256 shares,
        address destination,
        ShareState state
    ) internal override returns (uint256) {
        if (state == ShareState.Unlocked) {
            shares = shares / 2;
        }
        return (vault.withdraw(shares, destination, 10000));
    }

    /// @return The amount of underlying the input is worth
    function _underlying(uint256 shares, ShareState state)
        internal
        view
        override
        returns (uint256)
    {
        uint256 amount = (vault.pricePerShare() * shares) / one;
        if (state == ShareState.Unlocked) {
            amount = amount / 2;
        }
        return amount;
    }

    // This is for testing
    function lockedSharePrice() public view returns (uint256) {
        return (vault.pricePerShare() / one);
    }

    function setBalance(
        uint256 poolId,
        address who,
        uint256 amount
    ) public {
        balanceOf[poolId][who] = amount;
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;
import "../libraries/Authorizable.sol";
import "../libraries/ERC20Permit.sol";
import "../interfaces/IYearnVault.sol";

contract MockERC20YearnVault is IYearnVault, Authorizable, ERC20Permit {
    // total amount of vault shares in existence
    uint256 public totalShares;

    // a large number used to offset potential division precision errors
    uint256 public precisionFactor;

    // underlying token
    ERC20Permit public token;

    // last time someone deposited value through report()
    uint256 public lastReport;
    // the amount of tokens locked after a report()
    uint256 public lockedProfit;

    /**
    @param _token The ERC20 token the vault accepts
     */
    constructor(address _token)
        Authorizable()
        ERC20Permit("Mock Yearn Vault", "MYV")
    {
        _authorize(msg.sender);
        token = ERC20Permit(_token);
        decimals = token.decimals();
        precisionFactor = 10**(18 - decimals);
        // 6 hours in blocks
        // 6*60*60 ~= 1e6 / 46
    }

    function apiVersion() external pure returns (string memory) {
        return ("0.3.2");
    }

    /**
    @notice Add tokens to the vault. Increases totalAssets.
    @param _deposit The amount of tokens to deposit
    @dev There is no logic to rebalance lockedAmount.
    Repeat calls will just reset it.
    */
    function report(uint256 _deposit) external onlyAuthorized {
        lastReport = block.timestamp;
        // mock vault does not take performance or management fee
        // so the full deposit is locked profit.
        lockedProfit = _deposit;
        token.transferFrom(msg.sender, address(this), _deposit);
    }

    /**
    @notice Remove tokens from the vault.
    @param loss The amount of tokens to burn
    */
    function reportLoss(uint256 loss) external onlyAuthorized {
        lastReport = block.timestamp;
        // mock vault does not take performance or management fee
        // so the full deposit is locked profit.
        token.transferFrom(address(this), address(1), loss);
    }

    /**
    @notice Deposit `_amount` of tokens into the yearn vault.
    `_recipient` receives shares.
    @param _amount The amount of underlying tokens to deposit.
    @param _recipient The recipient of the vault shares.
    @return The vault shares received.

     */
    function deposit(uint256 _amount, address _recipient)
        external
        returns (uint256)
    {
        require(_amount > 0, "depositing 0 value");
        uint256 shares = _issueSharesForAmount(_recipient, _amount);
        token.transferFrom(msg.sender, address(this), _amount);
        return shares;
    }

    /**
    @notice Withdraw `_maxShares` of shares from caller `_recipient`
    receives underlying tokens.
    @param _maxShares The amount of shares to redeem for underlying.
    @param _recipient The recipient of the underlying tokens.
    @param _maxLoss The max permitted withdrawal loss. (1 = 0.01%, 10000 = 100%).
    @return The amount of underlying tokens that were redeemed from _maxShares shares.
     */
    function withdraw(
        uint256 _maxShares,
        address _recipient,
        uint256 _maxLoss
    ) external override returns (uint256) {
        // silence unused function parameter warning
        require(_maxLoss >= 0);
        require(_maxShares > 0, "Can't withdraw zero");
        require(balanceOf[msg.sender] >= _maxShares, "Shares exceed balance");
        uint256 value = _shareValue(_maxShares);

        totalShares -= _maxShares;
        balanceOf[msg.sender] -= _maxShares;

        token.transfer(_recipient, value);
        return value;
    }

    /**
    @notice Returns the amount of underlying per each unit [10^decimals] of yearn shares
     */
    function pricePerShare() public view override returns (uint256) {
        return _shareValue(10**decimals);
    }

    /**
    @notice Get the governance address. It will be address(0)
    it is not used for this mock.
     */
    function governance() public pure override returns (address) {
        return address(0);
    }

    /**
    @notice The deposit limit for this vault.
    @dev Can only be unlimited for this mock.
     */
    function setDepositLimit(uint256 _limit) public view override {
        // silence unused function parameter warning
        require(_limit >= 0);
        require(msg.sender == governance(), "!governance");
    }

    /**
    @notice Returns total assets held by the contract.
    @dev This is a mock and there is no debt. The total assets are just the
    underlying tokens held by the contract.
     */
    function totalAssets() public view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
    @param _to The address to receive the shares.
    @param _amount The amount of underlying tokens to convert to shares.
    @return The amount of shares _amount yields.
     */
    function _issueSharesForAmount(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 shares;
        if (totalShares > 0) {
            shares =
                (precisionFactor * _amount * totalShares) /
                totalAssets() /
                precisionFactor;
        } else {
            shares = _amount;
        }
        totalShares += shares;
        balanceOf[_to] += shares;
        return shares;
    }

    /**
    @notice Return the amount of underlying tokens an amount of `_shares`
    is worth at any given time.
    @param _shares The amount of shares to check.
    @return The amount of underlying tokens the `_shares` can be redeemed for.
     */
    function _shareValue(uint256 _shares) internal view returns (uint256) {
        if (totalShares == 0) {
            return _shares;
        }
        // determine the current value of the shares
        uint256 _totalAssets = totalAssets();

        return
            (precisionFactor * _shares * _totalAssets) /
            (totalShares * precisionFactor);
    }

    /**
    @notice Get the total number of vault shares.
    @return Total vault shares.
     */
    function totalSupply() external view override returns (uint256) {
        return totalShares;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./MultiToken.sol";
import "./interfaces/IYieldAdapter.sol";
import "./interfaces/ITerm.sol";
import "./interfaces/IERC20.sol";
import "./libraries/Authorizable.sol";
import "./libraries/Errors.sol";

abstract contract Term is ITerm, MultiToken, IYieldAdapter, Authorizable {
    // Struct to store packed yield term info, packed into one sstore
    struct YieldState {
        uint128 shares;
        uint128 pt;
    }

    // Struct to store for finalized expired timestamps, packed into one sstore
    struct FinalizedState {
        uint128 pricePerShare;
        uint128 interest;
    }

    // Maps expiration timestamps to the shares held backing the PT/YT at that timestamp
    mapping(uint256 => uint256) public sharesPerExpiry;
    // Maps the YT ID packed as [1][start time][expiry] to the shares and principal tokens
    // which exist for this yield start point
    mapping(uint256 => YieldState) public yieldTerms;
    // When terms are finalized we cache the final price per share and outstanding total interest
    mapping(uint256 => FinalizedState) public finalizedTerms;

    // The underlying token
    IERC20 public immutable override token;
    // The decimals and decimal adjusted constant 1
    uint8 public immutable decimals;
    uint256 public immutable one;

    // The unlocked term id is the YT id at start 0 expiration 0
    uint256 public constant UNLOCKED_YT_ID = 1 << 255;

    /// @notice Runs the initial deployment code
    /// @param _linkerCodeHash The hash of the erc20 linker contract deploy code
    /// @param _factory The factory which is used to deploy the linking contracts
    /// @param _token The ERC20 which is deposited into this contract
    /// @param _owner this address will be made owner
    constructor(
        bytes32 _linkerCodeHash,
        address _factory,
        IERC20 _token,
        address _owner
    ) MultiToken(_linkerCodeHash, _factory) {
        // Set the immutable token data
        token = _token;
        uint8 _decimals = _token.decimals();
        decimals = _decimals;
        one = 10**decimals;
        setOwner(_owner);
    }

    /// @notice Takes an input as a mix of the underlying token, expired PT and YT, and unlocked shares
    ///      then uses their value to create new PT and YT. Cannot make unlocked deposit shares
    /// @param assetIds The array of PT, YT and Unlocked share identifiers. NOTE - The IDs MUST be unique
    ///                 and sorted.
    /// @param assetAmounts The amount of each input PT, YT and Unlocked share to use
    /// @param underlyingAmount The amount of underlying transferred from the user.
    /// @param hasPreFunding If true a user can forward tokens ahead instead of doing transfer from
    /// @param ytDestination The address to mint the YTs to
    /// @param ptDestination The address to mint the PTs to
    /// @param ytBeginDate The start timestamp of the YTs, note if it is in the future the
    ///                    Yt will be created at current timestamp.
    /// @param expiration the expiration timestamp
    /// @return Returns the number of principal and yield tokens created
    function lock(
        uint256[] memory assetIds,
        uint256[] memory assetAmounts,
        uint256 underlyingAmount,
        bool hasPreFunding,
        address ytDestination,
        address ptDestination,
        uint256 ytBeginDate,
        uint256 expiration
    ) external returns (uint256, uint256) {
        // If the user enters something larger than the current timestamp we set the yt
        // expiry to the current timestamp
        ytBeginDate = ytBeginDate >= block.timestamp
            ? block.timestamp
            : ytBeginDate;

        // Next check the validity of the requested expiry
        if (expiration <= block.timestamp) revert ElementError.TermExpired();

        // The yt can't start after
        // Running tally of the added value
        uint256 totalValue = 0;
        // Running total of the total shares
        uint256 totalShares = 0;

        // Transfer underlying into the contract and then deposit into the yield source
        if (underlyingAmount != 0) {
            // Transfer in shares
            token.transferFrom(msg.sender, address(this), underlyingAmount);
        }
        // If the user is transferred from or they have transferred themselves
        // NOTE - These pre-funding paths allow external call sequencers to avoid ERC20 transfers
        if (underlyingAmount != 0 || hasPreFunding) {
            // We check if the deposit should be in the locked or unlocked state
            // Note - The code path difference is that locked must be invested while
            //        for some hard to withdraw yield strategies the unlocked term may not be
            (totalShares, totalValue) = _deposit(ShareState.Locked);
        }

        // Initialize the previous id for the sorting check
        uint256 previousId = 0;

        // Deletes (burn) any assets which are rolling over and returns how many much in terms of
        // shares and value they are worth.
        for (uint256 i = 0; i < assetIds.length; i++) {
            // helps the stack
            uint256 id = assetIds[i];
            uint256 amount = assetAmounts[i];
            // Requiring strict sorting is a cheap way to check for uniqueness
            if (previousId >= id) revert ElementError.UnsortedAssetIds();
            previousId = id;

            // Burn the asset from the user
            (uint256 shares, uint256 value) = _releaseAsset(
                id,
                msg.sender,
                amount
            );
            // Record the value
            totalValue += value;
            // We split, if this is the unlocked asset type it's invested shares may not match
            // the shares which back principal and yield tokens so we must convert.
            if (id == UNLOCKED_YT_ID) {
                // Convert the shares
                totalShares += _convert(ShareState.Unlocked, shares);
            } else {
                // The locked assets can be added directly to the running total
                totalShares += shares;
            }
        }

        // Use the total value to create the yield tokens, also sets internal accounting
        uint256 discount = _createYT(
            ytDestination,
            totalValue,
            totalShares,
            ytBeginDate,
            expiration
        );
        // Mint the user principal tokens
        // Note - Reverts if the user is trying to enter a term where they have not supplied enough
        //        value to pay for accumulated interest, the user should choose a more recent term.
        if (totalValue - discount > 0) {
            _mint(expiration, ptDestination, totalValue - discount);
        }
        // In this case the PT is totalValue - discount and the YT is total value
        return (totalValue - discount, totalValue);
    }

    /// @notice Creates an unlocked deposit into the term which can be withdraw at any time
    ///         this deposit can be locked into principal and yield tokens. It may or may not
    ///         earn interest depending on the implementation.
    /// @dev We use this functionality to help manage fund flow in the AMM, and keep LP funds invested
    /// @param underlyingAmount The token which will be transferred from the caller
    /// @param ptAmount If this is larger than zero the function will also try to burn PT from the caller
    /// @param ptExpiry The time the pt for the user expires, this is also it's id
    /// @param destination The destination of the outputted unlocked shares
    /// @return the value of the deposit, and the shares created
    function depositUnlocked(
        uint256 underlyingAmount,
        uint256 ptAmount,
        uint256 ptExpiry,
        address destination
    ) external override returns (uint256, uint256) {
        // If the user wants to send in tokens transfer them to this contract
        if (underlyingAmount != 0) {
            token.transferFrom(msg.sender, address(this), underlyingAmount);
        }
        // Do a deposit
        (uint256 shares, uint256 value) = _deposit(ShareState.Unlocked);

        // If we are also redeeming a PT
        if (ptAmount != 0) {
            // Ensure this is a PT Id
            // NOTE - All YT have the top bit as 1 and so are larger than any conceivable
            //        block.timestamp.
            // Todo - Make sure there's a test for the fact no YT id passes
            if (ptExpiry >= block.timestamp) revert ElementError.TermExpired();

            // Then we burn the pt from the user and release its shares
            (uint256 lockedShares, uint256 ptValue) = _releaseAsset(
                ptExpiry,
                msg.sender,
                ptAmount
            );
            // We convert those shares to a 'unlocked' form
            uint256 unlockedShares = _convert(ShareState.Locked, lockedShares);
            // Add them to ongoing totals
            shares += unlockedShares;
            value += ptValue;
        }
        // Mint YT for the user
        _createYT(destination, value, shares, 0, 0);
        // Return how much was deposited and the shares created
        return (value, shares);
    }

    /// @notice Redeems expired PT, YT and unlocked shares for their backing asset.
    /// @param destination The address to send the unlocked tokens too
    /// @param tokenIds The IDs of the token to unlock. NOTE- They MUST be unique and sorted.
    /// @param amounts The amounts of the tokens to unlock
    /// @return the total value of the tokens that have been unlocked
    function unlock(
        address destination,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external override returns (uint256) {
        // To release shares we delete any input PT and YT, these may be unlocked or locked
        uint256 releasedSharesLocked = 0;
        uint256 releasedSharesUnlocked = 0;
        uint256 previousId = 0;

        // Deletes any assets which are rolling over and returns how many much in terms of
        // shares and value they are worth.
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Requiring strict sorting is a cheap way to check for uniqueness
            if (previousId >= tokenIds[i])
                revert ElementError.UnsortedAssetIds();

            previousId = tokenIds[i];
            // Burns the tokens from the user account and returns how much they were worth
            // in shares and token value. Does not formally withdraw from yield source.
            (uint256 shares, ) = _releaseAsset(
                tokenIds[i],
                msg.sender,
                amounts[i]
            );

            // Record the shares which were released
            if (tokenIds[i] == UNLOCKED_YT_ID) {
                releasedSharesUnlocked += shares;
            } else {
                releasedSharesLocked += shares;
            }
        }

        // Withdraw the released shares
        uint256 valueFromLocked = 0;
        uint256 valueFromUnlocked = 0;
        // Only do the withdraw calls if there's something to withdraw
        // Note these calls will send the asset to the destination.
        if (releasedSharesLocked != 0) {
            valueFromLocked = _withdraw(
                releasedSharesLocked,
                destination,
                ShareState.Locked
            );
        }
        if (releasedSharesUnlocked != 0) {
            valueFromUnlocked = _withdraw(
                releasedSharesUnlocked,
                destination,
                ShareState.Unlocked
            );
        }

        // Return the total value released
        return (valueFromLocked + valueFromUnlocked);
    }

    /// @notice Quotes the price per share for unlocked tokens
    /// @return the price per share of unlocked shares
    function unlockedSharePrice() external view override returns (uint256) {
        return _underlying(one, ShareState.Unlocked);
    }

    /// @notice creates yield tokens
    /// @param destination the address the YTs belong to
    /// @param value the value of YTs to create
    /// @param totalShares the shares used to create YTs
    /// @param startTime the timestamp when the term started
    /// @param expiration the expiration of the term
    /// @return the amount created
    function _createYT(
        address destination,
        uint256 value,
        uint256 totalShares,
        uint256 startTime,
        uint256 expiration
    ) internal returns (uint256) {
        // We create only YT for the user with a 100% discount
        if (expiration == 0) {
            // In the unlocked term all assets are held as YT with a direct conversion to shares
            // The yield source should account for any changes in value as deposit withdraw happens
            _mint(UNLOCKED_YT_ID, destination, totalShares);
            // Increment shares per start
            yieldTerms[UNLOCKED_YT_ID].shares += uint128(totalShares);
            // Return that this is a 100% discount so no PT are made
            return value;
        } else {
            uint256 yieldTokenId = (1 << 255) + (startTime << 128) + expiration;
            YieldState memory state = yieldTerms[yieldTokenId];
            // For new YT, we split into two cases one a new YT which must start at this block
            // and not have any previous mints. And a branch which can have previous mints.
            if (startTime == block.timestamp && state.pt == 0) {
                // Initiate a new term
                _mint(yieldTokenId, destination, value);
                // Store the data from the first mint
                yieldTerms[yieldTokenId].shares = uint128(totalShares);
                yieldTerms[yieldTokenId].pt = uint128(value);
                sharesPerExpiry[expiration] += totalShares;
                // No interest earned and no discount.
                return 0;
            } else {
                // In this case the yield token is being backdated to match a pre-existing term
                // We require that it already existed, or we would not be able to capture accurate
                // interest rate data in the period
                if (state.shares == 0 || state.pt == 0)
                    revert ElementError.TermNotInitialized();

                // We calculate the current fair value of the YT by dividing the interest
                // earned by the number of YT. We can get the interest earned by subtracting
                // PT outstanding from the share multiplied by current price per share
                // NOTE - This step makes a strong assumption on the inputs to this function.
                uint256 impliedShareValue = (value * uint256(state.shares)) /
                    totalShares;
                // NOTE - Reverts on negative interest or on some 0 interest rounding errors
                uint256 interestEarned = impliedShareValue - uint256(state.pt);
                // Cost per yt is (interestEarned/total_yt) so the total discount is how many
                // YT the user wants to mint [ie 'value']
                uint256 totalDiscount = (value * interestEarned) /
                    totalSupply[yieldTokenId];
                // Now we mint the YT for the user
                _mint(yieldTokenId, destination, value);

                // Update the amount of shares for the expiry
                sharesPerExpiry[expiration] += totalShares - totalDiscount;

                // Update the reserve information for this YT term, and the total shares
                // backing the PT it will create.
                // NOTE - Reverts here if the interest is over 100% for the YT being minted
                yieldTerms[yieldTokenId] = YieldState(
                    state.shares + uint128(totalShares),
                    state.pt + uint128(value - totalDiscount)
                );

                // Return the discount so the right number of PT are minted
                return totalDiscount;
            }
        }
    }

    /// @notice Deletes an asset [expired PT/YT or unlocked share] and returns the shares released
    ///         and their value. Note - Shares from unlocked assets may be different than from PT/YT
    /// @param assetId The ID for the asset redeemed
    /// @param source The account to delete tokens from
    /// @param amount The amount to delete from the user.
    /// @return returns shares and their value
    function _releaseAsset(
        uint256 assetId,
        address source,
        uint256 amount
    ) internal returns (uint256, uint256) {
        // Note for both yt and pt the first 128 bits contain the expiry.
        (bool isYieldToken, , uint256 expiry) = _parseAssetId(assetId);
        // Check that the expiry has been hit
        if (expiry > block.timestamp && expiry != 0)
            revert ElementError.TermNotExpired();
        // Load the data which is cached when the first asset is released
        FinalizedState memory finalState = finalizedTerms[expiry];
        // If the term's final interest rate has not been recorded we record it
        if (assetId != UNLOCKED_YT_ID && finalState.interest == 0) {
            finalState = _finalizeTerm(expiry);
        }

        //  Special case the unlocked share redemption
        if (assetId == UNLOCKED_YT_ID) {
            return _releaseUnlocked(source, amount);
        } else if (isYieldToken) {
            // If the top bit is one do YT redemption
            return _releaseYT(finalState, assetId, source, amount);
        } else {
            return _releasePT(finalState, assetId, source, amount);
        }
    }

    /// @notice Before any PT/YT can be withdrawn from an expired timestamp the market interest rate is
    ///         cached. This call stores that price cache plus the implied outstanding interest.
    /// @param expiry The term's expiration time
    /// @return finalState The finalized term state for this expiry.
    function _finalizeTerm(uint256 expiry)
        internal
        returns (FinalizedState memory finalState)
    {
        // All shares corresponding to PT and YT expiring now
        uint256 termShares = sharesPerExpiry[expiry];
        // The implied value of term shares
        uint256 totalValue = _underlying(termShares, ShareState.Locked);
        // The interest is the value minus pt supply
        // To protect against the edge case where there is negative interest, we need to set
        // the interest to zero. This can happen if for some reason the underlying vault has
        // less assets in it than when the term was created.
        uint256 totalInterest = totalSupply[expiry] > totalValue
            ? 0
            : totalValue - totalSupply[expiry];
        // The shares needed to release this value at this point are calculated from the
        // implied price per share
        uint256 pricePerShare = (totalValue * one) / termShares;
        // Store this info and return
        finalState.interest = uint128(totalInterest);
        finalState.pricePerShare = uint128(pricePerShare);
        finalizedTerms[expiry] = finalState;
    }

    /// @notice Redeems unlocked term asset from a user
    /// @param source The user address who's balance to reduce
    /// @param amount The number of unlocked asset to reduce
    /// @return returns the shares unlocked and the amount they are worth
    function _releaseUnlocked(address source, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        // In this case we just do a proportional withdraw from the shares for this asset
        uint256 termShares = yieldTerms[UNLOCKED_YT_ID].shares;

        uint256 userShares = (termShares * amount) /
            totalSupply[UNLOCKED_YT_ID];

        // Query the value of these shares
        uint256 shareValue = _underlying(userShares, ShareState.Unlocked);

        // Burn from the user
        _burn(UNLOCKED_YT_ID, source, amount);
        // Subtract their shares from total
        yieldTerms[UNLOCKED_YT_ID].shares = uint128(termShares - userShares);
        // Return the shares released and their value
        return (userShares, shareValue);
    }

    /// @notice Removes expired YT from a user account and returns the shares released and their value
    /// @param finalState The finalized state of term with total interest and final price per share
    /// @param assetId The YT ID for this term
    /// @param source The account which is the source of this YT
    /// @param amount The amount of YT to remove from the user account.
    function _releaseYT(
        FinalizedState memory finalState,
        uint256 assetId,
        address source,
        uint256 amount
    ) internal returns (uint256, uint256) {
        // To release YT we calculate the implied earning of the differential between final price per share
        // and the stored price per share at the time of YT creation.
        YieldState memory yieldTerm = yieldTerms[assetId];
        uint256 termEndingValue = (uint256(yieldTerm.shares) *
            uint256(finalState.pricePerShare)) / one;

        // To protect against the edge case where there is negative interest, we need to set
        // the interest to zero. This can happen if for some reason the underlying vault has
        // less assets in it than when the term was created.
        uint256 termEndingInterest = yieldTerm.pt > termEndingValue
            ? 0
            : termEndingValue - yieldTerm.pt;

        // Calculate the value of this yt redemption by dividing total value by the number of YT
        uint256 totalYtSupply = totalSupply[assetId];
        uint256 userInterest = (termEndingInterest * amount) / totalYtSupply;
        // Now we load current share price to see how many shares the user is owed
        uint256 currentPricePerShare = _underlying(one, ShareState.Locked);
        uint256 userShares = (userInterest * one) / currentPricePerShare;
        // Now we decrement the PT shares and interest outstanding
        (, , uint256 expiry) = _parseAssetId(assetId);
        sharesPerExpiry[expiry] -= userShares;
        finalizedTerms[expiry].interest -= uint128(userInterest);
        // Next burn the user's YT and update the finalized YT info
        _burn(assetId, source, amount);
        // Note we proportionally reduce the shares and pt for the term to keep the final
        // interest earned per share the same in future calculations.
        yieldTerm.shares -= uint128(
            (uint256(yieldTerm.shares) * amount) / totalYtSupply
        );
        yieldTerm.pt -= uint128(
            (uint256(yieldTerm.pt) * amount) / totalYtSupply
        );
        yieldTerms[assetId] = yieldTerm;
        // Return the shares released and value
        return (userShares, userInterest);
    }

    /// @notice Releases PT from a user and returns the shares and value it was worth
    /// @param finalState The finalized state of the term
    /// @param assetId The ID of the PT, which will be equal to the expiry
    /// @param amount The number of PT to reduce
    /// @return the number of shares and their value
    function _releasePT(
        FinalizedState memory finalState,
        uint256 assetId,
        address source,
        uint256 amount
    ) internal returns (uint256, uint256) {
        // We release the PT by deducting the shares needed to pay interest obligations
        // then distributing the remaining shares pro-rata [meaning PT earn interest after expiry]

        uint256 termShares = sharesPerExpiry[assetId];

        uint256 currentPricePerShare = _underlying(one, ShareState.Locked);

        // Now we use the price per share to calculate the shares needed to satisfy interest
        uint256 sharesForInterest = (uint256(finalState.interest) * one) /
            currentPricePerShare;

        // The remaining shares for PT holders
        uint256 ptShares = termShares - sharesForInterest;

        // The user's shares are their percent of the total
        // Note - This is more than 1 to 1 as interest goes up
        uint256 userShares = (amount * ptShares) / totalSupply[assetId];

        // Burn from the user and deduct their freed shares from the total for this term
        _burn(assetId, source, amount);
        sharesPerExpiry[assetId] = termShares - userShares;

        // Return the shares freed and use the price per share to get value
        return (userShares, (userShares * currentPricePerShare) / one);
    }

    /// @notice takes an input YT in the past and creates a new one in the future
    /// @param assetId The ID of the YT to delete
    /// @param amount The number of YT to delete
    /// @param destination The address to credit the new YT to
    /// @param isCompound if true the interest is compounded instead of released
    /// @return the accrued interest in underlying
    function convertYT(
        uint256 assetId,
        uint256 amount,
        address destination,
        bool isCompound
    ) external returns (uint256) {
        (bool isYieldToken, uint256 startDate, uint256 expiry) = _parseAssetId(
            assetId
        );
        // make sure asset is a YT
        if (!isYieldToken) revert ElementError.NotAYieldTokenId();
        // expiry must be greater than zero
        if (expiry == 0) revert ElementError.ExpirationDateMustBeNonZero();
        // start date must be greater than zero
        if (startDate == 0) revert ElementError.StartDateMustBeNonZero();

        // load the state for the term
        YieldState memory state = yieldTerms[assetId];
        // make sure a term exists for the input asset
        if (state.pt == 0 || state.shares == 0)
            revert ElementError.TermNotInitialized();
        // calculate the shares belonging to the user
        uint256 userShares = (uint256(state.shares) * amount) /
            totalSupply[assetId];
        // remove shares from the yield state and the yt to burn from pt

        yieldTerms[assetId] = YieldState(
            state.shares - uint128(userShares),
            state.pt - uint128(amount)
        );

        // burn the yt from the user's balance
        _burn(assetId, msg.sender, amount);

        uint256 value = _underlying(amount, ShareState.Locked);

        if (isCompound) {
            // deposit freed shares into YT
            uint256 discount = _createYT(
                destination,
                value,
                userShares,
                block.timestamp,
                expiry
            );

            // yt created at current time so discount should always be 0
            if (discount != 0) revert ElementError.InvalidYieldTokenCreation();

            // create PT
            _mint(expiry, destination, value - amount);
        } else {
            // calculate the user's interest in terms of shares
            uint256 interestShares = ((value - amount) * userShares) / value;
            // withdraw the interest from the yield source
            _withdraw(interestShares, destination, ShareState.Locked);
            // create yt with remaining shares
            _createYT(
                destination,
                amount,
                userShares - interestShares,
                block.timestamp,
                expiry
            );
            // update the state for expiry timestamps
            sharesPerExpiry[expiry] -= interestShares;
        }
        return (value - amount);
    }

    /// @notice removes and burns input amount of YT's and PT's
    /// @param yieldTokenId the yt to redeem
    /// @param principalTokenId the pt to redeem
    /// @param amount the quantity of asset to remove
    /// @return the underlying value withdrawn
    function redeem(
        uint256 yieldTokenId,
        uint256 principalTokenId,
        uint256 amount
    ) external onlyAuthorized returns (uint256) {
        // yieldTokenId 256 bits:
        //        |      1 BIT    |     127 BITS     |  128 BITS  |
        //        |       255     |     254 - 128    |  127 - 0   |
        //        | YT IDENTIFIER |    START TIME    | EXPIRATION |
        //           (1 << 255) + (startTime << 128) + expiration

        // principalTokenId 128 bits:
        //        |  128 BITS  |
        //        |  127 - 0   |
        //        | EXPIRATION |

        // The YTs and PTs must be from the same term and therefore
        // the expiration times must be equal
        (, , uint256 ytExpiry) = _parseAssetId(yieldTokenId);
        if (ytExpiry != principalTokenId)
            revert ElementError.IncongruentPrincipalAndYieldTokenIds();

        // YTs can have different start times for a particular expiry.
        // This means that each YieldState instance is backed by
        // a different amount of underlying at a different share price.
        YieldState memory state = yieldTerms[yieldTokenId];
        // multiply this YieldState instance's shares by the ratio
        // of the YTs the user wants to redeem (i.e. amount) to totalYTSupply
        // for this YieldState instance.
        uint128 totalSharesRedeemable = uint128(
            (uint256(state.shares) * amount) / totalSupply[yieldTokenId]
        );
        // Update local YieldState instance with adjusted values
        state.shares -= totalSharesRedeemable;
        state.pt -= uint128(amount);
        // burn the yts and pts being redeemed
        _burn(yieldTokenId, msg.sender, amount);
        _burn(principalTokenId, msg.sender, amount);
        // update storage instance
        yieldTerms[yieldTokenId] = state;
        // Update the sharesPerExpiry. Note that the sum of the shares
        // in each YieldState instance with the same expiry should match
        // this value
        sharesPerExpiry[principalTokenId] -= totalSharesRedeemable;
        // withdraw shares from vault to user and return the amount of underlying withdrawn
        return _withdraw(totalSharesRedeemable, msg.sender, ShareState.Locked);
    }

    /// @notice Decodes an unknown assetId into either a YT or PT and gives the
    ///         relevant time paramaters
    /// @param assetId A YT or PT id
    function _parseAssetId(uint256 assetId)
        internal
        view
        returns (
            bool isYieldToken,
            uint256 startDate,
            uint256 expirationDate
        )
    {
        isYieldToken = assetId >> 255 == 1;
        if (isYieldToken) {
            startDate = ((assetId) & (2**255 - 1)) >> 128;
            expirationDate = assetId & (2**(128) - 1);
        } else {
            expirationDate = assetId;
        }
    }
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
pragma solidity >=0.7.0;

import "./Errors.sol";

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
        if (msg.sender != owner)
            revert ElementError.Authorizable_SenderMustBeOwner();
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        if (!isAuthorized(msg.sender))
            revert ElementError.Authorizable_SenderMustBeAuthorized();
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

import "../interfaces/IERC20Permit.sol";

// This default erc20 library is designed for max efficiency and security.
// WARNING: By default it does not include totalSupply which breaks the ERC20 standard
//          to use a fully standard compliant ERC20 use 'ERC20PermitWithSupply"
abstract contract ERC20Permit is IERC20Permit {
    // --- ERC20 Data ---
    // The name of the erc20 token
    string public name;
    // The symbol of the erc20 token
    string public override symbol;
    // The decimals of the erc20 token, should default to 18 for new tokens
    uint8 public override decimals;

    // A mapping which tracks user token balances
    mapping(address => uint256) public override balanceOf;
    // A mapping which tracks which addresses a user allows to move their tokens
    mapping(address => mapping(address => uint256)) public override allowance;
    // A mapping which tracks the permit signature nonces for users
    mapping(address => uint256) public override nonces;

    // --- EIP712 niceties ---
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public override DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Initializes the erc20 contract
    /// @param name_ the value 'name' will be set to
    /// @param symbol_ the value 'symbol' will be set to
    /// @dev decimals default to 18 and must be reset by an inheriting contract for
    ///      non standard decimal values
    constructor(string memory name_, string memory symbol_) {
        // Set the state variables
        name = name_;
        symbol = symbol_;
        decimals = 18;

        // By setting these addresses to 0 attempting to execute a transfer to
        // either of them will revert. This is a gas efficient way to prevent
        // a common user mistake where they transfer to the token address.
        // These values are not considered 'real' tokens and so are not included
        // in 'total supply' which only contains minted tokens.
        balanceOf[address(0)] = type(uint256).max;
        balanceOf[address(this)] = type(uint256).max;

        // Optional extra state manipulation
        _extraConstruction();

        // Computes the EIP 712 domain separator which prevents user signed messages for
        // this contract to be replayed in other contracts.
        // https://eips.ethereum.org/EIPS/eip-712
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice An optional override function to execute and change state before immutable assignment
    function _extraConstruction() internal virtual {}

    // --- Token ---
    /// @notice Allows a token owner to send tokens to another address
    /// @param recipient The address which will be credited with the tokens
    /// @param amount The amount user token to send
    /// @return returns true on success, reverts on failure so cannot return false.
    /// @dev transfers to this contract address or 0 will fail
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // We forward this call to 'transferFrom'
        return transferFrom(msg.sender, recipient, amount);
    }

    /// @notice Transfers an amount of erc20 from a spender to a receipt
    /// @param spender The source of the ERC20 tokens
    /// @param recipient The destination of the ERC20 tokens
    /// @param amount the number of tokens to send
    /// @return returns true on success and reverts on failure
    /// @dev will fail transfers which send funds to this contract or 0
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        // Load balance and allowance
        uint256 balance = balanceOf[spender];
        require(balance >= amount, "ERC20: insufficient-balance");
        // We potentially have to change allowances
        if (spender != msg.sender) {
            // Loading the allowance in the if block prevents vanilla transfers
            // from paying for the sload.
            uint256 allowed = allowance[spender][msg.sender];
            // If the allowance is max we do not reduce it
            // Note - This means that max allowances will be more gas efficient
            // by not requiring a sstore on 'transferFrom'
            if (allowed != type(uint256).max) {
                require(allowed >= amount, "ERC20: insufficient-allowance");
                allowance[spender][msg.sender] = allowed - amount;
            }
        }
        // Update the balances
        balanceOf[spender] = balance - amount;
        // Note - In the constructor we initialize the 'balanceOf' of address 0 and
        //        the token address to uint256.max and so in 8.0 transfers to those
        //        addresses revert on this step.
        balanceOf[recipient] = balanceOf[recipient] + amount;
        // Emit the needed event
        emit Transfer(spender, recipient, amount);
        // Return that this call succeeded
        return true;
    }

    /// @notice This internal minting function allows inheriting contracts
    ///         to mint tokens in the way they wish.
    /// @param account the address which will receive the token.
    /// @param amount the amount of token which they will receive
    /// @dev This function is virtual so that it can be overridden, if you
    ///      are reviewing this contract for security you should ensure to
    ///      check for overrides
    function _mint(address account, uint256 amount) internal virtual {
        // Add tokens to the account
        balanceOf[account] = balanceOf[account] + amount;
        // Emit an event to track the minting
        emit Transfer(address(0), account, amount);
    }

    /// @notice This internal burning function allows inheriting contracts to
    ///         burn tokens in the way they see fit.
    /// @param account the account to remove tokens from
    /// @param amount  the amount of tokens to remove
    /// @dev This function is virtual so that it can be overridden, if you
    ///      are reviewing this contract for security you should ensure to
    ///      check for overrides
    function _burn(address account, uint256 amount) internal virtual {
        // Reduce the balance of the account
        balanceOf[account] = balanceOf[account] - amount;
        // Emit an event tracking transfers
        emit Transfer(account, address(0), amount);
    }

    /// @notice This function allows a user to approve an account which can transfer
    ///         tokens on their behalf.
    /// @param account The account which will be approve to transfer tokens
    /// @param amount The approval amount, if set to uint256.max the allowance does not go down on transfers.
    /// @return returns true for compatibility with the ERC20 standard
    function approve(address account, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // Set the senders allowance for account to amount
        allowance[msg.sender][account] = amount;
        // Emit an event to track approvals
        emit Approval(msg.sender, account, amount);
        return true;
    }

    /// @notice This function allows a caller who is not the owner of an account to execute the functionality of 'approve' with the owners signature.
    /// @param owner the owner of the account which is having the new approval set
    /// @param spender the address which will be allowed to spend owner's tokens
    /// @param value the new allowance value
    /// @param deadline the timestamp which the signature must be submitted by to be valid
    /// @param v Extra ECDSA data which allows public key recovery from signature assumed to be 27 or 28
    /// @param r The r component of the ECDSA signature
    /// @param s The s component of the ECDSA signature
    /// @dev The signature for this function follows EIP 712 standard and should be generated with the
    ///      eth_signTypedData JSON RPC call instead of the eth_sign JSON RPC call. If using out of date
    ///      parity signing libraries the v component may need to be adjusted. Also it is very rare but possible
    ///      for v to be other values, those values are not supported.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // The EIP 712 digest for this function
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner],
                        deadline
                    )
                )
            )
        );
        // Require that the owner is not zero
        require(owner != address(0), "ERC20: invalid-address-0");
        // Require that we have a valid signature from the owner
        require(owner == ecrecover(digest, v, r, s), "ERC20: invalid-permit");
        // Require that the signature is not expired
        require(
            deadline == 0 || block.timestamp <= deadline,
            "ERC20: permit-expired"
        );
        // Format the signature to the default format
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ERC20: invalid signature 's' value"
        );
        // Increment the signature nonce to prevent replay
        nonces[owner]++;
        // Set the allowance to the new value
        allowance[owner][spender] = value;
        // Emit an approval event to be able to track this happening
        emit Approval(owner, spender, value);
    }

    /// @notice Internal function which allows inheriting contract to set custom decimals
    /// @param decimals_ the new decimal value
    function _setupDecimals(uint8 decimals_) internal {
        // Set the decimals
        decimals = decimals_;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./IERC20.sol";

interface IYearnVault is IERC20 {
    function deposit(uint256, address) external returns (uint256);

    function withdraw(
        uint256,
        address,
        uint256
    ) external returns (uint256);

    // Returns the amount of underlying per each unit [1e18] of yearn shares
    function pricePerShare() external view returns (uint256);

    function governance() external view returns (address);

    function setDepositLimit(uint256) external;

    function totalSupply() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function apiVersion() external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./interfaces/IMultiToken.sol";
import "./libraries/Errors.sol";

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
            revert ElementError.InvalidERC20Bridge();
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
        if (from == address(0) || to == address(0))
            revert ElementError.RestrictedZeroAddress();

        // Check for inconsistent length
        if (ids.length != values.length)
            revert ElementError.BatchInputLengthMismatch();

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
        if (block.timestamp > deadline) revert ElementError.ExpiredDeadline();
        // Require that the owner is not zero
        if (owner == address(0)) revert ElementError.RestrictedZeroAddress();

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
        if (signer != owner) revert ElementError.InvalidSignature();

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

/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

library ElementError {
    /// ###############
    /// ### General ###
    /// ###############
    error TermExpired();
    error TermNotExpired();
    error TermNotInitialized();
    error PoolInitialized();
    error PoolNotInitialized();
    error ExceededSlippageLimit();
    error RestrictedZeroAddress();
    error ExpiredDeadline();
    error InvalidSignature();

    /// ##################
    /// ### MultiToken ###
    /// ##################
    error InvalidERC20Bridge();
    error BatchInputLengthMismatch();

    /// ############
    /// ### Term ###
    /// ############
    error UnsortedAssetIds();
    error NotAYieldTokenId();
    error ExpirationDateMustBeNonZero();
    error StartDateMustBeNonZero();
    error InvalidYieldTokenCreation();
    error IncongruentPrincipalAndYieldTokenIds();
    error VaultShareReserveTooLow();

    /// ############
    /// ### Pool ###
    /// ############
    error TimeStretchMustBeNonZero();
    error UnderlyingInMustBeNonZero();
    error InaccurateUnlockShareTrade();

    /// ##################
    /// ### TWAROracle ###
    /// ##################
    error TWAROracle_IncorrectBufferLength();
    error TWAROracle_BufferAlreadyInitialized();
    error TWAROracle_MinTimeStepMustBeNonZero();
    error TWAROracle_IndexOutOfBounds();
    error TWAROracle_NotEnoughElements();

    /// ######################
    /// ### FixedPointMath ###
    /// ######################
    error FixedPointMath_AddOverflow();
    error FixedPointMath_SubOverflow();
    error FixedPointMath_InvalidExponent();
    error FixedPointMath_NegativeOrZeroInput();
    error FixedPointMath_NegativeInput();

    /// #####################
    /// ### Authorizable ####
    /// #####################
    error Authorizable_SenderMustBeOwner();
    error Authorizable_SenderMustBeAuthorized();
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

// Forked from openzepplin
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}