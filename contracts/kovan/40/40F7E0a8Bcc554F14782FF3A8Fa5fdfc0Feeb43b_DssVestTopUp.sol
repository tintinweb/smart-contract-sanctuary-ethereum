// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IUpkeepRefunder.sol";

interface DssVestLike {
    function vest(uint256 _id) external;

    function unpaid(uint256 _id) external view returns (uint256 amt);
}

interface DaiJoinLike {
    function join(address usr, uint256 wad) external;
}

interface KeeperRegistryLike {
    function getUpkeep(uint256 id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber
        );

    function addFunds(uint256 id, uint96 amount) external;
}

/**
 * @title DssVestTopUp
 * @notice Replenishes upkeep balance on demand
 * @dev Withdraws vested tokens or uses transferred tokens from Maker protocol and
 * funds an upkeep after swapping the payment tokens for LINK
 */
contract DssVestTopUp is IUpkeepRefunder, Ownable {
    DssVestLike public immutable dssVest;
    DaiJoinLike public immutable daiJoin;
    ISwapRouter public immutable swapRouter;
    address public immutable vow;
    address public immutable paymentToken;
    address public immutable linkToken;
    address public immutable paymentUsdPriceFeed;
    address public immutable linkUsdPriceFeed;
    KeeperRegistryLike public keeperRegistry;
    uint24 public uniswapPoolFee = 3000;
    uint24 public uniswapSlippageTolerancePercent = 2;
    uint256 public vestId;
    uint256 public upkeepId;
    uint256 public minWithdrawAmt;
    uint256 public maxDepositAmt;
    uint256 public threshold;

    event VestIdUpdated(uint256 newVestId);
    event UpkeepIdUpdated(uint256 newUpkeepId);
    event MinWithdrawAmtUpdated(uint256 newMinWithdrawAmt);
    event MaxDepositAmtUpdated(uint256 newMaxDepositAmt);
    event ThresholdUpdated(uint256 newThreshold);
    event VestedTokensWithdrawn(uint256 amount);
    event ExcessPaymentReturned(uint256 amount);
    event SwappedPaymentTokenForLink(uint256 amountIn, uint256 amountOut);
    event UpkeepRefunded(uint256 amount);
    event FundsRecovered(address token, uint256 amount);

    constructor(
        address _dssVest,
        address _daiJoin,
        address _vow,
        address _paymentToken,
        address _keeperRegistry,
        address _swapRouter,
        address _linkToken,
        address _paymentUsdPriceFeed,
        address _linkUsdPriceFeed,
        uint256 _minWithdrawAmt,
        uint256 _maxDepositAmt,
        uint256 _threshold
    ) {
        require(_dssVest != address(0), "invalid dssVest address");
        require(_daiJoin != address(0), "invalid daiJoin address");
        require(_vow != address(0), "invalid vow address");
        require(_paymentToken != address(0), "invalid paymentToken address");
        require(_keeperRegistry != address(0), "invalid keeperRegistry address");
        require(_swapRouter != address(0), "invalid swapRouter address");
        require(_linkToken != address(0), "invalid linkToken address");
        require(_paymentUsdPriceFeed != address(0), "invalid paymentUsdPriceFeed address");
        require(_linkUsdPriceFeed != address(0), "invalid linkUsdPriceFeed address");
        require(_minWithdrawAmt > 0, "invalid minWithdrawAmt");
        require(_maxDepositAmt > 0, "invalid maxDepositAmt");
        require(_threshold > 0, "invalid threshold");

        dssVest = DssVestLike(_dssVest);
        daiJoin = DaiJoinLike(_daiJoin);
        vow = _vow;
        paymentToken = _paymentToken;
        keeperRegistry = KeeperRegistryLike(_keeperRegistry);
        swapRouter = ISwapRouter(_swapRouter);
        linkToken = _linkToken;
        paymentUsdPriceFeed = _paymentUsdPriceFeed;
        linkUsdPriceFeed = _linkUsdPriceFeed;
        setMinWithdrawAmt(_minWithdrawAmt);
        setMaxDepositAmt(_maxDepositAmt);
        setThreshold(_threshold);
    }

    modifier initialized() {
        require(vestId > 0, "vestId not set");
        require(upkeepId > 0, "upkeepId not set");
        _;
    }

    // ACTIONS

    /**
     * @notice Top up upkeep balance with LINK
     * @dev Called by the DssCronKeeper contract when check returns true
     */
    function refundUpkeep() public initialized {
        require(shouldRefundUpkeep(), "refund not needed");
        uint256 amt;
        uint256 preBalance = getPaymentBalance();
        if (preBalance >= minWithdrawAmt) {
            // Emergency topup
            amt = preBalance;
        } else {
            // Withdraw vested tokens
            dssVest.vest(vestId);
            amt = getPaymentBalance();
            emit VestedTokensWithdrawn(amt);
            if (amt > maxDepositAmt) {
                // Return excess amount to surplus buffer
                uint256 excessAmt = amt - maxDepositAmt;
                daiJoin.join(vow, excessAmt);
                amt = maxDepositAmt;
                emit ExcessPaymentReturned(excessAmt);
            }
        }
        uint256 amtOut = _swapPaymentToLink(amt);
        _fundUpkeep(amtOut);
    }

    /**
     * @notice Check whether top up is needed
     * @dev Called by the keeper
     * @return result indicating if topping up the upkeep balance is needed and
     * if there's enough unpaid vested tokens or tokens in the contract balance
     */
    function shouldRefundUpkeep() public view initialized returns (bool) {
        (, , , uint96 balance, , , ) = keeperRegistry.getUpkeep(upkeepId);
        if (
            threshold < balance ||
            (dssVest.unpaid(vestId) < minWithdrawAmt &&
                getPaymentBalance() < minWithdrawAmt)
        ) {
            return false;
        }
        return true;
    }

    // HELPERS

    function _swapPaymentToLink(uint256 amount)
        internal
        returns (uint256 amountOut)
    {
        TransferHelper.safeApprove(paymentToken, address(swapRouter), amount);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: paymentToken,
                tokenOut: linkToken,
                fee: uniswapPoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: _getPaymentLinkSwapOutMin(amount),
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
        emit SwappedPaymentTokenForLink(amount, amountOut);
    }

    function _fundUpkeep(uint256 amount) internal {
        TransferHelper.safeApprove(linkToken, address(keeperRegistry), amount);
        keeperRegistry.addFunds(upkeepId, uint96(amount));
        emit UpkeepRefunded(amount);
    }

    function _getPaymentLinkSwapOutMin(uint256 amountIn) internal view returns (uint256) {
        uint256 linkDecimals = IERC20Metadata(linkToken).decimals();
        uint256 paymentLinkPrice = uint256(_getDerivedPrice(paymentUsdPriceFeed, linkUsdPriceFeed, uint8(linkDecimals)));

        uint256 paymentDecimals = IERC20Metadata(paymentToken).decimals();
        uint256 paymentAmt = uint256(_scalePrice(int256(amountIn), uint8(paymentDecimals), uint8(linkDecimals)));

        uint256 linkAmt = (paymentAmt * paymentLinkPrice) / 10 ** linkDecimals;
        uint256 slippageTolerance = (linkAmt * uniswapSlippageTolerancePercent) / 100;

        return linkAmt - slippageTolerance;
    }

    function _getDerivedPrice(address _base, address _quote, uint8 _decimals)
        internal
        view
        returns (int256)
    {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "invalid decimals");
        int256 decimals = int256(10 ** uint256(_decimals));
        ( , int256 basePrice, , , ) = AggregatorV3Interface(_base).latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = _scalePrice(basePrice, baseDecimals, _decimals);

        ( , int256 quotePrice, , , ) = AggregatorV3Interface(_quote).latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = _scalePrice(quotePrice, quoteDecimals, _decimals);

        return basePrice * decimals / quotePrice;
    }

    function _scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (int256)
    {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    /**
     * @dev Rescues random funds stuck
     * @param token address of the token to rescue
     */
    function recoverFunds(IERC20 token) external onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenBalance);
        emit FundsRecovered(address(token), tokenBalance);
    }

    // GETTERS

    /**
     * @notice Retrieve the vest payment token balance of this contract
     * @return balance
     */
    function getPaymentBalance() public view returns (uint256) {
        return IERC20(paymentToken).balanceOf(address(this));
    }

    // SETTERS

    function setVestId(uint256 _vestId) external onlyOwner {
        require(_vestId > 0, "invalid vestId");
        vestId = _vestId;
        emit VestIdUpdated(_vestId);
    }

    function setUpkeepId(uint256 _upkeepId) external onlyOwner {
        require(_upkeepId > 0, "invalid upkeepId");
        upkeepId = _upkeepId;
        emit UpkeepIdUpdated(_upkeepId);
    }

    function setMinWithdrawAmt(uint256 _minWithdrawAmt) public onlyOwner {
        require(_minWithdrawAmt > 0, "invalid minWithdrawAmt");
        minWithdrawAmt = _minWithdrawAmt;
        emit MinWithdrawAmtUpdated(_minWithdrawAmt);
    }

    function setMaxDepositAmt(uint256 _maxDepositAmt) public onlyOwner {
        require(_maxDepositAmt > 0, "invalid maxDepositAmt");
        maxDepositAmt = _maxDepositAmt;
        emit MaxDepositAmtUpdated(_maxDepositAmt);
    }

    function setThreshold(uint256 _threshold) public onlyOwner {
        require(_threshold > 0, "invalid threshold");
        threshold = _threshold;
        emit ThresholdUpdated(_threshold);
    }
    
     function setUniswapPoolFee(uint24 _uniSwapPoolFee) public onlyOwner {
        uniswapPoolFee = _uniSwapPoolFee;
    }

    function setSlippageTolerancePercent(
        uint24 _uniswapSlippageTolerancePercent
    ) public onlyOwner {
        uniswapSlippageTolerancePercent = _uniswapSlippageTolerancePercent;
    }

    function setKeeperRegistry(address _keeperRegistry) public onlyOwner {
        keeperRegistry = KeeperRegistryLike(_keeperRegistry);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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