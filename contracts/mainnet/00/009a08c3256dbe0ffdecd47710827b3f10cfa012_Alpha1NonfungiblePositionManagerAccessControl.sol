/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;


interface INonfungiblePositionManager {
    
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

        
}
                

contract Alpha1NonfungiblePositionManagerAccessControl {

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

    fallback() external {
        revert("Unauthorized access");
    }

    // ACL methods
    function mint(INonfungiblePositionManager.MintParams calldata params) external view onlySelf {
        require(_tokenWhitelist[params.token0], "Token is not allowed");
        require(_tokenWhitelist[params.token1], "Token is not allowed");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function collect(INonfungiblePositionManager.CollectParams calldata params) external view onlySelf {
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function sweepToken(address token, uint256 amountMinimum, address recipient) external view onlySelf {
        require(recipient == safeAddress, "Recipient is not allowed");
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) external view onlySelf {
        require(recipient == safeAddress, "Recipient is not allowed");
    }

    function increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams calldata params) external view onlySelf {}


    function decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params) external view onlySelf {}


    function refundETH() external view onlySelf {}
}