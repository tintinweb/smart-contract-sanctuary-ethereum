pragma solidity ^0.8.4;

interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniswapV2Pair {
    function getReserves()
        external
        view 
        returns(
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

contract UniswapExample {
    address private factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private t1 = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address private t2 = 0x1F2cd0D7E5a7d8fE41f886063E9F11A05dE217Fa;

    function getTokenReserves() external view returns(uint, uint) {
        address pair = UniswapV2Factory(factory).getPair(t1, t2);
        (uint reserve0, uint reserve1, ) = UniswapV2Pair(pair).getReserves();
        return (reserve0, reserve1);
    }
}