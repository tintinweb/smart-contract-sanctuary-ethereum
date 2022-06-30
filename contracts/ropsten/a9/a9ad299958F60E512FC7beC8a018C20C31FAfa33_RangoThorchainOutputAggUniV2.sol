// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../../interfaces/IThorchainRouter.sol";
import "../../../interfaces/IUniswapV2.sol";

/// @title Contract to handle thorchain output and pass it to a dex that implements UniV2 interface.
/// @author Thinking Particle
/// @notice Thorchain provides native token on destination chain. To swap it to desired token, this contract passes the native token to a dex.
/// @dev Thorchain only provides the desired token and the minimum amount to be received. Therefore, we cannot implement a single contract that supports all dexes. Instead we should deploy multiple instances of this contract for each dex and find the best one when creating the input transaction.
contract RangoThorchainOutputAggUniV2 is ReentrancyGuard {
    /// @dev wrapped native token contract address
    address public nativeWrappedAddress;
    /// @dev router contract address which implements UniswapV2 router
    IUniswapV2 public dexRouter;

    /// @param _nativeWrappedAddress wrapped native token contract address
    /// @param _dexRouter router contract address which implements UniswapV2 router
    constructor(address _nativeWrappedAddress, address _dexRouter) {
        nativeWrappedAddress = _nativeWrappedAddress;
        dexRouter = IUniswapV2(_dexRouter);
    }

    /// @dev This contract is only implemented to handle for swap output of thorchain. Therefore swapIn function is implemented as a revert to make sure that it won't be called as swapIn handler.
    function swapIn(
        address tcRouter,
        address tcVault,
        string calldata tcMemo,
        address token,
        uint amount,
        uint amountOutMin,
        uint deadline
    ) public nonReentrant {
        revert("this contract only supports swapOut");
    }

    /// @notice This function is called by thorchain nodes. It receives native token and swaps it to the desired token using the dex.
    /// @dev This function creates a simple 1 step path for uniswap v2 router. Note that this function can be called by anyone including (thorchain nodes).
    /// @param token The desired token contract address
    /// @param to The wallet address should receive the output.
    /// @param amountOutMin The minimum output amount below which the swap is invalid.
    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        address[] memory path = new address[](2);
        path[0] = nativeWrappedAddress;
        path[1] = token;
        dexRouter.swapExactETHForTokens{value : msg.value}(amountOutMin, path, to, type(uint).max);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev based on thorchain router https://gitlab.com/thorchain/ethereum/eth-router/-/blob/29b59c2d6c6fc7a65d6bbc0f80d90694ac4122f8/contracts/THORChain_Aggregator.sol#L12
interface IThorchainRouter {
    /// @param vault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param asset The token contract address (if token is native, should be 0x0000000000000000000000000000000000000000)
    /// @param amount The amount of token to be swapped. It should be positive and if token is native, msg.value should be bigger than amount.
    /// @param memo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint amount,
        string calldata memo,
        uint expiration
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

/// @dev based on swap router of uniswap v2 https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#swapexactethfortokens
interface IUniswapV2 {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}