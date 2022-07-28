// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/ILendingAddressRegistry.sol";
import "./interfaces/IPriceOracleAggregator.sol";
import "./interfaces/ILendingMarket.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/IAirUSD.sol";

/**
 * @title LendingMarket
 * @notice Lending pools where users can deposit/withdraw collateral and borrow AirUSD.
 * @dev If the user's health factor is below 1, anyone can liquidate his/her position.
 * Protocol will charge debt interest from borrowers and protocol revenue from liquidation.
 */
contract LendingMarket is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ILendingMarket
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using SafeERC20 for IAirUSD;

    /// @notice A struct to represent the rate in numerator/denominator
    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    /// @notice A struct for lending market settings
    struct MarketSettings {
        Rate interestApr; // debt interest rate in APR
        Rate orgFeeRate; // fees that will be charged upon minting AirUSD (0.3% in AirUSD)
        Rate liquidationPenalty; // liquidation penalty fees (5%)
    }

    /// @notice A struct for collateral settings
    struct CollateralSetting {
        bool isValid; // if collateral is valid or not
        Rate creditLimitRate; // collateral borrow limit (e.g. USDs = 80%, BTCs = 70%, AVAXs=70%)
        Rate liqLimitRate; // collateral liquidation threshold rate (greater than credit limit rate)
        uint8 decimals; // collateral token decimals
        uint256 totalBorrowCap;
    }

    /// @notice A struct for users collateral position
    struct Position {
        uint256 shares; // collateral amount
        uint256 debtPrincipal; // debt amount
        uint256 debtPortion; // accumulated debt interest
    }

    /// @notice An event thats emitted when user deposits collateral
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    /// @notice An event thats emitted when user borrows AirUSD
    event Borrowed(address indexed user, uint256 airUSDAmount);
    /// @notice An event thats emitted when user withdraws collateral
    event Withdraw(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    /// @notice An event thats emitted when user repays AirUSD
    event Repay(address indexed user, uint256 airUSDAmount);
    /// @notice An event thats emitted when liquidator liquidates a user's position
    event Liquidate(
        address indexed user,
        address indexed token,
        uint256 amount,
        address indexed liquidator
    );

    /// @notice address provider
    ILendingAddressRegistry public addressProvider;
    /// @notice AirUSD token address
    IAirUSD public airUSD;
    /// @notice lending market settings
    MarketSettings public settings;
    /// @notice collateral tokens in array
    address[] public collateralTokens;
    /// @notice collateral settings
    mapping(address => CollateralSetting) public collateralSettings; // token => collateral setting
    mapping(address => uint256) public collateralTotalShares; // token => total shares
    /// @notice users collateral position
    mapping(address => mapping(address => Position)) internal userPositions; // user => collateral token => position
    /// @notice airUSD total borrows per collateral token
    mapping(address => uint256) public totalBorrowsPerCollateral;
    /// @notice users array per collateral token
    mapping(address => address[]) internal marketUsers; // collateral token => users array
    /// @notice market user flag
    mapping(address => mapping(address => bool)) internal isMarketUser; // user => collateral token => flag

    /// @notice total borrowed amount accrued so far
    uint256 public totalDebtAmount;
    /// @notice last time of debt accrued
    uint256 public totalDebtAccruedAt;
    /// @notice total borrowed portion
    uint256 public totalDebtPortion;
    /// @notice total protocol fees accrued so far
    uint256 public totalFeeCollected;

    /**
     * @notice Initializer.
     * @param _provider address provider
     * @param _airUSD AirUSD token address
     * @param _settings lending market settings
     */
    function initialize(
        address _provider,
        IAirUSD _airUSD,
        MarketSettings memory _settings
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        // validates lending market settings
        _validateRate(_settings.interestApr); // should be updated to use cov ratio
        _validateRate(_settings.orgFeeRate); // 0.3%
        _validateRate(_settings.liquidationPenalty); // 5%

        addressProvider = ILendingAddressRegistry(_provider);
        airUSD = _airUSD;
        settings = _settings;
    }

    /**
     * @notice accrue debt interest
     * @dev Updates the contract's state by calculating the additional interest accrued since the last time
     */
    function accrue() public {
        // calculate additional interest from last time
        uint256 additionalInterest = _calculateInterestFromLastTime();

        // set last time accrued
        totalDebtAccruedAt = block.timestamp;

        // plus additional interest
        totalDebtAmount += additionalInterest;
        totalFeeCollected += additionalInterest;
    }

    /**
     * @notice set new address provider
     * @param _provider new address provider
     */
    function setAddressProvider(address _provider) external onlyOwner {
        addressProvider = ILendingAddressRegistry(_provider);
    }

    /**
     * @notice add a new collateral token
     * @dev only owner can call this function
     * @param _token collateral token address
     * @param _creditLimitRate borrow limit
     * @param _liqLimitRate liquidation threshold rate
     */
    function addCollateralToken(
        address _token,
        Rate memory _creditLimitRate,
        Rate memory _liqLimitRate,
        uint256 _totalBorrowCap
    ) external onlyOwner {
        // validates collateral settings
        _validateRate(_creditLimitRate);
        _validateRate(_liqLimitRate);

        // check if collateral token already exists
        require(!collateralSettings[_token].isValid, "collateral token exists");

        // add a new collateral
        collateralSettings[_token] = CollateralSetting({
            isValid: true,
            creditLimitRate: _creditLimitRate,
            liqLimitRate: _liqLimitRate,
            decimals: IERC20MetadataUpgradeable(_token).decimals(),
            totalBorrowCap: _totalBorrowCap
        });
        collateralTokens.push(_token);
    }

    function toogleCollateralToken(address _token) external onlyOwner {
        collateralSettings[_token].isValid;
    }

    /**
     * @notice update collateral token settings
     * @dev only owner can call this function
     * @param _token collateral token address
     * @param _creditLimitRate borrow limit
     * @param _liqLimitRate liquidation threshold rate
     */
    function updateCollateralToken(
        address _token,
        Rate memory _creditLimitRate,
        Rate memory _liqLimitRate,
        uint256 _totalBorrowCap
    ) external onlyOwner {
        // validates collateral settings
        _validateRate(_creditLimitRate);
        _validateRate(_liqLimitRate);

        // check if collateral token already exists
        require(collateralSettings[_token].isValid, "invalid collateral token");

        // update collateral token settings
        collateralSettings[_token] = CollateralSetting({
            isValid: true,
            creditLimitRate: _creditLimitRate,
            liqLimitRate: _liqLimitRate,
            decimals: IERC20MetadataUpgradeable(_token).decimals(),
            totalBorrowCap: _totalBorrowCap
        });
    }

    /**
     * @notice remove an existing collateral token
     * @dev only owner can call this function
     * @param _token collateral token address
     */
    function removeCollateralToken(address _token) external onlyOwner {
        // check if collateral token already exists
        require(collateralSettings[_token].isValid, "invalid collateral token");

        collateralSettings[_token].isValid = false;

        // remove an existing collateral
        uint256 index = 0;
        uint256 length = collateralTokens.length;
        for (; index < length; index++) {
            if (collateralTokens[index] == _token) {
                break;
            }
        }

        collateralTokens[index] = collateralTokens[length - 1];
        delete collateralTokens[length - 1];
        collateralTokens.pop();
    }

    /**
     * @notice returns all collateral tokens in array format
     * @return The collateral tokens in array format
     */
    function allCollateralTokens() external view returns (address[] memory) {
        return collateralTokens;
    }

    /**
     * @notice collect protocol fees accrued so far
     * @dev only owner can call this function
     */
    function collectOrgFee() external nonReentrant onlyOwner {
        accrue();

        // collect protocol fees in AirUSD
        _transferFee(totalFeeCollected, true);
        totalFeeCollected = 0;
    }

    /**
     * @notice deposit collateral
     * @dev user can call this function after approving his/her collateral amount
     * @param _token collateral token address
     * @param _amount collateral amount to deposit
     * @param _onBehalfOf deposit collateral for
     */
    function deposit(
        address _token,
        uint256 _amount,
        address _onBehalfOf
    ) external nonReentrant {
        require(collateralSettings[_token].isValid, "invalid token");

        uint256 shares = sharesFromAmount(_token, _amount);

        // get collateral from depositor
        IERC20MetadataUpgradeable(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // update a user's collateral position
        userPositions[_onBehalfOf][_token].shares += shares;
        collateralTotalShares[_token] += shares;

        // check if new market user enters
        if (!isMarketUser[_onBehalfOf][_token]) {
            isMarketUser[_onBehalfOf][_token] = true;
            marketUsers[_token].push(_onBehalfOf);
        }

        emit Deposit(_onBehalfOf, _token, _amount, shares);
    }

    /**
     * @notice borrow AirUSD
     * @dev user can call this function after depositing his/her collateral
     * @param _token collateral token address
     * @param _airUSDAmount AirUSD amount to borrow
     */
    function borrow(address _token, uint256 _airUSDAmount)
        external
        nonReentrant
    {
        // check if collateral is valid
        require(collateralSettings[_token].isValid, "invalid token");

        accrue();

        // calculate borrow limit in USD
        uint256 creditLimit = _creditLimitUSD(msg.sender, _token);
        // calculate debt amount in USD
        uint256 debtAmount = _debtUSD(msg.sender, _token);

        // check if additional borrow is available
        require(
            debtAmount + _airUSDAmount <= creditLimit,
            "insufficient collateral"
        );

        require(
            totalBorrowsPerCollateral[_token] + _airUSDAmount <=
                collateralSettings[_token].totalBorrowCap,
            "borrow cap reached"
        );

        // calculate AirUSD mint fee
        uint256 orgFee = (_airUSDAmount * settings.orgFeeRate.numerator) /
            settings.orgFeeRate.denominator;
        totalFeeCollected += orgFee;

        // mint AirUSD to user
        airUSD.mint(msg.sender, _airUSDAmount - orgFee);

        // update user's collateral position
        Position storage position = userPositions[msg.sender][_token];
        if (totalDebtPortion == 0) {
            totalDebtPortion = _airUSDAmount;
            position.debtPortion = _airUSDAmount;
        } else {
            uint256 plusPortion = (totalDebtPortion * _airUSDAmount) /
                totalDebtAmount;
            totalDebtPortion += plusPortion;
            position.debtPortion += plusPortion;
        }
        position.debtPrincipal += _airUSDAmount;
        totalDebtAmount += _airUSDAmount;

        // increase total borrows of the collateral market
        totalBorrowsPerCollateral[_token] += _airUSDAmount;

        emit Borrowed(msg.sender, _airUSDAmount);
    }

    /**
     * @notice withdraw collateral
     * @dev user can call this function after depositing his/her collateral
     * @param _token collateral token address
     * @param _amount collateral amount to withdraw
     */
    function withdraw(address _token, uint256 _amount) external nonReentrant {
        // check if collateral is valid
        require(collateralSettings[_token].isValid, "invalid token");

        accrue();

        Position storage position = userPositions[msg.sender][_token];

        uint256 shares = sharesFromAmount(_token, _amount);
        // need to consider dust here
        if (amountFromShares(_token, shares) < _amount) {
            shares += 1;
        }

        // check if withdraw shares is more than the collateral shares
        require(position.shares >= shares, "insufficient collateral");

        // calculate borrow limit after withdraw in USD
        uint256 creditLimitAfterWithdraw = (_tokenUSD(
            _token,
            amountFromShares(_token, position.shares - shares)
        ) * collateralSettings[_token].creditLimitRate.numerator) /
            collateralSettings[_token].creditLimitRate.denominator;
        // calculate debt amount in USD
        uint256 debtAmount = _debtUSD(msg.sender, _token);

        // check if withdraw is available
        require(
            debtAmount <= creditLimitAfterWithdraw,
            "insufficient collateral"
        );

        // update user's collateral position
        position.shares -= shares;
        collateralTotalShares[_token] -= shares;

        // transfer collateral to user
        IERC20MetadataUpgradeable(_token).safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _token, _amount, shares);
    }

    /**
     * @notice repay position with AirUSD
     * @dev user can call this function after approving his/her AirUSD amount to repay
     * @param _token collateral token address
     * @param _airUSDAmount AirUSD amount to repay
     */
    function repay(address _token, uint256 _airUSDAmount)
        external
        nonReentrant
    {
        // check if collateral is valid
        require(collateralSettings[_token].isValid, "invalid token");

        accrue();

        require(_airUSDAmount > 0, "invalid amount");

        Position storage position = userPositions[msg.sender][_token];

        // calculate debt amount in USD
        uint256 debtAmount = _debtUSD(msg.sender, _token);
        uint256 debtPrincipal = position.debtPrincipal;
        uint256 debtInterest = debtAmount - debtPrincipal;

        // only pays for the debt and returns remainings
        _airUSDAmount = _airUSDAmount > debtAmount ? debtAmount : _airUSDAmount;

        // burn repaid AirUSD
        airUSD.burnFrom(msg.sender, _airUSDAmount);

        // update user's collateral position
        uint256 paidPrincipal = _airUSDAmount > debtInterest
            ? _airUSDAmount - debtInterest
            : 0;
        uint256 minusPortion = paidPrincipal == debtPrincipal
            ? position.debtPortion
            : (totalDebtPortion * _airUSDAmount) / totalDebtAmount;

        totalDebtAmount -= _airUSDAmount;
        totalDebtPortion -= minusPortion;
        position.debtPrincipal -= paidPrincipal;
        position.debtPortion -= minusPortion;

        // decrease total borrows of the collateral market (exclude only principls)
        totalBorrowsPerCollateral[_token] -= paidPrincipal;

        emit Repay(msg.sender, _airUSDAmount);
    }

    function liquidate(address _user, address _token)
        external
        override
        nonReentrant
    {
        // check if msg.sender is chainlink keeper
        require(addressProvider.isKeeper(msg.sender), "not keeper");
        // check if collateral is valid
        require(collateralSettings[_token].isValid, "invalid token");

        accrue();

        Position storage position = userPositions[_user][_token];
        // calculate debt amount in USD
        uint256 debtAmount = _debtUSD(_user, _token);

        // check if liquidation is available
        require(
            debtAmount >= _liquidateLimitUSD(_user, _token),
            "not liquidatable"
        );

        // burn airUSD from keeper
        airUSD.burnFrom(msg.sender, debtAmount);

        // get price from collateral token oracle contract
        uint256 price = IPriceOracleAggregator(
            addressProvider.getPriceOracleAggregator()
        ).viewPriceInUSD(_token);
        // returnUSD = debtAmount + liquidation penalty (105%)
        uint256 returnUSD = debtAmount +
            (debtAmount * settings.liquidationPenalty.numerator) /
            settings.liquidationPenalty.denominator;
        // collateral amount in returnUSD
        uint256 collateralAmountIn = (returnUSD *
            (10**collateralSettings[_token].decimals)) /
            price /
            10**10;

        uint256 userCollateralAmount = amountFromShares(
            _token,
            position.shares
        );
        require(
            collateralAmountIn <= userCollateralAmount,
            "not enough collateral"
        );

        // swap collateral token in airUSD
        address swapper = addressProvider.getSwapper();
        IERC20(_token).approve(swapper, collateralAmountIn);
        uint256 airUSDAmountOut = ISwapper(swapper).swap(
            _token,
            address(airUSD),
            collateralAmountIn,
            address(this)
        );

        require(airUSDAmountOut > debtAmount, "zero penalty");

        // liquidation penalty
        uint256 liquidationPenalty = airUSDAmountOut - debtAmount;

        // debtAmount + 50% of penalty => keeper
        airUSD.transfer(msg.sender, debtAmount + liquidationPenalty / 2);

        // 50% of penalty => fees
        _transferFee(liquidationPenalty / 2, false);

        // return rest collateral token to user
        if (userCollateralAmount > collateralAmountIn) {
            IERC20MetadataUpgradeable(_token).safeTransfer(
                _user,
                userCollateralAmount - collateralAmountIn
            );
        }

        // update total info
        totalDebtAmount -= debtAmount;
        totalDebtPortion -= position.debtPortion;
        collateralTotalShares[_token] -= position.shares;

        // remove user position
        position.shares = 0;
        position.debtPortion = 0;
        position.debtPrincipal = 0;

        emit Liquidate(_user, _token, debtAmount, msg.sender);
    }

    /**
     * @notice returns a user's collateral position
     * @return position this includes a user's collateral, debt, liquidation data.
     */
    function positionView(address _user, address _token)
        external
        view
        override
        returns (PositionView memory)
    {
        Position memory position = userPositions[_user][_token];

        // this is a copy from _debtUSD but should include additional-interest calculation
        uint256 debtCalculated = totalDebtPortion == 0
            ? 0
            : ((totalDebtAmount + _calculateInterestFromLastTime()) *
                userPositions[_user][_token].debtPortion) / totalDebtPortion;
        uint256 debtPrincipal = userPositions[_user][_token].debtPrincipal;
        uint256 debtAmount = debtPrincipal > debtCalculated
            ? debtPrincipal
            : debtCalculated;

        uint256 collateralAmount = amountFromShares(_token, position.shares);
        return
            PositionView({
                owner: _user,
                token: _token,
                amount: collateralAmount,
                amountUSD: _tokenUSD(_token, collateralAmount),
                creditLimitUSD: _creditLimitUSD(_user, _token),
                debtPrincipal: position.debtPrincipal,
                debtInterest: debtAmount - position.debtPrincipal,
                liquidatable: debtAmount >= _liquidateLimitUSD(_user, _token)
            });
    }

    function liquidatable(address _user, address _token)
        external
        view
        override
        returns (bool)
    {
        // this is a copy from _debtUSD but should include additional-interest calculation
        uint256 debtCalculated = totalDebtPortion == 0
            ? 0
            : ((totalDebtAmount + _calculateInterestFromLastTime()) *
                userPositions[_user][_token].debtPortion) / totalDebtPortion;
        uint256 debtPrincipal = userPositions[_user][_token].debtPrincipal;
        uint256 debtAmount = debtPrincipal > debtCalculated
            ? debtPrincipal
            : debtCalculated;

        return debtAmount >= _liquidateLimitUSD(_user, _token);
    }

    function getUserCount(address _token)
        external
        view
        override
        returns (uint256)
    {
        return marketUsers[_token].length;
    }

    function getUserAt(address _token, uint256 _index)
        external
        view
        returns (address)
    {
        return marketUsers[_token][_index];
    }

    function collateralTotalAmount(address _token)
        public
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    function amountFromShares(address _token, uint256 _shares)
        public
        view
        returns (uint256)
    {
        uint256 totalShares = collateralTotalShares[_token];
        uint256 totalAmount = collateralTotalAmount(_token);
        if (totalShares == 0 || totalAmount == 0) {
            return _shares;
        }

        return (_shares * totalAmount) / totalShares;
    }

    function sharesFromAmount(address _token, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 totalShares = collateralTotalShares[_token];
        uint256 totalAmount = collateralTotalAmount(_token);
        if (totalShares == 0 || totalAmount == 0) {
            return _amount;
        }

        return (_amount * totalShares) / totalAmount;
    }

    /// INTERNAL FUNCTIONS

    /**
     * @notice validate rate denominator and numerator
     */
    function _validateRate(Rate memory rate) internal pure {
        require(
            rate.denominator > 0 && rate.denominator >= rate.numerator,
            "invalid rate"
        );
    }

    /**
     * @notice calculate additional interest accrued from last time
     * @return The interest accrued from last time
     */
    function _calculateInterestFromLastTime() internal view returns (uint256) {
        // calculate elapsed time from last accrued at
        uint256 elapsedTime = block.timestamp - totalDebtAccruedAt;

        // calculate interest based on elapsed time and interest APR
        return
            (elapsedTime * totalDebtAmount * settings.interestApr.numerator) /
            settings.interestApr.denominator /
            365 days;
    }

    /**
     * @notice returns the USD amount
     * @param token collateral token address
     * @param amount token amount
     * @return The USD amount in 18 decimals
     */
    function _tokenUSD(address token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        // get price from collateral token oracle contract
        uint256 price = IPriceOracleAggregator(
            addressProvider.getPriceOracleAggregator()
        ).viewPriceInUSD(token);

        // convert to 18 decimals
        return
            (amount * price * 10**10) /
            (10**collateralSettings[token].decimals);
    }

    /**
     * @notice returns the borrow limit amount in USD
     * @param _user user address
     * @param _token collateral token address
     * @return The USD amount in 18 decimals
     */
    function _creditLimitUSD(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 amount = amountFromShares(
            _token,
            userPositions[_user][_token].shares
        );
        uint256 totalUSD = _tokenUSD(_token, amount);
        return
            (totalUSD * collateralSettings[_token].creditLimitRate.numerator) /
            collateralSettings[_token].creditLimitRate.denominator;
    }

    /**
     * @notice returns the liquidation threshold amount in USD
     * @param _user user address
     * @param _token collateral token address
     * @return The USD amount in 18 decimals
     */
    function _liquidateLimitUSD(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 amount = amountFromShares(
            _token,
            userPositions[_user][_token].shares
        );
        uint256 totalUSD = _tokenUSD(_token, amount);
        return
            (totalUSD * collateralSettings[_token].liqLimitRate.numerator) /
            collateralSettings[_token].liqLimitRate.denominator;
    }

    /**
     * @notice returns the debt amount in USD
     * @param _user user address
     * @param _token collateral token address
     * @return The USD amount in 18 decimals
     */
    function _debtUSD(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 debtCalculated = totalDebtPortion == 0
            ? 0
            : (totalDebtAmount * userPositions[_user][_token].debtPortion) /
                totalDebtPortion;
        uint256 debtPrincipal = userPositions[_user][_token].debtPrincipal;

        return debtPrincipal > debtCalculated ? debtPrincipal : debtCalculated; // consider of round at debt calculation
    }

    /**
     * @notice transfer airUSD fee to staking (80%) and treasury (20%)
     * @param _fee fee amount
     * @param _mint airUSD mint or transfer
     */
    function _transferFee(uint256 _fee, bool _mint) internal {
        address treasury = addressProvider.getTreasury();
        uint256 treasuryFee = _fee / 5;

        address staking = addressProvider.getStaking();
        uint256 stakingFee = _fee - treasuryFee;

        if (_mint) {
            airUSD.mint(treasury, treasuryFee);
            airUSD.mint(staking, stakingFee);
        } else {
            airUSD.safeTransfer(treasury, treasuryFee);
            airUSD.safeTransfer(staking, stakingFee);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ILendingAddressRegistry {
    function initialize(
        address lendingMarket,
        address priceOracleAggregator,
        address treasury,
        address staking,
        address stablePool,
        address swapper
    ) external;

    function getLendingMarket() external view returns (address);

    function setLendingMarket(address lendingMarket) external;

    function getPriceOracleAggregator() external view returns (address);

    function setPriceOracleAggregator(address priceOracleAggregator) external;

    function getTreasury() external view returns (address);

    function setTreasury(address treasury) external;

    function getStaking() external view returns (address);

    function setStaking(address staking) external;

    function getStablePool() external view returns (address);

    function setStablePool(address stablePool) external;

    function getSwapper() external view returns (address);

    function setSwapper(address swapper) external;

    function getKeepers() external view returns (address[] memory);

    function addKeeper(address keeper) external;

    function isKeeper(address keeper) external view returns (bool);

    function getAddress(bytes32 id) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOracle.sol";

interface IPriceOracleAggregator {
    event UpdateOracle(address token, IOracle oracle);

    function updateOracleForAsset(address _asset, IOracle _oracle) external;

    function viewPriceInUSD(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILendingMarket {
    function getUserCount(address _token) external view returns (uint256);

    function getUserAt(address _token, uint256 _index)
        external
        view
        returns (address user);

    /// @notice A struct to preview a user's collateral position
    struct PositionView {
        address owner;
        address token;
        uint256 amount;
        uint256 amountUSD;
        uint256 creditLimitUSD;
        uint256 debtPrincipal;
        uint256 debtInterest;
        bool liquidatable;
    }

    function positionView(address _user, address _token)
        external
        view
        returns (PositionView memory);

    function liquidatable(address _user, address _token)
        external
        view
        returns (bool);

    function liquidate(address _user, address _token) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ISwapper {
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IAirUSD is IERC20 {
    function mint(address _to, uint256 _value) external;

    function burn(uint256 _value) external;

    function burnFrom(address _from, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

interface IOracle {
    function viewPriceInUSD() external view returns (uint256);
}