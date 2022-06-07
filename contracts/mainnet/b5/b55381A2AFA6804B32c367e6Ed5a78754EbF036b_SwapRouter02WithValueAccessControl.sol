// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

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

// for cobo safe module v0.3.0
contract SwapRouter02AccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;

    mapping(address => bool) _tokenWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // WETH
        _tokenWhitelist[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true;
        // BIT
        _tokenWhitelist[0x1A4b46696b2bB4794Eb3D4c26f1c55F9170fa4C5] = true;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    function check(bytes32 _role, bytes calldata data) external onlyModule returns (bool) {
        _checkedRole = _role;
        (bool success,) = address(this).staticcall(data);
        return success;
    }

    fallback() external {}

    // ACL methods

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to) external view onlySelf {
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }
            

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to) external view onlySelf {
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }

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

// for cobo safe module v0.4.0
contract SwapRouter02WithValueAccessControl {

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
        // WETH
        _tokenWhitelist[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true;
        // BIT
        _tokenWhitelist[0x1A4b46696b2bB4794Eb3D4c26f1c55F9170fa4C5] = true;
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

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to) external view onlySelf {
        require(_checkedValue == 0, "Invalid value");
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }


    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to) external view onlySelf {
        require(_checkedValue == 0, "Invalid value");
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }

    function exactInputSingle(IV3SwapRouter.ExactInputSingleParams calldata params) external view onlySelf {
        require(_checkedValue == 0, "Invalid value");
        require(_tokenWhitelist[params.tokenIn], "Token is not allowed");
        require(_tokenWhitelist[params.tokenOut], "Token is not allowed");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function exactOutputSingle(IV3SwapRouter.ExactOutputSingleParams calldata params) external view onlySelf {
        require(_checkedValue == 0, "Invalid value");
        require(_tokenWhitelist[params.tokenIn], "Token is not allowed");
        require(_tokenWhitelist[params.tokenOut], "Token is not allowed");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

}