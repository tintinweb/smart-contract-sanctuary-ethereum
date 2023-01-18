//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.1;

pragma experimental ABIEncoderV2;

interface Erc20Token {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

}

interface IUniswapV2Pair {

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

}

abstract contract UniswapV2Factory {

    mapping(address => mapping(address => address)) public getPair;

    address[] public allPairs;

    function allPairsLength() external view virtual returns (uint);

}

// In order to quickly load up data from Uniswap-like market, this contract allows easy iteration with a single eth_call
contract BitAspireUniswapV2Proxy {

    struct Pair {
        address pairAddress;
        address token0Address;
        string token0Name;
        string token0Symbol;
        uint8 token0Decimals;
        uint256 token0TotalSupply;
        address token1Address;
        string token1Name;
        string token1Symbol;
        uint8 token1Decimals;
        uint256 token1TotalSupply;
    }

    function allPairsLength(UniswapV2Factory _uniswapFactory) external view returns (uint256) {
        return _uniswapFactory.allPairsLength();
    }

    function getPairsByIndexRange(UniswapV2Factory _uniswapFactory, uint256 _start, uint256 _stop) external view returns (Pair[] memory)  {
        uint256 _allPairsLength = _uniswapFactory.allPairsLength();
        if (_stop > _allPairsLength) {
            _stop = _allPairsLength;
        }

        require(_stop >= _start, "start cannot be higher than stop");

        uint256 _qty = _stop - _start;

        Pair[] memory pairs = new Pair[](_qty);

        for (uint i = 0; i < _qty; i++) {
            IUniswapV2Pair _uniswapPair = IUniswapV2Pair(_uniswapFactory.allPairs(_start + i));
            address token0Address = _uniswapPair.token0();
            address token1Address = _uniswapPair.token1();
            bool errorGettingTokenInfo = false;
            try Erc20Token(token0Address).name() returns (string memory token0Name) {
                try Erc20Token(token1Address).name() returns (string memory token1Name) {
                    pairs[i] = Pair(
                        address(_uniswapPair),
                        token0Address,
                        token0Name,
                        Erc20Token(token0Address).symbol(),
                        Erc20Token(token0Address).decimals(),
                        Erc20Token(token0Address).totalSupply(),
                        token1Address,
                        token1Name,
                        Erc20Token(token1Address).symbol(),
                        Erc20Token(token1Address).decimals(),
                        Erc20Token(token1Address).totalSupply()
                    );
                } catch {
                    errorGettingTokenInfo = true;
                }
            } catch {
                errorGettingTokenInfo = true;
            }
            if (errorGettingTokenInfo) {
                pairs[i] = Pair(
                    address(_uniswapPair),
                    token0Address,
                    "invalid",
                    "invalid",
                    0,
                    0,
                    token1Address,
                    "invalid",
                    "invalid",
                    0,
                    0
                );
            }
        }

        return pairs;
    }

    function getReservesByPairs(IUniswapV2Pair[] calldata _pairs) external view returns (uint256[3][] memory) {
        uint256[3][] memory result = new uint256[3][](_pairs.length);
        for (uint i = 0; i < _pairs.length; i++) {
            (result[i][0], result[i][1], result[i][2]) = _pairs[i].getReserves();
        }
        return result;
    }

}