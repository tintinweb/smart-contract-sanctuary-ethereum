// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract Converter {

    // Uniswap SwapRouter02
    // Ethereum: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Rinkeby: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    address public constant SwapRouter02 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    // Ethereum: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // Rinkeby: 0xc778417E063141139Fce010982780140Aa0cD5Ab
    address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    function deposit(uint256 amount) external payable {
        assembly {
            // selector for deposit()
            mstore(0, 0xd0e30db000000000000000000000000000000000000000000000000000000000)
            if iszero(call(gas(), WETH, amount, 0, 0x4, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /// WETH.withdraw(amount)
    function withdraw(uint256 /* amount */) external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())
            if iszero(call(gas(), WETH, 0, 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function multicall(uint256 ethAmount, bytes[] calldata /* data */) external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            // Set the deadline to block.timestamp
            mstore(0x4, timestamp())

            // SwapRouter02.multicall{value: ethAmount}(deadline, data)
            if iszero(call(gas(), SwapRouter02, ethAmount, 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingleEx(uint256 ethAmount, ExactInputSingleParams calldata /* params */) external payable {
        assembly {
            // selector for SwapRouter02.exactInputSingle(params)
            mstore(0, 0x04e45aaf00000000000000000000000000000000000000000000000000000000)

            // Copy params to memory 0x4.
            // 0xe0 == 7 * 0x20
            calldatacopy(0x4, 0x24, 0xe0)

            // SwapRouter02.exactInputSingle{value:ethAmount}(params)
            if iszero(call(gas(), SwapRouter02, ethAmount, 0, 0xe4, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}