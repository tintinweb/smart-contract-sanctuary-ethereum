pragma solidity ^0.7.6;
pragma abicoder v2;

import "account.sol";
import "ISwapRouter.sol";
import {ISushiSwapRouter} from "sushiswap.sol";

contract Fallback {
    address private usdc;
    address private weth;
    ISushiSwapRouter private sushiswap_router;

    constructor(address _usdc, address _weth, address _sushiswap_router) {
        usdc = _usdc;
        weth = _weth;
        sushiswap_router = ISushiSwapRouter(_sushiswap_router);
    }

    function decode(uint start_byte, uint length) private pure returns (uint) {
        require(length + start_byte <= msg.data.length, "trying to read beyond calldata size");

        uint decoded;

        assembly {
            decoded := calldataload(start_byte)
        }

        decoded = decoded >> (256 - length * 8);
        return decoded;
    }

    function uniswap(address from_token, address to_token, uint24 pool_fee, uint from_amount, uint min_return_amount) private {
        // duplicated with uniswap.sol
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564).exactInputSingle(
            // this requires abicoder v2
            ISwapRouter.ExactInputSingleParams({
                    tokenIn: from_token,
                    tokenOut: to_token,
                    fee: pool_fee,
                    recipient: address(this),
                    deadline: 115792089237316195423570985008687907853269984665640564039457584007913129639935,
                    amountIn: from_amount,
                    amountOutMinimum: min_return_amount,
                    sqrtPriceLimitX96: 0
                })
        );
    }

    function sushiswap(address from_token, address to_token, uint from_amount, uint min_return_amount) private {
        address[] memory path = new address[](2);
        path[0] = from_token;
        path[1] = to_token;

        sushiswap_router.swapExactTokensForTokens(
            from_amount,
            min_return_amount,
            path,
            address(this),
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
    }

    function usdc_to_wei(uint start_byte) private pure returns (uint) {
        uint amount_length = 4;
        return decode(start_byte, amount_length) * 1e2;
    }

    function weth_to_wei(uint start_byte) private pure returns (uint) {
        uint amount_length = 4;
        return decode(start_byte, amount_length) * 1e14;
    }

    fallback() external {
        uint method;
        uint from_amount;
        uint min_return_amount;
        // 0.05% pool fee
        uint24 pool_fee_005 = 500;
        // 0.3% pool fee
        uint24 pool_fee_03 = 3000;
        uint amount_length = 4;

        method = decode(0, 1);

        // Methods meanings are in constants.py
        if (method == 1) {
            // Uniswap 0.05% USDC -> WETH
            // convert amount to wei. Reduce 1e4 because we have already zoomed it when encoding
            from_amount = usdc_to_wei(1);
            min_return_amount = weth_to_wei(5);
            return uniswap(usdc, weth, pool_fee_005, from_amount, min_return_amount);
        } else if (method == 2) {
            // Uniswap 0.05% WETH -> USDC
            from_amount = weth_to_wei(1);
            min_return_amount = usdc_to_wei(5);
            return uniswap(weth, usdc, pool_fee_005, from_amount, min_return_amount);
        }  else if (method == 10) {
            // Sushiswap USDC -> WETH
            from_amount = usdc_to_wei(1);
            min_return_amount = weth_to_wei(5);
            return sushiswap(usdc, weth, from_amount, min_return_amount);
        } else if (method == 11) {
            // Sushiswap WETH -> USDC
            from_amount = weth_to_wei(1);
            min_return_amount = usdc_to_wei(5);
            return sushiswap(weth, usdc, from_amount, min_return_amount);
        } else {
            revert('invalid method');
        }
    }
}

pragma solidity ^0.7.6;
pragma abicoder v2;

contract Account {
    mapping(address => bool) private authers;
    mapping(address => mapping(address => bool)) private withdrawal_addresses;
    uint private _auther_num = 1;

    constructor() {
        authers[msg.sender] = true;
    }

    modifier only_auther() {
        require(is_auther(), 'Caller is not auther');
        _;
    }

    function is_auther() public view returns (bool) {
        return authers[msg.sender];
    }

    function can_withdraw(address token, address user) public view returns (bool) {
        return authers[user] || withdrawal_addresses[token][user];
    }

    function add_withdrawal_address(address token, address user) external only_auther {
        withdrawal_addresses[token][user] = true;
    }

    function remove_withdrawal_address(address token, address user) external only_auther {
        delete withdrawal_addresses[token][user];
    }

    function add_auther(address user) external only_auther {
        require(!authers[user], 'User is already auther');
        authers[user] = true;
        _auther_num += 1;
    }

    function remove_auther(address user) external only_auther {
        require(_auther_num > 1, 'Can not remove last auther');
        delete authers[user];
        _auther_num -= 1;
    }


    // @notice Delegate contract call to other contract
    // @param target Target contract address.
    // @param data CallData of target contract.
    // add `payable` to save gas
    function d_call(address target, bytes memory data) public payable only_auther {
        // assembly doc: https://docs.soliditylang.org/en/v0.4.24/assembly.html
        assembly {
            let succeeded := delegatecall(gas(), target, add(data, 0x20), mload(data), 0, 0)

            switch iszero(succeeded)
            case 1 {
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                // throw if delegatecall failed
                revert(0x00, size)
            }
        }
    }

    // `bytes[] calldata data_list` requires pragma abicoder v2;
    function multiple_d_calls(address[] calldata targets, bytes[] calldata data_list) external payable only_auther {
        for (uint i = 0; i < targets.length; i++) {
            d_call(targets[i], data_list[i]);
        }
    }

    // same as delegatecall except using call instead of delegatecall
    function single_call(address target, bytes memory data) public payable only_auther {
        assembly {
            let succeeded := call(gas(), target, 0, add(data, 0x20), mload(data), 0, 0)

            switch iszero(succeeded)
            case 1 {
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                // throw if delegatecall failed
                revert(0x00, size)
            }
        }
    }

    function multiple_calls(address[] calldata targets, bytes[] calldata data_list) external payable only_auther {
        for (uint i = 0; i < targets.length; i++) {
            single_call(targets[i], data_list[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "IUniswapV3SwapCallback.sol";

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

pragma solidity ^0.7.6;

interface ISushiSwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}