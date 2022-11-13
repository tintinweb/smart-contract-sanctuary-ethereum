// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

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
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

interface IWETH is IERC20 {
    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract DCA {
    uint256 public lastTriggered; // last time the contract swapped
    uint256 public totalFunded; // from the owner for the swap cost

    address payable private _owner;
    uint256 public totalUsers;
    uint256 public _stablecoinEarned; // amount of STABLECOIN this contract has earned

    struct User {
        address walletAddress;
        uint256 amountPerPeriod;
        uint256 stablecoinBalance;
        uint256 ethBalance;
        uint256 allocation;
    }

    mapping(uint256 => address) public userIdToAddress; // list of indices for the _users mapping

    mapping(address => User) private _users; // all users

    address public immutable STABLECOIN;
    address public immutable UNIV3ROUTER2;
    address public immutable WETH;
    ISwapRouter public immutable ROUTER;
    IERC20 public immutable StableCoinContract;
    IWETH public immutable WETHcontract;
    uint256 private constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 public constant swapTimeThreshold = 1 weeks;

    event Swap(
        uint256 totalAmountIn,
        uint256 swapAmountOut,
        uint256 timeOfSwap
    );

    modifier onlyOwner() {
        require(isOwner(), "You are not the owner.");
        _;
    }

    constructor(
        address stableCoinAddress,
        address uniswapV3routerAddress,
        address wethAddress
    ) {
        // init
        _owner = payable(msg.sender);
        STABLECOIN = stableCoinAddress;
        UNIV3ROUTER2 = uniswapV3routerAddress;
        WETH = wethAddress;
        StableCoinContract = IERC20(stableCoinAddress);
        WETHcontract = IWETH(payable(wethAddress));
        ROUTER = ISwapRouter(uniswapV3routerAddress);
    }

    function approveStableCoinForUniV3Router() public onlyOwner {
        IERC20(STABLECOIN).approve(address(UNIV3ROUTER2), MAX_INT);
    }

    function approveStableCoinForDCA() external {
        StableCoinContract.approve(address(this), MAX_INT);
    }

    function withdrawEarnedUsdc() public onlyOwner {
        uint256 transferAmount = _stablecoinEarned;
        _stablecoinEarned = 0;
        StableCoinContract.transferFrom(address(this), _owner, transferAmount);
    }

    function withdraw() external onlyOwner {
        uint256 lockedEth;

        for (uint256 i = 0; i < totalUsers; i++) {
            // iterate through all users
            User memory user = _users[userIdToAddress[i]];
            lockedEth = lockedEth + user.ethBalance;
        }

        uint256 withdrawableAmount = address(this).balance - lockedEth;

        _owner.transfer(withdrawableAmount);
    }

    function deposit() external payable onlyOwner {
        totalFunded = totalFunded + msg.value;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    // Chainlink Keeper Function
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        if (lastTriggered < block.timestamp - swapTimeThreshold) {
            bytes4 selector = bytes4(keccak256("scheduleSwap()"));
            return (true, abi.encodeWithSelector(selector));
        } else {
            return (false, "0x");
        }
    }

    function becomeUser(uint256 amountPerPeriod, uint256 stablecoinAmount)
        public
        payable
    {
        // only one User per wallet
        User memory user = _users[msg.sender];
        require(user.walletAddress == address(0), "Address already is User");

        uint256 allowance = StableCoinContract.allowance(
            msg.sender,
            address(this)
        );
        require(
            allowance > stablecoinAmount,
            "Stablecoin Allowance insufficient"
        );

        StableCoinContract.transferFrom(
            msg.sender,
            address(this),
            stablecoinAmount
        );

        _users[msg.sender] = User(
            msg.sender,
            amountPerPeriod,
            stablecoinAmount,
            msg.value,
            0
        );
        userIdToAddress[totalUsers] = msg.sender;
        totalUsers = totalUsers + 1;
    }

    function getUser(address account) public view returns (User memory) {
        return _users[account];
    }

    function scheduleSwap() external {
        uint256 totalAmountIn;
        // Stablecoin has 6 decimals, 1000000 equals 1
        uint256 swapFee = 1000000;

        for (uint256 i = 0; i < totalUsers; i++) {
            // iterate through all users
            // and sum up the users amountPerPeriod StableCoin balances
            User memory user = _users[userIdToAddress[i]];
            if (user.stablecoinBalance >= user.amountPerPeriod + swapFee) {
                // check if user has enough funds
                user.stablecoinBalance =
                    user.stablecoinBalance -
                    (user.amountPerPeriod + swapFee);
                _stablecoinEarned = _stablecoinEarned + swapFee;

                totalAmountIn = totalAmountIn + user.amountPerPeriod;
            }
        }
        if (totalAmountIn > 0) {
            for (uint256 i = 0; i < totalUsers; i++) {
                // iterate through all users
                // and calculate each users allocation
                // i.e. the ratio of his contribution to the toalAmount of StableCoin balances
                User memory user = _users[userIdToAddress[i]];
                // SRB if totalAmountIn is bigger than user.amountPerPeriod
                // user.allocation will be zero, which is almost guaranteed
                user.allocation = user.amountPerPeriod / totalAmountIn;
            }

            // perform the swap of StableCoin to WETH
            // will be 18 decimal number
            uint256 amountOut = _swapExactInputSingle(totalAmountIn);
            // unwrap WETH
            WETHcontract.withdraw(amountOut);
            // log results
            emit Swap(totalAmountIn, amountOut, block.timestamp);

            for (uint256 i = 0; i < totalUsers; i++) {
                // iterate through all users
                // and calculate their share of the returned swap amount
                User memory user = _users[userIdToAddress[i]];
                // SRB:  user.allocation can be zero
                user.ethBalance = user.allocation * amountOut;
            }
        }

        lastTriggered = block.timestamp;
    }

    function _swapExactInputSingle(uint256 amountIn)
        internal
        returns (uint256 amountOut)
    {
        uint256 allowance = StableCoinContract.allowance(
            address(this),
            UNIV3ROUTER2
        );
        require(allowance > amountIn, "UNISWAP ROUTER Allowance insufficient");

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: STABLECOIN,
                tokenOut: WETH,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 10 minutes,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = ROUTER.exactInputSingle(params);
    }
}