// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../library/common/DataTypes.sol";
import "../library/common/ConfigurationParam.sol";
import "../product/interfaces/IProductPool.sol";
import "../product/interfaces/ICustomerPool.sol";

contract Execution {
    function executeWithRewards(
        address productPoolAddress,
        uint256 releaseHeight,
        address customerAddress,
        uint256 productId,
        ICustomerPool pool
    )
        external
        view
        returns (
            DataTypes.CustomerByCrypto memory,
            DataTypes.CustomerByCrypto memory
        )
    {
        IProductPool productPool = IProductPool(productPoolAddress);
        DataTypes.ProductInfo memory product = productPool.getProductInfoByPid(
            productId
        );
        _validateProductStatus(product);
        DataTypes.PurchaseProduct memory customerProduct = pool
            .getSpecifiedProduct(productId, customerAddress, releaseHeight);
        _validatePurchaseProduct(customerProduct);
        return _getCustomerRewardAndPrincipal(customerAddress, customerProduct);
    }

    function executeWithSwap(
        address productPoolAdd,
        uint256 releaseHeight,
        address customerAddress,
        uint256 productId,
        ICustomerPool pool
    ) external view returns (DataTypes.CustomerByCrypto memory) {
        IProductPool productPool = IProductPool(productPoolAdd);
        DataTypes.ProductInfo memory product = productPool.getProductInfoByPid(
            productId
        );
        _validateProductStatus(product);
        DataTypes.PurchaseProduct memory purchaseProduct = pool
            .getSpecifiedProduct(productId, customerAddress, releaseHeight);
        _validatePurchaseProduct(purchaseProduct);
        if (DataTypes.ProductType.BUY_LOW == product.productType) {
            return
                DataTypes.CustomerByCrypto(
                    customerAddress,
                    product.cryptoType,
                    purchaseProduct.cryptoQuantity
                );
        } else {
            return
                DataTypes.CustomerByCrypto(
                    customerAddress,
                    ConfigurationParam.USDC,
                    purchaseProduct.cryptoQuantity
                );
        }
    }

    function _getCustomerRewardAndPrincipal(
        address customerAddress,
        DataTypes.PurchaseProduct memory purchaseProduct
    )
        private
        pure
        returns (
            DataTypes.CustomerByCrypto memory,
            DataTypes.CustomerByCrypto memory
        )
    {
        DataTypes.CustomerByCrypto memory customerByCrypto = DataTypes
            .CustomerByCrypto(
                customerAddress,
                purchaseProduct.tokenAddress,
                purchaseProduct.amount
            );
        DataTypes.CustomerByCrypto memory customerByCryptoReward = DataTypes
            .CustomerByCrypto(
                customerAddress,
                ConfigurationParam.USDC,
                purchaseProduct.customerReward
            );
        return (customerByCrypto, customerByCryptoReward);
    }

    function _validateProductStatus(DataTypes.ProductInfo memory product)
        private
        pure
        returns (bool)
    {
        require(
            DataTypes.ProgressStatus.UNDELIVERED != product.resultByCondition,
            "Undelivered product"
        );
        return true;
    }

    function _validatePurchaseProduct(
        DataTypes.PurchaseProduct memory customerProduct
    ) private pure returns (bool) {
        require(
            customerProduct.amount > 0 && customerProduct.releaseHeight > 0,
            "The user has not purchased the product"
        );
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library ConfigurationParam {
    //uint256 internal constant WAD_RAY_RATIO = 1e9;
    //dev
    //address internal constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant ROUTER_ADDRESS =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint24 internal constant POOLFEE = 3000;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "../../library/common/DataTypes.sol";

interface ICustomerPool {
    function getProductList(uint256 _prod)
        external
        view
        returns (DataTypes.PurchaseProduct[] memory);

    function getSpecifiedProduct(
        uint256 _prod,
        address _customerAddress,
        uint256 _releaseHeight
    ) external view returns (DataTypes.PurchaseProduct memory);
    
     function deleteSpecifiedProduct(
        uint256 _prod,
        address _customerAddress,
        uint256 _releaseHeight
    ) external returns (bool);

    function addCustomerByProduct(
        uint256 _pid,
        address _customerAddress,
        uint256 _amount,
        address _token,
        uint256 _customerReward,
        uint256 _cryptoQuantity
    ) external returns (bool);
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