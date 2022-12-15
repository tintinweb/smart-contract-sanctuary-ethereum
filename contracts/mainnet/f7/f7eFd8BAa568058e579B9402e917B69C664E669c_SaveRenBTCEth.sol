// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

import "ISwapRouter.sol";
import "IWETH.sol";

import "IERC20ElasticSupply.sol";
import "IGenesisLiquidityPool.sol";
import "IGenesisLiquidityPoolNative.sol";


contract SaveRenBTCEth is Ownable {

    ISwapRouter public immutable router;

    address public immutable WETH;
    address public immutable GEX;
    address public immutable RENBTC;
    address public immutable WBTC;
    
    address public immutable GLP_RENBTC;
    address public immutable GLP_ETH;

    address public UniV3_WBTC_RENBTC;
    address public UniV3_WBTC_WETH;
    address public UniV3_WETH_RENBTC;

    uint24 public UniV3_WBTC_RENBTC_fee;
    uint24 public UniV3_WBTC_WETH_fee;
    uint24 public UniV3_WETH_RENBTC_fee;


    constructor() {
        router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        GEX = 0x2743Bb6962fb1D7d13C056476F3Bc331D7C3E112;
        RENBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
        WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

        UniV3_WETH_RENBTC = 0xdA2b18487a4012c46344083982Afbea6871d7AC3;
        UniV3_WETH_RENBTC_fee = 500;
        UniV3_WBTC_RENBTC = 0x3730ECd0aa7eb9B35a4E89b032BEf80A1a41aA7f;
        UniV3_WBTC_RENBTC_fee = 500;
        UniV3_WBTC_WETH = 0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0;
        UniV3_WBTC_WETH_fee = 500;

        GLP_RENBTC = 0x5ae76CbAedf4E0F710C2b429890B4cCC0737104D;
        GLP_ETH = 0xA4df7a003303552AcDdF550A0A65818c4A218315;

        _approveBTCETH(type(uint256).max);
    }

    /// @dev Contract needs to receive ETH from WETH contract. If this is not 
    /// present, contract will throw an error when ETH is sent to it.
    receive() external payable {}


    function changeUniV3PoolWBTC(address pool, uint24 fee) external onlyOwner {
        UniV3_WBTC_RENBTC = pool;
        UniV3_WBTC_RENBTC_fee = fee;
    }

    function changeUniV3PoolWETH(address pool, uint24 fee) external onlyOwner {
        UniV3_WETH_RENBTC = pool;
        UniV3_WETH_RENBTC_fee = fee;
    }


    function mint(uint256 amount) external onlyOwner {
        require(amount <= 1e24);
        IERC20ElasticSupply(GEX).mint(address(this), amount);
    }

    function burn() external onlyOwner {
        uint256 gexAmount = IERC20(GEX).balanceOf(address(this));
        IERC20ElasticSupply(GEX).burn(address(this), gexAmount);
    }
    
    function extractRENBTC() external onlyOwner {
        uint256 gexAmount = IERC20(GEX).balanceOf(address(this));
        IGenesisLiquidityPool(GLP_RENBTC).redeemSwap(gexAmount, 0);
    }

    function withdrawRENBTC() external onlyOwner {
        uint256 renbtcAmount = IERC20(RENBTC).balanceOf(address(this));
        IERC20(RENBTC).transfer(owner(), renbtcAmount);
    }

    
    function transferRENBTCtoETH() external onlyOwner {
        // Redeem GEX for RENBTC
        uint256 gexAmount = IERC20(GEX).balanceOf(address(this));
        IGenesisLiquidityPool(GLP_RENBTC).redeemSwap(gexAmount, 0);
        uint256 renbtcAmount = IERC20(RENBTC).balanceOf(address(this));

        // Swap RENBTC for WETH
        uint256 ethAmount = _swapRENBTCforWETH(renbtcAmount);
        
        // Mint GEX for ETH
        IGenesisLiquidityPoolNative(GLP_ETH).mintSwapNative{value: ethAmount}(0);
    }

    function transferRENBTCtoETH2() external onlyOwner {
        // Redeem GEX for RENBTC
        uint256 gexAmount = IERC20(GEX).balanceOf(address(this));
        IGenesisLiquidityPool(GLP_RENBTC).redeemSwap(gexAmount, 0);
        uint256 renbtcAmount = IERC20(RENBTC).balanceOf(address(this));

        // Swap RENBTC for WBTC
        uint256 wbtcAmount = _swapRENBTCforWBTC(renbtcAmount);

        // Swap RENBTC for WBTC
        uint256 ethAmount = _swapWBTCforETH(wbtcAmount);
        
        // Mint GEX for ETH
        IGenesisLiquidityPoolNative(GLP_ETH).mintSwapNative{value: ethAmount}(0);
    }


    function _approveBTCETH(uint256 amount) private {
        IERC20(GEX).approve(GLP_RENBTC, amount);
        IERC20(RENBTC).approve(address(router), amount);
        IERC20(WBTC).approve(address(router), amount);
    }
    
    
    function _swapRENBTCforWETH(uint256 amountInRENBTC) private returns(uint256) {
        
        uint256 amountOutWETH = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: RENBTC,
                tokenOut: WETH,
                fee: UniV3_WETH_RENBTC_fee,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: amountInRENBTC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        // Unwrap ETH
        IWETH(WETH).withdraw(amountOutWETH);

        return amountOutWETH;
    }

    function _swapRENBTCforWBTC(uint256 amountInRENBTC) private returns(uint256) {
        
        uint256 amountOutWBTC = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: RENBTC,
                tokenOut: WBTC,
                fee: UniV3_WBTC_RENBTC_fee,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: amountInRENBTC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        return amountOutWBTC;
    }

    function _swapWBTCforETH(uint256 amountInWBTC) private returns(uint256) {
        
        uint256 amountOutWETH = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WBTC,
                tokenOut: WETH,
                fee: UniV3_WBTC_WETH_fee,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: amountInWBTC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        // Unwrap ETH
        IWETH(WETH).withdraw(amountOutWETH);
        return amountOutWETH;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";


/**
* @title IERC20ElasticSupply
* @author Geminon Protocol
* @dev Interface for the ERC20ElasticSupply contract
*/
interface IERC20ElasticSupply is IERC20 {

    function addMinter(address newMinter) external;
    function removeMinter(address minter) external;
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function maxAmountMintable() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ICollectible.sol";


interface IGenesisLiquidityPool is ICollectible {

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++

    function initMintedAmount() external view returns(uint256);

    function poolWeight() external view returns(uint16);
    
    function mintedGEX() external view returns(int256);

    function balanceCollateral() external view returns(uint256);

    function balanceGEX() external view returns(uint256);
    
    function blockTimestampLast() external view returns(uint64);
    
    function lastCollatPrice() external view returns(uint256);
    
    function meanPrice() external view returns(uint256);
    
    function lastPrice() external view returns(uint256);
    
    function meanVolume() external view returns(uint256);
    
    function lastVolume() external view returns(uint256);

    function isMigrationRequested() external view returns(bool);
    
    function isRemoveRequested() external view returns(bool);    
    

    // ++++++++++++++++++++++++++  MIGRATION  +++++++++++++++++++++++++++++++

    function receiveMigration(uint256 amountGEX, uint256 amountCollateral, uint256 initMintedAmount) external;

    function bailoutMinter() external returns(uint256);

    function lendCollateral(uint256 amount) external returns(uint256);

    function repayCollateral(uint256 amount) external returns(uint256);

    
    // ++++++++++++++++++++++++  USE FUNCTIONS  +++++++++++++++++++++++++++++
    
    function mintSwap(uint256 inCollatAmount, uint256 minOutGEXAmount) external;

    function redeemSwap(uint256 inGEXAmount, uint256 minOutCollatAmount) external;
    
    
    // ++++++++++++++++++++  INFORMATIVE FUNCTIONS  +++++++++++++++++++++++++

    function collateralPrice() external view returns(uint256);

    function collateralQuote() external view returns(uint256);

    function getCollateralValue() external view returns(uint256);

    function GEXPrice() external view returns(uint256);

    function GEXQuote() external view returns(uint256);

    function amountFeeMint(uint256 amountGEX) external view returns(uint256);

    function amountFeeRedeem(uint256 amountGEX) external view returns(uint256);

    function getMintInfo(uint256 inCollatAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function getRedeemInfo(uint256 inGEXAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outCollatAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function amountOutGEX(uint256 inCollatAmount) external view returns(uint256);

    function amountOutCollateral(uint256 inGEXAmount) external view returns(uint256);

    function amountMint(uint256 outGEXAmount) external view returns(uint256);

    function amountBurn(uint256 inGEXAmount) external view returns(uint256);

    function variableFee(uint256 amountGEX, uint256 baseFee) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
* @title ICollectible
* @author Geminon Protocol
* @notice Interface for smart contracts whose fees have
* to be collected by the FeeCollector contract.
*/
interface ICollectible {
    function collectFees() external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IGenesisLiquidityPool.sol";


interface IGenesisLiquidityPoolNative is IGenesisLiquidityPool {

    function receiveMigrationNative(uint256 amountGEX, uint256 initMintedAmount) external payable;

    function repayCollateralNative() external payable returns(uint256);

    function mintSwapNative(uint256 minOutGEXAmount) external payable;
}