/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

interface IV3SwapRouter {

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
}

contract Alpha1SwapRouter02AccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    mapping(address => bool) _tokenWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // WBTC
        _tokenWhitelist[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = true;
        // WETH
        _tokenWhitelist[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true;
        // USDC
        _tokenWhitelist[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    function check(bytes32 _role, uint256 _value, bytes calldata data) external onlyModule returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        (bool success,) = address(this).staticcall(data);
        return success;
    }

    fallback() external {
        revert("Unauthorized access");
    }

    // ACL methods

    function exactInputSingle(IV3SwapRouter.ExactInputSingleParams calldata params) external view onlySelf {
        require(_tokenWhitelist[params.tokenIn], "Token is not allowed");
        require(_tokenWhitelist[params.tokenOut], "Token is not allowed");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function exactOutputSingle(IV3SwapRouter.ExactOutputSingleParams calldata params) external view onlySelf {
        require(_tokenWhitelist[params.tokenIn], "Token is not allowed");
        require(_tokenWhitelist[params.tokenOut], "Token is not allowed");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }
}