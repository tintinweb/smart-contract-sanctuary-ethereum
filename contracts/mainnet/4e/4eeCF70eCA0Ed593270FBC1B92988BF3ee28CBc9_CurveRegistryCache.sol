// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "../libraries/CurvePoolUtils.sol";

import "../interfaces/ICurveRegistryCache.sol";
import "../interfaces/vendor/ICurveMetaRegistry.sol";
import "../interfaces/vendor/ICurvePoolV1.sol";

contract CurveRegistryCache is ICurveRegistryCache {
    ICurveMetaRegistry internal constant _CURVE_REGISTRY =
            ICurveMetaRegistry(0xF98B45FA17DE75FB1aD0e7aFD971b0ca00e379fC);

    IBooster public constant BOOSTER = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    modifier onlyInitialized(address pool) {
        require(_isRegistered[pool], "CurveRegistryCache: pool not initialized");
        _;
    }

    mapping(address => bool) internal _isRegistered;
    mapping(address => address) internal _lpToken;
    mapping(address => mapping(address => bool)) internal _hasCoinDirectly;
    mapping(address => mapping(address => bool)) internal _hasCoinAnywhere;
    mapping(address => address) internal _basePool;
    mapping(address => mapping(address => int128)) internal _coinIndex;
    mapping(address => uint256) internal _nCoins;
    mapping(address => address[]) internal _coins;
    mapping(address => uint256[]) internal _decimals;
    mapping(address => address) internal _poolFromLpToken;
    mapping(address => CurvePoolUtils.AssetType) internal _assetType;
    mapping(address => uint256) internal _interfaceVersion;

    /// Information needed for staking Curve LP tokens on Convex
    mapping(address => uint256) internal _convexPid;
    mapping(address => address) internal _convexRewardPool; // curve pool => CRV rewards pool (convex)

    function initPool(address pool_) external override {
        _initPool(pool_, false, 0);
    }

    function initPool(address pool_, uint256 pid_) external override {
        _initPool(pool_, true, pid_);
    }

    function _initPool(
        address pool_,
        bool setPid_,
        uint256 pid_
    ) internal {
        if (_isRegistered[pool_]) return;
        require(_isCurvePool(pool_), "CurveRegistryCache: invalid curve pool");

        _isRegistered[pool_] = true;
        address curveLpToken_ = _CURVE_REGISTRY.get_lp_token(pool_);
        _lpToken[pool_] = curveLpToken_;
        if (setPid_) {
            _setConvexPid(pool_, curveLpToken_, pid_);
        } else {
            _setConvexPid(pool_, curveLpToken_);
        }
        _poolFromLpToken[curveLpToken_] = pool_;
        address basePool_ = _CURVE_REGISTRY.get_base_pool(pool_);
        _basePool[pool_] = basePool_;
        if (basePool_ != address(0)) {
            _initPool(basePool_, false, 0);
            address[] memory basePoolCoins_ = _coins[basePool_];
            for (uint256 i; i < basePoolCoins_.length; i++) {
                address coin_ = basePoolCoins_[i];
                _hasCoinAnywhere[pool_][coin_] = true;
            }
        }
        _assetType[pool_] = CurvePoolUtils.AssetType(_CURVE_REGISTRY.get_pool_asset_type(pool_));
        uint256 nCoins_ = _CURVE_REGISTRY.get_n_coins(pool_);
        address[8] memory staticCoins_ = _CURVE_REGISTRY.get_coins(pool_);
        uint256[8] memory staticDecimals_ = _CURVE_REGISTRY.get_decimals(pool_);
        address[] memory coins_ = new address[](nCoins_);
        for (uint256 i; i < nCoins_; i++) {
            address coin_ = staticCoins_[i];
            require(coin_ != address(0), "CurveRegistryCache: invalid coin");
            coins_[i] = coin_;
            _hasCoinDirectly[pool_][coin_] = true;
            _hasCoinAnywhere[pool_][coin_] = true;
            _coinIndex[pool_][coin_] = int128(uint128(i));
            _decimals[pool_].push(staticDecimals_[i]);
        }
        _nCoins[pool_] = nCoins_;
        _coins[pool_] = coins_;
        _interfaceVersion[pool_] = _getInterfaceVersion(pool_);
    }

    function _setConvexPid(address pool_, address lpToken_) internal {
        uint256 length = BOOSTER.poolLength();
        address rewardPool;
        for (uint256 i; i < length; i++) {
            (address curveToken, , , address rewardPool_, , bool _isShutdown) = BOOSTER.poolInfo(i);
            if (lpToken_ != curveToken || _isShutdown) continue;
            rewardPool = rewardPool_;
            _convexPid[pool_] = i;
            break;
        }
        /// Only Curve pools that have a valid Convex PID can be added to the cache
        require(rewardPool != address(0), "no convex pid found");
        _convexRewardPool[pool_] = rewardPool;
    }

    function _setConvexPid(
        address pool_,
        address lpToken_,
        uint256 pid_
    ) internal {
        (address curveToken, , , address rewardPool_, , bool _isShutdown) = BOOSTER.poolInfo(pid_);
        require(lpToken_ == curveToken, "invalid lp token for curve pool");
        require(!_isShutdown, "convex pool is shutdown");
        require(rewardPool_ != address(0), "no convex pid found");
        _convexRewardPool[pool_] = rewardPool_;
        _convexPid[pool_] = pid_;
    }

    function isRegistered(address pool_) external view override returns (bool) {
        return _isRegistered[pool_];
    }

    function lpToken(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (address)
    {
        return _lpToken[pool_];
    }

    function assetType(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (CurvePoolUtils.AssetType)
    {
        return _assetType[pool_];
    }

    function hasCoinDirectly(address pool_, address coin_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (bool)
    {
        return _hasCoinDirectly[pool_][coin_];
    }

    function hasCoinAnywhere(address pool_, address coin_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (bool)
    {
        return _hasCoinAnywhere[pool_][coin_];
    }

    function basePool(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (address)
    {
        return _basePool[pool_];
    }

    function coinIndex(address pool_, address coin_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (int128)
    {
        return _coinIndex[pool_][coin_];
    }

    function nCoins(address pool_) external view override onlyInitialized(pool_) returns (uint256) {
        return _nCoins[pool_];
    }

    function coinIndices(
        address pool_,
        address from_,
        address to_
    )
        external
        view
        override
        onlyInitialized(pool_)
        returns (
            int128,
            int128,
            bool
        )
    {
        return (
            _coinIndex[pool_][from_],
            _coinIndex[pool_][to_],
            _hasCoinDirectly[pool_][from_] && _hasCoinDirectly[pool_][to_]
        );
    }

    function decimals(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (uint256[] memory)
    {
        return _decimals[pool_];
    }

    /// @notice Returns the Curve interface version for a given pool
    /// @dev Version 0 uses `int128` for `coins` and `balances`, and `int128` for `get_dy`
    /// Version 1 uses `uint256` for `coins` and `balances`, and `int128` for `get_dy`
    /// Version 2 uses `uint256` for `coins` and `balances`, and `uint256` for `get_dy`
    /// They correspond with which interface the pool implements: ICurvePoolV0, ICurvePoolV1, ICurvePoolV2
    function interfaceVersion(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (uint256)
    {
        return _interfaceVersion[pool_];
    }

    function poolFromLpToken(address lpToken_) external view override returns (address) {
        return _poolFromLpToken[lpToken_];
    }

    function coins(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (address[] memory)
    {
        return _coins[pool_];
    }

    function getPid(address pool_) external view override onlyInitialized(pool_) returns (uint256) {
        require(_convexRewardPool[pool_] != address(0), "pid not found");
        return _convexPid[pool_];
    }

    function getRewardPool(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (address)
    {
        return _convexRewardPool[pool_];
    }

    function isShutdownPid(uint256 pid_) external view override returns (bool) {
        (, , , , , bool _isShutdown) = BOOSTER.poolInfo(pid_);
        return _isShutdown;
    }

    function _isCurvePool(address pool_) internal view returns (bool) {
        try _CURVE_REGISTRY.is_registered(pool_) returns (bool registered_) {
            return registered_;
        } catch {
            return false;
        }
    }

    function _getInterfaceVersion(address pool_) internal view returns (uint256) {
        if (_assetType[pool_] == CurvePoolUtils.AssetType.CRYPTO) return 2;
        try ICurvePoolV1(pool_).balances(uint256(0)) returns (uint256) {
            return 1;
        } catch {
            return 0;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "../interfaces/vendor/ICurvePoolV2.sol";
import "../interfaces/vendor/ICurvePoolV1.sol";
import "./ScaledMath.sol";

library CurvePoolUtils {
    using ScaledMath for uint256;

    uint256 internal constant _DEFAULT_IMBALANCE_THRESHOLD = 0.02e18;

    enum AssetType {
        USD,
        ETH,
        BTC,
        OTHER,
        CRYPTO
    }

    struct PoolMeta {
        address pool;
        uint256 numberOfCoins;
        AssetType assetType;
        uint256[] decimals;
        uint256[] prices;
        uint256[] thresholds;
    }

    function ensurePoolBalanced(PoolMeta memory poolMeta) internal view {
        uint256 fromDecimals = poolMeta.decimals[0];
        uint256 fromBalance = 10**fromDecimals;
        uint256 fromPrice = poolMeta.prices[0];
        for (uint256 i = 1; i < poolMeta.numberOfCoins; i++) {
            uint256 toDecimals = poolMeta.decimals[i];
            uint256 toPrice = poolMeta.prices[i];
            uint256 toExpectedUnscaled = (fromBalance * fromPrice) / toPrice;
            uint256 toExpected = toExpectedUnscaled.convertScale(
                uint8(fromDecimals),
                uint8(toDecimals)
            );

            uint256 toActual;

            if (poolMeta.assetType == AssetType.CRYPTO) {
                // Handling crypto pools
                toActual = ICurvePoolV2(poolMeta.pool).get_dy(0, i, fromBalance);
            } else {
                // Handling other pools
                toActual = ICurvePoolV1(poolMeta.pool).get_dy(0, int128(uint128(i)), fromBalance);
            }

            require(
                _isWithinThreshold(toExpected, toActual, poolMeta.thresholds[i]),
                "pool is not balanced"
            );
        }
    }

    function _isWithinThreshold(
        uint256 a,
        uint256 b,
        uint256 imbalanceTreshold
    ) internal pure returns (bool) {
        if (imbalanceTreshold == 0) imbalanceTreshold = _DEFAULT_IMBALANCE_THRESHOLD;
        if (a > b) return (a - b).divDown(a) <= imbalanceTreshold;
        return (b - a).divDown(b) <= imbalanceTreshold;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "./vendor/IBooster.sol";
import "../libraries/CurvePoolUtils.sol";

interface ICurveRegistryCache {
    function BOOSTER() external view returns (IBooster);

    function initPool(address pool_) external;

    function initPool(address pool_, uint256 pid_) external;

    function lpToken(address pool_) external view returns (address);

    function assetType(address pool_) external view returns (CurvePoolUtils.AssetType);

    function isRegistered(address pool_) external view returns (bool);

    function hasCoinDirectly(address pool_, address coin_) external view returns (bool);

    function hasCoinAnywhere(address pool_, address coin_) external view returns (bool);

    function basePool(address pool_) external view returns (address);

    function coinIndex(address pool_, address coin_) external view returns (int128);

    function nCoins(address pool_) external view returns (uint256);

    function coinIndices(
        address pool_,
        address from_,
        address to_
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );

    function decimals(address pool_) external view returns (uint256[] memory);

    function interfaceVersion(address pool_) external view returns (uint256);

    function poolFromLpToken(address lpToken_) external view returns (address);

    function coins(address pool_) external view returns (address[] memory);

    function getPid(address _pool) external view returns (uint256);

    function getRewardPool(address _pool) external view returns (address);

    function isShutdownPid(uint256 pid_) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ICurveMetaRegistry {
    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);
    event NewAdmin(address indexed admin);

    function add_registry_handler(address _registry_handler) external;

    function update_registry_handler(uint256 _index, address _registry_handler)
        external;

    function get_registry_handlers_from_pool(address _pool)
        external
        view
        returns (address[10] memory);

    function get_base_registry(address registry_handler)
        external
        view
        returns (address);

    function find_pool_for_coins(address _from, address _to)
        external
        view
        returns (address);

    function find_pool_for_coins(
        address _from,
        address _to,
        uint256 i
    ) external view returns (address);

    function find_pools_for_coins(address _from, address _to)
        external
        view
        returns (address[] memory);

    function get_admin_balances(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_admin_balances(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256[8] memory);

    function get_balances(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_balances(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256[8] memory);

    function get_base_pool(address _pool) external view returns (address);

    function get_base_pool(address _pool, uint256 _handler_id)
        external
        view
        returns (address);

    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );

    function get_coin_indices(
        address _pool,
        address _from,
        address _to,
        uint256 _handler_id
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_coins(address _pool, uint256 _handler_id)
        external
        view
        returns (address[8] memory);

    function get_decimals(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_decimals(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256[8] memory);

    function get_fees(address _pool) external view returns (uint256[10] memory);

    function get_fees(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256[10] memory);

    function get_gauge(address _pool) external view returns (address);

    function get_gauge(address _pool, uint256 gauge_idx)
        external
        view
        returns (address);

    function get_gauge(
        address _pool,
        uint256 gauge_idx,
        uint256 _handler_id
    ) external view returns (address);

    function get_gauge_type(address _pool) external view returns (int128);

    function get_gauge_type(address _pool, uint256 gauge_idx)
        external
        view
        returns (int128);

    function get_gauge_type(
        address _pool,
        uint256 gauge_idx,
        uint256 _handler_id
    ) external view returns (int128);

    function get_lp_token(address _pool) external view returns (address);

    function get_lp_token(address _pool, uint256 _handler_id)
        external
        view
        returns (address);

    function get_n_coins(address _pool) external view returns (uint256);

    function get_n_coins(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256);

    function get_n_underlying_coins(address _pool)
        external
        view
        returns (uint256);

    function get_n_underlying_coins(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256);

    function get_pool_asset_type(address _pool) external view returns (uint256);

    function get_pool_asset_type(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256);

    function get_pool_from_lp_token(address _token)
        external
        view
        returns (address);

    function get_pool_from_lp_token(address _token, uint256 _handler_id)
        external
        view
        returns (address);

    function get_pool_params(address _pool)
        external
        view
        returns (uint256[20] memory);

    function get_pool_params(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256[20] memory);

    function get_pool_name(address _pool) external view returns (string memory);

    function get_pool_name(address _pool, uint256 _handler_id)
        external
        view
        returns (string memory);

    function get_underlying_balances(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_underlying_balances(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256[8] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);

    function get_underlying_coins(address _pool, uint256 _handler_id)
        external
        view
        returns (address[8] memory);

    function get_underlying_decimals(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_underlying_decimals(address _pool, uint256 _handler_id)
        external
        view
        returns (uint256[8] memory);

    function get_virtual_price_from_lp_token(address _token)
        external
        view
        returns (uint256);

    function get_virtual_price_from_lp_token(
        address _token,
        uint256 _handler_id
    ) external view returns (uint256);

    function is_meta(address _pool) external view returns (bool);

    function is_meta(address _pool, uint256 _handler_id)
        external
        view
        returns (bool);

    function is_registered(address _pool) external view returns (bool);

    function is_registered(address _pool, uint256 _handler_id)
        external
        view
        returns (bool);

    function pool_count() external view returns (uint256);

    function pool_list(uint256 _index) external view returns (address);

    function address_provider() external view returns (address);

    function owner() external view returns (address);

    function get_registry(uint256 arg0) external view returns (address);

    function registry_length() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ICurvePoolV1 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[8] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[7] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount)
        external;

    function lp_token() external view returns (address);

    function A_PRECISION() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ICurvePoolV2 {
    function token() external view returns (address);

    function coins(uint256 i) external view returns (address);

    function factory() external view returns (address);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity(
        uint256 _amount,
        uint256[2] memory min_amounts,
        bool use_eth,
        address receiver
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external;

    function remove_liquidity(
        uint256 _amount,
        uint256[3] memory min_amounts,
        bool use_eth,
        address receiver
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[] memory amounts)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i)
        external
        view
        returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

library ScaledMath {
    uint256 internal constant DECIMALS = 18;
    uint256 internal constant ONE = 10**DECIMALS;

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulDown(
        uint256 a,
        uint256 b,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (a * b) / (10**decimals);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function divDown(
        uint256 a,
        uint256 b,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (a * 10**decimals) / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        return ((a * ONE) - 1) / b + 1;
    }

    function mulDown(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / int256(ONE);
    }

    function mulDownUint128(uint128 a, uint128 b) internal pure returns (uint128) {
        return (a * b) / uint128(ONE);
    }

    function mulDown(
        int256 a,
        int256 b,
        uint256 decimals
    ) internal pure returns (int256) {
        return (a * b) / int256(10**decimals);
    }

    function divDown(int256 a, int256 b) internal pure returns (int256) {
        return (a * int256(ONE)) / b;
    }

    function divDownUint128(uint128 a, uint128 b) internal pure returns (uint128) {
        return (a * uint128(ONE)) / b;
    }

    function divDown(
        int256 a,
        int256 b,
        uint256 decimals
    ) internal pure returns (int256) {
        return (a * int256(10**decimals)) / b;
    }

    function convertScale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) return a;
        if (fromDecimals > toDecimals) return downscale(a, fromDecimals, toDecimals);
        return upscale(a, fromDecimals, toDecimals);
    }

    function convertScale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        if (fromDecimals == toDecimals) return a;
        if (fromDecimals > toDecimals) return downscale(a, fromDecimals, toDecimals);
        return upscale(a, fromDecimals, toDecimals);
    }

    function upscale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        return a * (10**(toDecimals - fromDecimals));
    }

    function downscale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        return a / (10**(fromDecimals - toDecimals));
    }

    function upscale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        return a * int256(10**(toDecimals - fromDecimals));
    }

    function downscale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        return a / int256(10**(fromDecimals - toDecimals));
    }

    function intPow(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 result = ONE;
        for (uint256 i; i < n; ) {
            result = mulDown(result, a);
            unchecked {
                ++i;
            }
        }
        return result;
    }

    function absSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a >= b ? a - b : b - a;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IBooster {
    function poolInfo(uint256 pid)
        external
        view
        returns (
            address lpToken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function poolLength() external view returns (uint256);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function isShutdown() external view returns (bool);
}