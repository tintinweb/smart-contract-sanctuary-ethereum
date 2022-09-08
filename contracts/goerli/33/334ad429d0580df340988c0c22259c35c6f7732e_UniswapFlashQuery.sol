/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

/*import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/UniswapV2Factory.sol";*/
pragma experimental ABIEncoderV2;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

abstract contract UniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function allPairsLength() external view virtual returns (uint);
}

contract UniswapFlashQuery {
    string public message = "i love u";

    function getReservesByEachPairs(IUniswapV2Pair[] calldata _pairs)
        external
        view
        returns (uint256[3][] memory)
    {
        uint256[3][] memory result = new uint256[3][](_pairs.length);
        for (uint i = 0; i < _pairs.length; i++) {
            // return address of token0 , address of token 1 and blocktimestamp
            (result[i][0], result[i][1], result[i][2]) = _pairs[i]
                .getReserves();
        }
        return result;
    }

    function getPairsByIndexRange(
        UniswapV2Factory _uniswapFactory,
        uint256 _start,
        uint256 _stop
    ) external view returns (address[3][] memory) {
        uint256 _allPairsLength = _uniswapFactory.allPairsLength();
        if (_stop > _allPairsLength) {
            _stop = _allPairsLength;
        }
        require(_stop >= _start, "start is bigger than stop");
        uint256 _rangeOfPairs = _stop - _start;

        address[3][] memory result = new address[3][](_rangeOfPairs);

        for (uint i = 0; i < _rangeOfPairs; i++) {
            IUniswapV2Pair _uniswapPair = IUniswapV2Pair(
                _uniswapFactory.allPairs(_start + i)
            );
            // return address of token0 , address of token 1 and address of the pair
            result[i][0] = _uniswapPair.token0();
            result[i][1] = _uniswapPair.token1();
            result[i][2] = address(_uniswapPair);
        }
        return result;
    }
}