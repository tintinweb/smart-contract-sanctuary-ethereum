// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../library/interfaces/IPriceFeed.sol";
import "../library/common/DataTypes.sol";
import "../product/interfaces/IProductPool.sol";

contract JudgementCondition {
    function judgementConditionAmount(
        address productPoolAddress,
        uint256 productId
    ) external view returns (DataTypes.ProgressStatus) {
        IProductPool productPool = IProductPool(productPoolAddress);
        DataTypes.ProductInfo memory product = productPool.getProductInfoByPid(
            productId
        );
        require(
            block.number >= product.releaseHeight,
            "Authentication: release height error"
        );
        return
            _getResultByCondition(
                product.cryptoExchangeAddress,
                product.conditionAmount,
                product.productType
            );
    }

    function _getTokenPrice(address token) private view returns (uint256) {
        IPriceFeed priceFeed = IPriceFeed(token);
        int256 price = priceFeed.latestAnswer();
        require(price > 0, "OraclePriceFeed: invalid price");
        return uint256(price);
    }

    function _getResultByCondition(
        address cryptoExchangeAddress,
        uint256 conditionAmount,
        DataTypes.ProductType productType
    ) private view returns (DataTypes.ProgressStatus) {
        uint256 currentValue = _getTokenPrice(cryptoExchangeAddress);
        if (
            DataTypes.ProductType.BUY_LOW == productType &&
            currentValue >= conditionAmount
        ) {
            return DataTypes.ProgressStatus.UNREACHED;
        } else if (
            DataTypes.ProductType.BUY_LOW == productType &&
            currentValue < conditionAmount
        ) {
            return DataTypes.ProgressStatus.REACHED;
        } else if (
            DataTypes.ProductType.SELL_HIGH == productType &&
            currentValue > conditionAmount
        ) {
            return DataTypes.ProgressStatus.REACHED;
        } else {
            return DataTypes.ProgressStatus.UNREACHED;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library DataTypes {
    struct PurchaseProduct {
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
        address tokenAddress;
        uint256 customerReward;
        uint256 cryptoQuantity;
    }

    struct CustomerByCrypto {
        address customerAddress;
        address cryptoAddress;
        uint256 amount;
    }

    struct ExchangeTotal {
        address tokenIn;
        address tokenOut;
        uint256 tokenInAmount;
        uint256 tokenOutAmount;
    }

    struct ProductInfo {
        uint256 productId;
        uint256 conditionAmount;
        uint256 customerQuantity;
        uint256 cryptoQuantity;
        address cryptoType;
        ProgressStatus resultByCondition;
        address cryptoExchangeAddress;
        uint256 releaseHeight;
        ProductType productType;
        uint256 totalCustomerReward;
        bool isSatisfied;
        uint256 totalAvailableVolume;
        uint256 sellEndTime;
        uint256 sellTotalAmount;
        RewardType rewardType;
        int256 safetyBufferRate;
    }

    enum ProductType {
        BUY_LOW,
        SELL_HIGH
    }

    enum ProgressStatus {
        UNDELIVERED,
        REACHED,
        UNREACHED
    }

    enum RewardType {
        APR,
        APY
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IPriceFeed {
    function description() external view returns (string memory);

    function aggregator() external view returns (address);

    function latestAnswer() external view returns (int256);

    function latestRound() external view returns (uint80);

    function getRoundData(uint80 roundId)
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../../library/common/DataTypes.sol";

interface IProductPool {
    function getProductInfoByPid(uint256 productId)
        external
        view
        returns (DataTypes.ProductInfo memory);

    function getProductInfoList()
        external
        view
        returns (DataTypes.ProductInfo[] memory);

    function _s_retireProductAndUpdateInfo(
        uint256 productId,
        DataTypes.ProgressStatus resultByCondition,
        uint256 totalCustomerReward
    ) external returns (bool);
}