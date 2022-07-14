// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;


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
        
}
                

// for cobo safe module v0.4.0
contract NonfungiblePositionManagerWithValueAccessControl {

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
//        // WETH
//        _tokenWhitelist[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true;
//        // BIT
//        _tokenWhitelist[0x1A4b46696b2bB4794Eb3D4c26f1c55F9170fa4C5] = true;
        // WETH
        _tokenWhitelist[0xc778417E063141139Fce010982780140Aa0cD5Ab] = true;
        // WBTC
        _tokenWhitelist[0x577D296678535e4903D59A4C929B718e1D575e0A] = true;
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
        require(_checkedValue == 0, "invalid value");
    }

    // ACL methods

    function mint(INonfungiblePositionManager.MintParams calldata params) external view onlySelf {
        require(_checkedValue == 0, "Invalid value");
        require(_tokenWhitelist[params.token0], "Token is not allowed");
        require(_tokenWhitelist[params.token1], "Token is not allowed");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function collect(INonfungiblePositionManager.CollectParams calldata params) external view onlySelf {
        require(_checkedValue == 0, "Invalid value");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function sweepToken(address token, uint256 amountMinimum, address recipient) external view onlySelf {
        require(_checkedValue == 0, "Invalid value");
        require(recipient == safeAddress, "Recipient is not allowed");
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) external view onlySelf {
        require(_checkedValue == 0, "Invalid value");
        require(recipient == safeAddress, "Recipient is not allowed");
    }

}