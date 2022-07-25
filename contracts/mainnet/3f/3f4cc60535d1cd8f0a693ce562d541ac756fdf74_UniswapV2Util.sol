/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract UniswapV2Util {

    struct PoolInfo {
        address token;
        uint reserve;
        string symbol;
        string name;
        uint8 decimals;
    }

    function _getPoolInfo(address pool) internal view returns (PoolInfo[] memory poolInfos){
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        address token0Address = pair.token0();
        address token1Address = pair.token1();
        IERC20 token0 = IERC20(token0Address);
        IERC20 token1 = IERC20(token1Address);
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pool).getReserves();

        PoolInfo memory poolInfo0 = PoolInfo(token0Address, reserve0, token0.symbol(), token0.name(), token0.decimals());
        PoolInfo memory poolInfo1 = PoolInfo(token1Address, reserve1, token1.symbol(), token1.name(), token1.decimals());

        poolInfos = new PoolInfo[](2);

        poolInfos[0] = poolInfo0;
        poolInfos[1] = poolInfo1;

        return poolInfos;
    }

    function getPoolInfo(address pool) external view returns (PoolInfo[] memory poolInfos){
        return _getPoolInfo(pool);
    }

    struct UserInfo {
        uint balance;
        uint totalSupply;
        uint decimals;
    }

    function getUserInfo(address pool, address user) external view returns (UserInfo memory userInfo){
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        uint balance = pair.balanceOf(user);
        uint totalSupply = pair.totalSupply();
        uint8 decimals = pair.decimals();

        userInfo.balance = balance;
        userInfo.totalSupply = totalSupply;
        userInfo.decimals = decimals;

        return userInfo;
    }
}