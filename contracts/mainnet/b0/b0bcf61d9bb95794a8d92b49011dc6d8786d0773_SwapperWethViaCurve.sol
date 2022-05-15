// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


import "../interfaces/swappers/ISwapper.sol";
import "./AbstractSwapper.sol";
import "./helpers/CurveHelper.sol";
import "../interfaces/curve/ICurvePoolMeta.sol";
import "../interfaces/curve/ICurvePoolCrypto.sol";
import "../helpers/SafeMath.sol";
import "../helpers/IUniswapV2PairFull.sol";
import '../helpers/TransferHelper.sol';
import "../helpers/ReentrancyGuard.sol";
import "../Auth2.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev swap usdp/weth
 */
contract SwapperWethViaCurve is AbstractSwapper {
    using SafeMath for uint;
    using CurveHelper for ICurvePoolMeta;
    using CurveHelper for ICurvePoolCrypto;
    using TransferHelper for address;

    IERC20 public immutable WETH;
    IERC20 public immutable USDT;

    ICurvePoolMeta public immutable USDP_3CRV_POOL;
    int128 public immutable USDP_3CRV_POOL_USDP;
    int128 public immutable USDP_3CRV_POOL_USDT;

    ICurvePoolCrypto public immutable TRICRYPTO2_POOL;
    uint256 public immutable TRICRYPTO2_USDT;
    uint256 public immutable TRICRYPTO2_WETH;


    constructor(
        address _vaultParameters, address _weth,  address _usdp, address _usdt,
        address _usdp3crvPool, address _tricrypto2Pool
    ) AbstractSwapper(_vaultParameters, _usdp) {
        require(
            _weth != address(0)
            && _usdt != address(0)
            && _usdp3crvPool != address(0)
            && _tricrypto2Pool != address(0)
            , "Unit Protocol Swappers: ZERO_ADDRESS"
        );

        WETH = IERC20(_weth);
        USDT = IERC20(_usdt);

        USDP_3CRV_POOL = ICurvePoolMeta(_usdp3crvPool);
        USDP_3CRV_POOL_USDP = ICurvePoolMeta(_usdp3crvPool).getCoinIndexInMetaPool(_usdp);
        USDP_3CRV_POOL_USDT = ICurvePoolMeta(_usdp3crvPool).getCoinIndexInMetaPool(_usdt);

        TRICRYPTO2_POOL = ICurvePoolCrypto(_tricrypto2Pool);
        TRICRYPTO2_USDT = uint(ICurvePoolCrypto(_tricrypto2Pool).getCoinIndexInPool(_usdt));
        TRICRYPTO2_WETH = uint(ICurvePoolCrypto(_tricrypto2Pool).getCoinIndexInPool(_weth));

        // for usdp to weth
        _usdp.safeApprove(_usdp3crvPool, type(uint256).max);
        _usdt.safeApprove(_tricrypto2Pool, type(uint256).max);

        // for weth to usdp
        _weth.safeApprove(_tricrypto2Pool, type(uint256).max);
        _usdt.safeApprove(_usdp3crvPool, type(uint256).max);
    }

    function predictAssetOut(address _asset, uint256 _usdpAmountIn) external view override returns (uint predictedAssetAmount) {
        require(_asset == address(WETH), "Unit Protocol Swappers: UNSUPPORTED_ASSET");

        // USDP -> USDT
        uint usdtAmount = USDP_3CRV_POOL.get_dy_underlying(USDP_3CRV_POOL_USDP, USDP_3CRV_POOL_USDT, _usdpAmountIn);

        // USDT -> WETH
        predictedAssetAmount = TRICRYPTO2_POOL.get_dy(TRICRYPTO2_USDT, TRICRYPTO2_WETH, usdtAmount);
    }

    /**
     * @dev calculates with some small (~0.005%) error bcs of approximate calculations of fee in get_dy_underlying
     */
    function predictUsdpOut(address _asset, uint256 _assetAmountIn) external view override returns (uint predictedUsdpAmount) {
        require(_asset == address(WETH), "Unit Protocol Swappers: UNSUPPORTED_ASSET");

        // WETH -> USDT
        uint usdtAmount = TRICRYPTO2_POOL.get_dy(TRICRYPTO2_WETH, TRICRYPTO2_USDT, _assetAmountIn);

        // USDT -> USDP
        predictedUsdpAmount = USDP_3CRV_POOL.get_dy_underlying(USDP_3CRV_POOL_USDT, USDP_3CRV_POOL_USDP, usdtAmount);
    }

    function _swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 /** _minAssetAmount */)
        internal override returns (uint swappedAssetAmount)
    {
        require(_asset == address(WETH), "Unit Protocol Swappers: UNSUPPORTED_ASSET");

        // USDP -> USDT
        uint usdtAmount = USDP_3CRV_POOL.exchange_underlying(USDP_3CRV_POOL_USDP, USDP_3CRV_POOL_USDT, _usdpAmount, 0);

        // USDT -> WETH
        TRICRYPTO2_POOL.exchange(TRICRYPTO2_USDT, TRICRYPTO2_WETH, usdtAmount, 0);
        swappedAssetAmount = WETH.balanceOf(address(this));

        // WETH -> user
        address(WETH).safeTransfer(_user, swappedAssetAmount);
    }

    function _swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 /** _minUsdpAmount */)
        internal override returns (uint swappedUsdpAmount)
    {
        require(_asset == address(WETH), "Unit Protocol Swappers: UNSUPPORTED_ASSET");

        // WETH -> USDT
        TRICRYPTO2_POOL.exchange(TRICRYPTO2_WETH, TRICRYPTO2_USDT, _assetAmount, 0);
        uint usdtAmount = USDT.balanceOf(address(this));

        // USDT -> USDP
        swappedUsdpAmount = USDP_3CRV_POOL.exchange_underlying(USDP_3CRV_POOL_USDT, USDP_3CRV_POOL_USDP, usdtAmount, 0);

        // USDP -> user
        address(USDP).safeTransfer(_user, swappedUsdpAmount);
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


interface ISwapper {

    /**
     * @notice Predict asset amount after usdp swap
     */
    function predictAssetOut(address _asset, uint256 _usdpAmountIn) external view returns (uint predictedAssetAmount);

    /**
     * @notice Predict USDP amount after asset swap
     */
    function predictUsdpOut(address _asset, uint256 _assetAmountIn) external view returns (uint predictedUsdpAmount);

    /**
     * @notice usdp must be approved to swapper
     * @dev asset must be sent to user after swap
     */
    function swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount) external returns (uint swappedAssetAmount);

    /**
     * @notice asset must be approved to swapper
     * @dev usdp must be sent to user after swap
     */
    function swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount) external returns (uint swappedUsdpAmount);

    /**
     * @notice DO NOT SEND tokens to contract manually. For usage in contracts only.
     * @dev for gas saving with usage in contracts tokens must be send directly to contract instead
     * @dev asset must be sent to user after swap
     */
    function swapUsdpToAssetWithDirectSending(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount) external returns (uint swappedAssetAmount);

    /**
     * @notice DO NOT SEND tokens to contract manually. For usage in contracts only.
     * @dev for gas saving with usage in contracts tokens must be send directly to contract instead
     * @dev usdp must be sent to user after swap
     */
    function swapAssetToUsdpWithDirectSending(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount) external returns (uint swappedUsdpAmount);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


