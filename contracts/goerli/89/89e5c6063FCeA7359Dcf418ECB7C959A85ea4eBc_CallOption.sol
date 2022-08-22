// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "./OptionsPool.sol";

/**
 * @notice Contract implementation of a call option using
 * the abstract OptionsPool as base
 */
contract CallOption is OptionsPool {
    constructor(
        IERC20 _token,
        string memory name,
        string memory symbol,
        address _optionErc20Implementation,
        uint256 _expiryThreshold,
        uint256 _strikePricePrecision,
        IPriceCalculator _pricer,
        IOracle _priceProvider,
        uint256 _protocolFeePercentage,
        IProtocolFeeBurn _protocolFeeBurn
    )
        OptionsPool(
            _token,
            name,
            symbol,
            _optionErc20Implementation,
            _expiryThreshold,
            _strikePricePrecision,
            _pricer,
            _priceProvider,
            _protocolFeePercentage,
            _protocolFeeBurn
        )
    {}

    /**
     * @notice Override the base _profitOf function to include logics specific to a
     * call option
     * @inheritdoc OptionsPool
     */
    function _profitOf(uint256 amount, uint256 strikePrice)
        internal
        view
        override
        returns (uint256)
    {
        uint256 currentPrice = _currentPrice();
        if (currentPrice < strikePrice) return 0;
        return ((currentPrice - strikePrice) * amount) / currentPrice;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "../../Interfaces/IOptionsPool.sol";
import "../../Interfaces/IOracle.sol";
import "../../Interfaces/IProtocolFeeBurn.sol";
import "../../Interfaces/IPriceCalculator.sol";
import "../../Interfaces/ILiquidityMining.sol";
import "../../Interfaces/IPayoutPool.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice revert with this error when minShare larger than share
error REQUESTED_SHARE_TOO_LARGE();
/// @notice revert with this error when share is smaller than 0
error AVAILABLE_SHARE_LESS_THAN_ZERO();
/// @notice revert with this error when lock period is more than 30 days
error POOL_ERR_PERIOD_TOO_LONG();
/// @notice revert with this error when lock period is more than 1 day
error POOL_ERR_PERIOD_TOO_SHORT();
/// @notice revert with this error when
/// MaxUtilizationRate is either below 50 or above 100
error INVALID_LIMITATION_VALUE();
/// @notice revert with this error when CollateralizationRatio is either below 30 or above 100
error INVALID_COLLATERALIZATION_VALUE();
/// @notice revert with this error when
/// provided amount is more than remaning balance(maxDepositAmount - totalBalance).
error NO_DEPOSIT_ALLOWED();
/// @notice revert with this error when
/// current time has not passed the (t.creationTimestamp + lockupPeriodForTranches) time
error WITHDRAWL_LOCKED_UP();
/// @notice revert with this error when tranche state is closed
error TRANCHES_CLOSED();
/// @notice revert with this error when
/// fraction of strike price and strikePricePrecision is not zero
error OPTIONAL_POOL_ERR_PRICE_NOT_CORRECT();
/// @notice revert with this error when the option has not expired
error POOL_ERR_NOT_EXPIRED();
/// @notice revert with this error when the pool does not have enough liquidity
error POOL_ERR_NOT_ENOUGH_LIQUIDITY();
/// @notice revert with this error when the option of specific price and expiry date already exists.
error OPTION_ALREADY_EXISTS();
/// @notice revert with this error when oprion.expiry is 0 (already expired)
error POOL_ERR_INVALID_OPTIONERC20();
/// @notice revert with this error when holder is 0
error POOL_ERR_NOT_ENOUGH_BALANCE();

/**
 * @notice Base option pool contract that will be inherited by CallOption or PutOption
 * contains common functionalities of an OptionPool with some overridable functions
 * that will be unique to call and put option
 */
abstract contract OptionsPool is
    IOptionsPool,
    Pausable,
    AccessControl,
    ReentrancyGuard,
    ERC721
{
    using SafeERC20 for IERC20;

    uint256 public constant INITIAL_RATE = 1e20;
    address public immutable optionErc20Implementation;
    uint256 public strikePricePrecision;
    uint256 public expiryThreshold;
    IOracle public immutable priceProvider;
    IPriceCalculator public pricer;
    ILiquidityMining public liquidityMining;
    uint256 public lockupPeriodForTranches = 30 days;
    uint256 public maxUtilizationRate = 80;
    uint256 public collateralizationRatio = 50;
    uint256 public lockedAmount;
    uint256 public maxDepositAmount = type(uint256).max;
    uint256 public protocolFeePercentage; // 1% = 1e18, in 18dp
    IProtocolFeeBurn public protocolFeeBurn;
    /// @dev to be set in a seperate call due to stack too deep error
    IPayoutPool public payOutPool;
    uint256 public percentagePayout;

    uint256 public totalShare = 0;
    uint256 public totalBalance = 0;
    // required to know how much original stake the pool and the user has
    // before it has incurred any losses
    // will be required when liquidity mining
    uint256 public totalRawAmount = 0;
    mapping(address => uint256) public userRawAmount;

    Tranche[] public tranches;
    IERC20 public override token;

    // expiry => strikePrice => OptionErc20 address
    mapping(uint256 => mapping(uint256 => IOptionErc20)) public optionErc20s;
    // reverse mapping to reduce sload, maybe this is not needed
    mapping(IOptionErc20 => OptionErc20Detail) public optionErc20sReverse;
    // stores all options that expires into the same array
    // so that it is easy for ppl to loop through
    // in the real example, we will only allow expire at 8am utc, so we know the key to the mapping
    mapping(uint256 => IOptionErc20[]) public optionDates;
    // mapping from expiry to number of expired options that has been unlocked
    mapping(uint256 => uint256) public optionDateUnlockCount;

    constructor(
        IERC20 _token,
        string memory name,
        string memory symbol,
        address _optionErc20Implementation,
        uint256 _expiryThreshold,
        uint256 _strikePricePrecision,
        IPriceCalculator _pricer,
        IOracle _priceProvider,
        uint256 _protocolFeePercentage,
        IProtocolFeeBurn _protocolFeeBurn
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = _token;
        optionErc20Implementation = _optionErc20Implementation;
        strikePricePrecision = _strikePricePrecision;
        expiryThreshold = _expiryThreshold;
        pricer = _pricer;
        priceProvider = _priceProvider;
        protocolFeePercentage = _protocolFeePercentage;
        protocolFeeBurn = _protocolFeeBurn;
    }

    /**
     * @notice Used by admin to pause the contract in the case of emergency
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Used by admin to unpause the contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Used by admin for setting the liquidity lock-up periods during which
     * the liquidity providers who deposited the funds into the pools contracts
     * won't be able to withdraw them.
     * @param value Liquidity tranches lock-up in seconds
     */
    function setLockupPeriod(uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!_checkPeriod(value)) revert POOL_ERR_PERIOD_TOO_LONG();
        lockupPeriodForTranches = value;
    }

    /**
     * @notice Used by admin for setting the total maximum amount
     * that could be deposited into the pools contracts.
     * @param total Maximum amount of assets in the pool
     * in liquidity tranches combined
     **/
    function setMaxDepositAmount(uint256 total)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxDepositAmount = total;
    }

    /**
     * @notice Used by admin for setting the maximum share of the pool
     * size that could be utilized as a collateral in the options.
     *
     * Example: if `MaxUtilizationRate` = 50, then only 50%
     * of liquidity on the pools contracts would be used for
     * collateralizing options while 50% will be sitting idle
     * available for withdrawals by the liquidity providers.
     * @param value The utilization ratio in a range of 50% — 100%
     */
    function setMaxUtilizationRate(uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (value < 50 && value > 100) revert INVALID_LIMITATION_VALUE();
        maxUtilizationRate = value;
    }

    /**
     * @notice Used by admin for setting the collateralization ratio for the option
     * collateral size that will be locked at the moment of buying them.
     *
     * Example: if `CollateralizationRatio` = 50, then 50% of an option's
     * notional size will be locked in the pools at the moment of buying it:
     * say, 1 ETH call option will be collateralized with 0.5 ETH (50%).
     * Note that if an option holder's net P&L USD value (as options
     * are cash-settled) will exceed the amount of the collateral locked
     * in the option, she will receive the required amount at the moment
     * of exercising the option using the pool's unutilized (unlocked) funds.
     * @param value The collateralization ratio in a range of 30% — 100%
     */
    function setCollateralizationRatio(uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (value < 30 && value > 100) revert INVALID_COLLATERALIZATION_VALUE();
        collateralizationRatio = value;
    }

    /**
     * @notice Used by admin for setting the price calculator
     * contract that will be used for pricing the options.
     * @param pc A new price calculator contract address
     */
    function setPriceCalculator(IPriceCalculator pc)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pricer = pc;
    }

    /**
     * @notice Used by admin to set the liquidity mining logic contract
     * set to the zero address to deactivate the logic
     * @param lm New liquidity mining logic contract address
     */
    function setLiquidityMining(ILiquidityMining lm)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        liquidityMining = lm;
    }

    /**
     * @notice Used by admin to set the percentage of premium fee that
     * will be contributed as protocol fee
     * @param _protocolFeePercentage percentage of premium that will be used as the protocol
     * fee
     */
    function setProtocolFeePercentage(uint256 _protocolFeePercentage)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        protocolFeePercentage = _protocolFeePercentage;
    }

    /**
     * @notice Used by admin only to set protocol fee burn address. Protocol fee that
     * is collected from the premium will be sent to the burn address via the logic in
     * this protocolFeeBurn contract
     * @param _protocolFeeBurn contract that will contain the protocol fee burn logic
     *
     */
    function setProtocolFeeBurn(IProtocolFeeBurn _protocolFeeBurn)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        protocolFeeBurn = _protocolFeeBurn;
    }

    /**
     * @notice Used by admin to set the expiry threshold.
     * entire optionErc20 of a specified strike price and expiry
     * @param _expiryThreshold The time threshold after expiry that allows anyone to invalidate the
     * entire optionErc20 of a specified strike price and expiry
     */
    function setExpiryThreshold(uint256 _expiryThreshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        expiryThreshold = _expiryThreshold;
    }

    /**
     * @notice Used by admin to set the strike price precision of the underlying asset of the option
     * @param _strikePricePrecision The price 'steps' for the underlying asset. (eg. if strike price precision
     * is set to 10e6, that means that the strike price can only be an incremental of 10usd, 20usd,... 3010usd,...)
     * that means that strike price of 3001usd will not be allowed.
     */
    function setStrikePricePrecision(uint256 _strikePricePrecision)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        strikePricePrecision = _strikePricePrecision;
    }

    /**
     * @notice Used by admin to set the payout pool
     * @param _payOutPool The pool that will contain the accumulated token which will be
     * used to payout a partial of the profit
     **/
    function setPayOutPool(IPayoutPool _payOutPool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payOutPool = _payOutPool;
    }

    /**
     * @notice Used by admin to set the percentage payout
     * @param _percentagePayout percentage payout is the percentage of the option's buyers
     * profit that will be undertaken by the payoutpool.
     **/
    function setPercentagePayout(uint256 _percentagePayout)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        percentagePayout = _percentagePayout;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IOptionsPool).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }

    /**
     * @notice get the number of options from the specific expiry date
     * @param timestamp the expiry date of option that we are interested in
     **/
    function getOptionDatesLength(uint256 timestamp)
        external
        view
        returns (uint256)
    {
        return optionDates[timestamp].length;
    }

    /**
     * @notice Used for depositing the funds into the pool
     * and minting the liquidity tranche ERC721 token
     * which represents the liquidity provider's share
     * in the pool and her unrealized P&L for this tranche.
     * @param account The liquidity provider's address
     * @param amount The size of the liquidity tranche
     * @param minShare The minimum share in the pool for the user
     **/
    function provideFrom(
        address account,
        uint256 amount,
        uint256 minShare
    ) external whenNotPaused nonReentrant returns (uint256 share) {
        if (address(liquidityMining) != address(0)) {
            liquidityMining.beforeHook(account);
        }

        share = totalShare > 0 && totalBalance > 0
            ? (amount * totalShare) / totalBalance
            : amount * INITIAL_RATE;
        uint256 limit = maxDepositAmount - totalBalance;
        if (share < minShare) revert REQUESTED_SHARE_TOO_LARGE();
        if (share <= 0) revert AVAILABLE_SHARE_LESS_THAN_ZERO();
        if (amount > limit) revert NO_DEPOSIT_ALLOWED();

        totalShare += share;
        totalBalance += amount;
        totalRawAmount += amount;
        userRawAmount[account] += amount;

        uint256 trancheID = tranches.length;
        tranches.push(
            Tranche(TrancheState.Open, share, amount, block.timestamp)
        );
        _safeMint(account, trancheID);
        token.safeTransferFrom(_msgSender(), address(this), amount);
    }

    /**
     * @notice Used for withdrawing the funds from the pool
     * plus the net positive P&L earned or
     * minus the net negative P&L lost on
     * providing liquidity and selling options.
     * @param trancheID The liquidity tranche ID of which the stake is going
     * to be withdrawn. (Note: it is the owner's responsibility to keep track
     * of the ID of their own tranche)
     * @return amount The amount received after the withdrawal
     **/
    function withdraw(uint256 trancheID)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 amount)
    {
        address owner = ownerOf(trancheID);
        if (address(liquidityMining) != address(0)) {
            liquidityMining.beforeHook(owner);
        }
        amount = _withdraw(owner, trancheID);

        emit Withdrawn(owner, trancheID, amount);
    }

    /**
     * @notice Internal function that will handle the withdrawal logic
     * including the transferring of funds back to the owner
     * @dev It will check the state of the tranche,
     * handle the proportion of amount represeneted by the share
     * as well as handle the scenario whereby there are not enough funds to be
     * fully withdrawn due to locked collaterals
     * @param owner Owner fo the tranche
     * @param trancheID ID of the tranche which stakes is going to be withdrawn
     * @return amount The amount that is withdrawn
     */
    function _withdraw(address owner, uint256 trancheID)
        internal
        returns (uint256 amount)
    {
        Tranche memory t = tranches[trancheID];
        require(t.state == TrancheState.Open);
        require(_isApprovedOrOwner(_msgSender(), trancheID));
        if (block.timestamp <= t.creationTimestamp + lockupPeriodForTranches)
            revert WITHDRAWL_LOCKED_UP();
        amount = (t.share * totalBalance) / totalShare;

        uint256 maxBalanceToWithdraw = availableBalance();
        uint256 originalAmount = t.amount;
        // when unlockedamount is not enough for withdrawal
        if (amount > maxBalanceToWithdraw) {
            // set the amount to the total value of unlocked funds
            amount = maxBalanceToWithdraw;
            uint256 share = (maxBalanceToWithdraw * totalShare) / totalBalance;
            uint256 amountProportion = (share * 1e20) / t.share;

            t.share = t.share - share;
            totalShare -= share;
            totalBalance -= maxBalanceToWithdraw;

            /// calcute how much of the raw amount is deducted
            uint256 rawAmountDeducted = (t.amount * amountProportion) / 1e20;
            originalAmount = rawAmountDeducted;
            t.amount -= rawAmountDeducted;
            totalRawAmount -= rawAmountDeducted;
            userRawAmount[owner] -= rawAmountDeducted;
        } else {
            // close the tranche if we manage to withdraw completely
            t.state = TrancheState.Closed;

            // able to remove share and amount completely
            totalShare -= t.share;
            totalBalance -= amount;

            totalRawAmount -= t.amount;
            userRawAmount[owner] -= t.amount;
        }

        tranches[trancheID] = t;

        token.safeTransfer(owner, amount);
    }

    /**
     * @notice get the available balance that is available to sell option or withdraw
     * @return balance Returns the amount of liquidity available for withdrawing
     **/
    function availableBalance() public view returns (uint256 balance) {
        return totalBalance - lockedAmount;
    }

    /**
     * @notice A hook that overrides the default internal function in
     * the OpenZeppelin's ERC721 contract.
     * Will check that the tranche is open before any token transfer
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address,
        address,
        uint256 id
    ) internal view override {
        if (tranches[id].state != TrancheState.Open) revert TRANCHES_CLOSED();
    }

    /**
     * @notice Sell an option to buyer using a portion of the pool amount as collateral
     * @param holder the owner of the option
     * @param expiry the expiration date of the option of which option can only be exercised
     * after the expirition date
     * @param amount the amount of underlying asset that the option owner has right to buy/sell
     * @param strike the strike price of the option
     */
    function sellOption(
        address holder,
        uint256 expiry,
        uint256 amount,
        uint256 strike
    ) external whenNotPaused nonReentrant {
        // strike price precision
        if (strike % strikePricePrecision != 0)
            revert OPTIONAL_POOL_ERR_PRICE_NOT_CORRECT();

        uint256 amountToBeLocked = _calculateLockedAmount(amount);

        uint256 period = expiry - block.timestamp;
        //Revert if period is less than 1 day
        if (period < 1 days) revert POOL_ERR_PERIOD_TOO_SHORT();
        //Revert if period is more than 30 days
        if (!_checkPeriod(period)) revert POOL_ERR_PERIOD_TOO_LONG();
        //Only option that expires at 8am UTC is allowed
        if (!_checkUTCSpecificTime(expiry)) revert POOL_ERR_NOT_EXPIRED();
        if (
            (lockedAmount + amountToBeLocked) * 100 >
            totalBalance * maxUtilizationRate
        ) revert POOL_ERR_NOT_ENOUGH_LIQUIDITY();
        uint256 premium = _calculatePremiumPriceUpdatePercentageFactor(
            period,
            amount,
            strike
        );
        lockedAmount += amountToBeLocked;
        IOptionErc20 optionErc20 = optionErc20s[expiry][strike];
        // deploy this optionErc20 if not found
        if (address(optionErc20) == address(0)) {
            optionErc20 = deployOptionErc20(expiry, strike);
        }

        optionErc20.mint(holder, amount, amountToBeLocked, premium);

        token.safeTransferFrom(_msgSender(), address(this), premium);
        emit Purchase(holder, expiry, strike, amount, premium);
    }

    /**
     * @notice An internal function which will perform the calculation of
     * the amount of collateral which will be locked for the option that is sold
     * @param amount The option amount
     * @return collateral The collateral which will be locked up
     */
    function _calculateLockedAmount(uint256 amount)
        internal
        virtual
        returns (uint256)
    {
        return (amount * collateralizationRatio) / 100;
    }

    /**
     * @notice Deploy an optionErc20 contract of a particular expiry and strikeprice
     * using minimal proxy pattern
     * @param expiry Expiration of the option
     * @param strikePrice Strike price of the option
     * @return optionErc20 address of the deployed optionErc20 contract
     */
    function deployOptionErc20(uint256 expiry, uint256 strikePrice)
        public
        whenNotPaused
        returns (IOptionErc20 optionErc20)
    {
        if (address(optionErc20s[expiry][strikePrice]) != address(0))
            revert OPTION_ALREADY_EXISTS();

        // some gas expensive operation that the first option buyer needs to bear
        optionErc20 = _deployAndInitOptionErc20(expiry, strikePrice);
        optionErc20s[expiry][strikePrice] = optionErc20;
        optionDates[expiry].push(optionErc20);
        optionErc20sReverse[optionErc20] = OptionErc20Detail({
            expiry: expiry,
            strikePrice: strikePrice
        });
    }

    /**
     * @notice An internal function which will deploy the OptionErc20 contract
     * using minimal proxy pattern and add the details to the relevant mappings
     * @param expiry The expiration date of the option
     * @param strikePrice The strike price of the option
     * @return optionErc20 The address of the deployed contract
     */
    function _deployAndInitOptionErc20(uint256 expiry, uint256 strikePrice)
        internal
        returns (IOptionErc20 optionErc20)
    {
        address clonedAddress = Clones.clone(optionErc20Implementation);
        optionErc20 = IOptionErc20(clonedAddress);
        optionErc20.initialize(expiry, strikePrice, expiryThreshold);
        emit CreateOptionErc20(expiry, strikePrice, clonedAddress);
    }

    /**
     * @notice Exercise and option after its expiration date. Can be called
     * by anyone. Unlock the premium and collateral and return them back to the pool
     * @param optionErc20 the address of the optionErc20 that will be unlocked
     * @param holder holder of the option
     */
    function unlock(IOptionErc20 optionErc20, address holder)
        external
        whenNotPaused
        nonReentrant
    {
        OptionErc20Detail memory detail = optionErc20sReverse[optionErc20];
        // expiry date is checked in optionErc20
        // this check is added also as a way to check if this address is valid
        if (detail.expiry == 0) revert POOL_ERR_INVALID_OPTIONERC20();
        uint256 balanceOf = optionErc20.balanceOf(holder);
        if (balanceOf <= 0) revert POOL_ERR_NOT_ENOUGH_BALANCE();
        uint256 profit = _profitOf(balanceOf, detail.strikePrice);
        (
            uint256 unlockedAmount,
            uint256 unlockedPremium,
            bool isFullyUnlocked
        ) = optionErc20.burn(holder, balanceOf);

        _unlock(
            unlockedAmount,
            unlockedPremium,
            isFullyUnlocked,
            detail.expiry
        );

        if (profit > 0) {
            // if payoutPool exist
            if (address(payOutPool) != address(0) && percentagePayout > 0) {
                uint256 payoutAmount = (profit * percentagePayout) / 1e20;

                // if payout fail, profit will not be beared by the payout pool
                try payOutPool.payout(payoutAmount, holder) returns (
                    uint256 leftover
                ) {
                    profit -= payoutAmount - leftover;
                } catch {}
            }

            uint256 remainingBalance = totalBalance;
            // in case profit exceeds whatever is left in the pool
            // especially during large price swing
            // and profit is large
            if (profit > remainingBalance) {
                profit = remainingBalance;
            }
            _send(holder, profit);
        }
        emit Exercised(detail.expiry, detail.strikePrice, holder, profit);
    }

    /**
     * @notice Unlock and invalidate the optionErc20, returning the locked collateral and premium
     * to the pool
     * @param optionErc20 the optionErc20 address that we would like to invalidate
     */
    function unlockOptionErc20(IOptionErc20 optionErc20)
        external
        whenNotPaused
        nonReentrant
    {
        OptionErc20Detail memory detail = optionErc20sReverse[optionErc20];
        // expiry date is checked in optionErc20
        // this check is added also as a way to check if this address is valid
        if (detail.expiry == 0) revert POOL_ERR_INVALID_OPTIONERC20();

        (uint256 unlockedAmount, uint256 unlockedPremium) = optionErc20
            .fullyUnlock();

        _unlock(unlockedAmount, unlockedPremium, true, detail.expiry);
        emit FullyUnlocked(address(optionErc20));
    }

    /**
     * @notice Will be used to withdraw all funds from the pool in the case of an emergency.
     * This function can only be called by the admin only when the contract is paused.
     * Admin will then have the responsibilty to return the funds to respective owners manually
     * @param recipient The recipient of the withdrawn funcs
     * @param amount The amount to be withdrawn
     */
    function emergencyWithdraw(address recipient, uint256 amount)
        external
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        token.safeTransfer(recipient, amount);
    }

    /**
     * @notice An internal function that will handle the logic when an option is unlocked
     * @dev Including logic for protocol burn
     * @param unlockedAmount Amount of collateral which will be unlocked
     * @param unlockedPremium Amount of premium which will be unlocked
     * @param isFullyUnlocked A flag which is used to indicate if the optionErc20 is fully unlocked
     * (i.e. no erc20s are left in the contract)
     * @param expiry The expiration date of the option
     */
    function _unlock(
        uint256 unlockedAmount,
        uint256 unlockedPremium,
        bool isFullyUnlocked,
        uint256 expiry
    ) internal {
        lockedAmount -= unlockedAmount;
        uint256 premiumEarned = unlockedPremium;

        if (isFullyUnlocked) {
            optionDateUnlockCount[expiry]++;
        }

        // a portion of the premium is transferred off to a burner contract
        if (
            protocolFeePercentage > 0 && address(protocolFeeBurn) != address(0)
        ) {
            uint256 fee = (protocolFeePercentage * premiumEarned) / 1e20;
            if (fee == 0) {
                // adding this just in case
                // burn something even though precision is too small
                // the premium will never be zero due to checking in sellOption (_calculateTotalPremium)
                fee = 1;
            }
            // send fee to protocolFeeBurn
            // this flow will allow us to bypass token approval of the protocolFeeBurn contract
            token.safeTransfer(address(protocolFeeBurn), fee);
            protocolFeeBurn.swapAndBurn(address(token));
            premiumEarned -= fee;
        }

        totalBalance += premiumEarned;
    }

    /**
     * @notice An internal function that will handle to logic of the sending of amount
     * @param to To whom the amount will be sent to
     * @param transferAmount The amount that will be transferred to the recipient
     */
    function _send(address to, uint256 transferAmount) private {
        require(to != address(0));
        totalBalance -= transferAmount;
        token.safeTransfer(to, transferAmount);
    }

    /**
     * @notice Returns the amount of unrealized P&L of the option
     * that could be received by the option holder in case
     * if she exercises it as an ITM (in-the-money) option.
     * @param amount amount of options
     * @param strikePrice strike price of the option
     **/
    function profitOf(uint256 amount, uint256 strikePrice)
        external
        view
        returns (uint256)
    {
        return _profitOf(amount, strikePrice);
    }

    /**
     * @notice Internal function which will be needed to override by
     * the call or put option
     * @param amount The amount of underlying asset in the option
     * @param strikePrice The strike price of the option
     */
    function _profitOf(uint256 amount, uint256 strikePrice)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @notice Used for calculating the `TotalPremium`
     * for the particular option with regards to
     * the parameters chosen by the option buyer
     * such as the period of holding, size (amount)
     * and strike price. Based on current oracle price
     * @param timestamp The expiry time in unix timestamp format
     * @param amount The size of the option
     * @param strike strike price
     **/
    function calculateTotalPremium(
        uint256 timestamp,
        uint256 amount,
        uint256 strike
    ) external view returns (uint256) {
        uint256 period = timestamp - block.timestamp;
        return _calculateTotalPremium(period, amount, strike);
    }

    /**
     * @notice An overridable internal function which is used to calculate the total premium
     * of an option. This function will not update the IV of the priceCalculator
     * @dev PutOption will need to override this default internal function
     * @param period The time to expiry of an option
     * @param amount The option amount
     * @param strike The strike price of the option
     * @return premiumPrice The premium price of the option
     */
    function _calculateTotalPremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) internal view virtual returns (uint256) {
        uint256 premium = pricer.calculatePremiumPrice(
            amount,
            strike,
            _currentPrice(),
            period
        );
        return premium;
    }

    /**
     * @notice An overridable internal function which is used to calculate the total premium
     * of an option. This function WILL update the IV of the priceCalculator
     * @dev PutOption will need to override this default internal function
     * @param period The time to expiry of an option
     * @param amount The option amount
     * @param strike The strike price of the option (in 8dp, same dp as oracle)
     * @return premiumPrice The premium price of the option
     */
    function _calculatePremiumPriceUpdatePercentageFactor(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) internal virtual returns (uint256) {
        uint256 premium = pricer.calculatePremiumPriceUpdatePercentageFactor(
            amount,
            strike,
            _currentPrice(),
            period
        );
        return premium;
    }

    /**
     * @notice An internal function which will call the price oracle
     * @return price The price of the underlying asset returned by the
     * specified oracle
     */
    function _currentPrice() internal view returns (uint256 price) {
        return uint256(priceProvider.getCurrentPrice());
    }

    /**
     * @notice An internal function that will unforce the checking of
     * expiriration date that has to be 8am UTC daily only
     * @param timestamp The expiration timestamp
     * @return isSpecificTime  True if timestamp is at 8am utc, False otherwise
     */
    function _checkUTCSpecificTime(uint256 timestamp)
        internal
        pure
        returns (bool)
    {
        uint256 timeSeconds = 28800; // 8am utc
        uint256 daySeconds = 86400;

        uint256 time = timestamp % daySeconds;
        return timeSeconds == time;
    }

    /**
     * @notice An internal function to check that the _period should be
     * less than or equal 30 days
     * @param _period number of days to be locked for
     * @return True if the lock period is less than 30 days
     */
    function _checkPeriod(uint256 _period) internal pure returns (bool) {
        if (_period <= 30 days) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IOptionErc20.sol";

interface IOptionsPool is IERC721 {
    enum TrancheState {
        Invalid,
        Open,
        Closed
    }

    /**
     * @param state The state of the liquidity tranche: Invalid, Open, Closed
     * @param share The liquidity provider's share in the pool
     * @param amount The size of liquidity provided
     * @param creationTimestamp The liquidity deposit timestamp
     **/
    struct Tranche {
        TrancheState state;
        uint256 share;
        uint256 amount;
        uint256 creationTimestamp;
    }

    struct OptionErc20Detail {
        uint256 expiry;
        uint256 strikePrice;
    }

    /**
     * @param account The liquidity provider's address
     * @param trancheID The liquidity tranche ID
     **/
    event Withdrawn(
        address indexed account,
        uint256 indexed trancheID,
        uint256 amount
    );

    /**
     * @param holder Option holder
     * @param expiry Option expiry
     * @param strikePrice Option strikeprice
     * @param amount amount of options purchased
     * @param premium amount of premium paid
     **/
    event Purchase(
        address indexed holder,
        uint256 indexed expiry,
        uint256 indexed strikePrice,
        uint256 amount,
        uint256 premium
    );

    event CreateOptionErc20(
        uint256 indexed expiry,
        uint256 indexed strikePrice,
        address optionErc20
    );

    event Exercised(
        uint256 indexed expiry,
        uint256 indexed strikePrice,
        address indexed holder,
        uint256 profit
    );

    event FullyUnlocked(address indexed optionErc20);

    function token() external view returns (IERC20);

    function provideFrom(
        address account,
        uint256 amount,
        uint256 minShare
    ) external returns (uint256 share);

    function sellOption(
        address holder,
        uint256 expiry,
        uint256 amount,
        uint256 strike
    ) external;

    function calculateTotalPremium(
        uint256 timestamp,
        uint256 amount,
        uint256 strike
    ) external view returns (uint256);

    function unlock(IOptionErc20 optionErc20, address holder) external;

    function unlockOptionErc20(IOptionErc20 optionErc20) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

/**
 * @dev we will decide later on the format of the oracle
 *  for now it is as simple as it can get
 */
interface IOracle {
    function getCurrentPrice() external view returns (int256);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

interface IProtocolFeeBurn {
    function swapAndBurn(address tokenBurn) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

interface IPriceCalculator {
    function calculatePremiumPriceUpdatePercentageFactor(
        uint256 amount,
        uint256 strikePrice,
        uint256 currentPrice,
        uint256 timeToExpire
    ) external returns (uint256);

    function calculatePremiumPrice(
        uint256 amount,
        uint256 strikePrice,
        uint256 currentPrice,
        uint256 timeToExpire
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

interface ILiquidityMining {
    function beforeHook(address recipient) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

interface IPayoutPool {
    function payout(uint256 amount, address recipient)
        external
        returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IOptionErc20 is IERC20Upgradeable {
    function initialize(
        uint256 _optionExpiryTimestamp,
        uint256 _strikePrice,
        uint256 _expiryThreshold
    ) external;

    function mint(
        address to,
        uint256 amountDenominated,
        uint256 lockedAmount,
        uint256 premiumPaid
    ) external;

    function burnAll(address account)
        external
        returns (
            uint256 unlockedAmount,
            uint256 unlockedPremium,
            bool isFullyUnlocked
        );

    function burn(address account, uint256 amountDenominated)
        external
        returns (
            uint256 unlockedAmount,
            uint256 unlockedPremium,
            bool isFullyUnlocked
        );

    function fullyUnlock()
        external
        returns (uint256 unlockedAmount, uint256 unlockedPremium);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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