// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;


interface IV3SwapRouter {
    
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
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
        

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
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
                

interface IApproveAndCall {
    
    struct IncreaseLiquidityParams {
        address token0;
        address token1;
        uint256 tokenId;
        uint256 amount0Min;
        uint256 amount1Min;
    }
        

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
    }
        
}
                

contract SwapRouter02AccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
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

    
    function approveMax(address token) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function approveMaxMinusOne(address token) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function approveZeroThenMax(address token) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function approveZeroThenMaxMinusOne(address token) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function callPositionManager(bytes calldata data) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function exactInput(IV3SwapRouter.ExactInputParams calldata params) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function exactInputSingle(IV3SwapRouter.ExactInputSingleParams calldata params) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function exactOutput(IV3SwapRouter.ExactOutputParams calldata params) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function exactOutputSingle(IV3SwapRouter.ExactOutputSingleParams calldata params) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function getApprovalType(address token, uint256 amount) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function increaseLiquidity(IApproveAndCall.IncreaseLiquidityParams calldata params) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function mint(IApproveAndCall.MintParams calldata params) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function multicall(bytes32 previousBlockhash, bytes[] calldata data) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function multicall(uint256 deadline, bytes[] calldata data) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function multicall(bytes[] calldata data) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function pull(address token, uint256 value) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function refundETH() external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function selfPermit(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function selfPermitAllowed(address token, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function selfPermitAllowedIfNecessary(address token, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function selfPermitIfNecessary(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function sweepToken(address token, uint256 amountMinimum, address recipient) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function sweepToken(address token, uint256 amountMinimum) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function sweepTokenWithFee(address token, uint256 amountMinimum, uint256 feeBips, address feeRecipient) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function sweepTokenWithFee(address token, uint256 amountMinimum, address recipient, uint256 feeBips, address feeRecipient) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function unwrapWETH9(uint256 amountMinimum, address recipient) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function unwrapWETH9(uint256 amountMinimum) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function unwrapWETH9WithFee(uint256 amountMinimum, address recipient, uint256 feeBips, address feeRecipient) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function unwrapWETH9WithFee(uint256 amountMinimum, uint256 feeBips, address feeRecipient) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            

    function wrapETH(uint256 value) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
    }
            
}