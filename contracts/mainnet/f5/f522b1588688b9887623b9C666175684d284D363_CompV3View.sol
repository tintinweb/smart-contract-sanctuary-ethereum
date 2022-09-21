/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;




contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}





contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}





contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) internal pure returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) internal pure returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) internal pure returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) internal pure returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) internal pure returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) internal pure returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }

    function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) internal pure returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) internal pure returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) internal pure returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) internal pure returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) internal pure returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) internal pure returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) internal pure returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) internal pure returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) internal pure returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) internal pure returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
}





abstract contract IComet {

    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

      struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }


    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct TotalsBasic {
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    function totalsBasic() public virtual view returns (TotalsBasic memory);

    function totalsCollateral(address) public virtual returns (TotalsCollateral memory);
    
    function supply(address asset, uint amount) virtual external;
    function supplyTo(address dst, address asset, uint amount) virtual external;
    function supplyFrom(address from, address dst, address asset, uint amount) virtual external;

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);

    function transferAsset(address dst, address asset, uint amount) virtual external;
    function transferAssetFrom(address src, address dst, address asset, uint amount) virtual external;

    function withdraw(address asset, uint amount) virtual external;
    function withdrawTo(address to, address asset, uint amount) virtual external;
    function withdrawFrom(address src, address to, address asset, uint amount) virtual external;

    function accrueAccount(address account) virtual external;
    function getSupplyRate(uint utilization) virtual public view returns (uint64);
    function getBorrowRate(uint utilization) virtual public view returns (uint64);
    function getUtilization() virtual public view returns (uint);

    function governor() virtual external view returns (address);
    function baseToken() virtual external view returns (address);
    function baseTokenPriceFeed() virtual external view returns (address);

    function balanceOf(address account) virtual public view returns (uint256);
    function collateralBalanceOf(address account, address asset) virtual external view returns (uint128);
    function borrowBalanceOf(address account) virtual public view returns (uint256);
    function totalSupply() virtual external view returns (uint256);

    function numAssets() virtual public view returns (uint8);
    function getAssetInfo(uint8 i) virtual public view returns (AssetInfo memory);
    function getAssetInfoByAddress(address asset) virtual public view returns (AssetInfo memory);
    function getPrice(address priceFeed) virtual public view returns (uint256);

    function allow(address manager, bool isAllowed) virtual external;
    function allowance(address owner, address spender) virtual external view returns (uint256);

    function isSupplyPaused() virtual external view returns (bool);
    function isTransferPaused() virtual external view returns (bool);
    function isWithdrawPaused() virtual external view returns (bool);
    function isAbsorbPaused() virtual external view returns (bool);
    function baseIndexScale() virtual external pure returns (uint64);

    function userBasic(address) virtual external view returns (UserBasic memory);
    function userCollateral(address, address) virtual external view returns (UserCollateral memory);
    function priceScale() virtual external pure returns (uint64);
    function factorScale() virtual external pure returns (uint64);

    function baseBorrowMin() virtual external pure returns (uint256);
    function baseTrackingBorrowSpeed() virtual external pure returns (uint256);
    function baseTrackingSupplySpeed() virtual external pure returns (uint256);

}





abstract contract ICometExt {
    function allow(address manager, bool isAllowed) virtual external;
    function collateralBalanceOf(address account, address asset) virtual external view returns (uint128);
    function allowance(address owner, address spender) virtual external view returns (uint256);
}





abstract contract ICometRewards {
    struct RewardConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpscale;
    }
    struct RewardOwed {
        address token;
        uint owed;
    }

    function rewardConfig(address) external virtual returns (RewardConfig memory);

    function claimTo(
        address comet,
        address src,
        address to,
        bool shouldAccrue
    ) external virtual;

    function rewardsClaimed(address _market, address _user) external virtual view returns (uint256);
    function getRewardOwed(address _market, address _user) external virtual returns (RewardOwed memory);
}





contract MainnetCompV3Addresses {
    address internal constant COMET_REWARDS_ADDR = 0x1B0e765F6224C21223AeA2af16c1C46E38885a40;
}






contract CompV3Helper is MainnetCompV3Addresses{
    
}









