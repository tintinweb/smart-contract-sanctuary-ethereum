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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAverage} from "./interfaces/IAverage.sol";

contract Average is IAverage {
    uint256 public positionId;
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    address[] public users;
    address[] public assets;

    // by user
    mapping(address => Position[]) private _positions;
    mapping(address => Transaction[]) private _transactions;

    // by asset
    mapping(address => uint256[]) _blocksByAsset;

    // by asset / block
    mapping(address => mapping(uint256 => Trade)) private _trades;
    mapping(address => mapping(uint256 => uint256)) private _amountPerBlock;
    mapping(address => mapping(uint256 => uint256)) private _cumulativeQuantity;

    address private constant USDC_GOERLI =
        0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // decimals: 6
    address private constant WETH_GOERLI =
        0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // decimals: 18
    address private constant WBTC_GOERLI =
        0xdA4a47eDf8ab3c5EeeB537A97c5B66eA42F49CdA; // decimals: 8
    ISwapRouter public immutable swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    constructor() {
        assets = [USDC_GOERLI, WETH_GOERLI, WBTC_GOERLI];
        // Approve the router to spend USDC.
        TransferHelper.safeApprove(
            USDC_GOERLI,
            address(swapRouter),
            type(uint256).max
        );
    }

    function isObsolete() public view {}

    function getPositionBalance(Position memory position)
        public
        view
        returns (uint256 balance)
    {
        address asset = position.target;
        uint256 t0 = position.start;
        uint256 t = position.end > block.number ? block.number : position.end;
        uint256 cost = numBlocks(t0, t, asset);
        uint256 multiplier = balanceMultiplier(asset, t0, t);
        balance = (multiplier - cost) * position.amountPerBlock;
    }

    //  amount per block (USDC):                                    1
    //  price:                                                      10_000             20_000        5_000       40_000
    //  quantity: amount per block / price                          0.0001             0.00005       0.0002      0.000025
    //  cumulative quantity: cq(t-1) + q(t)                         0.0001             0.00015       0.00035     0.000375
    //  cumulative cost: cc(t-1) + amount per block                 1                  2             3           4
    //  balance multiplier: price(t) * cq(t-1) / cc(t-1)            1                  2             0.375       4.666667
    function balanceMultiplier(
        address asset,
        uint256 start,
        uint256 end
    ) public view returns (uint256 multiplier) {
        uint256 price = getPrice(asset, end);
        uint256 quantity = getQuantity(asset, end);
        uint256 thisCumulativeQuantity = _cumulativeQuantity[asset][end];
        uint256 cumulativeQuantityLastBlock = thisCumulativeQuantity - quantity;
        uint256 cumulativeCostLastBlock = numBlocks(start, end, asset);
        multiplier =
            (price * cumulativeQuantityLastBlock) /
            cumulativeCostLastBlock;
    }

    function numBlocks(
        uint256 start,
        uint256 end,
        address asset
    ) public view returns (uint256) {
        uint256 num = 0;
        uint256[] memory blocks = _blocksByAsset[asset];
        for (uint256 i; i < blocks.length; i++) {
            if (blocks[i] > end) {
                return num;
            } else if (blocks[i] > start) {
                num += 1;
            }
        }
        return num;
    }

    function addTrade(
        address source,
        address target,
        uint256 price,
        uint256 quantity,
        uint256 blockNum
    ) public {
        // require: only Average can call this
        _trades[target][blockNum] = Trade(source, price, quantity);
    }

    address assetToSwap = WBTC_GOERLI;

    function swap() public returns (uint256 amountOut) {
        // require: only admin can call once per block/hour/day
        uint256 amountIn = 1e6;

        amountOut = _swap(assetToSwap, amountIn);
        // Change assetToSwap for the next swap
        assetToSwap = assetToSwap == WBTC_GOERLI ? WETH_GOERLI : WBTC_GOERLI;

        // update positions
        updatePositions(assetToSwap, amountIn, amountOut);

        // update trades
        Trade memory trade = Trade({
            source: USDC_GOERLI,
            price: amountIn,
            quantity: amountOut
        });
        _trades[USDC_GOERLI][block.number] = trade;
    }

    function updatePositions(
        address asset,
        uint256 price,
        uint256 quantity
    ) public {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            // Add a mock transaction
            Transaction memory transaction = Transaction({
                asset: asset,
                amount: int256(quantity),
                time: block.timestamp
            });
            _transactions[user].push(transaction);
        }
    }

    function _swap(address asset, uint256 amountIn)
        private
        returns (uint256 amountOut)
    {
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: USDC_GOERLI,
                tokenOut: asset,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    function addUser(address user) public {
        if (_transactions[user].length == 0) {
            users.push(user);
        }
    }

    function deleteUser(address user) public {
        for (uint256 u; u < users.length; u++) {
            if (users[u] == user) {
                users[u] = users[users.length - 1];
                users.pop();
            }
        }
        delete _positions[user];
        delete _transactions[user];
    }

    function deposit(uint256 amount, address asset) public {
        // uint256 _blocks
        // require(asset == USDC_GOERLI);
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        // TODO: add to list msg.sender amount/_blocks starting at blockNumber
        // addUser(msg.sender);
        Transaction memory transaction = Transaction(
            asset,
            int256(amount),
            block.timestamp
        );
        _transactions[msg.sender].push(transaction);

        // Update amount per block (TODO)

        // trade(_amount);

        emit Deposit(msg.sender, transaction);
    }

    function withdraw(uint256 amount, address asset) public {
        // TODO: perform some checks, and then subtract from user balance
        IERC20(asset).transfer(msg.sender, amount);
        Transaction memory transaction = Transaction(
            asset,
            -int256(amount),
            block.timestamp
        );
        _transactions[msg.sender].push(transaction);
    }

    function createPosition(
        address source,
        address target,
        uint256 amount,
        Duration duration
    ) public {
        require(source == USDC_GOERLI, "source is not valid");

        positionId++;
        Position memory position = Position({
            source: source,
            target: target,
            amount: amount,
            duration: duration,
            id: positionId,
            start: block.number + 1,
            amountPerBlock: 1, // TODO
            end: block.number + 2, //TODO
            isActive: true
        });
        _positions[msg.sender].push(position);
        // TODO: map start/end block *efficiently*
        _amountPerBlock[position.target][position.start] += position
            .amountPerBlock;
        // _amountPerBlock[position.target][position.end] -= position
        //     .amountPerBlock;
    }

    function closePosition(address user, uint closePositionId) public {
        for (uint256 i; i < _positions[user].length; i++) {
            if (_positions[user][i].id == closePositionId) {
                // if (_positions[user][i].end > block.number) {
                _positions[user][i].end = block.number;
                _positions[user][i].isActive = false;
                // }
            }
        }
        // TODO:
        // - update amountPerBlock
        // - update end on user's other _positions
    }

    function getUserBalances(address user)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory balances = new uint256[](assets.length);
        for (uint256 i; i < assets.length; i++) {
            balances[i] = getUserBalance(user, assets[i]);
        }
        return (assets, balances);
    }

    function getUserBalance(address user, address asset)
        public
        view
        returns (uint256)
    {
        return getUserBalanceRealized(user, asset);
        // getUserBalanceUnrealized(user, asset);
    }

    function getUserBalanceRealized(address user, address asset)
        public
        view
        returns (uint256)
    {
        int256 balance;
        for (uint256 i; i < _transactions[user].length; i++) {
            if (_transactions[user][i].asset == asset) {
                balance += _transactions[user][i].amount;
            }
        }
        return uint256(balance);
    }

    function getUserBalanceUnrealized(address user, address asset)
        public
        view
        returns (uint256)
    {
        uint256 result;
        Position[] memory userPositions = getUserPositionsByAsset(user, asset);
        for (uint256 i; i < userPositions.length; i++) {
            result += getPositionBalance(userPositions[i]);
        }
        return result;
    }

    function getContractBalance(address asset) external view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    function getUserPositionsByAsset(address user, address asset)
        public
        view
        returns (Position[] memory)
    {
        // https://stackoverflow.com/questions/68010434/why-cant-i-return-dynamic-array-in-solidity/68010807#68010807
        uint256 count;
        for (uint256 i; i < _positions[user].length; i++) {
            if (_positions[user][i].target == asset) {
                count++;
            }
        }
        Position[] memory results;
        uint256 j;
        for (uint256 i; i < _positions[user].length; i++) {
            if (_positions[user][i].target == asset) {
                results[j] = _positions[user][i];
                j++;
            }
        }
        return results;
    }

    function getPrice(address asset, uint256 _block)
        public
        view
        returns (uint256)
    {
        return _trades[asset][_block].price;
    }

    function getQuantity(address asset, uint256 _block)
        public
        view
        returns (uint256)
    {
        return _trades[asset][_block].quantity;
    }

    /// @inheritdoc IAverage
    function positions(address user) external view returns (Position[] memory) {
        return _positions[user];
    }

    /// @inheritdoc IAverage
    function transactions(address user)
        external
        view
        returns (Transaction[] memory)
    {
        return _transactions[user];
    }

    /// @inheritdoc IAverage
    function blocksByAsset(address asset)
        external
        view
        returns (uint256[] memory)
    {
        return _blocksByAsset[asset];
    }

    /// @inheritdoc IAverage
    function trades(address asset, uint256 blockNum)
        external
        view
        returns (Trade memory)
    {
        return _trades[asset][blockNum];
    }

    /// @inheritdoc IAverage
    function amountPerBlock(address asset, uint256 blockNum)
        external
        view
        returns (uint256)
    {
        return _amountPerBlock[asset][blockNum];
    }

    /// @inheritdoc IAverage
    function cumulativeQuantity(address asset, uint256 blockNum)
        external
        view
        returns (uint256)
    {
        return _cumulativeQuantity[asset][blockNum];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TODO: natspec
interface IAverage {

    struct Position {
        address source;
        address target;
        uint amount;
        Duration duration;
        uint id;
        uint start;
        uint amountPerBlock;
        uint end;
        bool isActive;
    }
    enum Duration {
        DAY,
        WEEK,
        FORTNIGHT,
        MONTH,
        YEAR
    }

    struct Transaction {
        // uint id;
        address asset;
        int256 amount;
        uint time;
    }

    struct Trade {
        address source;
        uint price;
        uint quantity;
    }

    event Deposit(address user, Transaction transaction);

    // access to mappings
    function positions(address user) external view returns (Position[] memory);
    function transactions(address user) external view returns (Transaction[] memory);
    function blocksByAsset(address asset) external view returns (uint256[] memory);
    function trades(address asset, uint256 blockNum) external view returns (Trade memory);
    function amountPerBlock(address asset, uint256 blockNum) external view returns (uint256);
    function cumulativeQuantity(address asset, uint256 blockNumb) external view returns (uint256);
}