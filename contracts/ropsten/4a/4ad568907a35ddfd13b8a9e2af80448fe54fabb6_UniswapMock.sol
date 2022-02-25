pragma solidity >=0.5.0;

contract UniswapMock {

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = 5280000000;
        _reserve1 = 1000000000000000000;
        _blockTimestampLast = 100000000;
    }

}