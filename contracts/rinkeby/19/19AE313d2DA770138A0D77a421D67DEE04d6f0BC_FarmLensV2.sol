// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IJoeERC20.sol";
import "./interfaces/IJoePair.sol";
import "./interfaces/IJoeFactory.sol";

interface IMasterChef {
    struct PoolInfo {
        IJoeERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. JOE to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that JOE distribution occurs.
        uint256 accJoePerShare; // Accumulated JOE per share, times 1e12. See below.
    }

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function joePerSec() external view returns (uint256);
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
        uint256 accJoePerShare;
        uint256 accJoePerFactorPerShare;
        uint64 lastRewardTimestamp;
        address rewarder;
        uint32 veJoeShareBp;
        uint256 totalFactor;
        uint256 totalLpSupply;
    }

    function userInfo(uint256 _pid, address user) external view returns (UserInfo memory);

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function joePerSec() external view returns (uint256);
}

contract FarmLensV2 {
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
        uint256 chefJoePerSec;
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
        uint256 chefJoePerSec;
        uint256 baseAPR;
        uint256 boostedAPR;
        uint256 boostFactor;
    }

    struct AllFarmData {
        uint256 avaxPriceUsd;
        uint256 joePriceUsd;
        uint256 totalAllocChefV2;
        uint256 totalAllocChefV3;
        uint256 totalAllocBMCJ;
        uint256 joePerSecChefV2;
        uint256 joePerSecChefV3;
        uint256 joePerSecBMCJ;
        FarmInfo[] farmInfosV2;
        FarmInfo[] farmInfosV3;
        FarmInfoBMCJ[] farmInfosBMCJ;
    }

    struct GlobalInfo {
        address chef;
        uint256 totalAlloc;
        uint256 joePerSec;
    }

    /// @dev 365 * 86400, hard coding it for gas optimisation
    uint256 private constant SEC_PER_YEAR = 31536000;
    uint256 private constant BP_PRECISION = 10_000;
    uint256 private constant PRECISION = 1e18;

    address public immutable joe; // 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    address public immutable wavax; // 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    IJoePair public immutable wavaxUsdte; // 0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256
    IJoePair public immutable wavaxUsdce; // 0xA389f9430876455C36478DeEa9769B7Ca4E3DDB1
    IJoePair public immutable wavaxUsdc; // 0xf4003f4efbe8691b60249e6afbd307abe7758adb
    IJoeFactory public immutable joeFactory; // 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10
    IMasterChef public immutable chefv2; // 0xd6a4F121CA35509aF06A0Be99093d08462f53052
    IMasterChef public immutable chefv3; // 0x188bED1968b795d5c9022F6a0bb5931Ac4c18F00
    IBoostedMasterchef public immutable bmcj; // Not deployed yet
    bool private immutable isWavaxToken1InWavaxUsdte;
    bool private immutable isWavaxToken1InWavaxUsdce;
    bool private immutable isWavaxToken1InWavaxUsdc;

    constructor(
        address _joe,
        address _wavax,
        IJoePair _wavaxUsdte,
        IJoePair _wavaxUsdce,
        IJoePair _wavaxUsdc,
        IJoeFactory _joeFactory,
        IMasterChef _chefv2,
        IMasterChef _chefv3,
        IBoostedMasterchef _bmcj
    ) public {
        joe = _joe;
        wavax = _wavax;
        wavaxUsdte = _wavaxUsdte;
        wavaxUsdce = _wavaxUsdce;
        wavaxUsdc = _wavaxUsdc;
        joeFactory = _joeFactory;
        chefv2 = _chefv2;
        chefv3 = _chefv3;
        bmcj = _bmcj;

        isWavaxToken1InWavaxUsdte = _wavaxUsdte.token1() == _wavax;
        isWavaxToken1InWavaxUsdce = _wavaxUsdce.token1() == _wavax;
        isWavaxToken1InWavaxUsdc = _wavaxUsdc.token1() == _wavax;
    }

    /// @notice Returns the price of avax in Usd
    /// @return uint256 the avax price, scaled to 18 decimals
    function getAvaxPrice() external view returns (uint256) {
        return _getAvaxPrice();
    }

    /// @notice Returns the derived price of token, it needs to be paired with wavax
    /// @param token The address of the token
    /// @return uint256 the token derived price, scaled to 18 decimals
    function getDerivedAvaxPriceOfToken(address token) external view returns (uint256) {
        return _getDerivedAvaxPriceOfToken(token);
    }

    /// @notice Returns the Usd price of token, it needs to be paired with wavax
    /// @param token The address of the token
    /// @return uint256 the Usd price of token, scaled to 18 decimals
    function getTokenPrice(address token) external view returns (uint256) {
        return _getDerivedAvaxPriceOfToken(token).mul(_getAvaxPrice()) / 1e18;
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

        uint256 avaxPrice = _getAvaxPrice();
        return _getMCFarmInfos(chef, avaxPrice, whitelistedPids);
    }

    /// @notice Returns the farm pairs data for BoostedMasterChefJoe
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

        uint256 avaxPrice = _getAvaxPrice();
        uint256 joePrice = _getDerivedAvaxPriceOfToken(joe).mul(avaxPrice) / PRECISION;
        return _getBMCJFarmInfos(avaxPrice, joePrice, user, whitelistedPids);
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

        uint256 avaxPrice = _getAvaxPrice();
        uint256 joePrice = _getDerivedAvaxPriceOfToken(joe).mul(avaxPrice) / PRECISION;

        allFarmData.avaxPriceUsd = avaxPrice;
        allFarmData.joePriceUsd = joePrice;

        allFarmData.totalAllocChefV2 = chefv2.totalAllocPoint();
        allFarmData.joePerSecChefV2 = chefv2.joePerSec();

        allFarmData.totalAllocChefV3 = chefv3.totalAllocPoint();
        allFarmData.joePerSecChefV3 = chefv3.joePerSec();

        allFarmData.totalAllocBMCJ = bmcj.totalAllocPoint();
        allFarmData.joePerSecBMCJ = bmcj.joePerSec();

        allFarmData.farmInfosV2 = _getMCFarmInfos(chefv2, avaxPrice, whitelistedPidsV2);
        allFarmData.farmInfosV3 = _getMCFarmInfos(chefv3, avaxPrice, whitelistedPidsV3);
        allFarmData.farmInfosBMCJ = _getBMCJFarmInfos(avaxPrice, joePrice, user, whitelistedPidsBMCJ);

        return allFarmData;
    }

    /// @notice Returns the price of avax in Usd internally
    /// @return uint256 the avax price, scaled to 18 decimals
    function _getAvaxPrice() private view returns (uint256) {
        return
            _getDerivedTokenPriceOfPair(wavaxUsdte, isWavaxToken1InWavaxUsdte)
                .add(_getDerivedTokenPriceOfPair(wavaxUsdce, isWavaxToken1InWavaxUsdce))
                .add(_getDerivedTokenPriceOfPair(wavaxUsdc, isWavaxToken1InWavaxUsdc)) / 3;
    }

    /// @notice Returns the derived price of token in the other token
    /// @param pair The address of the pair
    /// @param derivedtoken0 If price should be derived from token0 if true, or token1 if false
    /// @return uint256 the derived price, scaled to 18 decimals
    function _getDerivedTokenPriceOfPair(IJoePair pair, bool derivedtoken0) private view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 decimals0 = IERC20(pair.token0()).safeDecimals();
        uint256 decimals1 = IERC20(pair.token1()).safeDecimals();

        if (derivedtoken0) {
            return _scaleTo(reserve0, decimals1.add(18).sub(decimals0)).div(reserve1);
        } else {
            return _scaleTo(reserve1, decimals0.add(18).sub(decimals1)).div(reserve0);
        }
    }

    /// @notice Returns the derived price of token, it needs to be paired with wavax
    /// @param token The address of the token
    /// @return uint256 the token derived price, scaled to 18 decimals
    function _getDerivedAvaxPriceOfToken(address token) private view returns (uint256) {
        if (token == wavax) {
            return PRECISION;
        }
        IJoePair pair = IJoePair(joeFactory.getPair(token, wavax));
        if (address(pair) == address(0)) {
            return 0;
        }
        // instead of testing wavax == pair.token0(), we do the opposite to save gas
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

    /// @notice Returns the derived avax liquidity, at least one of the token needs to be paired with wavax
    /// @param pair The address of the pair
    /// @return uint256 the derived price of pair's liquidity, scaled to 18 decimals
    function _getDerivedAvaxLiquidityOfPair(IJoePair pair) private view returns (uint256) {
        address _wavax = wavax;
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        IERC20 token0 = IERC20(pair.token0());
        IERC20 token1 = IERC20(pair.token1());
        uint256 decimals0 = token0.safeDecimals();
        uint256 decimals1 = token1.safeDecimals();

        reserve0 = _scaleTo(reserve0, uint256(18).sub(decimals0));
        reserve1 = _scaleTo(reserve1, uint256(18).sub(decimals1));

        uint256 token0DerivedAvaxPrice;
        uint256 token1DerivedAvaxPrice;
        if (address(token0) == _wavax) {
            token0DerivedAvaxPrice = PRECISION;
            token1DerivedAvaxPrice = _getDerivedTokenPriceOfPair(pair, true);
        } else if (address(token1) == _wavax) {
            token0DerivedAvaxPrice = _getDerivedTokenPriceOfPair(pair, false);
            token1DerivedAvaxPrice = PRECISION;
        } else {
            token0DerivedAvaxPrice = _getDerivedAvaxPriceOfToken(address(token0));
            token1DerivedAvaxPrice = _getDerivedAvaxPriceOfToken(address(token1));
            // If one token isn't paired with wavax, then we hope that the second one is.
            // E.g, TOKEN/UsdC, token might not be paired with wavax, but UsdC is.
            // If both aren't paired with wavax, return 0
            if (token0DerivedAvaxPrice == 0) return reserve1.mul(token1DerivedAvaxPrice).mul(2) / PRECISION;
            if (token1DerivedAvaxPrice == 0) return reserve0.mul(token0DerivedAvaxPrice).mul(2) / PRECISION;
        }
        return reserve0.mul(token0DerivedAvaxPrice).add(reserve1.mul(token1DerivedAvaxPrice)) / PRECISION;
    }

    /// @notice Private function to return the farm pairs data for a given MasterChef (V2 or V3)
    /// @param chef The address of the MasterChef
    /// @param avaxPrice The avax price as a parameter to save gas
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfo The information of all the whitelisted farms of MCV2 or MCV3
    function _getMCFarmInfos(
        IMasterChef chef,
        uint256 avaxPrice,
        uint256[] calldata whitelistedPids
    ) private view returns (FarmInfo[] memory) {
        uint256 whitelistLength = whitelistedPids.length;
        FarmInfo[] memory farmInfos = new FarmInfo[](whitelistLength);

        uint256 chefTotalAlloc = chef.totalAllocPoint();
        uint256 chefJoePerSec = chef.joePerSec();

        for (uint256 i; i < whitelistLength; i++) {
            uint256 pid = whitelistedPids[i];
            IMasterChef.PoolInfo memory pool = chef.poolInfo(pid);

            farmInfos[i] = _getMCFarmInfo(
                chef,
                avaxPrice,
                pid,
                IJoePair(address(pool.lpToken)),
                pool.allocPoint,
                chefTotalAlloc,
                chefJoePerSec
            );
        }

        return farmInfos;
    }

    /// @notice Helper function to return the farm info of a given pool
    /// @param chef The address of the MasterChef
    /// @param avaxPrice The avax price as a parameter to save gas
    /// @param pid The pid of the pool
    /// @param lpToken The lpToken of the pool
    /// @param allocPoint The allocPoint of the pool
    /// @return FarmInfo The information of all the whitelisted farms of MCV2 or MCV3
    function _getMCFarmInfo(
        IMasterChef chef,
        uint256 avaxPrice,
        uint256 pid,
        IJoePair lpToken,
        uint256 allocPoint,
        uint256 totalAllocPoint,
        uint256 chefJoePerSec
    ) private view returns (FarmInfo memory) {
        uint256 decimals = lpToken.decimals();
        uint256 totalSupplyScaled = _scaleTo(lpToken.totalSupply(), 18 - decimals);
        uint256 chefBalanceScaled = _scaleTo(lpToken.balanceOf(address(chef)), 18 - decimals);
        uint256 reserveUsd = _getDerivedAvaxLiquidityOfPair(lpToken).mul(avaxPrice) / PRECISION;
        IERC20 token0 = IERC20(lpToken.token0());
        IERC20 token1 = IERC20(lpToken.token1());

        return
            FarmInfo({
                id: pid,
                allocPoint: allocPoint,
                lpAddress: address(lpToken),
                token0Address: address(token0),
                token1Address: address(token1),
                token0Symbol: token0.safeSymbol(),
                token1Symbol: token1.safeSymbol(),
                reserveUsd: reserveUsd,
                totalSupplyScaled: totalSupplyScaled,
                chefBalanceScaled: chefBalanceScaled,
                chefAddress: address(chef),
                chefTotalAlloc: totalAllocPoint,
                chefJoePerSec: chefJoePerSec
            });
    }

    /// @notice Private function to return the farm pairs data for boostedMasterChef
    /// @param avaxPrice The avax price as a parameter to save gas
    /// @param joePrice The joe price as a parameter to save gas
    /// @param user The address of the user, if address(0), returns global info
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfoBMCJ The information of all the whitelisted farms of BMCJ
    function _getBMCJFarmInfos(
        uint256 avaxPrice,
        uint256 joePrice,
        address user,
        uint256[] calldata whitelistedPids
    ) private view returns (FarmInfoBMCJ[] memory) {
        GlobalInfo memory globalInfo = GlobalInfo(address(bmcj), bmcj.totalAllocPoint(), bmcj.joePerSec());

        uint256 whitelistLength = whitelistedPids.length;
        FarmInfoBMCJ[] memory farmInfos = new FarmInfoBMCJ[](whitelistLength);

        for (uint256 i; i < whitelistLength; i++) {
            uint256 pid = whitelistedPids[i];
            IBoostedMasterchef.PoolInfo memory pool = IBoostedMasterchef(globalInfo.chef).poolInfo(pid);
            IBoostedMasterchef.UserInfo memory userInfo;
            if (user != address(0)) {
                userInfo = IBoostedMasterchef(globalInfo.chef).userInfo(pid, user);
            } else {
                userInfo = IBoostedMasterchef.UserInfo({
                    amount: pool.totalLpSupply,
                    rewardDebt: 0,
                    factor: pool.totalFactor
                });
            }

            farmInfos[i] = _getBMCJFarmInfo(
                avaxPrice,
                globalInfo.joePerSec.mul(joePrice) / PRECISION,
                globalInfo.totalAlloc,
                pool,
                userInfo
            );
            farmInfos[i].id = pid;
            farmInfos[i].chefAddress = globalInfo.chef;
            farmInfos[i].chefTotalAlloc = globalInfo.totalAlloc;
            farmInfos[i].chefJoePerSec = globalInfo.joePerSec;
        }

        return farmInfos;
    }

    /// @notice Helper function to return the farm info of a given pool of BMCJ
    /// @param avaxPrice The avax price as a parameter to save gas
    /// @param UsdPerSec The Usd per sec emitted to BMCJ
    /// @param pool The pool
    /// @param user The userInfo
    /// @return farmInfo The information of all the whitelisted farms of MCV2 or MCV3
    function _getBMCJFarmInfo(
        uint256 avaxPrice,
        uint256 UsdPerSec,
        uint256 totalAlloc,
        IBoostedMasterchef.PoolInfo memory pool,
        IBoostedMasterchef.UserInfo memory user
    ) private view returns (FarmInfoBMCJ memory farmInfo) {
        uint256 reserveUsd;
        {
            IJoePair lpToken = IJoePair(address(pool.lpToken));
            reserveUsd = _getDerivedAvaxLiquidityOfPair(lpToken).mul(avaxPrice) / PRECISION;
            IERC20 token0 = IERC20(lpToken.token0());
            IERC20 token1 = IERC20(lpToken.token1());

            farmInfo.allocPoint = pool.allocPoint;
            farmInfo.lpAddress = address(lpToken);
            farmInfo.token0Address = address(token0);
            farmInfo.token1Address = address(token1);
            farmInfo.token0Symbol = token0.safeSymbol();
            farmInfo.token1Symbol = token1.safeSymbol();
            farmInfo.reserveUsd = reserveUsd;
            // LP is in 18 decimals, so it's already scaled for JLP
            farmInfo.totalSupplyScaled = lpToken.totalSupply();
            farmInfo.chefBalanceScaled = pool.totalLpSupply;
            if (pool.veJoeShareBp == BP_PRECISION) {
                farmInfo.boostFactor = ~uint256(0);
            } else {
                // can't over or underflow, so normal math is fine
                farmInfo.boostFactor =
                    (pool.veJoeShareBp * BP_PRECISION) /
                    (BP_PRECISION - pool.veJoeShareBp) +
                    BP_PRECISION;
            }
        }

        if (pool.totalLpSupply != 0 && farmInfo.totalSupplyScaled != 0 && totalAlloc != 0 && farmInfo.reserveUsd != 0) {
            uint256 poolUsdPerYear = UsdPerSec.mul(pool.allocPoint).mul(SEC_PER_YEAR) / totalAlloc;

            uint256 poolReserveUsd = farmInfo.reserveUsd.mul(farmInfo.chefBalanceScaled) / farmInfo.totalSupplyScaled;

            if (poolReserveUsd == 0) return farmInfo;

            farmInfo.baseAPR = poolUsdPerYear
                .mul(PRECISION)
                .mul(BP_PRECISION - pool.veJoeShareBp)
                .div(poolReserveUsd)
                .div(BP_PRECISION);

            if (pool.totalFactor != 0) {
                uint256 userUsdPerYear = poolUsdPerYear
                    .mul(pool.veJoeShareBp)
                    .mul(user.factor)
                    .div(pool.totalFactor)
                    .mul(user.amount)
                    .div(pool.totalLpSupply);
                farmInfo.boostedAPR = userUsdPerYear.mul(PRECISION).div(BP_PRECISION).div(poolReserveUsd);
            }
        }
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

interface IERC20Joe {
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

interface IJoeERC20 {
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

interface IJoePair {
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

interface IJoeFactory {
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