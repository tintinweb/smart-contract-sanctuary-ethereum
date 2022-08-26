// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IMatrixERC20.sol";
import "./interfaces/IMatrixPair.sol";
import "./interfaces/IMatrixFactory.sol";


interface IRewarder {
    using SafeERC20 for IERC20;

    function onMatrixReward(address user, uint256 newLpAmount) external;

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (address);

    function tokenPerSec() external view returns (uint256);
}

interface IMasterChef {
    struct PoolInfo {
        IMatrixPair lpToken; // Address of LP token contract.
        uint256 accMatrixPerShare; // Accumulated MATRIX per share, times 1e12. See below.
        uint256 lastRewardTimestamp; // Last block number that MATRIX distribution occurs.
        uint256 allocPoint; // How many allocation points assigned to this pool. MATRIX to distribute per block.
        IRewarder rewarder;
    }

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function matrixPerSec() external view returns (uint256);
}

interface IBoostedMasterchef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 factor;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint96 allocPoint;
        uint256 accMatrixPerShare;
        uint256 accMatrixPerFactorPerShare;
        uint64 lastRewardTimestamp;
        IRewarder rewarder;
        uint32 veMatrixShareBp;
        uint256 totalFactor;
        uint256 totalLpSupply;
    }

    function userInfo(uint256 _pid, address user) external view returns (UserInfo memory);

    function pendingTokens(uint256 _pid, address user)
        external
        view
        returns (
            uint256,
            address,
            string memory,
            uint256
        );

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function matrixPerSec() external view returns (uint256);
}

