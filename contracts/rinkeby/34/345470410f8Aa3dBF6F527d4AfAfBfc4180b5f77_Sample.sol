// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import 'interfaces/IUniswapV2Factory.sol';
import 'interfaces/IUniswapV2Pair.sol';

contract Sample {
    struct ReservesOutputs {
        uint112 reserve0;
        uint112 reserve1;
    }

    struct TokenPair {
        address token0;
        address token1;
    }

    address public immutable UniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    TokenPair[] public pairs;
    ReservesOutputs[] public outs;

    function addPair(address _token0, address _token1) public {
        require(getPairAddress(TokenPair(_token0, _token1)) == address(0)
            || _token0 == _token1, "Incorrect or equal addresses");
        pairs.push(TokenPair(_token0, _token1));
    }

    function checkReserves() public returns (ReservesOutputs[] memory){
        for (uint8 i = 0; i < pairs.length; ++i) {
            uint112[2] memory reserves = getPairReserve(pairs[i]);
            outs.push(ReservesOutputs(reserves[0], reserves[1]));
        }
        return outs;
    }

    function getPairAddress(TokenPair memory pair) private view returns (address){
        return IUniswapV2Factory(UniswapV2Factory).getPair(pair.token0, pair.token1);
    }

    function getPairReserve(TokenPair memory pair) private view returns (uint112[2] memory){
        address pairAddress = getPairAddress(pair);
        (uint112 token0, uint112 token1,) = IUniswapV2Pair(pairAddress).getReserves();
        return [token0, token1];
    }

}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

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