pragma solidity ^0.8.14;

contract SushiswapV2Router02ACL {
    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping(address => bool) _tokenWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        _tokenWhitelist[usdc] = true;
        _tokenWhitelist[weth] = true;
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
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }
}