contract FarmLensMatrixV3 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct FarmInfo {
        uint256 id;
        uint256 allocPoint;
        address lpAddress;
        address token0Address;
        address token1Address;
        string token0Symbol;
        string token1Symbol;
        uint256 reserveUsd;
        uint256 totalSupplyScaled;
        address chefAddress;
        uint256 chefBalanceScaled;
        uint256 chefTotalAlloc;
        uint256 chefMatrixPerSec;
        uint256 baseApr;
        uint256 bonusApr;
        uint256 matrixPriceUsd;
        string rewardSymbol;
    }

    struct FarmInfoBMCJ {
        uint256 id;
        uint256 allocPoint;
        address lpAddress;
        address token0Address;
        address token1Address;
        string token0Symbol;
        string token1Symbol;
        uint256 reserveUsd;
        uint256 totalSupplyScaled;
        address chefAddress;
        uint256 chefBalanceScaled;
        uint256 chefTotalAlloc;
        uint256 chefMatrixPerSec;
        uint256 baseApr;
        uint256 averageBoostedApr;
        uint256 veMatrixShareBp;
        uint256 matrixPriceUsd;
        uint256 userLp;
        uint256 userPendingMatrix;
        uint256 userBoostedApr;
        uint256 userFactorShare;
        string rewardSymbol;
    }

    struct AllFarmData {
        uint256 maticPriceUsd;
        uint256 matrixPriceUsd;
        uint256 totalAllocChefV2;
        uint256 totalAllocChefV3;
        uint256 totalAllocBMCJ;
        uint256 matrixPerSecChefV2;
        uint256 matrixPerSecChefV3;
        uint256 matrixPerSecBMCJ;
        FarmInfo[] farmInfosV2;
        FarmInfo[] farmInfosV3;
        FarmInfoBMCJ[] farmInfosBMCJ;
    }

    struct GlobalInfo {
        address chef;
        uint256 totalAlloc;
        uint256 matrixPerSec;
    }

    struct Rewarder {
        string symbol;
        uint256 tokenPerSec;
    }

    /// @dev 365 * 86400, hard coding it for gas optimisation
    uint256 private constant SEC_PER_YEAR = 31536000;
    uint256 private constant BP_PRECISION = 10_000;
    uint256 private constant PRECISION = 1e18;

    address public immutable matrix; 
    address public immutable wmatic; 
    IMatrixPair public immutable wmaticUsdt;
    IMatrixPair public immutable wmaticUsdce;
    IMatrixPair public immutable wmaticUsdc;
    IMatrixFactory public immutable matrixFactory;
    IMasterChef public immutable chefv2;
    IMasterChef public immutable chefv3;
    IBoostedMasterchef public immutable bmcj;
    bool private immutable isWmaticToken1InWmaticUsdt;
    bool private immutable isWmaticToken1InWmaticUsdce;
    bool private immutable isWmaticToken1InWmaticUsdc;

    constructor(
        address _matrix,
        address _wmatic,
        IMatrixPair _wmaticUsdt,
        IMatrixPair _wmaticUsdce,
        IMatrixPair _wmaticUsdc,
        IMatrixFactory _matrixFactory,
        IMasterChef _chefv2,
        IMasterChef _chefv3,
        IBoostedMasterchef _bmcj
    ) public {
        matrix = _matrix;
        wmatic = _wmatic;
        wmaticUsdt = _wmaticUsdt;
        wmaticUsdce = _wmaticUsdce;
        wmaticUsdc = _wmaticUsdc;
        matrixFactory = _matrixFactory;
        chefv2 = _chefv2;
        chefv3 = _chefv3;
        bmcj = _bmcj;

        isWmaticToken1InWmaticUsdt = _wmaticUsdt.token1() == _wmatic;
        isWmaticToken1InWmaticUsdce = _wmaticUsdce.token1() == _wmatic;
        isWmaticToken1InWmaticUsdc = _wmaticUsdc.token1() == _wmatic;
    }

    /// @notice Returns the price of matic in Usd
    /// @return uint256 the matic price, scaled to 18 decimals
    function getMaticPrice() external view returns (uint256) {
        return _getMaticPrice();
    }

    /// @notice Returns the derived price of token, it needs to be paired with wmatic
    /// @param token The address of the token
    /// @return uint256 the token derived price, scaled to 18 decimals
    function getDerivedMaticPriceOfToken(address token) external view returns (uint256) {
        return _getDerivedMaticPriceOfToken(token);
    }

    /// @notice Returns the Usd price of token, it needs to be paired with wmatic
    /// @param token The address of the token
    /// @return uint256 the Usd price of token, scaled to 18 decimals
    function getTokenPrice(address token) external view returns (uint256) {
        return _getDerivedMaticPriceOfToken(token).mul(_getMaticPrice()) / 1e18;
    }

    /// @notice Returns the farm pairs data for MCV2 and MCV3
    /// @param chef The address of the MasterChef
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfo The information of all the whitelisted farms of MCV2 or MCV3
    function getMCFarmInfos(IMasterChef chef, uint256[] calldata whitelistedPids)
        external
        view
        returns (FarmInfo[] memory)
    {
        require(chef == chefv2 || chef == chefv3, "FarmLensV2: only for MCV2 and MCV3");

        uint256 maticPrice = _getMaticPrice();
        uint256 matrixPrice = _getDerivedMaticPriceOfToken(matrix).mul(maticPrice) / PRECISION;
        return _getMCFarmInfos(chef, maticPrice, matrixPrice, whitelistedPids);
    }

    /// @notice Returns the farm pairs data for BoostedMasterChefMatrix
    /// @param chef The address of the MasterChef
    /// @param user The address of the user, if address(0), returns global info
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfoBMCJ The information of all the whitelisted farms of BMCJ
    function getBMCJFarmInfos(
        IBoostedMasterchef chef,
        address user,
        uint256[] calldata whitelistedPids
    ) external view returns (FarmInfoBMCJ[] memory) {
        require(chef == bmcj, "FarmLensV2: Only for BMCJ");

        uint256 maticPrice = _getMaticPrice();
        uint256 matrixPrice = _getDerivedMaticPriceOfToken(matrix).mul(maticPrice) / PRECISION;
        return _getBMCJFarmInfos(maticPrice, matrixPrice, user, whitelistedPids);
    }

    /// @notice Get all data needed for useFarms hook.
    /// @param whitelistedPidsV2 Array of all ids of pools that are whitelisted in chefV2
    /// @param whitelistedPidsV3 Array of all ids of pools that are whitelisted in chefV3
    /// @param whitelistedPidsBMCJ Array of all ids of pools that are whitelisted in BMCJ
    /// @param user The address of the user, if address(0), returns global info
    /// @return AllFarmData The information of all the whitelisted farms of MCV2, MCV3 and BMCJ
    function getAllFarmData(
        uint256[] calldata whitelistedPidsV2,
        uint256[] calldata whitelistedPidsV3,
        uint256[] calldata whitelistedPidsBMCJ,
        address user
    ) external view returns (AllFarmData memory) {
        AllFarmData memory allFarmData;

        uint256 maticPrice = _getMaticPrice();
        uint256 matrixPrice = _getDerivedMaticPriceOfToken(matrix).mul(maticPrice) / PRECISION;

        allFarmData.maticPriceUsd = maticPrice;
        allFarmData.matrixPriceUsd = matrixPrice;

        allFarmData.totalAllocChefV2 = chefv2.totalAllocPoint();
        allFarmData.matrixPerSecChefV2 = chefv2.matrixPerSec();

        allFarmData.totalAllocChefV3 = chefv3.totalAllocPoint();
        allFarmData.matrixPerSecChefV3 = chefv3.matrixPerSec();

        allFarmData.totalAllocBMCJ = bmcj.totalAllocPoint();
        allFarmData.matrixPerSecBMCJ = bmcj.matrixPerSec();

        allFarmData.farmInfosV2 = _getMCFarmInfos(chefv2, maticPrice, matrixPrice, whitelistedPidsV2);
        allFarmData.farmInfosV3 = _getMCFarmInfos(chefv3, maticPrice, matrixPrice, whitelistedPidsV3);
        allFarmData.farmInfosBMCJ = _getBMCJFarmInfos(maticPrice, matrixPrice, user, whitelistedPidsBMCJ);

        return allFarmData;
    }

    /// @notice Returns the price of matic in Usd internally
    /// @return uint256 the matic price, scaled to 18 decimals
    function _getMaticPrice() private view returns (uint256) {
        return
            _getDerivedTokenPriceOfPair(wmaticUsdt, isWmaticToken1InWmaticUsdt)
                .add(_getDerivedTokenPriceOfPair(wmaticUsdce, isWmaticToken1InWmaticUsdce))
                .add(_getDerivedTokenPriceOfPair(wmaticUsdc, isWmaticToken1InWmaticUsdc)) / 3;
    }

    /// @notice Returns the derived price of token in the other token
    /// @param pair The address of the pair
    /// @param derivedtoken0 If price should be derived from token0 if true, or token1 if false
    /// @return uint256 the derived price, scaled to 18 decimals
    function _getDerivedTokenPriceOfPair(IMatrixPair pair, bool derivedtoken0) private view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 decimals0 = IERC20(pair.token0()).safeDecimals();
        uint256 decimals1 = IERC20(pair.token1()).safeDecimals();

        if (derivedtoken0) {
            return _scaleTo(reserve0, decimals1.add(18).sub(decimals0)).div(reserve1);
        } else {
            return _scaleTo(reserve1, decimals0.add(18).sub(decimals1)).div(reserve0);
        }
    }

    /// @notice Returns the derived price of token, it needs to be paired with wmatic
    /// @param token The address of the token
    /// @return uint256 the token derived price, scaled to 18 decimals
    function _getDerivedMaticPriceOfToken(address token) private view returns (uint256) {
        if (token == wmatic) {
            return PRECISION;
        }
        IMatrixPair pair = IMatrixPair(matrixFactory.getPair(token, wmatic));
        if (address(pair) == address(0)) {
            return 0;
        }
        // instead of testing wmatic == pair.token0(), we do the opposite to save gas
        return _getDerivedTokenPriceOfPair(pair, token == pair.token1());
    }

    /// @notice Returns the amount scaled to decimals
    /// @param amount The amount
    /// @param decimals The decimals to scale `amount`
    /// @return uint256 The amount scaled to decimals
    function _scaleTo(uint256 amount, uint256 decimals) private pure returns (uint256) {
        if (decimals == 0) return amount;
        return amount.mul(10**decimals);
    }

    /// @notice Returns the derived matic liquidity, at least one of the token needs to be paired with wmatic
    /// @param pair The address of the pair
    /// @return uint256 the derived price of pair's liquidity, scaled to 18 decimals
    function _getDerivedMaticLiquidityOfPair(IMatrixPair pair) private view returns (uint256) {
        address _wmatic = wmatic;
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        IERC20 token0 = IERC20(pair.token0());
        IERC20 token1 = IERC20(pair.token1());
        uint256 decimals0 = token0.safeDecimals();
        uint256 decimals1 = token1.safeDecimals();

        reserve0 = _scaleTo(reserve0, uint256(18).sub(decimals0));
        reserve1 = _scaleTo(reserve1, uint256(18).sub(decimals1));

        uint256 token0DerivedMaticPrice;
        uint256 token1DerivedMaticPrice;
        if (address(token0) == _wmatic) {
            token0DerivedMaticPrice = PRECISION;
            token1DerivedMaticPrice = _getDerivedTokenPriceOfPair(pair, true);
        } else if (address(token1) == _wmatic) {
            token0DerivedMaticPrice = _getDerivedTokenPriceOfPair(pair, false);
            token1DerivedMaticPrice = PRECISION;
        } else {
            token0DerivedMaticPrice = _getDerivedMaticPriceOfToken(address(token0));
            token1DerivedMaticPrice = _getDerivedMaticPriceOfToken(address(token1));
            // If one token isn't paired with wmatic, then we hope that the second one is.
            // E.g, TOKEN/UsdC, token might not be paired with wmatic, but UsdC is.
            // If both aren't paired with wmatic, return 0
            if (token0DerivedMaticPrice == 0) return reserve1.mul(token1DerivedMaticPrice).mul(2) / PRECISION;
            if (token1DerivedMaticPrice == 0) return reserve0.mul(token0DerivedMaticPrice).mul(2) / PRECISION;
        }
        return reserve0.mul(token0DerivedMaticPrice).add(reserve1.mul(token1DerivedMaticPrice)) / PRECISION;
    }

    /// @notice Private function to return the farm pairs data for a given MasterChef (V2 or V3)
    /// @param chef The address of the MasterChef
    /// @param maticPrice The matic price as a parameter to save gas
    /// @param matrixPrice The matrix price as a parameter to save gas
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfo The information of all the whitelisted farms of MCV2 or MCV3
    function _getMCFarmInfos(
        IMasterChef chef,
        uint256 maticPrice,
        uint256 matrixPrice,
        uint256[] calldata whitelistedPids
    ) private view returns (FarmInfo[] memory) {
        GlobalInfo memory globalInfo = GlobalInfo(address(chef), chef.totalAllocPoint(), chef.matrixPerSec());
        
        uint256 whitelistLength = whitelistedPids.length;
        FarmInfo[] memory farmInfos = new FarmInfo[](whitelistLength);

        for (uint256 i; i < whitelistLength; i++) {
            uint256 pid = whitelistedPids[i];
            IMasterChef.PoolInfo memory pool = IMasterChef(globalInfo.chef).poolInfo(pid);
            
            farmInfos[i].id = pid;
            farmInfos[i].chefAddress = globalInfo.chef;
            farmInfos[i].chefTotalAlloc = globalInfo.totalAlloc;
            farmInfos[i].chefMatrixPerSec = globalInfo.matrixPerSec;
            farmInfos[i].matrixPriceUsd = matrixPrice;
            _getMCFarmInfo(
                maticPrice,
                globalInfo.matrixPerSec.mul(matrixPrice) / PRECISION,
                _rewarderInfo(pool.rewarder).tokenPerSec,
                farmInfos[i],
                pool
            );
        }

        return farmInfos;
    }

    /// @notice Helper function to return the farm info of a given pool
    /// @param maticPrice The matic price as a parameter to save gas
    /// @param BaseUsdPerSec The Usd per sec emitted to MCV3
    /// @param BonusUsdPerSec The Usd per sec emitted by rewarder
    /// @param farmInfo The farmInfo of that pool
    /// @param pool The pool info
    function _getMCFarmInfo(
        uint256 maticPrice,
        uint256 BaseUsdPerSec,
        uint256 BonusUsdPerSec,
        FarmInfo memory farmInfo,
        IMasterChef.PoolInfo memory pool
    ) private view {
        {
            uint256 decimals = pool.lpToken.decimals();
            IERC20 token0 = IERC20(pool.lpToken.token0());
            IERC20 token1 = IERC20(pool.lpToken.token1());

            farmInfo.allocPoint = pool.allocPoint;
            farmInfo.lpAddress = address(pool.lpToken);
            farmInfo.token0Address = address(token0);
            farmInfo.token1Address = address(token1);
            farmInfo.token0Symbol = token0.safeSymbol();
            farmInfo.token1Symbol = token1.safeSymbol();
            farmInfo.rewardSymbol = _rewarderInfo(pool.rewarder).symbol;
            farmInfo.reserveUsd = _getDerivedMaticLiquidityOfPair(pool.lpToken).mul(maticPrice) / PRECISION;
            // LP is in 18 decimals, so it's already scaled for JLP
            farmInfo.totalSupplyScaled = _scaleTo(pool.lpToken.totalSupply(), 18 - decimals);
            farmInfo.chefBalanceScaled = _scaleTo(pool.lpToken.balanceOf(address(farmInfo.chefAddress)), 18 - decimals);
        }

        if (
            farmInfo.chefBalanceScaled != 0 &&
            farmInfo.totalSupplyScaled != 0 &&
            farmInfo.chefTotalAlloc != 0 &&
            farmInfo.reserveUsd != 0
        ) {
            uint256 poolUsdPerYear = BaseUsdPerSec.mul(pool.allocPoint).mul(SEC_PER_YEAR) / farmInfo.chefTotalAlloc;
            uint256 bonusUsdPerYear = BonusUsdPerSec.mul(SEC_PER_YEAR);

            uint256 poolReserveUsd = farmInfo.reserveUsd.mul(farmInfo.chefBalanceScaled) / farmInfo.totalSupplyScaled;

            if (poolReserveUsd == 0) return;

            farmInfo.baseApr = poolUsdPerYear.mul(PRECISION) / poolReserveUsd;
            farmInfo.bonusApr = bonusUsdPerYear.mul(PRECISION) / poolReserveUsd;
        }
    }

    /// @notice Private function to return the farm pairs data for boostedMasterChef
    /// @param maticPrice The matic price as a parameter to save gas
    /// @param matrixPrice The matrix price as a parameter to save gas
    /// @param user The address of the user, if address(0), returns global info
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfoBMCJ The information of all the whitelisted farms of BMCJ
    function _getBMCJFarmInfos(
        uint256 maticPrice,
        uint256 matrixPrice,
        address user,
        uint256[] calldata whitelistedPids
    ) private view returns (FarmInfoBMCJ[] memory) {
        GlobalInfo memory globalInfo = GlobalInfo(address(bmcj), bmcj.totalAllocPoint(), bmcj.matrixPerSec());

        uint256 whitelistLength = whitelistedPids.length;
        FarmInfoBMCJ[] memory farmInfos = new FarmInfoBMCJ[](whitelistLength);

        for (uint256 i; i < whitelistLength; i++) {
            uint256 pid = whitelistedPids[i];
            IBoostedMasterchef.PoolInfo memory pool = IBoostedMasterchef(globalInfo.chef).poolInfo(pid);
            IBoostedMasterchef.UserInfo memory userInfo;
            userInfo = IBoostedMasterchef(globalInfo.chef).userInfo(pid, user);

            farmInfos[i].id = pid;
            farmInfos[i].chefAddress = globalInfo.chef;
            farmInfos[i].chefTotalAlloc = globalInfo.totalAlloc;
            farmInfos[i].chefMatrixPerSec = globalInfo.matrixPerSec;
            farmInfos[i].matrixPriceUsd = matrixPrice;
            _getBMCJFarmInfo(
                maticPrice,
                globalInfo.matrixPerSec.mul(matrixPrice) / PRECISION,
                user,
                farmInfos[i],
                pool,
                userInfo
            );
        }

        return farmInfos;
    }

    /// @notice Helper function to return the farm info of a given pool of BMCJ
    /// @param maticPrice The matic price as a parameter to save gas
    /// @param UsdPerSec The Usd per sec emitted to BMCJ
    /// @param userAddress The address of the user
    /// @param farmInfo The farmInfo of that pool
    /// @param user The user information
    function _getBMCJFarmInfo(
        uint256 maticPrice,
        uint256 UsdPerSec,
        address userAddress,
        FarmInfoBMCJ memory farmInfo,
        IBoostedMasterchef.PoolInfo memory pool,
        IBoostedMasterchef.UserInfo memory user
    ) private view {
        {
            IMatrixPair lpToken = IMatrixPair(address(pool.lpToken));
            IERC20 token0 = IERC20(lpToken.token0());
            IERC20 token1 = IERC20(lpToken.token1());

            farmInfo.allocPoint = pool.allocPoint;
            farmInfo.lpAddress = address(lpToken);
            farmInfo.token0Address = address(token0);
            farmInfo.token1Address = address(token1);
            farmInfo.token0Symbol = token0.safeSymbol();
            farmInfo.token1Symbol = token1.safeSymbol();
            farmInfo.rewardSymbol = _rewarderInfo(pool.rewarder).symbol;
            farmInfo.reserveUsd = _getDerivedMaticLiquidityOfPair(lpToken).mul(maticPrice) / PRECISION;
            // LP is in 18 decimals, so it's already scaled for JLP
            farmInfo.totalSupplyScaled = lpToken.totalSupply();
            farmInfo.chefBalanceScaled = pool.totalLpSupply;
            farmInfo.userLp = user.amount;
            farmInfo.veMatrixShareBp = pool.veMatrixShareBp;
            (farmInfo.userPendingMatrix, , , ) = bmcj.pendingTokens(farmInfo.id, userAddress);
        }

        if (
            pool.totalLpSupply != 0 &&
            farmInfo.totalSupplyScaled != 0 &&
            farmInfo.chefTotalAlloc != 0 &&
            farmInfo.reserveUsd != 0
        ) {
            uint256 poolUsdPerYear = UsdPerSec.mul(pool.allocPoint).mul(SEC_PER_YEAR) / farmInfo.chefTotalAlloc;

            uint256 poolReserveUsd = farmInfo.reserveUsd.mul(farmInfo.chefBalanceScaled) / farmInfo.totalSupplyScaled;

            if (poolReserveUsd == 0) return;

            farmInfo.baseApr =
                poolUsdPerYear.mul(BP_PRECISION - pool.veMatrixShareBp).mul(PRECISION) /
                poolReserveUsd /
                BP_PRECISION;

            if (pool.totalFactor != 0) {
                farmInfo.averageBoostedApr =
                    poolUsdPerYear.mul(pool.veMatrixShareBp).mul(PRECISION) /
                    poolReserveUsd /
                    BP_PRECISION;

                if (user.amount != 0 && user.factor != 0) {
                    uint256 userLpUsd = user.amount.mul(farmInfo.reserveUsd) / pool.totalLpSupply;

                    farmInfo.userBoostedApr =
                        poolUsdPerYear.mul(pool.veMatrixShareBp).mul(user.factor).div(pool.totalFactor).mul(PRECISION) /
                        userLpUsd /
                        BP_PRECISION;

                    farmInfo.userFactorShare = user.factor.mul(PRECISION) / pool.totalFactor;
                }
            }
        }
    }

    function _rewarderInfo(IRewarder rewarder) internal view returns (Rewarder memory) {
        Rewarder memory sRewarder;
        uint256 maticPrice = _getMaticPrice();
        if (address(rewarder) != address(0)) {
            sRewarder.symbol = IERC20(rewarder.rewardToken()).safeSymbol();
            uint256 tokenPrice = _getDerivedMaticPriceOfToken(rewarder.rewardToken()).mul(maticPrice) / PRECISION;

            sRewarder.tokenPerSec = rewarder.tokenPerSec().mul(tokenPrice) / PRECISION;
        }

        return sRewarder;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "SafeMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "SafeMath: Div by Zero");
        c = a / b;
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "SafeMath: uint128 Overflow");
        c = uint128(a);
    }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Matrix {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IMatrixERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IMatrixPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IMatrixFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}