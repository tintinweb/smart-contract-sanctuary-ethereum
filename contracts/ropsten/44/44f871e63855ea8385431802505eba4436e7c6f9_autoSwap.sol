/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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

// File: contracts/autoSwap.sol

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

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

contract autoSwap is Ownable {
    address public PROFIT;
    address public WETH;
    address public WMATIC;
    address public USDT;
    // TODO: Need to create struct for weth, wmatic, usdt. With respective fees
    ISwapRouter public dexRouter;
    IUniswapV3Factory public v3Factory;
    constructor (
        address _PROFIT,
        address _WETH,
        address _WMATIC,
        address _USDT,
        ISwapRouter _dexRouter,
        IUniswapV3Factory _v3Factory
    ) {
        PROFIT = _PROFIT;
        WETH = _WETH;
        WMATIC = _WMATIC;
        USDT = _USDT;
        dexRouter = _dexRouter;
        v3Factory = _v3Factory;
    }
    
    struct TokenInfo {
        address tokenToSwap;
    }

    // An array of tokens that are available to be swapped to PROFIT.
    TokenInfo[] public tokenInfo;

    function addedTokens() external view returns (uint256) {
        return tokenInfo.length;
    }

    // Add a new tokenToSwap for the new pool. Can only be called by the owner.
    function addToken(address _tokenToSwap) public onlyOwner {
        tokenInfo.push(TokenInfo({tokenToSwap: _tokenToSwap}));
    }
    function swapTokens() public {
        for (uint8 i = 0; i < tokenInfo.length; i++) {
            TokenInfo storage token = tokenInfo[i];
            uint256 tokenBal = IERC20(token.tokenToSwap).balanceOf(address(this));

            // If TOKEN is Paired with WETH
            if (v3Factory.getPool(token.tokenToSwap, WETH, 3000) != address(0) && tokenBal > 0) {
                // Swap TOKEN to WETH
                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                    tokenIn: token.tokenToSwap,
                    tokenOut: WETH,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp + 60 * 20,
                    amountIn: tokenBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                // approve dexRouter to spend tokens
                if (IERC20(token.tokenToSwap).allowance(address(this), address(dexRouter)) < tokenBal) {
                    IERC20(token.tokenToSwap).approve(address(dexRouter), type(uint256).max);
                }
                dexRouter.exactInputSingle(params);
                // Swap WETH to PROFIT
                uint256 wethBal = IERC20(WETH).balanceOf(address(this));
                ISwapRouter.ExactInputSingleParams memory params2 = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH,
                    tokenOut: PROFIT,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp + 60 * 20,
                    amountIn: wethBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
                // approve dexRouter to spend WETH
                if (IERC20(WETH).allowance(address(this), address(dexRouter)) < wethBal) {
                    IERC20(WETH).approve(address(dexRouter), type(uint256).max);
                }
                dexRouter.exactInputSingle(params2);
            }

            // If TOKEN is Paired with WMATIC
            if (v3Factory.getPool(token.tokenToSwap, WMATIC, 3000) != address(0) && tokenBal > 0) {
                // Swap TOKEN to WMATIC
                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                    tokenIn: token.tokenToSwap,
                    tokenOut: WMATIC,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp + 60 * 20,
                    amountIn: tokenBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
                // approve dexRouter to spend TOKEN
                if (IERC20(token.tokenToSwap).allowance(address(this), address(dexRouter)) < tokenBal) {
                    IERC20(token.tokenToSwap).approve(address(dexRouter), type(uint256).max);
                }
                dexRouter.exactInputSingle(params);
                // Swap WMATIC to WETH
                uint256 wMaticBal = IERC20(WMATIC).balanceOf(address(this));
                ISwapRouter.ExactInputSingleParams memory params2 = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WMATIC,
                    tokenOut: WETH,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp + 60 * 20,
                    amountIn: wMaticBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
                // approve dexRouter to spend WMATIC
                if (IERC20(WMATIC).allowance(address(this), address(dexRouter)) < wMaticBal) {
                    IERC20(WMATIC).approve(address(dexRouter), type(uint256).max);
                }
                dexRouter.exactInputSingle(params2);
                // Swap WETH to PROFIT
                uint256 wethBal = IERC20(WETH).balanceOf(address(this));
                ISwapRouter.ExactInputSingleParams memory params3 = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH,
                    tokenOut: PROFIT,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp + 60 * 20,
                    amountIn: wethBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
                // approve dexRouter to spend WETH
                if (IERC20(WETH).allowance(address(this), address(dexRouter)) < wethBal) {
                    IERC20(WETH).approve(address(dexRouter), type(uint256).max);
                }
                dexRouter.exactInputSingle(params3);
            }

            // If TOKEN is Paired with USDT
            if (v3Factory.getPool(token.tokenToSwap, USDT, 3000) != address(0) && tokenBal > 0) {
                // Swap TOKEN to USDT
                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                    tokenIn: token.tokenToSwap,
                    tokenOut: USDT,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp + 60 * 20,
                    amountIn: tokenBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
                // approve dexRouter to spend TOKEN
                if (IERC20(token.tokenToSwap).allowance(address(this), address(dexRouter)) < tokenBal) {
                    IERC20(token.tokenToSwap).approve(address(dexRouter), type(uint256).max);
                }
                dexRouter.exactInputSingle(params);
                // Swap USDT to WETH
                uint256 usdtBal = IERC20(USDT).balanceOf(address(this));
                ISwapRouter.ExactInputSingleParams memory params2 = ISwapRouter.ExactInputSingleParams({
                    tokenIn: USDT,
                    tokenOut: WETH,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp + 60 * 20,
                    amountIn: usdtBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
                // approve dexRouter to spend USDT
                if (IERC20(USDT).allowance(address(this), address(dexRouter)) < tokenBal) {
                    IERC20(USDT).approve(address(dexRouter), type(uint256).max);
                }
                dexRouter.exactInputSingle(params2);
                // Swap WETH to PROFIT
                uint256 wethBal = IERC20(WETH).balanceOf(address(this));
                ISwapRouter.ExactInputSingleParams memory params3 = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH,
                    tokenOut: PROFIT,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp + 60 * 20,
                    amountIn: wethBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
                // approve dexRouter to spend WETH
                if (IERC20(WETH).allowance(address(this), address(dexRouter)) < wethBal) {
                    IERC20(WETH).approve(address(dexRouter), type(uint256).max);
                }
                dexRouter.exactInputSingle(params3);
            }
            
        }
    }

    // function to withdraw PROFIT tokens for input amount
    function withdraw(address _token, address _to, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    // function to withdraw all PROFIT tokens in this contract
}