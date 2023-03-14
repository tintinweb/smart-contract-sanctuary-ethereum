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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// import "hardhat/console.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error swapFee__InsufficentFee();
error swapFee__FeeExceeded();
error swapFee__FeeNotPaid();
error swapFee__FeeNotRequired();

/**
 * @title Uniswap V3 contract
 * @author Hari Krishna, Sabir Aboobaker
 * @notice This contract has unsiswapV3 implementation for swapping tokens with platform commision
 * @dev This contract implements Uniswap V3 and Aggregator V3 interface for checking price
 */
contract SeekerSwapRouter is ISwapRouter, Pausable, Ownable {
    ISwapRouter private uniswapRouterAddress;
    AggregatorV3Interface private chainLinkEthToUsdAggregatorAddress;
    uint256 private usdFee;
    uint256 private feeSlippagePercentage;

    //Events
    event UpdatedConfiguration(
        address uniswapRouterAddress,
        address aggregatorAddress,
        uint usdFee,
        uint _feeSlippagePercentage
    );
    event SwapToken(
        address indexed user,
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint amountOut,
        uint swapFee,
        uint platformFee
    );

    constructor(
        address _uniswapRouterAddress,
        address _chainLinkEthToUsdAggregatorAddress,
        uint256 _usdFee,
        uint256 _feeSlippagePercentage
    ) {
        usdFee = _usdFee * 10e16;
        feeSlippagePercentage = _feeSlippagePercentage;
        if (_uniswapRouterAddress != address(0))
            uniswapRouterAddress = ISwapRouter(_uniswapRouterAddress);
        if (_chainLinkEthToUsdAggregatorAddress != address(0))
            chainLinkEthToUsdAggregatorAddress = AggregatorV3Interface(
                _chainLinkEthToUsdAggregatorAddress
            );
        emit UpdatedConfiguration(
            address(uniswapRouterAddress),
            address(chainLinkEthToUsdAggregatorAddress),
            usdFee,
            feeSlippagePercentage
        );
    }

    modifier validatePlatformFee() {
        if (usdFee > 0) {
            uint256 platformFeeInWei = _getPriceInWei();
            uint256 slippageAmount = platformFeeInWei *
                (feeSlippagePercentage / 100);
            uint256 higherSlippageLimit = platformFeeInWei + slippageAmount;
            uint256 lowerSlippageLimit = platformFeeInWei - slippageAmount;
            if (msg.value > higherSlippageLimit) revert swapFee__FeeExceeded();
            if (msg.value < lowerSlippageLimit)
                revert swapFee__InsufficentFee();
        } else if (msg.value > 0) revert swapFee__FeeNotRequired();
        _;
    }

    function updateConfiguration(
        address _uniswapRouterAddress,
        address _chainLinkEthToUsdAggregatorAddress,
        uint256 _usdFee,
        uint256 _feeSlippagePercentage
    ) external onlyOwner {
        usdFee = _usdFee * 10e16;
        feeSlippagePercentage = _feeSlippagePercentage;
        if (_uniswapRouterAddress != address(0))
            uniswapRouterAddress = ISwapRouter(_uniswapRouterAddress);
        if (_chainLinkEthToUsdAggregatorAddress != address(0))
            chainLinkEthToUsdAggregatorAddress = AggregatorV3Interface(
                _chainLinkEthToUsdAggregatorAddress
            );
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external whenNotPaused {
        uniswapRouterAddress.uniswapV3SwapCallback(
            amount0Delta,
            amount1Delta,
            data
        );
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    )
        external
        payable
        override
        whenNotPaused
        validatePlatformFee
        returns (uint256 amountOut)
    {
        amountOut = uniswapRouterAddress.exactInputSingle(params);
        emit SwapToken(
            params.recipient,
            params.tokenIn,
            params.amountIn,
            params.tokenOut,
            amountOut,
            params.fee,
            msg.value
        );
    }

    function exactInput(
        ExactInputParams calldata params
    )
        external
        payable
        override
        whenNotPaused
        validatePlatformFee
        returns (uint256 amountOut)
    {
        return uniswapRouterAddress.exactInput(params);
    }

    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    )
        external
        payable
        override
        whenNotPaused
        validatePlatformFee
        returns (uint256 amountIn)
    {
        amountIn = uniswapRouterAddress.exactOutputSingle(params);
        emit SwapToken(
            params.recipient,
            params.tokenIn,
            amountIn,
            params.tokenOut,
            params.amountOut,
            params.fee,
            msg.value
        );
    }

    function exactOutput(
        ExactOutputParams calldata params
    )
        external
        payable
        override
        whenNotPaused
        validatePlatformFee
        returns (uint256 amountIn)
    {
        return uniswapRouterAddress.exactOutput(params);
    }

    function _getPriceInWei() internal view returns (uint256 feeInWei) {
        uint decimals = chainLinkEthToUsdAggregatorAddress.decimals();
        (, int256 answer, , , ) = chainLinkEthToUsdAggregatorAddress
            .latestRoundData();
        uint256 ethPriceInUSD18Decimals = uint256(
            answer * int256(10 ** (uint(18) - decimals))
        );
        feeInWei = usdFee / ethPriceInUSD18Decimals;
    }
}