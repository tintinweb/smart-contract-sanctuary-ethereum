// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPathFinder} from "../interfaces/external/IPathFinder.sol";
import {IQuoterV2} from "../intergrations/uniswap/IQuoterV2.sol";
import {Constants} from "../libraries/Constants.sol";

contract PathFinder is IPathFinder, Ownable {
    IQuoterV2 public quoter;
    uint24[] private fees = [500, 3000, 10000];
    address[] private sharedTokens;

    // Contract version
    uint256 public constant version = 1;

    constructor(address _quoter, address[] memory _tokens) {
        quoter = IQuoterV2(_quoter);
        sharedTokens = _tokens;
    }

    function exactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path) {
        address[] memory tokens = sharedTokens;
        path = bestExactInputPath(tokenIn, tokenOut, amount, tokens);
    }

    function exactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path) {
        address[] memory tokens = sharedTokens;
        path = bestExactOutputPath(tokenIn, tokenOut, amount, tokens);
    }

    function bestExactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] memory tokens
    ) public returns (TradePath memory path) {
        path = _bestV3Path(Constants.EXACT_INPUT, tokenIn, tokenOut, amountIn, tokens);
    }

    function bestExactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address[] memory tokens
    ) public returns (TradePath memory path) {
        path = _bestV3Path(Constants.EXACT_OUTPUT, tokenOut, tokenIn, amountOut, tokens);
    }

    function getFees() public view returns (uint24[] memory) {
        return fees;
    }

    function getSharedTokens() public view returns (address[] memory) {
        return sharedTokens;
    }

    function updateFees(uint24[] memory _fees) external onlyOwner {
        fees = _fees;
    }

    function updateTokens(address[] memory tokens) external onlyOwner {
        sharedTokens = tokens;
    }

    function _bestV3Path(
        uint256 tradeType,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) internal returns (TradePath memory tradePath) {
        if (amount == 0 || tokenIn == address(0) || tokenOut == address(0) || tokenIn == tokenOut) return tradePath;

        tradePath.expectedAmount = tradeType == Constants.EXACT_INPUT ? 0 : Constants.MAX_UINT256;
        for (uint256 i = 0; i < fees.length; i++) {
            bytes memory path = abi.encodePacked(tokenIn, fees[i], tokenOut);
            (
                bool best,
                uint256 expectedAmount,
                uint160[] memory sqrtPriceX96AfterList,
                uint32[] memory initializedTicksCrossedList,
                uint256 gas
            ) = _getAmount(tradeType, path, amount, tradePath.expectedAmount);
            if (best) {
                tradePath.expectedAmount = expectedAmount;
                tradePath.sqrtPriceX96AfterList = sqrtPriceX96AfterList;
                tradePath.initializedTicksCrossedList = initializedTicksCrossedList;
                tradePath.gasEstimate = gas;
                tradePath.path = path;
            }
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenIn == tokens[i] || tokenOut == tokens[i]) continue;
            for (uint256 j = 0; j < fees.length; j++) {
                for (uint256 k = 0; k < fees.length; k++) {
                    bytes memory path = abi.encodePacked(tokenIn, fees[j], tokens[i], fees[k], tokenOut);
                    (
                        bool best,
                        uint256 expectedAmount,
                        uint160[] memory sqrtPriceX96AfterList,
                        uint32[] memory initializedTicksCrossedList,
                        uint256 gas
                    ) = _getAmount(tradeType, path, amount, tradePath.expectedAmount);
                    if (best) {
                        tradePath.expectedAmount = expectedAmount;
                        tradePath.sqrtPriceX96AfterList = sqrtPriceX96AfterList;
                        tradePath.initializedTicksCrossedList = initializedTicksCrossedList;
                        tradePath.gasEstimate = gas;
                        tradePath.path = path;
                    }
                }
            }
        }
    }

    function _getAmount(
        uint256 tradeType,
        bytes memory path,
        uint256 amount,
        uint256 bestAmount
    )
        internal
        returns (
            bool best,
            uint256 expectedAmount,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        )
    {
        expectedAmount = bestAmount;
        if (tradeType == Constants.EXACT_INPUT) {
            try quoter.quoteExactInput(path, amount) returns (
                uint256 amountOut,
                uint160[] memory afterList,
                uint32[] memory crossedList,
                uint256 gas
            ) {
                expectedAmount = amountOut;
                sqrtPriceX96AfterList = afterList;
                initializedTicksCrossedList = crossedList;
                gasEstimate = gas;
            } catch {}
        } else if (tradeType == Constants.EXACT_OUTPUT) {
            try quoter.quoteExactOutput(path, amount) returns (
                uint256 amountIn,
                uint160[] memory afterList,
                uint32[] memory crossedList,
                uint256 gas
            ) {
                expectedAmount = amountIn;
                sqrtPriceX96AfterList = afterList;
                initializedTicksCrossedList = crossedList;
                gasEstimate = gas;
            } catch {}
        }

        best =
            (tradeType == Constants.EXACT_INPUT && expectedAmount > bestAmount) ||
            (tradeType == Constants.EXACT_OUTPUT && expectedAmount < bestAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPathFinder {
    struct TradePath {
        bytes path;
        uint256 expectedAmount;
        uint160[] sqrtPriceX96AfterList;
        uint32[] initializedTicksCrossedList;
        uint256 gasEstimate;
    }

    function exactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path);

    function exactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path);

    function bestExactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) external returns (TradePath memory path);

    function bestExactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) external returns (TradePath memory path);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoterV2 {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountIn The desired input amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountOut The desired output amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
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
pragma solidity >=0.8.14;

library Constants {
    // ACTIONS
    uint256 internal constant EXACT_INPUT = 1;
    uint256 internal constant EXACT_OUTPUT = 2;

    // SIZES
    uint256 internal constant NAME_MIN_SIZE = 3;
    uint256 internal constant NAME_MAX_SIZE = 72;

    uint256 internal constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint128 internal constant MAX_UINT128 = type(uint128).max;

    uint256 internal constant BASE_RATIO = 1e4;
}