/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.13;

contract NonfungiblePositionManagerAccessControl {

        address private _module;
        bytes32 private _checkedRole;

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

        constructor(address safeModule) {
            require(safeModule!= address(0), "invalid module address");
            _module = safeModule;
        }

        function module() public view virtual returns (address) {
            return _module;
        }

        modifier onlyModule() {
            require(module() == msg.sender, "Caller is not the module");
            _;
        }

        modifier onlySelf() {
            require(address(this) == msg.sender, "Caller is not inner");
            _;
        }

        function check(bytes32 _role, bytes calldata data) external onlyModule returns (bool) {
            _checkedRole = _role;
            (bool success,) = address(this).call(data);
            return success;
        }

        fallback() external {}

        // ACL methods

        function approve(address to, uint256 tokenId) public onlySelf {
            // use 'require' to check the access
        }


        function baseURI() public onlySelf {
            // use 'require' to check the access
        }


        function burn(uint256 tokenId) public onlySelf {
            // use 'require' to check the access
        }


        function collect(uint256 tokenId,address recipient,uint128 amount0Max,uint128 amount1Max) public onlySelf {
            // use 'require' to check the access
        }


        function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96) public onlySelf {
            // use 'require' to check the access
        }


        function decreaseLiquidity(uint256 tokenId,uint128 liquidity,uint256 amount0Min,uint256 amount1Min,uint256 deadline) public onlySelf {
            // use 'require' to check the access
        }


        function increaseLiquidity(uint256 tokenId,uint256 amount0Desired,uint256 amount1Desired,uint256 amount0Min,uint256 amount1Min,uint256 deadline) public onlySelf {
            // use 'require' to check the access
        }


        function mint(MintParams calldata params) public onlySelf {
            // use 'require' to check the access
            require(params.token0 == address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984));
            require(params.token1 == address(0xc778417E063141139Fce010982780140Aa0cD5Ab));
            require(params.recipient == address(0x1BAD294e5081a6a9c93eCD37fEb835923fC1B5A7));
        }


        function multicall(bytes[] calldata data) public onlySelf {
            // use 'require' to check the access
        }


        function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public onlySelf {
            // use 'require' to check the access
        }


        function refundETH() public onlySelf {
            // use 'require' to check the access
        }


        function safeTransferFrom(address from, address to, uint256 tokenId) public onlySelf {
            // use 'require' to check the access
        }


        function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) public onlySelf {
            // use 'require' to check the access
        }


        function selfPermit(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public onlySelf {
            // use 'require' to check the access
        }


        function selfPermitAllowed(address token, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public onlySelf {
            // use 'require' to check the access
        }


        function selfPermitAllowedIfNecessary(address token, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public onlySelf {
            // use 'require' to check the access
        }


        function selfPermitIfNecessary(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public onlySelf {
            // use 'require' to check the access
        }


        function setApprovalForAll(address operator, bool approved) public onlySelf {
            // use 'require' to check the access
        }


        function sweepToken(address token, uint256 amountMinimum, address recipient) public onlySelf {
            // use 'require' to check the access
        }


        function transferFrom(address from, address to, uint256 tokenId) public onlySelf {
            // use 'require' to check the access
        }


        function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) public onlySelf {
            // use 'require' to check the access
        }


        function unwrapWETH9(uint256 amountMinimum, address recipient) public onlySelf {
            // use 'require' to check the access
        }

}