import "../interfaces/swappers/ISwapper.sol";
import "../helpers/ReentrancyGuard.sol";
import '../helpers/TransferHelper.sol';
import "../helpers/SafeMath.sol";
import "../Auth2.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev base class for swappers, makes common checks
 * @dev internal _swapUsdpToAsset and _swapAssetToUsdp must be overridden instead of external swapUsdpToAsset and swapAssetToUsdp
 */
abstract contract AbstractSwapper is ISwapper, ReentrancyGuard, Auth2 {
    using TransferHelper for address;
    using SafeMath for uint;

    IERC20 public immutable USDP;

    constructor(address _vaultParameters, address _usdp) Auth2(_vaultParameters) {
        require(_usdp != address(0), "Unit Protocol Swappers: ZERO_ADDRESS");

        USDP = IERC20(_usdp);
    }

    /**
     * @dev usdp already transferred to swapper
     */
    function _swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount)
        internal virtual returns (uint swappedAssetAmount);

    /**
     * @dev asset already transferred to swapper
     */
    function _swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount)
        internal virtual returns (uint swappedUsdpAmount);

    function swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount)
        external override returns (uint swappedAssetAmount) // nonReentrant in swapUsdpToAssetWithDirectSending
    {
        // get USDP from user
        address(USDP).safeTransferFrom(_user, address(this), _usdpAmount);

        return swapUsdpToAssetWithDirectSending(_user, _asset, _usdpAmount, _minAssetAmount);
    }

    function swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount)
        external override returns (uint swappedUsdpAmount) // nonReentrant in swapAssetToUsdpWithDirectSending
    {
        // get asset from user
        _asset.safeTransferFrom(_user, address(this), _assetAmount);

        return swapAssetToUsdpWithDirectSending(_user, _asset, _assetAmount, _minUsdpAmount);
    }

    function swapUsdpToAssetWithDirectSending(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount)
        public override nonReentrant returns (uint swappedAssetAmount)
    {
        require(msg.sender == _user || vaultParameters.canModifyVault(msg.sender), "Unit Protocol Swappers: AUTH_FAILED");

        swappedAssetAmount = _swapUsdpToAsset(_user, _asset, _usdpAmount, _minAssetAmount);

        require(swappedAssetAmount >= _minAssetAmount, "Unit Protocol Swapper: SWAPPED_AMOUNT_LESS_THAN_EXPECTED_MINIMUM");
    }

    function swapAssetToUsdpWithDirectSending(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount)
        public override nonReentrant returns (uint swappedUsdpAmount)
    {
        require(msg.sender == _user || vaultParameters.canModifyVault(msg.sender), "Unit Protocol Swappers: AUTH_FAILED");

        swappedUsdpAmount = _swapAssetToUsdp(_user, _asset, _assetAmount, _minUsdpAmount);

        require(swappedUsdpAmount >= _minUsdpAmount, "Unit Protocol Swappers: SWAPPED_AMOUNT_LESS_THAN_EXPECTED_MINIMUM");
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "../../interfaces/ICurvePool.sol";
import "../../interfaces/curve/ICurvePoolMeta.sol";

library CurveHelper {

    int128 public constant MAX_COINS = 30;

    function getCoinIndexInMetaPool(ICurvePoolMeta _pool, address _coin) internal view returns (int128) {
        int128 basePoolIndex = 0;
        for (int128 i=0; i < MAX_COINS; i++) {
            address coin = tryGetCoin(_pool, i);
            if (coin == address(0)) {
                basePoolIndex = i - 1;
                break;
            } else if (_coin == coin) {
                return i;
            }
        }
        require(basePoolIndex > 0, "Unit Protocol Swappers: BROKEN_POOL"); // expected that base pool is the last

        int128 coinIndexInBasePool = getCoinIndexInPool(ICurvePool(_pool.base_pool()), _coin);
        require(coinIndexInBasePool >= 0, "Unit Protocol Swappers: BROKEN_POOL");

        int128 coinIndex = coinIndexInBasePool + basePoolIndex;
        require(coinIndex >= coinIndexInBasePool, "Unit Protocol Swappers: BROKEN_POOL"); // assert from safe math since here we use int128

        return coinIndex;
    }

    function getCoinIndexInPool(ICurvePool _pool, address _coin) internal view returns (int128) {
        for (int128 i=0; i < MAX_COINS; i++) {
            address coin = tryGetCoin(_pool, i);
            if (coin == address(0)) {
                break;
            } else if (_coin == coin) {
                return i;
            }
        }

        revert("Unit Protocol Swappers: COIN_NOT_FOUND_IN_POOL");
    }

    function tryGetCoin(ICurvePool _pool, int128 i) private view returns (address) {
        (bool success,  bytes memory data) = address(_pool).staticcall{gas:20000}(abi.encodeWithSignature("coins(uint256)", uint(i)));
        if (!success || data.length != 32) {
            return address(0);
        }

        return bytesToAddress(data);
    }

    function bytesToAddress(bytes memory _bytes) private pure returns (address addr) {
        assembly {
          addr := mload(add(_bytes, 32))
        }
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

import "./ICurvePoolBase.sol";

interface ICurvePoolMeta is ICurvePoolBase {

    function base_pool() external view returns (address);

    /**
     * @dev variant of token/3crv pool
     * @param i Index value for the underlying coin to send
     * @param j Index value of the underlying coin to recieve
     * @param _dx Amount of `i` being exchanged
     * @param _min_dy Minimum amount of `j` to receive
     * @return Actual amount of `j` received
     */
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);

    function get_dy_underlying(int128 i, int128 j, uint256 _dx) external view returns (uint256);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

import "../ICurvePool.sol";

interface ICurvePoolCrypto is ICurvePool {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

interface IUniswapV2PairFull {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "./VaultParameters.sol";


/**
 * @title Auth2
 * @dev Manages USDP's system access
 * @dev copy of Auth from VaultParameters.sol but with immutable vaultParameters for saving gas
 **/
contract Auth2 {

    // address of the the contract with vault parameters
    VaultParameters public immutable vaultParameters;

    constructor(address _parameters) {
        require(_parameters != address(0), "Unit Protocol: ZERO_ADDRESS");

        vaultParameters = VaultParameters(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is able to modify the Vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is the Vault
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: AUTH_FAILED");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;



/**
 * @title Auth
 * @dev Manages USDP's system access
 **/
contract Auth {

    // address of the the contract with vault parameters
    VaultParameters public vaultParameters;

    constructor(address _parameters) {
        vaultParameters = VaultParameters(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is able to modify the Vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is the Vault
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: AUTH_FAILED");
        _;
    }
}



/**
 * @title VaultParameters
 **/
contract VaultParameters is Auth {

    // map token to stability fee percentage; 3 decimals
    mapping(address => uint) public stabilityFee;

    // map token to liquidation fee percentage, 0 decimals
    mapping(address => uint) public liquidationFee;

    // map token to USDP mint limit
    mapping(address => uint) public tokenDebtLimit;

    // permissions to modify the Vault
    mapping(address => bool) public canModifyVault;

    // managers
    mapping(address => bool) public isManager;

    // enabled oracle types
    mapping(uint => mapping (address => bool)) public isOracleTypeEnabled;

    // address of the Vault
    address payable public vault;

    // The foundation address
    address public foundation;

    /**
     * The address for an Ethereum contract is deterministically computed from the address of its creator (sender)
     * and how many transactions the creator has sent (nonce). The sender and nonce are RLP encoded and then
     * hashed with Keccak-256.
     * Therefore, the Vault address can be pre-computed and passed as an argument before deployment.
    **/
    constructor(address payable _vault, address _foundation) Auth(address(this)) {
        require(_vault != address(0), "Unit Protocol: ZERO_ADDRESS");
        require(_foundation != address(0), "Unit Protocol: ZERO_ADDRESS");

        isManager[msg.sender] = true;
        vault = _vault;
        foundation = _foundation;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Grants and revokes manager's status of any address
     * @param who The target address
     * @param permit The permission flag
     **/
    function setManager(address who, bool permit) external onlyManager {
        isManager[who] = permit;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the foundation address
     * @param newFoundation The new foundation address
     **/
    function setFoundation(address newFoundation) external onlyManager {
        require(newFoundation != address(0), "Unit Protocol: ZERO_ADDRESS");
        foundation = newFoundation;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets ability to use token as the main collateral
     * @param asset The address of the main collateral token
     * @param stabilityFeeValue The percentage of the year stability fee (3 decimals)
     * @param liquidationFeeValue The liquidation fee percentage (0 decimals)
     * @param usdpLimit The USDP token issue limit
     * @param oracles The enables oracle types
     **/
    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint usdpLimit,
        uint[] calldata oracles
    ) external onlyManager {
        setStabilityFee(asset, stabilityFeeValue);
        setLiquidationFee(asset, liquidationFeeValue);
        setTokenDebtLimit(asset, usdpLimit);
        for (uint i=0; i < oracles.length; i++) {
            setOracleType(oracles[i], asset, true);
        }
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets a permission for an address to modify the Vault
     * @param who The target address
     * @param permit The permission flag
     **/
    function setVaultAccess(address who, bool permit) external onlyManager {
        canModifyVault[who] = permit;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage of the year stability fee for a particular collateral
     * @param asset The address of the main collateral token
     * @param newValue The stability fee percentage (3 decimals)
     **/
    function setStabilityFee(address asset, uint newValue) public onlyManager {
        stabilityFee[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage of the liquidation fee for a particular collateral
     * @param asset The address of the main collateral token
     * @param newValue The liquidation fee percentage (0 decimals)
     **/
    function setLiquidationFee(address asset, uint newValue) public onlyManager {
        require(newValue <= 100, "Unit Protocol: VALUE_OUT_OF_RANGE");
        liquidationFee[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Enables/disables oracle types
     * @param _type The type of the oracle
     * @param asset The address of the main collateral token
     * @param enabled The control flag
     **/
    function setOracleType(uint _type, address asset, bool enabled) public onlyManager {
        isOracleTypeEnabled[_type][asset] = enabled;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets USDP limit for a specific collateral
     * @param asset The address of the main collateral token
     * @param limit The limit number
     **/
    function setTokenDebtLimit(address asset, uint limit) public onlyManager {
        tokenDebtLimit[asset] = limit;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface ICurvePool {
    function get_virtual_price() external view returns (uint);
    function coins(uint) external view returns (address);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

import "../ICurvePool.sol";

interface ICurvePoolBase is ICurvePool {
    /**
     * @notice Perform an exchange between two coins
     * @dev Index values can be found via the `coins` public getter method
     * @param i Index value for the coin to send
     * @param j Index valie of the coin to recieve
     * @param _dx Amount of `i` being exchanged
     * @param _min_dy Minimum amount of `j` to receive
     * @return Actual amount of `j` received
     */
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);

    function get_dy(int128 i, int128 j, uint256 _dx) external view returns (uint256);
}