//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "web3-signature-validator/contracts/Validator.sol";
import "./LiquidityPool.sol";

struct Position {
    /* The usd size of the position */
    uint256 size;
    /* The usd collateral of the position */
    uint256 collateral;
    /* The price at which assets have been purchased */
    uint256 averagePrice;
    /* The last time fees have been collected for this position */
    uint256 lastFeeCollection;
    /* The total fees charged for this position */
    uint256 accumulatedFees;
    /* The funding rate at time of last increase */
    uint256 lastFundingRate;
}

struct AssetSettings {
    /* Whether or not this asset can be traded */
    bool enabled;
    /* The percentage difference between the price and bid/ask price */
    uint256 spreadBasisPoints;

    /* The difference between longs and shorts that will result in the maximum funding rate */
    uint256 differenceForMaxFundingRate;
    /* The neutral funding rate for this asset, in FUNDING_RATE_DIVISOR basis points*/
    uint256 neutralFundingRate;
}

struct AssetInfo {
    /* The total usd amount longed in this asset */
    uint256 totalLong;
    /* The total usd amount shorted in this asset */
    uint256 totalShort;
}

contract TradeManager is Validator, Ownable {

    /* ERC20 token address that will be used as a USD equivilant */
    address public usdToken;

    /* Trade settings */
    uint256 public constant BASIS_POINTS_DIVISOR = 10_000;
    uint256 public maxLeverage = 100_000;
    uint256 public minLeverage = 10_000;
    uint256 public liquidationFee = 10 * 10 ** 18; // 10 USD, if token has 18 decimals

    /* Funding rate divisor is higher as funding rate needs greater precision */
    uint256 public constant FUNDING_RATE_DIVISOR = 1_000_000;

    /* Fees */
    uint256 public tradeFeeBasisPoints = 10; // 0.1%, only collected on decrease position

    /* The address of the liquidity pool */
    address public liquidityPool;

    /* The receiver of operator fees */
    address public operatorFeeReceiver;
    /* When trade fees are taken, this percentage goes to the operatorFeeReceiver */
    uint256 public operatorFeeBasisPoints = 5_000; // 50%

    /* Mapping of position keys to a position */
    mapping(bytes32 => Position) public positions;

    /* Mapping of asset to whether or not it is supported */
    mapping(bytes32 => AssetSettings) public assetSettings;
    /* Mapping of asset to information about the asset */
    mapping(bytes32 => AssetInfo) public assetInfo;

    event IncreasePosition(
        address indexed account, 
        bytes32 indexed asset,
        bool isLong,
        uint256 sizeIncrease, 
        uint256 collateralIncrease, 
        uint256 assetPrice
    );

    event DecreasePosition(
        address indexed account, 
        bytes32 indexed asset,
        bool isLong,
        uint256 sizeDecrease, 
        uint256 collateralDecrease, 
        uint256 assetPrice,
        uint256 refundAmount
    );

    event LiquidatePosition(
        address indexed account, 
        bytes32 indexed asset,
        bool isLong
    );

    event AssetSettingsChanged(
        bytes32 indexed asset, 
        bool indexed enabled, 
        uint256 spreadBasisPoints,
        uint256 differenceForMaxFundingRate,
        uint256 neutralFundingRate
    );

    event ClosePosition(
        address indexed account, 
        bytes32 indexed asset,
        bool isLong
    );

    event OpenPosition(
        address indexed account, 
        bytes32 indexed asset,
        bool isLong
    );

    constructor(address _usdToken, address _liquidityPool) {
        usdToken = _usdToken;
        liquidityPool = _liquidityPool;
        operatorFeeReceiver = msg.sender;
    }

    /**
     * @dev Sets the fees of the trade manager
     */
    function setFees(uint256 _tradeFeeBasisPoints, uint256 _operatorFeeBasisPoints) public onlyOwner {
        tradeFeeBasisPoints = _tradeFeeBasisPoints;
        operatorFeeBasisPoints = _operatorFeeBasisPoints;
    }

    /**
     * @dev Sets the address of the receiver of the operator fees
     */
    function setOperatorFeeReceiver(address _operatorFeeReceiver) public onlyOwner {
        require(_operatorFeeReceiver != address(0), "TradeManager: Operator fee receiver cannot be zero address");
        operatorFeeReceiver = _operatorFeeReceiver;
    }

    /**
     * @dev Sets the trade settings of the trade manager
     */
    function setTradeSettings(
        uint256 _maxLeverage, 
        uint256 _minLeverage, 
        uint256 _liquidationFee
    ) public onlyOwner {
        maxLeverage = _maxLeverage;
        minLeverage = _minLeverage;
        liquidationFee = _liquidationFee;
    }

    /**
     * @dev Sets the status of a supported asset
     */
    function setAssetSettings(
        bytes32 _asset, 
        bool _enabled,
        uint256 _spreadBasisPoints,
        uint256 _differenceForMaxFundingRate,
        uint256 _neutralFundingRate
    ) public onlyOwner {
        require(_spreadBasisPoints < BASIS_POINTS_DIVISOR, "TradeManager: Spread must be less than 100%");
        require(_neutralFundingRate < FUNDING_RATE_DIVISOR, "TradeManager: Max funding rate must be less than 100%");
        assetSettings[_asset] = AssetSettings(
            _enabled,
            _spreadBasisPoints,
            _differenceForMaxFundingRate,
            _neutralFundingRate
        );
        emit AssetSettingsChanged(_asset, _enabled, _spreadBasisPoints, _differenceForMaxFundingRate, _neutralFundingRate);
    }

    /**
     * @dev Sets an address as a validator
     */
    function setValidator(address _validator, bool _isValidator) public onlyOwner {
        _setValidator(_validator, _isValidator);
    }

    /**
     * @dev Subtracts the trade fee and returns the remaining amount
     */
    function collectTradeFee(uint256 _amount) internal returns (uint256) {
        uint256 fee = _amount * tradeFeeBasisPoints / BASIS_POINTS_DIVISOR;

        collectFee(fee);
        
        return _amount - fee;
    }

    function collectFee(uint256 _fee) internal {
        uint256 operatorPortion = _fee * operatorFeeBasisPoints / BASIS_POINTS_DIVISOR;
        _transferToOperator(operatorPortion);

        LiquidityPool(liquidityPool).increaseCollectedFees(_fee - operatorPortion);
    }

    /**
     * @dev Transfers an amount to the operator fee receiver
     */
    function _transferToOperator(uint256 _amount) internal {
        _transferFromPool(operatorFeeReceiver, _amount);
    }

    /**
     * @dev Transfers an amount from the liquidity pool to an address
     */
    function _transferFromPool(address _to, uint256 _amount) internal {
        LiquidityPool(liquidityPool).transferOut(_to, _amount);
    }

    /**
     * @dev validates that a price has been signed by a validator
     */
    function _validatedPrice(bytes32 _asset, uint256 _assetPrice, uint256 _priceExpiryTimestamp, bytes memory _signature) internal view {
        validateSignature(abi.encodePacked(_asset, _assetPrice, _priceExpiryTimestamp), _signature);
        require(_priceExpiryTimestamp > block.timestamp, "TradeManager: Price has expired");
    }

    /**
     * @dev gets the price of an asset by either adding or subtracting the spread, depending
     * on whether the asset is maximised
     */
    function getSpreadPrice(bytes32 _asset, uint256 _assetPrice, bool _maximize) internal view returns (uint256) {
        uint256 spreadBasisPoints = assetSettings[_asset].spreadBasisPoints;
        uint256 spread = spreadBasisPoints * _assetPrice / BASIS_POINTS_DIVISOR;
        return _maximize ? _assetPrice + spread : _assetPrice - spread;
    }

    /**
     * @dev Liquidates a position at a given price
     */
    function liquidatePosition(
        address _account,
        bytes32 _asset, 
        bool _isLong, 
        uint256 _assetPrice, 
        uint256 _priceExpiryTimestamp, 
        bytes memory _signature
    ) public {
        _validatedPrice(_asset, _assetPrice, _priceExpiryTimestamp, _signature);
        uint256 price = getSpreadPrice(_asset, _assetPrice, !_isLong);
        _liquidatePosition(_account, _asset, _isLong, price);
    }

    /**
     * @dev liquidates a position, if it is valid
     */
    function _liquidatePosition(address _account, bytes32 _asset, bool _isLong, uint256 _assetPrice) internal {
        require(canPositionBeLiquidated(
            _account, 
            _asset, 
            _isLong, 
            _assetPrice
        ), "TradeManager: Invalid liquidation");

        bytes32 key = getPositionKey(_account, _asset, _isLong);
        Position storage position = positions[key];

        if (position.collateral < liquidationFee) {
            position.collateral = 0;
        } else {
            position.collateral -= liquidationFee;
        }
        _transferToOperator(liquidationFee);

        _closePosition(_account, _asset, _isLong, _assetPrice);
        emit LiquidatePosition(_account, _asset, _isLong);
    }

    /**
     * @dev returns true if a position can be liquidated, false otherwise
     */
    function canPositionBeLiquidated(
        address _account, 
        bytes32 _asset, 
        bool _isLong, 
        uint256 _currentPrice
    ) public view returns (bool) {
        bytes32 key = getPositionKey(_account, _asset, _isLong);
        Position memory position = positions[key];

        // if asset is not enabled, position can be liquidated regardless of circumstances
        if (!assetSettings[_asset].enabled) {
            return true;
        }

        (uint256 delta, bool hasProfit) = getPositionDelta(_account, _asset, _isLong, _currentPrice);

        uint256 remainingCollateral = getCollateralWithDelta(position.collateral, hasProfit, delta);

        // Position can be liquidated if the remaining collateral is beneath the minimum collateral
        if (remainingCollateral < liquidationFee) {
            return true;
        }

        uint256 leverage = getCurrentLeverage(position.size, position.collateral, hasProfit, delta);
        if (leverage > maxLeverage) {
            return true;
        }

        return false;
    }

    /**
     * @dev Decreases a position with a validated price
     */
    function decreasePosition(
        bytes32 _asset, 
        bool _isLong, 
        uint256 _sizeDecrease, 
        uint256 _collateralDecrease, 
        uint256 _assetPrice, 
        uint256 _priceExpiryTimestamp, 
        bytes memory _signature
    ) public {
        _validatedPrice(_asset, _assetPrice, _priceExpiryTimestamp, _signature);
        // If the position is short, maximize, otherwise minimize
        uint256 price = getSpreadPrice(_asset, _assetPrice, !_isLong);
        _decreasePosition(msg.sender, _asset, _isLong, _sizeDecrease, _collateralDecrease, price);
    }

    /**
     * @dev Decreases a position size and/or collateral.
     */
    function _decreasePosition(address _account, bytes32 _asset, bool _isLong, uint256 _sizeDecrease, uint256 _collateralDecrease, uint256 _assetPrice) internal {
        _cumulatePositionFees(_account, _asset, _isLong);

        bytes32 key = getPositionKey(_account, _asset, _isLong);
        Position storage position = positions[key];

        // if position size is getting decreased to zero, close the position
        if (position.size <= _sizeDecrease) {
            _closePosition(_account, _asset, _isLong, _assetPrice);
            return;
        }
        
        // Transfer out a fraction of the delta if there is a profit
        (uint256 delta, bool hasProfit) = getPositionDelta(_account, _asset, _isLong, _assetPrice);
        // Delta out is the delta multiplied by the faction of the decrease compared to the full size
        uint256 deltaOut = delta * _sizeDecrease / position.size;

        // Validates the decrease
        _validateCollateralDecrease(position.collateral, _collateralDecrease, hasProfit, delta);

        // Decrease the position size and collateral
        position.size -= _sizeDecrease;
        position.collateral -= _collateralDecrease;
        _adjustGlobalAssetValues(_asset, _isLong, _sizeDecrease, false);

        // Validates the new position is valid
        _validateLeverage(position.size, position.collateral);

        // If there is a profit, include the profit
        uint256 refundAmount = hasProfit 
            ? _collateralDecrease + deltaOut
            : _collateralDecrease;

        // If the refundAmount is greater than zero, transfer out the amount
        if (refundAmount > 0) {
            _transferFromPool(_account, refundAmount);
        }
        
        // Emits event
        emit DecreasePosition(
            _account, 
            _asset, 
            _isLong, 
            _sizeDecrease, 
            _collateralDecrease, 
            _assetPrice, 
            refundAmount
        );
    }

    /**
     * @dev Closes a position at a given price
     */
    function _closePosition(address _account, bytes32 _asset, bool _isLong, uint256 _assetPrice) internal {
        bytes32 key = getPositionKey(_account, _asset, _isLong);
        Position storage position = positions[key];

        // Get the profit/loss of the position
        (uint256 _delta, bool _hasProfit) = getPositionDelta(_account, _asset, _isLong, _assetPrice);
        uint256 _amountOut = getCollateralWithDelta(position.collateral, _hasProfit, _delta);

        // Transfer out the amount of collateral and/or profit/loss
        if (_amountOut > 0) {
            _transferFromPool(_account, _amountOut);
        }

        // move accumulated fees to liquidity pool
        collectFee(position.accumulatedFees);

        // emits events
        emit ClosePosition(_account, _asset, _isLong);
        emit DecreasePosition(
            _account, 
            _asset, 
            _isLong, 
            position.size, 
            position.collateral, 
            _assetPrice, 
            _amountOut
        );
        
        // resets the position
        _adjustGlobalAssetValues(_asset, _isLong, position.size, false);
        delete positions[key];
    }

    /**
     * @dev Validates that the collateral decrease is valid
     */
    function _validateCollateralDecrease(uint256 _collateral, uint256 _collateralDecrease, bool hasProfit, uint256 delta) internal view returns (bool) {
        uint256 _currentCollateral = getCollateralWithDelta(_collateral, hasProfit, delta);
        require(_currentCollateral >= _collateralDecrease, "TradeManager: Decrease exceeds collateral");
        require(_currentCollateral - _collateralDecrease >= liquidationFee, "TradeManager: Decrease exceeds minimum collateral");
        
        return true;
    }

    /**
     * @dev Increases a position with a validated price
     */
    function increasePosition(
        bytes32 _asset, 
        bool _isLong, 
        uint256 _sizeIncrease, 
        uint256 _collateralIncrease, 
        uint256 _assetPrice, 
        uint256 _priceExpiryTimestamp, 
        bytes memory _signature
    ) public {
         _validatedPrice(_asset, _assetPrice, _priceExpiryTimestamp, _signature);
        // If the position is long, maximize, otherwise minimize
         uint256 price = getSpreadPrice(_asset, _assetPrice, _isLong);
        _increasePosition(msg.sender, _asset, _isLong, _sizeIncrease, _collateralIncrease, price);
    }

    /**
     * @dev Increases a positions size and/or collateral.
     */
    function _increasePosition(address _account, bytes32 _asset, bool _isLong, uint256 _sizeIncrease, uint256 _collateralIncrease, uint256 _assetPrice) internal {
        _validateAsset(_asset);
        _cumulatePositionFees(_account, _asset, _isLong);

        bytes32 key = getPositionKey(_account, _asset, _isLong);
        Position storage position = positions[key];

        // If position has no size, and size is increased, open the position
        if (position.size == 0 && _sizeIncrease > 0) {
            emit OpenPosition(_account, _asset, _isLong);
        }

        // Move the collateral from the account to the pool
        IERC20(usdToken).transferFrom(_account, liquidityPool, _collateralIncrease);

        // Increase the position and collateral by the desired amount
        uint256 collateralLessFee = collectTradeFee(_collateralIncrease);

        position.size += _sizeIncrease;
        position.collateral += collateralLessFee;
        _adjustGlobalAssetValues(_asset, _isLong, _sizeIncrease, true);

        // Validates the position static leverage is not too low
        uint256 leverage = position.size * BASIS_POINTS_DIVISOR / position.collateral;
        require(leverage >= minLeverage, "TradeManager: Leverage too low");

        // Update the average price
        position.averagePrice = getAveragePrice(position.size, position.averagePrice, _isLong, _assetPrice);

        // Validate the new position
        _validateLeverage(position.size, position.collateral);
        emit IncreasePosition(_account, _asset, _isLong, _sizeIncrease, collateralLessFee, _assetPrice);
    }

    /**
     * @dev Validates that leverage is beneath the maximum leverage.
     */
    function _validateLeverage(
        uint256 _size, 
        uint256 _collateral
    ) internal view returns (bool) {
        uint256 leverage = _size * BASIS_POINTS_DIVISOR / _collateral;
        require(leverage <= maxLeverage, "TradeManager: Leverage too high");
        require(_collateral > liquidationFee, "TradeManager: Collateral under fee");

        return true;
    }

    /**
     * @dev check if an asset is valid
     */
    function _validateAsset(bytes32 _asset) internal view returns (bool) {
        require(assetSettings[_asset].enabled, "TradeManager: Invalid asset");
        return true;
    }

    /**
     * @dev adds the accrued positions fees to the position accumulated fees
     */
    function _cumulatePositionFees(address _account, bytes32 _asset, bool _isLong) internal {
        bytes32 key = getPositionKey(_account, _asset, _isLong);
        Position storage position = positions[key];

        // Adds the accumulated fees to the outstanding fees
        position.accumulatedFees += getOutstandingFees(_account, _asset, _isLong);

        // Updates the last fee collection timestamp
        position.lastFeeCollection = block.timestamp;
        position.lastFundingRate = getAssetFundingRate(_asset, _isLong);
    }

    /**
     * @dev gets fees that have not been added to position accumulated fees
     */
    function getOutstandingFees(address _account, bytes32 _asset, bool _isLong) public view returns (uint256) {
        bytes32 key = getPositionKey(_account, _asset, _isLong);
        Position memory position = positions[key];

        // Gets the total funding rate for the amount of hours since the last fee was accrued
        uint256 totalFundingRate = position.lastFundingRate * 
            (block.timestamp - position.lastFeeCollection) / 1 hours;

        // Returns the funding rate multiplied by the position size to the accrued fees
        return totalFundingRate * position.size / FUNDING_RATE_DIVISOR;
    }

    /**
     * @dev changes an assets global long or short value
     */
    function _adjustGlobalAssetValues(bytes32 _asset, bool _isLong, uint256 _size, bool _increasingSize) internal {
        if (_isLong) {
            if (_increasingSize) {
                assetInfo[_asset].totalLong += _size;
            } else {
                assetInfo[_asset].totalLong -= _size;
            }
        } else {
            if (_increasingSize) {
                assetInfo[_asset].totalShort += _size;
            } else {
                assetInfo[_asset].totalShort -= _size;
            }
        }
    }

    /**
     * @dev returns the current funding rate for a given asset
     */
    function getAssetFundingRate(bytes32 _asset, bool _isLong) public view returns (uint256) {
        AssetInfo memory _assetInfo = assetInfo[_asset];
        AssetSettings memory _assetSettings = assetSettings[_asset];

        // If the total long and total short are equal, the funding rate is half of the max
        if (_assetInfo.totalLong == _assetInfo.totalShort) {
            return _assetSettings.neutralFundingRate;
        }

        // If the global longs are greater than the shorts, the funding rate for shorts will be below half the max
        // otherwise, it will be above half the max. This also goes for longs.
        bool useLowFundingRate = _isLong 
            ? _assetInfo.totalLong < _assetInfo.totalShort
            : _assetInfo.totalShort < _assetInfo.totalLong;

        // This calculates the absolute difference between the asset longs and shorts
        uint256 difference = _assetInfo.totalLong < _assetInfo.totalShort
            ? _assetInfo.totalShort - _assetInfo.totalLong
            : _assetInfo.totalLong - _assetInfo.totalShort;

        // If the difference is greater than the max difference, the funding rate is the max, or zero, based on whether
        // useLowFundingRate is true
        if (difference >= _assetSettings.differenceForMaxFundingRate) {
            return useLowFundingRate ? 0 : _assetSettings.neutralFundingRate * 2;
        }

        // Converts the difference to a funding rate
        uint256 fundingRateDifference = _assetSettings.neutralFundingRate * 
            difference / _assetSettings.differenceForMaxFundingRate;
        
        // If useLowFundingRate is true, the funding rate is the average minus the difference, 
        // otherwise it is the average + the difference
        return useLowFundingRate 
            ? _assetSettings.neutralFundingRate - fundingRateDifference 
            : _assetSettings.neutralFundingRate + fundingRateDifference;
    }

    /**
     * @dev gets the current collateral of a position including the delta
     */
    function getCollateralWithDelta(uint256 _collateral, bool _hasProfit, uint256 _delta) internal pure returns (uint256) {
        if (!_hasProfit && _delta > _collateral) return 0;
        return _hasProfit ? _collateral + _delta : _collateral - _delta;
    }

    /**
     * @dev gets the current leverage of a position including the delta in basis points
     */
    function getCurrentLeverage(uint256 _size, uint256 _collateral, bool _hasProfit, uint256 _delta) internal pure returns (uint256) {
        uint256 collateral = getCollateralWithDelta(_collateral, _hasProfit, _delta);
        require(collateral > 0, "TradeManager: Leverage not computable, collateral is zero");
        return _size * BASIS_POINTS_DIVISOR / collateral;
    }

    /**
     * @dev Gets the average price given a current price and position
     * for longs: averagePrice = (price * size)/ (size + delta)
     * for shorts: averagePrice = (price * size) / (size - delta)
     */
    function getAveragePrice(uint256 _size, uint256 _oldAveragePrice, bool _isLong, uint256 _currentPrice) internal pure returns (uint256) {
        // If no previous average price, average price is the current price
        if (_oldAveragePrice == 0) {
            return _currentPrice;
        }

        (uint256 delta, bool hasProfit) = getRawDelta(_size, _oldAveragePrice, _isLong, _currentPrice);
        uint256 divisor;
        if (_isLong) {
            divisor = hasProfit ? _size + delta : _size - delta;
        } else {
            divisor = hasProfit ? _size - delta : _size + delta;
        }
        return _currentPrice * _size / divisor;
    }

    /**
     * @dev Returns the delta of a position given the size, average price, and current price of the given asset.
     */
    function getRawDelta(uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _currentPrice) internal pure returns (uint256, bool) {
        uint256 priceDelta = _averagePrice > _currentPrice ? _averagePrice - _currentPrice : _currentPrice - _averagePrice;
        uint256 delta = _size * priceDelta / _averagePrice;
        bool hasProfit = _isLong ? _currentPrice > _averagePrice : _averagePrice > _currentPrice;
        return (delta, hasProfit);
    }

    /**
     * @dev Returns the delta of a position given the position and current price. 
     * It also takes into account the cumulative fees.
     */
    function getPositionDelta(address _account, bytes32 _asset, bool _isLong, uint256 _currentPrice) internal view returns (uint256, bool) {
        bytes32 key = getPositionKey(_account, _asset, _isLong);
        Position memory position = positions[key];
        (uint256 delta, bool hasProfit) = getRawDelta(position.size, position.averagePrice, _isLong, _currentPrice);

        uint256 currentFees = position.accumulatedFees + getOutstandingFees(_account, _asset, _isLong);

        // If the position has profit, but the fees are greater than the profit, the position no longer has profit
        // and the delta set to the difference between the fees and the previous delta. This effectively subtracts
        // the fees from the delta.
        if (hasProfit && delta < currentFees) {
            delta = currentFees - delta;
            hasProfit = false;
        }

        // If the delta is profitable and greater than the fees, simply subtract the fees from the detla
        if (hasProfit && delta >= currentFees) {
            delta -= currentFees;
        }

        // If the position does not have profit, add the fees to the negative delta
        if (!hasProfit) {
            delta += currentFees;
        }

        return (delta, hasProfit);
    }

    /**
     * @dev Gets the key for a given position, that represents it in the positions mapping.
     */
    function getPositionKey(address _account, bytes32 _asset, bool _isLong) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _asset, _isLong));
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Validator {
    mapping(bytes32 => bool) private _isNonceUsed;
    mapping(address => bool) private _isValidator;

    event ValidatorAdded(address validator);
    event ValidatorRemoved(address validator);

    function _setValidator(address validator, bool newValidatorValue) internal {
        if (newValidatorValue) {
            _isValidator[validator] = true;
            emit ValidatorAdded(validator);
        } else {
            _isValidator[validator] = false;
            emit ValidatorRemoved(validator);
        }
    }

    function isValidator(address validator) public view returns (bool) {
        return _isValidator[validator];
    }

    function _isSignedByValidator(bytes32 _messageHash, bytes memory _signature) internal view returns (bool)
    {
        bytes32 _hash = ECDSA.toEthSignedMessageHash(_messageHash);
        return _isValidator[ECDSA.recover(_hash, _signature)];
    }

    /** 
     * @param _message - a message created by a list of arguments encoded with abi.encodePacked
     * @param _nonce - a nonce for this verification
     * @param _signature - a signature (should be passed in by external source)
     */
    function validateSignatureWithNonce(
        bytes memory _message,
        bytes32 _nonce,
        bytes memory _signature
    ) public returns (bool) {
        // signature is not valid if nonce has been used before
        require(!_isNonceUsed[_nonce], "Validator: Nonce already used");
        _isNonceUsed[_nonce] = true;
        
        bytes memory nonceMessage = abi.encodePacked(_message, _nonce);
        bytes32 messageHash = keccak256(nonceMessage);

        require(_isSignedByValidator(messageHash, _signature), "Validator: Invalid signature");
        return true;
    }

    /**
     * @param _message - a message created by a list of arguments encoded with abi.encodePacked
     * @param _signature - a signature (should be passed in by external source)
     */
    function validateSignature(
        bytes memory _message,
        bytes memory _signature
    ) public view returns (bool) {
        bytes32 messageHash = keccak256(_message);

        require(_isSignedByValidator(messageHash, _signature), "Validator: Invalid signature");
        return true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LiquidityToken.sol";

contract LiquidityPool is Ownable {
    uint256 public constant MAX_UINT256 = 2**256 - 1;
    /* The USD equivilant token */
    address public usdToken;

    /* The trade manager that is able to access liquidity funds */
    address public tradeManager;

    /* Collected fees */
    uint256 public collectedFees;

    /* The liquidity token */
    LiquidityToken public liquidityToken;

    constructor(address _usdToken, uint8 _usdTokenDecimals) {
        usdToken = _usdToken;
        liquidityToken = new LiquidityToken(_usdTokenDecimals);
    }

    /**
     * @dev sets the trade manager
     */
    function setTradeManager(address _tradeManager) public onlyOwner {
        tradeManager = _tradeManager;
    }

    /**
     * @dev transfers liquidity to a certain account. Can only be called by the trade manager
     */
    function transferOut(address _to, uint256 _amount) public {
        require(msg.sender == tradeManager, "LiquidityPool: Only the trade manager can transfer liquidity funds");
        IERC20(usdToken).transfer(_to, _amount);
    }

    /**
     * @dev increases the collected fees by a certain amount
     */
    function increaseCollectedFees(uint256 _amount) public {
        require(msg.sender == tradeManager, "LiquidityPool: Only the trade manager can increase collected fees");
        collectedFees += _amount;
    }

    /**
     * @dev deposits usd to the pool in exchange for liquidity tokens
     */
    function deposit(uint256 _usdAmount) public {
        _deposit(msg.sender, _usdAmount);
    }
    
    /**
     * @dev withdraws usd from the pool by swapping it for liquidity tokens.
     * Fees proportional to the amount of liquidity tokens are collected.
     */
    function withdraw(uint256 _liquidityTokenAmount) public {
        _withdraw(msg.sender, _liquidityTokenAmount);
    }

    /**
     * @dev deposits usd to the pool in exchange for liquidity tokens
     */
    function _deposit(address _account, uint256 _usdAmount) internal {
        IERC20(usdToken).transferFrom(_account, address(this), _usdAmount);

        (uint256 liquidityTokenAmount, uint256 fees) = getLiqudityTokensFromUsd(_usdAmount);
        liquidityToken.mint(_account, liquidityTokenAmount);
        collectedFees += fees;
    }

    /**
     * @dev withdraws usd from the pool by swapping it for liquidity tokens.
     * Fees proportional to the amount of liquidity tokens are collected.
     */
    function _withdraw(address _account, uint256 _liquidityTokenAmount) internal {
        uint256 fee = getFeeRepresentation(_liquidityTokenAmount);
        collectedFees -= fee;

        liquidityToken.burn(msg.sender, _liquidityTokenAmount);

        IERC20(usdToken).transfer(_account, _liquidityTokenAmount + fee);
    }

    /**
     * @dev returns the fees that would be collected by withdrawing an amount of liquidty tokens
     */
    function getFeeRepresentation(uint256 _liquidityTokenAmount) public view returns (uint256) {
        if (liquidityToken.totalSupply() == 0) {
            return collectedFees;
        }
        return collectedFees * _liquidityTokenAmount / liquidityToken.totalSupply();
    }

    /**
     * @dev gets the amount of liquidity tokens and fees that a deposit of usd would be split into
     */
    function getLiqudityTokensFromUsd(uint256 _usdAmount) public view returns (uint256, uint256) {
        uint256 totalSupply = liquidityToken.totalSupply();
        // If there is no supply and no fees, the user should just get the usd amount in liquidity tokens
        if (totalSupply + collectedFees == 0) {
            return (_usdAmount, 0);
        }
        // This calculation is designed so that a user will get exactly what they put in if the collected fees
        // have not changed
        uint256 liquidityTokenAmount = _usdAmount * totalSupply / (totalSupply + collectedFees);
        uint256 fees = _usdAmount * collectedFees / (totalSupply + collectedFees);
        return (liquidityTokenAmount, fees);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidityToken is ERC20 {
    address liquidityPool;
    uint8 _decimals;

    constructor(uint8 _tokenDecimals) ERC20("LiquidityToken", "LT") {
        liquidityPool = msg.sender;
        _decimals = _tokenDecimals;
    }

    modifier onlyLiquidityPool() {
        require(msg.sender == liquidityPool, "LiquidityToken: Function can only be called by liquidity pool");
        _;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address _to, uint256 _amount) public onlyLiquidityPool {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyLiquidityPool {
        _burn(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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