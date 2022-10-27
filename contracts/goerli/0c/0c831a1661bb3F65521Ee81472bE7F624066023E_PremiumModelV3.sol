pragma solidity 0.8.12;
/**
 * @title PremiumModelV3
 * @author @InsureDAO
 * @notice PremiumModelV3
 * check the model here: https://www.desmos.com/calculator/fyf66soh6v
 * SPDX-License-Identifier: GPL-3.0
 */

import "../interfaces/IPremiumModel.sol";
import "../interfaces/IOwnership.sol";

contract PremiumModelV3 is IPremiumModel {
    IOwnership public immutable ownership;

    struct Rate {
        uint64 baseRate;
        uint64 rateSlope1;
        uint64 rateSlope2;
        uint64 optimalUtilizeRatio;
    }

    mapping(address => Rate) public rates;

    uint256 internal constant MAX_RATIO = 1e6; //100%
    uint256 internal constant MAGIC_SCALE = 1e6;

    modifier onlyOwner() {
        require(ownership.owner() == msg.sender, "Caller is not allowed to operate");
        _;
    }

    constructor(
        address _ownership,
        uint64 _defaultRate,
        uint64 _defaultRateSlope1,
        uint64 _defaultRateSlope2,
        uint64 _optimalUtilizeRatio
    ) {
        require(_ownership != address(0), "zero address");
        require(_defaultRate != 0, "rate is zero");
        require(_defaultRateSlope1 != 0, "slope1 is zero");
        require(_defaultRateSlope2 != 0, "slope2 is zero");
        require(_optimalUtilizeRatio != 0, "ratio is zero");
        require(_optimalUtilizeRatio <= MAX_RATIO, "exceed max rate");

        ownership = IOwnership(_ownership);
        rates[address(0)] = Rate(_defaultRate, _defaultRateSlope1, _defaultRateSlope2, _optimalUtilizeRatio);
    }

    function getCurrentPremiumRate(
        address _market,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256) {
        uint256 _utilizedRate;

        if (_lockedAmount != 0 && _totalLiquidity != 0) {
            _utilizedRate = (_lockedAmount * MAGIC_SCALE) / _totalLiquidity;
        }

        Rate memory _rate = _getRate(_market);
        return _getPremiumRate(_rate, _utilizedRate);
    }

    function getPremiumRate(
        address _market,
        uint256 _amount,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256) {
        uint256 rate;
        if (_amount != 0 && _totalLiquidity != 0) {
            uint256 premium = getPremium(_market, _amount, 365 days, _totalLiquidity, _lockedAmount);
            rate = (premium * MAGIC_SCALE) / _amount;
        }

        return rate;
    }

    function getPremium(
        address _market,
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) public view returns (uint256) {
        require(_amount + _lockedAmount <= _totalLiquidity, "Amount exceeds total liquidity");
        require(_totalLiquidity != 0, "totalLiquidity is 0");

        Rate memory _rate = _getRate(_market);

        uint256 _utilizedRateBefore = (_lockedAmount * MAGIC_SCALE) / _totalLiquidity;
        uint256 _utilizedRateAfter = ((_lockedAmount + _amount) * MAGIC_SCALE) / _totalLiquidity;
        uint256 _premium;

        if (_utilizedRateAfter <= _rate.optimalUtilizeRatio || _rate.optimalUtilizeRatio <= _utilizedRateBefore) {
            //slope1 or 2
            _premium += _calcOneSidePremiumAmount(_rate, _totalLiquidity, _utilizedRateBefore, _utilizedRateAfter);
        } else {
            //slope1 & 2
            _premium += _calcOneSidePremiumAmount(
                _rate,
                _totalLiquidity,
                _utilizedRateBefore,
                _rate.optimalUtilizeRatio
            );
            _premium += _calcOneSidePremiumAmount(
                _rate,
                _totalLiquidity,
                _rate.optimalUtilizeRatio,
                _utilizedRateAfter
            );
        }

        _premium = (_premium * _term) / 365 days;

        return _premium;
    }

    function getRate(address _market) external view returns (Rate memory) {
        return _getRate(_market);
    }

    function setRate(address _market, Rate calldata _rate) external onlyOwner {
        require(_rate.optimalUtilizeRatio <= MAX_RATIO, "exceed max rate");
        rates[_market] = _rate;
    }

    function _calcOneSidePremiumAmount(
        Rate memory _rate,
        uint256 _totalLiquidity,
        uint256 _utilizedRateBefore,
        uint256 _utilizedRateAfter
    ) internal pure returns (uint256) {
        require(
            !(_utilizedRateBefore < _rate.optimalUtilizeRatio && _utilizedRateAfter > _rate.optimalUtilizeRatio),
            "Contains the corner"
        );

        uint256 _currentPremiumBefore = _getPremiumRate(_rate, _utilizedRateBefore);
        uint256 _currentPremiumAfter = _getPremiumRate(_rate, _utilizedRateAfter);

        uint256 _avePremiumRate = (_currentPremiumBefore + _currentPremiumAfter) / 2;
        uint256 _amount = ((_utilizedRateAfter - _utilizedRateBefore) * _totalLiquidity) / MAGIC_SCALE;

        uint256 _premium = (_amount * _avePremiumRate) / MAGIC_SCALE;

        return _premium;
    }

    /**
     * @dev return BaseRate when _utilizedRate is 0;
     */
    function _getPremiumRate(Rate memory _rate, uint256 _utilizedRate) internal pure returns (uint256) {
        uint256 _currentPremiumRate = _rate.baseRate;
        uint256 _maxExcessUtilizeRatio = MAGIC_SCALE - _rate.optimalUtilizeRatio;

        if (_utilizedRate > _rate.optimalUtilizeRatio) {
            uint256 excessUtilizeRatio;
            unchecked {
                excessUtilizeRatio = _utilizedRate - _rate.optimalUtilizeRatio;
            }
            _currentPremiumRate += (_rate.rateSlope1 +
                ((_rate.rateSlope2 * excessUtilizeRatio) / _maxExcessUtilizeRatio));
        } else {
            _currentPremiumRate += (_rate.rateSlope1 * _utilizedRate) / _rate.optimalUtilizeRatio;
        }

        return _currentPremiumRate;
    }

    function _getRate(address _market) internal view returns (Rate memory) {
        Rate memory _rate = rates[_market];
        Rate memory _defaultRate = rates[address(0)];

        uint64 _baseRate = _rate.baseRate == 0 ? _defaultRate.baseRate : _rate.baseRate;
        uint64 _rateSlope1 = _rate.rateSlope1 == 0 ? _defaultRate.rateSlope1 : _rate.rateSlope1;
        uint64 _rateSlope2 = _rate.rateSlope2 == 0 ? _defaultRate.rateSlope2 : _rate.rateSlope2;
        uint64 _optimalUtilizeRatio = _rate.optimalUtilizeRatio == 0
            ? _defaultRate.optimalUtilizeRatio
            : _rate.optimalUtilizeRatio;

        return Rate(_baseRate, _rateSlope1, _rateSlope2, _optimalUtilizeRatio);
    }
}

pragma solidity 0.8.12;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}

pragma solidity 0.8.12;

interface IPremiumModel {
    function getCurrentPremiumRate(
        address _market,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    function getPremiumRate(
        address _market,
        uint256 _amount,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    function getPremium(
        address _market,
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);
}