/**
 *Submitted for verification at Etherscan.io on 2022-11-18
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

interface AggregatorV3Interface {
    function latestRoundData() external view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract Alpha1SwapRouter02AccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    mapping(address => bool) _tokenWhitelist;
    mapping(address => address) _tokenAggregator;

    uint256 private constant SLIPPAGE_BASE = 10000;
    uint256 private _maxSlippagePercent = 200;

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
        _tokenAggregator[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;

        // USDC
        _tokenWhitelist[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true;
        _tokenAggregator[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    modifier onlySafe() {
        require(safeAddress == msg.sender, "Caller is not the safe");
        _;
    }

    function check(bytes32 _role, uint256 _value, bytes calldata data) external onlyModule returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        (bool success,) = address(this).staticcall(data);
        return success;
    }
    
    function setMaxSlippagePercent(uint256 maxSlippagePercent) external onlySafe {
        require(maxSlippagePercent >= 0 && maxSlippagePercent <= SLIPPAGE_BASE, "invalid max slippage percent");
        _maxSlippagePercent = maxSlippagePercent;
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

    function getPrice(address token) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_tokenAggregator[token]);
        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(price > 0, "Chainlink: price <= 0");
        require(answeredInRound >= roundId, "Chainlink: answeredInRound <= roundId");
        require(updatedAt > 0, "Chainlink: updatedAt <= 0");
        return uint256(price) * (10 ** (18 - priceFeed.decimals()));
    }

    function decodePath(bytes memory path)
        internal
        view
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
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");

        // check swap slippage
        uint256 priceInput = getPrice(path[0]);
        uint256 priceOutput = getPrice(path[path.length - 1]);
        uint256 valueInput = amountIn * priceInput / (10 ** IERC20(path[0]).decimals());
        uint256 valueOutput = amountOutMin * priceOutput / (10 ** IERC20(path[path.length - 1]).decimals());
        require(valueOutput >= valueInput * (SLIPPAGE_BASE - _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");

        require(to == safeAddress, "To address is not allowed");
    }

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to) external view onlySelf {
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");

        // check swap slippage
        uint256 priceInput = getPrice(path[0]);
        uint256 priceOutput = getPrice(path[path.length - 1]);
        uint256 valueInput = amountInMax * priceInput / (10 ** IERC20(path[0]).decimals());
        uint256 valueOutput = amountOut * priceOutput / (10 ** IERC20(path[path.length - 1]).decimals());
        require(valueInput <= valueOutput * (SLIPPAGE_BASE + _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");

        require(to == safeAddress, "To address is not allowed");
    }

    function exactInputSingle(IV3SwapRouter.ExactInputSingleParams calldata params) external view onlySelf {
        require(_tokenWhitelist[params.tokenIn], "Token is not allowed");
        require(_tokenWhitelist[params.tokenOut], "Token is not allowed");

        // check swap slippage
        uint256 priceInput = getPrice(params.tokenIn);
        uint256 priceOutput = getPrice(params.tokenOut);
        uint256 valueInput = params.amountIn * priceInput / (10 ** IERC20(params.tokenIn).decimals());
        uint256 valueOutput = params.amountOutMinimum * priceOutput / (10 ** IERC20(params.tokenOut).decimals());
        require(valueOutput >= valueInput * (SLIPPAGE_BASE - _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");

        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function exactOutputSingle(IV3SwapRouter.ExactOutputSingleParams calldata params) external view onlySelf {
        require(_tokenWhitelist[params.tokenIn], "Token is not allowed");
        require(_tokenWhitelist[params.tokenOut], "Token is not allowed");

        // check swap slippage
        uint256 priceInput = getPrice(params.tokenIn);
        uint256 priceOutput = getPrice(params.tokenOut);
        uint256 valueInput = params.amountInMaximum * priceInput / (10 ** IERC20(params.tokenIn).decimals());
        uint256 valueOutput = params.amountOut * priceOutput / (10 ** IERC20(params.tokenOut).decimals());
        require(valueInput <= valueOutput * (SLIPPAGE_BASE + _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");

        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function exactOutput(IV3SwapRouter.ExactOutputParams calldata params) external view onlySelf {
        (address tokenIn, address tokenOut, uint24 fee) = decodePath(params.path);
        require(_tokenWhitelist[tokenIn], "Token is not allowed");
        require(_tokenWhitelist[tokenOut], "Token is not allowed");

        // check swap slippage
        uint256 priceInput = getPrice(tokenIn);
        uint256 priceOutput = getPrice(tokenOut);
        uint256 valueInput = params.amountInMaximum * priceInput / (10 ** IERC20(tokenIn).decimals());
        uint256 valueOutput = params.amountOut * priceOutput / (10 ** IERC20(tokenOut).decimals());
        require(valueInput <= valueOutput * (SLIPPAGE_BASE + _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");

        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function exactInput(IV3SwapRouter.ExactInputParams calldata params) external view onlySelf {
        (address tokenIn, address tokenOut, uint24 fee) = decodePath(params.path);
        require(_tokenWhitelist[tokenIn], "Token is not allowed");
        require(_tokenWhitelist[tokenOut], "Token is not allowed");

        // check swap slippage
        uint256 priceInput = getPrice(tokenIn);
        uint256 priceOutput = getPrice(tokenOut);
        uint256 valueInput = params.amountIn * priceInput / (10 ** IERC20(tokenIn).decimals());
        uint256 valueOutput = params.amountOutMinimum * priceOutput / (10 ** IERC20(tokenOut).decimals());
        require(valueOutput >= valueInput * (SLIPPAGE_BASE - _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");

        require(params.recipient == safeAddress, "Recipient is not allowed");
    }
}