pragma solidity 0.8.10;
/**
 * @title FlatPremium
 * @author @InsureDAO
 * @notice Insurance Premium Calclator
 * SPDX-License-Identifier: GPL-3.0
 */

import "../interfaces/IPremiumModel.sol";
import "../interfaces/IOwnership.sol";

contract FlatPremium is IPremiumModel {
    IOwnership public immutable ownership;

    //variables
    uint256 public rate;
    uint256 public constant MAX_RATE = 1e6;
    uint256 private constant RATE_DENOMINATOR = 1e6;

    modifier onlyOwner() {
        require(
            ownership.owner() == msg.sender,
            "Caller is not allowed to operate"
        );
        _;
    }

    constructor(address _ownership) {
        require(_ownership != address(0), "zero address");
        ownership = IOwnership(_ownership);
    }

    function getCurrentPremiumRate(
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view override returns (uint256) {
        return rate;
    }

    function getPremiumRate(
        uint256 _amount,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) public view override returns (uint256) {
        return rate;
    }

    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view override returns (uint256) {
        require(
            _amount + _lockedAmount <= _totalLiquidity,
            "Amount exceeds total liquidity"
        );

        if (_amount == 0) {
            return 0;
        }

        uint256 premium = (_amount * rate * _term) /
            365 days /
            RATE_DENOMINATOR;

        return premium;
    }

    /**
     * @notice Set a premium model
     * @param _rate new rate
     */
    function setPremiumParameters(
        uint256 _rate,
        uint256 _a_zero,
        uint256 _b_zero,
        uint256 _c_zero
    ) external override onlyOwner {
        require(
            _rate < MAX_RATE && _a_zero == 0 && _b_zero == 0 && _c_zero == 0,
            "input invalid number"
        );

        rate = _rate;
    }
}

pragma solidity 0.8.10;

interface IPremiumModel {

    function getCurrentPremiumRate(
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    function getPremiumRate(
        uint256 _amount,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    //onlyOwner
    function setPremiumParameters(
        uint256,
        uint256,
        uint256,
        uint256
    ) external;
}

pragma solidity 0.8.10;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}