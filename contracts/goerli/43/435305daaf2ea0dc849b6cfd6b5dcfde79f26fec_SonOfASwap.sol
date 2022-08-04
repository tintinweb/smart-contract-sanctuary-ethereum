// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

// V3 SwapRouter
// import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
// V2V3 SwapRouter
import "@uniswap/swap-router-contracts/contracts/interfaces/ISwapRouter02.sol";
import "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";

struct SwapOrder {
    address router;
    uint256 amountIn;
    uint256 amountOut;
    string tradeType; // enum? // "v3_exactInputSingle" | "v3_exactOutputSingle" | "v3_exactInput" | "v3_exactOutput" | "v2_swapExactTokensForTokens" | "v2_swapTokensForExactTokens"
    address recipient;
    address[] path;
    uint256 deadline;
    // v3
    uint256 sqrtPriceLimitX96; // uint160 represented as uint256 for golang compatibility // TODO: remove casting (fix golang lib)
    uint256 fee; // uint24 represented as uint256 for golang compatibility // TODO: remove casting (fix golang lib)
    // TODO: use fee[] since pools in the path might have different fees
    uint256 nonce;
}

contract SonOfASwap {
    uint256 public status;
    address private owner;
    mapping(address => uint256) public nonces;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    string private constant EIP712_DOMAIN =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    string private constant SWAPORDER =
        "SwapOrder(address router,uint256 amountIn,uint256 amountOut,string tradeType,address recipient,address[] path,uint deadline,uint256 sqrtPriceLimitX96,uint256 fee,uint256 nonce)";

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant SWAPORDER_TYPEHASH =
        keccak256(abi.encodePacked(SWAPORDER));

    bytes32 private DOMAIN_SEPARATOR;

    function getChainID() internal pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    constructor() {
        owner = msg.sender;
        status = 0;
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: "SonOfASwap",
                version: "1",
                chainId: getChainID(),
                verifyingContract: address(this)
            })
        );
    }

    receive() external payable {}

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function hash(SwapOrder memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SWAPORDER_TYPEHASH,
                    order.router,
                    order.amountIn,
                    order.amountOut,
                    keccak256(bytes(order.tradeType)),
                    order.recipient,
                    keccak256(abi.encodePacked(order.path)),
                    order.deadline,
                    order.sqrtPriceLimitX96,
                    order.fee,
                    order.nonce
                )
            );
    }

    function verify(
        SwapOrder memory order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(order))
        );
        address recovered = ecrecover(digest, v, r, s);
        return recovered == order.recipient;
    }

    function stringsEqual(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    /**
    Encodes multihop V3 path.
    https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps
    */
    function encodeMultihopPath(address[] memory path, uint24 fee)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodedPath;
        for (uint256 i = 0; i < path.length; i++) {
            encodedPath = abi.encodePacked(encodedPath, path[i]);
            if (i < path.length - 1) {
                // path = abi.encodePacked(path, fees[i]); // TODO <<
                encodedPath = abi.encodePacked(encodedPath, fee);
            }
        }
        return encodedPath;
    }

    function sendOrder(SwapOrder memory order) internal {
        // instantiate router interface
        ISwapRouter02 router = ISwapRouter02(order.router);
        // instantiate input token interface
        IERC20 tokenIn = IERC20(order.path[0]);

        // transfer input token from user to (this)
        tokenIn.transferFrom(order.recipient, address(this), order.amountIn);
        // TODO: deal with refunds due to slippage (and later, realized MEV)

        // approve router to spend (this) tokenIn
        tokenIn.approve(order.router, order.amountIn);

        // choose router method based on order type
        if (stringsEqual(order.tradeType, "v3_exactInputSingle")) {
            // encode function params based on order
            IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
                .ExactInputSingleParams(
                    order.path[0], // tokenIn
                    order.path[1], // tokenOut
                    uint24(order.fee), // fee
                    order.recipient, // recipient
                    // order.deadline, // deadline
                    order.amountIn, // amountIn
                    order.amountOut, // amountOutMinimum
                    uint160(order.sqrtPriceLimitX96) // sqrtPriceLimitX96
                );

            // send order to router
            router.exactInputSingle{value: 0x0}(params);
        } else if (stringsEqual(order.tradeType, "v3_exactOutputSingle")) {
            IV3SwapRouter.ExactOutputSingleParams memory params = IV3SwapRouter
                .ExactOutputSingleParams(
                    order.path[0], // tokenIn
                    order.path[1], // tokenOut
                    uint24(order.fee), // fee
                    order.recipient, // recipient
                    // order.deadline, // deadline
                    order.amountOut, // amountOut
                    order.amountIn, // amountInMaximum
                    uint160(order.sqrtPriceLimitX96) // sqrtPriceLimitX96
                );

            router.exactOutputSingle{value: 0x0}(params);
        } else if (stringsEqual(order.tradeType, "v3_exactInput")) {
            IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
                .ExactInputParams(
                    encodeMultihopPath(order.path, uint24(order.fee)), // path
                    order.recipient, // recipient
                    // order.deadline, // deadline
                    order.amountIn, // amountIn
                    order.amountOut // amountOutMinimum
                );
            router.exactInput{value: 0x0}(params);
        } else if (stringsEqual(order.tradeType, "v3_exactOutput")) {
            IV3SwapRouter.ExactOutputParams memory params = IV3SwapRouter
                .ExactOutputParams(
                    encodeMultihopPath(order.path, uint24(order.fee)), // path
                    order.recipient, // recipient
                    // order.deadline, // deadline
                    order.amountOut, // amountOut
                    order.amountIn // amountInMaximum
                );
            router.exactOutput{value: 0x0}(params);
        } else if (
            stringsEqual(order.tradeType, "v2_swapExactTokensForTokens")
        ) {
            router.swapExactTokensForTokens{value: 0x0}(
                order.amountIn, // amountIn
                order.amountOut, // amountOutMin
                order.path, // path
                order.recipient // to
            );
        } else if (
            stringsEqual(order.tradeType, "v2_swapTokensForExactTokens")
        ) {
            router.swapTokensForExactTokens{value: 0x0}(
                order.amountOut, // amountOut
                order.amountIn, // amountInMax
                order.path, // path
                order.recipient // to
            );
        } else {
            revert("METHOD_DNE");
        }
    }

    function verifyAndSend(
        SwapOrder memory order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(verify(order, v, r, s), "invalid signature");
        if (order.nonce == nonces[order.recipient]) {
            sendOrder(order);
            nonces[order.recipient] += 1;
        } else {
            revert("INVALID_NONCE");
        }
    }

    // liquidate assets from this contract (for testing purposes only)
    function liquidate(address tokenAddress) public {
        require(msg.sender == owner);
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISelfPermit.sol';

import './IV2SwapRouter.sol';
import './IV3SwapRouter.sol';
import './IApproveAndCall.sol';
import './IMulticallExtended.sol';

/// @title Router token swapping functionality
interface ISwapRouter02 is IV2SwapRouter, IV3SwapRouter, IApproveAndCall, IMulticallExtended, ISelfPermit {

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.7.5;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token
    /// @param amountOut The amount of token to swap for
    /// @param amountInMax The maximum amount of input that the caller will pay
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountIn The amount of token to pay
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

interface IApproveAndCall {
    enum ApprovalType {NOT_REQUIRED, MAX, MAX_MINUS_ONE, ZERO_THEN_MAX, ZERO_THEN_MAX_MINUS_ONE}

    /// @dev Lens to be called off-chain to determine which (if any) of the relevant approval functions should be called
    /// @param token The token to approve
    /// @param amount The amount to approve
    /// @return The required approval type
    function getApprovalType(address token, uint256 amount) external returns (ApprovalType);

    /// @notice Approves a token for the maximum possible amount
    /// @param token The token to approve
    function approveMax(address token) external payable;

    /// @notice Approves a token for the maximum possible amount minus one
    /// @param token The token to approve
    function approveMaxMinusOne(address token) external payable;

    /// @notice Approves a token for zero, then the maximum possible amount
    /// @param token The token to approve
    function approveZeroThenMax(address token) external payable;

    /// @notice Approves a token for zero, then the maximum possible amount minus one
    /// @param token The token to approve
    function approveZeroThenMaxMinusOne(address token) external payable;

    /// @notice Calls the position manager with arbitrary calldata
    /// @param data Calldata to pass along to the position manager
    /// @return result The result from the call
    function callPositionManager(bytes memory data) external payable returns (bytes memory result);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
    }

    /// @notice Calls the position manager's mint function
    /// @param params Calldata to pass along to the position manager
    /// @return result The result from the call
    function mint(MintParams calldata params) external payable returns (bytes memory result);

    struct IncreaseLiquidityParams {
        address token0;
        address token1;
        uint256 tokenId;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    /// @notice Calls the position manager's increaseLiquidity function
    /// @param params Calldata to pass along to the position manager
    /// @return result The result from the call
    function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable returns (bytes memory result);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol';

/// @title MulticallExtended interface
/// @notice Enables calling multiple methods in a single call to the contract with optional validation
interface IMulticallExtended is IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param deadline The time by which this function must be called before failing
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(uint256 deadline, bytes[] calldata data) external payable returns (bytes[] memory results);

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param previousBlockhash The expected parent blockHash
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes32 previousBlockhash, bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
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

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}