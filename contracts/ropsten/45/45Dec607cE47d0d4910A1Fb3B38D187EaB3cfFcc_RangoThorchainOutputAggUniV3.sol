// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "ReentrancyGuard.sol";
import "IThorchainRouter.sol";
import "IUniswapV3.sol";
import "IWETH.sol";


contract RangoThorchainOutputAggUniV3 is ReentrancyGuard {
    IWETH public nativeWrappedToken;
    IUniswapV3 public dexRouter;
    uint24 public v3PoolFee;

    constructor(address _nativeWrappedAddress, address _dexRouter, uint24 _v3PoolFee) {
        nativeWrappedToken = IWETH(_nativeWrappedAddress);
        dexRouter = IUniswapV3(_dexRouter);
        v3PoolFee = _v3PoolFee;
    }

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

    //############################## OUT ##############################
    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
//        nativeWrappedToken.deposit{value : msg.value}();
        dexRouter.exactInputSingle(
            IUniswapV3.ExactInputSingleParams(
            {
            tokenIn : address(nativeWrappedToken),
            tokenOut : token,
            fee : v3PoolFee,
            recipient : to,
            deadline : type(uint).max,
            amountIn : msg.value,
            amountOutMinimum : amountOutMin,
            sqrtPriceLimitX96 : 0
            })
        );
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
pragma solidity ^0.8.9;

interface IThorchainRouter {
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint amount,
        string calldata memo,
        uint expiration
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IUniswapV3 {
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

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}