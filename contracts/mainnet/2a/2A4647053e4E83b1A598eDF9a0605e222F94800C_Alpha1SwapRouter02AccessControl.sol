// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

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

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
}

contract Alpha1SwapRouter02AccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    mapping(address => bool) _tokenWhitelist;

    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    address private constant EMPTY_ADDRESS = address(0);

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // WBTC
        _tokenWhitelist[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = true;
        // WETH
        _tokenWhitelist[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true;
        // USDT
        _tokenWhitelist[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true;
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

    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function decodeFirstPool(bytes memory path, uint256 _start)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = toAddress(path, _start);
        fee = toUint24(path, _start + ADDR_SIZE);
        tokenB = toAddress(path, _start + NEXT_OFFSET);
    }

    function decodePath(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        require(path.length >= POP_OFFSET, "Invalid path");
        bool hasMultiplePools = hasMultiplePools(path);
        if (!hasMultiplePools) {
            return decodeFirstPool(path, 0);
        }
        tokenA = EMPTY_ADDRESS;
        tokenB = EMPTY_ADDRESS;
        fee = 0;
        uint256 start = 0;
        while (true) {
            if (start + NEXT_OFFSET > path.length) {
                break;
            }
            (address _tokenA, address _tokenB, uint24 _fee) = decodeFirstPool(path, start);
            if (tokenA == EMPTY_ADDRESS) {
                tokenA = _tokenA;
            }
            tokenB = _tokenB;
            fee = fee + _fee;
            start = start + NEXT_OFFSET;
        }
    }

    fallback() external {
        revert("Unauthorized access");
    }

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

    function exactOutput(IV3SwapRouter.ExactOutputParams calldata params) external view onlySelf {
        (address tokenOut, address tokenIn, uint24 fee) = decodePath(params.path);
        require(_tokenWhitelist[tokenIn], "Token is not allowed");
        require(_tokenWhitelist[tokenOut], "Token is not allowed");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function exactInput(IV3SwapRouter.ExactInputParams calldata params) external view onlySelf {
        (address tokenOut, address tokenIn, uint24 fee) = decodePath(params.path);
        require(_tokenWhitelist[tokenIn], "Token is not allowed");
        require(_tokenWhitelist[tokenOut], "Token is not allowed");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }
}