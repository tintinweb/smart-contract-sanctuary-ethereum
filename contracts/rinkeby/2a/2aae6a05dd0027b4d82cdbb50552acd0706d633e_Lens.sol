// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

contract ExponentialNoError {
    uint constant expScale = 1e18;

    struct Exp {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa : mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa : mul_(a.mantissa, b)});
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

}

interface CToken {
    function balanceOf(address owner) external view returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
}

interface PriceOracle {
    function getUnderlyingPrice(CToken cToken) external view returns (uint);
}


abstract contract Comptroller {
    struct Market {
        bool isListed;
        uint collateralFactorMantissa;
        bool isComped;
    }

    function getAllMarkets() external virtual view returns (CToken[] memory);

    PriceOracle public oracle;
    mapping(address => Market) public markets;
}

contract Lens is ExponentialNoError {

    struct CTokenBalances {
        CTokenBalance[] balances;
        uint sumCollateral;
        uint sumBorrow;
    }

    struct CTokenBalance {
        address cToken;
        uint balanceOf;
        uint borrowBalance;
        uint balanceOfUnderlying;
        uint collateralValue;
        uint borrowValue;
        uint collateralFactor;
    }

    function getBorrowBalance(CToken asset, address account) external returns (uint) {
        return asset.borrowBalanceCurrent(account);
    }

    function cTokenBalances(Comptroller comp, address payable account) external returns (CTokenBalances memory) {
        CToken[] memory assets = comp.getAllMarkets();
        PriceOracle oracle = comp.oracle();

        CTokenBalances memory res;

        res.balances = new CTokenBalance[](assets.length);

        for (uint i = 0; i < assets.length; i++) {
            if (address(assets[i]) == address(0)) {
                continue;
            }
            CToken asset = assets[i];
            CTokenBalance memory balance;
            balance.cToken = address(asset);
            balance.borrowBalance = asset.borrowBalanceCurrent(account);
            balance.balanceOfUnderlying = asset.balanceOfUnderlying(account);
            balance.balanceOf = asset.balanceOf(account);
            (, balance.collateralFactor,) = comp.markets(address(asset));

            Exp memory collateralFactor = Exp({mantissa : balance.collateralFactor});

            // Get the normalized price of the asset
            uint oraclePriceMantissa = getPrice(oracle, address(asset));

            if (oraclePriceMantissa == 0) {
                continue;
            }
            Exp memory oraclePrice = Exp({mantissa : oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            Exp memory tokensToDenom = mul_(collateralFactor, oraclePrice);

            // sumCollateral += tokensToDenom * cTokenBalance
            balance.collateralValue = mul_ScalarTruncate(tokensToDenom, balance.balanceOfUnderlying);
            res.sumCollateral = add_(balance.collateralValue, res.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            balance.borrowValue = mul_ScalarTruncate(oraclePrice, balance.borrowBalance);
            res.sumBorrow = add_(balance.borrowValue, res.sumBorrow);

            res.balances[i] = balance;
        }

        return res;
    }

    function getPrice(PriceOracle oracle, address addr) public returns (uint) {
        (bool success, bytes memory returnData) =
        address(oracle).call(
            abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, addr)
        );
        if (success && returnData.length != 0) {
            return abi.decode(returnData, (uint));
        }

        // get underlying asset
        (success, returnData) = addr.call(abi.encodeWithSignature("underlying()"));
        if (success && returnData.length != 0) {
            return getPrice(oracle, abi.decode(returnData, (address)));
        }
        return 0;
    }
}