contract CompV3View is Exponential, DSMath, CompV3Helper {

    struct LoanData {
        address user;
        address[] collAddr;
        uint[] collAmounts;
        uint depositAmount;
        uint depositValue;
        uint borrowAmount;
        uint borrowValue;
        uint collValue;
    }

    struct CollateralInfoFull {
        address tokenAddr;
        uint totalSupply;
        uint supplyReserved;
        uint borrowCollateralFactor;
        uint liquidateCollateralFactor;
        uint liquidationFactor;
        uint price;
        uint supplyCap;
    }

    struct BaseTokenInfoFull {
        address tokenAddr;
        uint price;
        uint supplyIndex;
        uint borrowIndex;
        uint trackingSupplyIndex;
        uint trackingBorrowIndex;
        uint supplyRate;
        uint borrowRate;
        uint totalSupply;
        uint totalBorrow;
        uint utilization;
        uint baseBorrowMin;
        uint baseTrackingBorrowRewardsSpeed;
        uint baseTrackingSupplyRewardsSpeed;
    }

    struct GovernanceInfoFull {
        bool isSupplyPaused;
        bool isTransferPaused;
        bool isWithdrawPaused;
        bool isAbsorbPaused;
    }
    
    function isAllowed(address _market, address _owner, address _manager) public view returns(bool isAllowed) {
        return ICometExt(_market).allowance(_owner, _manager) == 0 ? false : true;
    }

    /// @notice Returns all supported collateral assets 
    function getAssets(address _market) public view returns(IComet.AssetInfo[] memory assets){
        uint8 numAssets = IComet(_market).numAssets();
        assets = new IComet.AssetInfo[](numAssets);

        for(uint8 i = 0; i < numAssets; i++){
            assets[i] = IComet(_market).getAssetInfo(i);
        }
        return assets;
    }


    /// @notice Fetches all the collateral/debt address and amounts, denominated in usd
    /// @param _users Addresses of the user
    /// @return loans Array of LoanData information
    function getLoanDataArr(address _market, address[] memory _users) public view returns (LoanData[] memory loans) {
        loans = new LoanData[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            loans[i] = getLoanData(_market, _users[i]);
        }
    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in usd
    /// @param _user Address of the user
    /// @return data LoanData information
    function getLoanData(address _market, address _user) public view returns (LoanData memory data) {
        IComet.AssetInfo[] memory assets = getAssets(_market);
        IComet comet = IComet(_market);

        data = LoanData({
            user: _user,
            collAddr: new address[](assets.length),
            collAmounts: new uint[](assets.length),
            depositAmount: 0,
            depositValue: 0,
            borrowAmount: 0,
            borrowValue: 0,
            collValue: 0
        });

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i].asset;
            address priceFeed = assets[i].priceFeed; 

            uint tokenBalance = comet.collateralBalanceOf(_user,asset);
            data.collAddr[i] = asset;
            data.collAmounts[i] = tokenBalance;
            if (tokenBalance != 0) {
                data.collAddr[i] = asset;
                uint value = tokenBalance * comet.getPrice(priceFeed) / assets[i].scale;
                data.collAmounts[i] = tokenBalance;
                data.collValue += value;
            }
        }

        address usdcPriceFeed = comet.baseTokenPriceFeed();
        data.borrowAmount = comet.borrowBalanceOf(_user);
        data.borrowValue = comet.borrowBalanceOf(_user) * comet.getPrice(usdcPriceFeed) / comet.priceScale();
        data.depositAmount = comet.balanceOf(_user);
        data.depositValue = comet.balanceOf(_user) * comet.getPrice(usdcPriceFeed) / comet.priceScale();

        return data;
    }

    function getFullCollInfo(address _market, address _tokenAddr) public returns(CollateralInfoFull memory coll) {
        IComet comet = IComet(_market);

        IComet.AssetInfo memory assetInfo = comet.getAssetInfoByAddress(_tokenAddr);
        IComet.TotalsCollateral memory totalColl = comet.totalsCollateral(_tokenAddr);

        coll = CollateralInfoFull({
            tokenAddr: _tokenAddr,
            totalSupply: totalColl.totalSupplyAsset,
            supplyReserved: totalColl._reserved,
            borrowCollateralFactor: assetInfo.borrowCollateralFactor,
            liquidateCollateralFactor: assetInfo.liquidateCollateralFactor,
            liquidationFactor: assetInfo.liquidationFactor,
            price: comet.getPrice(assetInfo.priceFeed),
            supplyCap: assetInfo.supplyCap
        });
    }

    function getFullBaseTokenInfo(address _market) public view returns (BaseTokenInfoFull memory baseToken) {
        IComet comet = IComet(_market);

        IComet.TotalsBasic memory basics = comet.totalsBasic();

        uint utilization = comet.getUtilization();

        baseToken = BaseTokenInfoFull({
            tokenAddr: comet.baseToken(),
            price: comet.getPrice(comet.baseTokenPriceFeed()),
            supplyIndex: basics.baseSupplyIndex,
            borrowIndex: basics.baseBorrowIndex,
            trackingSupplyIndex: basics.trackingSupplyIndex,
            trackingBorrowIndex: basics.trackingBorrowIndex,
            supplyRate: comet.getSupplyRate(utilization),
            borrowRate: comet.getBorrowRate(utilization),
            totalSupply: basics.totalSupplyBase,
            totalBorrow: basics.totalBorrowBase,
            utilization: utilization,
            baseBorrowMin: comet.baseBorrowMin(),
            baseTrackingBorrowRewardsSpeed: comet.baseTrackingBorrowSpeed(),
            baseTrackingSupplyRewardsSpeed: comet.baseTrackingSupplySpeed()
        });
    }

    function getFullCollInfos(address _market) public returns(CollateralInfoFull[] memory colls) {
        IComet.AssetInfo[] memory assets = getAssets(_market);
        colls = new CollateralInfoFull[](assets.length);

        for (uint i; i < assets.length; ++i) {
            colls[i] = getFullCollInfo(_market, assets[i].asset);
        }
    }

    function getAssetPrice(address _market, address _tokenAddr) public view returns (uint256) {
        IComet comet = IComet(_market);
        IComet.AssetInfo memory assetInfo = comet.getAssetInfoByAddress(_tokenAddr);

        return comet.getPrice(assetInfo.priceFeed);
    }

    function getGovernanceInfoFull(address _market) public view returns (GovernanceInfoFull memory govInfo) {
        IComet comet = IComet(_market);

        govInfo = GovernanceInfoFull({
            isSupplyPaused: comet.isSupplyPaused(),
            isTransferPaused: comet.isTransferPaused(),
            isWithdrawPaused: comet.isWithdrawPaused(),
            isAbsorbPaused: comet.isAbsorbPaused()
        });
    }

    function getRewardsOwed(address _market, address _user) public returns (ICometRewards.RewardOwed memory rewardsOwed){
        return ICometRewards(COMET_REWARDS_ADDR).getRewardOwed(_market, _user);
    }
}