/**
 *Submitted for verification at Etherscan.io on 2022-11-15
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

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract Alpha1SwapRouter02AccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    mapping(address => bool) _pairWhitelist;
    mapping(address => bool) _poolWhitelist;

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
    
        // Top pairs: https://v2.info.uniswap.org/pairs
        // USDC-ETH
        _pairWhitelist[0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc] = true;
        // ETH-USDT
        _pairWhitelist[0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852] = true;
        // USDC-USDT
        _pairWhitelist[0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f] = true;


        // Top pools: https://info.uniswap.org/#/pools
        // WBTC-ETH-0.3%
        _poolWhitelist[0xCBCdF9626bC03E24f779434178A73a0B4bad62eD] = true;
        // WBTC-ETH-0.05%
        _poolWhitelist[0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0] = true;
        // USDC-ETH-0.3%
        _poolWhitelist[0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8] = true;
        // USDC-ETH-0.05%
        _poolWhitelist[0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640] = true;
        // USDC-USDT-0.01%
        _poolWhitelist[0x3416cF6C708Da44DB2624D63ea0AAef7113527C6] = true;
        // ETH-USDT-0.3%
        _poolWhitelist[0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36] = true;
        // WBTC-USDC-0.3%
        _poolWhitelist[0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35] = true;
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

    // get pool addr from uniswap v3 factory
    function getPool(address tokenA, address tokenB, uint24 fee) internal view returns (address pool) {
        pool = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984).getPool(tokenA, tokenB, fee);
    }

    // get pair addr from uniswap v2 factory
    function getPair(address tokenA, address tokenB) internal view returns (address pair) {
        pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).getPair(tokenA, tokenB);
    }

    function checkPath(bytes memory path)
        internal
        view
    {
        address tokenA = EMPTY_ADDRESS;
        address tokenB = EMPTY_ADDRESS;
        uint24 fee = 0;

        require(path.length >= POP_OFFSET, "Invalid path");
        bool hasMultiplePools = hasMultiplePools(path);
        if (!hasMultiplePools) {
            (tokenA, tokenB, fee) = decodeFirstPool(path, 0);
            require(_poolWhitelist[getPool(tokenA, tokenB, fee)], "Invalid pool");
            return;
        }
        uint256 start = 0;
        while (true) {
            if (start + NEXT_OFFSET > path.length) {
                break;
            }
            (address _tokenA, address _tokenB, uint24 _fee) = decodeFirstPool(path, start);
            require(_poolWhitelist[getPool(_tokenA, _tokenB, _fee)], "Invalid pool");
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
        for (uint i=0; i<path.length-1; i++) {
            require(_pairWhitelist[getPair(path[i], path[i+1])], "Invalid pair");
        }
        require(to == safeAddress, "To address is not allowed");
    }

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to) external view onlySelf {
        for (uint i=0; i<path.length-1; i++) {
            require(_pairWhitelist[getPair(path[i], path[i+1])], "Invalid pair");
        }
        require(to == safeAddress, "To address is not allowed");
    }

    function exactInputSingle(IV3SwapRouter.ExactInputSingleParams calldata params) external view onlySelf {
        require(_poolWhitelist[getPool(params.tokenIn, params.tokenOut, params.fee)], "Unauthorized pool");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function exactOutputSingle(IV3SwapRouter.ExactOutputSingleParams calldata params) external view onlySelf {
        require(_poolWhitelist[getPool(params.tokenIn, params.tokenOut, params.fee)], "Unauthorized pool");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function exactOutput(IV3SwapRouter.ExactOutputParams calldata params) external view onlySelf {
        checkPath(params.path);
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function exactInput(IV3SwapRouter.ExactInputParams calldata params) external view onlySelf {
        checkPath(params.path);
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }
}