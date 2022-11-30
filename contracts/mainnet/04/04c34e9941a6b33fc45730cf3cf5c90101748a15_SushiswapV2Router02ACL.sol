/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

pragma solidity ^0.8.17;

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

contract SushiswapV2Router02ACL {
    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    mapping(address => bool) _tokenWhitelist;
    mapping(address => address) _tokenAggregator;

    uint256 private constant SLIPPAGE_BASE = 10000;
    uint256 private _maxSlippagePercent = 200;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        _tokenWhitelist[usdc] = true;
        _tokenAggregator[usdc] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
        _tokenWhitelist[weth] = true;
        _tokenAggregator[weth] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        _tokenWhitelist[sushi] = true;
        _tokenAggregator[sushi] = 0xCc70F09A6CC17553b2E31954cD36E4A2d89501f7;
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

    fallback() external {
        revert("Unauthorized access");
    }

    function setMaxSlippagePercent(uint256 maxSlippagePercent) external onlySafe {
        require(maxSlippagePercent >= 0 && maxSlippagePercent <= SLIPPAGE_BASE, "invalid max slippage percent");
        _maxSlippagePercent = maxSlippagePercent;
    }

    function getPrice(address _token) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_tokenAggregator[_token]);
        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(price > 0, "Chainlink: price <= 0");
        require(answeredInRound >= roundId, "Chainlink: answeredInRound <= roundId");
        require(updatedAt > 0, "Chainlink: updatedAt <= 0");
        return uint256(price) * (10 ** (18 - priceFeed.decimals()));
    }

    // ===== ACL Function =====
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_tokenWhitelist[tokenA], "Token is not allowed");
        require(_tokenWhitelist[tokenB], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }

    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_tokenWhitelist[tokenA], "Token is not allowed");
        require(_tokenWhitelist[tokenB], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to,uint256 deadline) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
        // check swap slippage
        uint256 priceInput = getPrice(path[0]);
        uint256 priceOutput = getPrice(path[path.length - 1]);
        uint256 valueInput = amountIn * priceInput / (10 ** IERC20(path[0]).decimals());
        uint256 valueOutput = amountOutMin * priceOutput / (10 ** IERC20(path[path.length - 1]).decimals());
        require(valueOutput >= valueInput * (SLIPPAGE_BASE - _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");
    }

    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
        // check swap slippage
        uint256 priceInput = getPrice(path[0]);
        uint256 priceOutput = getPrice(path[path.length - 1]);
        uint256 valueInput = amountInMax * priceInput / (10 ** IERC20(path[0]).decimals());
        uint256 valueOutput = amountOut * priceOutput / (10 ** IERC20(path[path.length - 1]).decimals());
        require(valueInput <= valueOutput * (SLIPPAGE_BASE + _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external view onlySelf {
        require(_checkedValue != 0, "invalid value");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
        // check swap slippage
        uint256 priceInput = getPrice(path[0]);
        uint256 priceOutput = getPrice(path[path.length - 1]);
        uint256 valueInput = _checkedValue * priceInput / (10 ** IERC20(path[0]).decimals());
        uint256 valueOutput = amountOutMin * priceOutput / (10 ** IERC20(path[path.length - 1]).decimals());
        require(valueOutput >= valueInput * (SLIPPAGE_BASE - _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");
    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external view onlySelf {
        require(_checkedValue != 0, "invalid value");
        require(path.length == 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
        // check swap slippage
        uint256 priceInput = getPrice(path[0]);
        uint256 priceOutput = getPrice(path[path.length - 1]);
        uint256 valueInput = _checkedValue * priceInput / (10 ** IERC20(path[0]).decimals());
        uint256 valueOutput = amountOut * priceOutput / (10 ** IERC20(path[path.length - 1]).decimals());
        require(valueInput <= valueOutput * (SLIPPAGE_BASE + _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
        // check swap slippage
        uint256 priceInput = getPrice(path[0]);
        uint256 priceOutput = getPrice(path[path.length - 1]);
        uint256 valueInput = amountIn * priceInput / (10 ** IERC20(path[0]).decimals());
        uint256 valueOutput = amountOutMin * priceOutput / (10 ** IERC20(path[path.length - 1]).decimals());
        require(valueOutput >= valueInput * (SLIPPAGE_BASE - _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
        // check swap slippage
        uint256 priceInput = getPrice(path[0]);
        uint256 priceOutput = getPrice(path[path.length - 1]);
        uint256 valueInput = amountInMax * priceInput / (10 ** IERC20(path[0]).decimals());
        uint256 valueOutput = amountOut * priceOutput / (10 ** IERC20(path[path.length - 1]).decimals());
        require(valueInput <= valueOutput * (SLIPPAGE_BASE + _maxSlippagePercent) / SLIPPAGE_BASE, "Slippage is too high");
    }

    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external view onlySelf {
        require(_checkedValue != 0, "invalid value");
        require(_tokenWhitelist[token], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_tokenWhitelist[token], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }
}