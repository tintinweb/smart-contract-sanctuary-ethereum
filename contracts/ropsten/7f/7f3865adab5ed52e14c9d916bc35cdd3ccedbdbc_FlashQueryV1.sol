/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

abstract contract ERC20Detailed {
    function symbol() public view virtual returns (string memory);
    function name() public view virtual returns (string memory);
    function decimals() public view virtual returns (uint8);
}

abstract contract UniswapV2Factory  {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    function allPairsLength() external view virtual returns (uint);
}

contract FlashQueryV1 {
    function getReservesByPairs(IUniswapV2Pair[] calldata _pairs) external view  
        returns (uint256[3][] memory reserves) {
        reserves = new uint256[3][](_pairs.length);
        for (uint i = 0; i < _pairs.length; i++) {
            (reserves[i][0], reserves[i][1], reserves[i][2]) = _pairs[i].getReserves();
        }
    }

    function getPairsByIndexRange(UniswapV2Factory _uniswapFactory, uint256 _start, uint256 _stop) external view returns (bytes[] memory result)  {
        uint256 _allPairsLength = _uniswapFactory.allPairsLength();
        if (_stop > _allPairsLength) {
            _stop = _allPairsLength;
        }
        require(_stop >= _start, "start cannot be higher than stop");
        uint256 _qty = _stop - _start;
        result = new bytes[](_qty);
        for (uint i = 0; i < _qty; i++) {
            IUniswapV2Pair _uniswapPair = IUniswapV2Pair(_uniswapFactory.allPairs(_start + i));
            ERC20Detailed _token0 = ERC20Detailed(_uniswapPair.token0());
            ERC20Detailed _token1 = ERC20Detailed(_uniswapPair.token1());
            result[i] = abi.encode(
                address(_token0), _token0.symbol(), _token0.name(), _token0.decimals(),
                address(_token1), _token1.symbol(), _token1.name(), _token1.decimals(),
                address(_uniswapPair));
        }
        return result;
    }
}