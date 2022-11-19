/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT
// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


pragma solidity >=0.5.0;

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

// File: @uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol


pragma solidity >=0.7.5;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: DCA.sol


pragma solidity ^0.8.0;


contract DCA {

    //////////////////////
    // Public Variables //
    //////////////////////

    address public immutable baseTokenAddress;
    address public immutable targetTokenAddress;
    address payable public immutable recipient;
    uint256 public immutable amount;
    uint24 public immutable poolFee;
    uint256 public immutable maxEpoch;
    uint256 public immutable swapInterval;

    IERC20 public immutable BASE_TOKEN;
    IERC20 public immutable TARGET_TOKEN;

    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    uint256 public currentEpoch;
    uint256 public swapTime;

    ///////////////////////
    // Private Variables //
    ///////////////////////

    address payable private _fundingAddress;
    
    ////////////
    // Events //
    ////////////

    event Swap(
        address indexed baseTokenAddress,
        uint256 amountIn,
        address indexed targetTokenAddress,
        uint256 amountOut,
        address indexed executedBy
    );

    ///////////////
    // Modifiers //
    ///////////////

    // Check for the interval between 
    modifier canSwap{
        require(block.timestamp >= swapTime, "ERROR: TIME LIMIT");
        require(currentEpoch <= (maxEpoch-1), "ERROR: EPOCH LIMIT");
        _;
    }

    /*
    * @notice initialize contract with the base asset and router for the swapping function.
    * @param _amount: amount of token to sell.
    * @param _baseToken: address of token you are selling for the target token.
    * @param _targetToken: address of the token you are acquiring.
    * @param _interval: time interval between each DCA interval.
    * @param _startNow: 0 or 1 value. 0 -> start in the next interval. 1 -> dca starting now.
    * @param _recipient: address recieving the token from swaps.
    * @param _funder: the address paying for the swap.
    * @param _poolFee: the Uniswap pool you want to use for this pair.
    * @param _maxEpoch: maximum number of the swaps one can do.
    */
    constructor(
        uint256 _amount,
        address _baseToken,
        address _targetToken,
        uint256 _interval,
        uint8 _startNow,
        address payable _recipient,
        address payable _funder,
        uint24 _poolFee,
        uint256 _maxEpoch
    ){
        // initialize Token Addresses
        baseTokenAddress = _baseToken;
        targetTokenAddress = _targetToken;

        // initialize pool option
        poolFee = _poolFee;

        // initialize interval value
        swapInterval = _interval;
        
        // initialize next swap time.
        swapTime = block.timestamp + (1 - _startNow) * swapInterval;


        // initialize ERC20 tokens.
        BASE_TOKEN = IERC20(baseTokenAddress);
        TARGET_TOKEN = IERC20(targetTokenAddress);

        // initialize DCA amount for each epoch.
        amount = _amount;
        maxEpoch = _maxEpoch;
        currentEpoch = 0;
        
        // Set reciever of token.
        recipient = _recipient;
        _fundingAddress = _funder;

        // Approve DCA bot to interact with Uniswap router.
        BASE_TOKEN.approve(address(swapRouter), BASE_TOKEN.totalSupply());

    }

    /*
    * @notice swap asset from base to target
    * @param amountMin The minimum amount of target asset output. NOTE: Need to be calculated offchain.
    */
    function swap(uint256 amountMin) public payable canSwap returns (uint256 amountOut) {

        // Transfer in base asset.
        BASE_TOKEN.transferFrom(_fundingAddress, address(this), amount);

        // Execute Swap
        // https://docs.uniswap.org/protocol/guides/swaps/single-swaps
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: baseTokenAddress,
                tokenOut: targetTokenAddress,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: amountMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        // Set last swap time to current.
        swapTime = block.timestamp;
        // Increment current epoch number.
        currentEpoch++;

        emit Swap(baseTokenAddress, amount, targetTokenAddress, amountOut, msg.sender);

    }

    /*
    * @notice Remove all ETH from Smart Contract in case funds being suck inside.
    */
    function unstuckETH() public payable {
        recipient.transfer(address(this).balance);
    }

    /*
    * @notice Remove all base asset from Smart Contract in case funds being suck inside.
    */
    function unstuckERC(address erc20) public payable {
        IERC20(erc20).transfer(recipient, IERC20(erc20).balanceOf(address(this)));
    }
    

}
// File: DCAFactory.sol


pragma solidity ^0.8.0;


contract DCAFactory{
    DCA[] public DCABots;

    address[] public DCABotRecipient;

    event DCACreated(
        address indexed funder,
        address indexed recipient,
        address indexed bot,
        address baseToken,
        address targetToken,
        uint256 amount,
        uint256 interval,
        uint256 maxEpoch
    );

    /*
    * @notice documentation copied from DCA.sol's constructor. Create function creates a new instance of DCA and stores address.
    * @param _amount: amount of token to sell.
    * @param _baseToken: address of token you are selling for the target token.
    * @param _targetToken: address of the token you are acquiring.
    * @param _interval: time interval between each DCA interval.
    * @param _startNow: 0 or 1 value. 0 -> start in the next interval. 1 -> dca starting now.
    * @param _recipient: address recieving the token from swaps.
    * @param _funder: the address paying for the swap.
    * @param _poolFee: the Uniswap pool you want to use for this pair.
    * @param _maxEpoch: maximum number of the swaps one can do.
    */
    function createDCA (
        uint256 _amount,
        address _baseToken,
        address _targetToken,
        uint256 _interval,
        uint8 _startNow,
        address payable _recipient,
        address payable _funder,
        uint24 _poolFee,
        uint256 _maxEpoch
    ) public {
        
        // Deploy new DCA Bot.
        DCA newDCA = new DCA(
            _amount,
            _baseToken,
            _targetToken,
            _interval,
            _startNow,
            _recipient,
            _funder,
            _poolFee,
            _maxEpoch
        );
        
        // Store new DCA Bot address and recipient for the bot.
        DCABots.push(newDCA);
        DCABotRecipient.push(_recipient);

        emit DCACreated(
            _funder,
            _recipient,
            address(newDCA),
            _baseToken,
            _targetToken,
            _amount,
            _interval,
            _maxEpoch
        );

    }

    // Query length of total DCA bot length. For front end purposes.
    function totalDCALength() external view returns (uint256) {
        return DCABots.length;
    }


}