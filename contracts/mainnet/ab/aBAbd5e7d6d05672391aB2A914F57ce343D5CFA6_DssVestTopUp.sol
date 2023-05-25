// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../vendor/dss-cron/src/interfaces/INetworkTreasury.sol";
import "./interfaces/IUpkeepRefunder.sol";

interface NetworkPaymentAdapterLike {
    function topUp() external returns (uint256 daiSent);

    function canTopUp() external view returns (bool);
}

interface KeeperRegistryLike {
    struct UpkeepInfo {
        address target;
        uint32 executeGas;
        bytes checkData;
        uint96 balance;
        address admin;
        uint64 maxValidBlocknumber;
        uint32 lastPerformBlockNumber;
        uint96 amountSpent;
        bool paused;
        bytes offchainConfig;
    }

    function getUpkeep(uint256) external view returns (UpkeepInfo memory upkeepInfo);

    function addFunds(uint256 id, uint96 amount) external;
}

/**
 * @title DssVestTopUp
 * @notice Replenishes Chainlink upkeep balance on demand from MakerDAO vesting plan.
 * Reports upkeep buffer size convrted in DAI.
 */
contract DssVestTopUp is IUpkeepRefunder, INetworkTreasury, Ownable {
    // DATA
    ISwapRouter public immutable swapRouter;
    address public immutable daiToken;
    address public immutable linkToken;
    address public immutable daiUsdPriceFeed;
    address public immutable linkUsdPriceFeed;
    uint8 public immutable priceFeedDecimals;

    // PARAMS
    uint256 public upkeepId;
    bytes public uniswapPath;
    uint24 public slippageToleranceBps;
    NetworkPaymentAdapterLike public paymentAdapter;
    KeeperRegistryLike public keeperRegistry;

    // EVENTS
    event UpkeepRefunded(uint256 amount);
    event SwappedDaiForLink(uint256 amountIn, uint256 amountOut);
    event FundsRecovered(address token, uint256 amount);
    event PaymentAdapterSet(address paymentAdapter);
    event KeeperRegistrySet(address keeperRegistry);
    event UpkeepIdSet(uint256 upkeepId);
    event UniswapPathSet(bytes uniswapPath);
    event SlippageToleranceSet(uint24 slippageToleranceBps);

    // ERRORS
    error InvalidParam(string name);

    constructor(
        uint256 _upkeepId,
        address _keeperRegistry,
        address _daiToken,
        address _linkToken,
        address _paymentAdapter,
        address _daiUsdPriceFeed,
        address _linkUsdPriceFeed,
        address _swapRouter,
        uint24 _slippageToleranceBps,
        bytes memory _uniswapPath
    ) {
        if (_upkeepId == 0) revert InvalidParam("Upkeep ID");
        if (_keeperRegistry == address(0)) revert InvalidParam("KeeperRegistry");
        if (_daiToken == address(0)) revert InvalidParam("DAI Token");
        if (_linkToken == address(0)) revert InvalidParam("LINK Token");
        if (_paymentAdapter == address(0)) revert InvalidParam("Payment Adapter");
        if (_daiUsdPriceFeed == address(0)) revert InvalidParam("DAI/USD Price Feed");
        if (_linkUsdPriceFeed == address(0)) revert InvalidParam("LINK/USD Price Feed");
        if (_swapRouter == address(0)) revert InvalidParam("Uniswap Router");
        if (_uniswapPath.length == 0) revert InvalidParam("Uniswap Path");

        upkeepId = _upkeepId;
        keeperRegistry = KeeperRegistryLike(_keeperRegistry);
        daiToken = _daiToken;
        linkToken = _linkToken;
        paymentAdapter = NetworkPaymentAdapterLike(_paymentAdapter);
        daiUsdPriceFeed = _daiUsdPriceFeed;
        linkUsdPriceFeed = _linkUsdPriceFeed;
        swapRouter = ISwapRouter(_swapRouter);
        uniswapPath = _uniswapPath;
        slippageToleranceBps = _slippageToleranceBps;

        // Validate price oracle decimals
        uint8 linkUsdDecimals = AggregatorV3Interface(linkUsdPriceFeed).decimals();
        uint8 daiUsdDecimals = AggregatorV3Interface(daiUsdPriceFeed).decimals();
        if (linkUsdDecimals != daiUsdDecimals) revert InvalidParam("Price oracle");
        priceFeedDecimals = linkUsdDecimals;

        // Allow spending of LINK and DAI tokens
        TransferHelper.safeApprove(daiToken, address(swapRouter), type(uint256).max);
        TransferHelper.safeApprove(linkToken, address(keeperRegistry), type(uint256).max);
    }

    // ACTIONS

    /**
     * @notice Withdraw accumulated funds and top up the upkeep balance
     */
    function refundUpkeep() external {
        uint256 daiReceived = paymentAdapter.topUp();
        uint256 linkAmount = _swapDaiForLink(daiReceived);

        keeperRegistry.addFunds(upkeepId, uint96(linkAmount));
        emit UpkeepRefunded(linkAmount);
    }

    // GETTERS

    /**
     * @notice Check if the upkeep balance should be topped up
     */
    function shouldRefundUpkeep() external view returns (bool) {
        return paymentAdapter.canTopUp();
    }

    /**
     * @notice Get the current upkeep balance in DAI
     * @dev Called by the NetworkPaymentAdapter
     */
    function getBufferSize() external view returns (uint256 daiAmount) {
        uint96 balance = keeperRegistry.getUpkeep(upkeepId).balance;
        daiAmount = _convertLinkToDai(balance);
    }

    // HELPERS

    function _swapDaiForLink(uint256 _daiAmountIn) internal returns (uint256 linkAmountOut) {
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: uniswapPath,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _daiAmountIn,
            amountOutMinimum: _getDaiLinkSwapOutMin(_daiAmountIn)
        });
        linkAmountOut = swapRouter.exactInput(params);
        emit SwappedDaiForLink(_daiAmountIn, linkAmountOut);
    }

    function _getDaiLinkSwapOutMin(uint256 _daiAmountIn) internal view returns (uint256 minLinkAmountOut) {
        uint256 linkAmount = _convertDaiToLink(_daiAmountIn);
        uint256 slippageTolerance = (linkAmount * slippageToleranceBps) / 10000;
        minLinkAmountOut = linkAmount - slippageTolerance;
    }

    function _convertLinkToDai(uint256 _linkAmount) internal view returns (uint256 daiAmount) {
        int256 decimals = int256(10 ** uint256(priceFeedDecimals));
        int256 linkDaiPrice = _getDerivedPrice(linkUsdPriceFeed, daiUsdPriceFeed, decimals);
        daiAmount = uint256((int256(_linkAmount) * linkDaiPrice) / decimals);
    }

    function _convertDaiToLink(uint256 _daiAmount) internal view returns (uint256 linkAmount) {
        int256 decimals = int256(10 ** uint256(priceFeedDecimals));
        int256 daiLinkPrice = _getDerivedPrice(daiUsdPriceFeed, linkUsdPriceFeed, decimals);
        linkAmount = uint256((int256(_daiAmount) * daiLinkPrice) / decimals);
    }

    function _getDerivedPrice(address _base, address _quote, int256 decimals) internal view returns (int256) {
        (, int256 basePrice, , , ) = AggregatorV3Interface(_base).latestRoundData();
        (, int256 quotePrice, , , ) = AggregatorV3Interface(_quote).latestRoundData();
        return (basePrice * decimals) / quotePrice;
    }

    // SETTERS

    function setPaymentAdapter(address _paymentAdapter) external onlyOwner {
        if (_paymentAdapter == address(0)) revert InvalidParam("Payment Adapter");
        paymentAdapter = NetworkPaymentAdapterLike(_paymentAdapter);
        emit PaymentAdapterSet(_paymentAdapter);
    }

    function setKeeperRegistry(address _keeperRegistry) external onlyOwner {
        if (_keeperRegistry == address(0)) revert InvalidParam("KeeperRegistry");
        keeperRegistry = KeeperRegistryLike(_keeperRegistry);
        emit KeeperRegistrySet(_keeperRegistry);
    }

    function setUpkeepId(uint256 _upkeepId) external onlyOwner {
        if (_upkeepId == 0) revert InvalidParam("Upkeep ID");
        upkeepId = _upkeepId;
        emit UpkeepIdSet(_upkeepId);
    }

    function setUniswapPath(bytes memory _uniswapPath) external onlyOwner {
        if (_uniswapPath.length == 0) revert InvalidParam("Uniswap Path");
        uniswapPath = _uniswapPath;
        emit UniswapPathSet(_uniswapPath);
    }

    function setSlippageTolerance(uint24 _slippageToleranceBps) external onlyOwner {
        slippageToleranceBps = _slippageToleranceBps;
        emit SlippageToleranceSet(_slippageToleranceBps);
    }

    // MISC

    function recoverFunds(IERC20 _token) external onlyOwner {
        uint256 tokenBalance = _token.balanceOf(address(this));
        _token.transfer(msg.sender, tokenBalance);
        emit FundsRecovered(address(_token), tokenBalance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity 0.8.13;

interface INetworkTreasury {

	/**
	 * @dev This should return an estimate of the total value of the buffer in DAI.
	 * Keeper Networks should convert non-DAI assets to DAI value via an oracle.
	 * 
	 * Ex) If the network bulk trades DAI for ETH then the value of the ETH sitting
	 * in the treasury should count towards this buffer size.
	 */
	function getBufferSize() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUpkeepRefunder {
    function refundUpkeep() external;

    function shouldRefundUpkeep() external view returns (bool);

    function setUpkeepId(uint256 _upkeepId) external;
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