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

    //    struct Pair {
    //        address pairAddress;
    //        address token0Address;
    //        string token0Name;
    //        string token0Symbol;
    //        uint8 token0Decimals;
    //        uint256 token0TotalSupply;
    //        address token1Address;
    //        string token1Name;
    //        string token1Symbol;
    //        uint8 token1Decimals;
    //        uint256 token1TotalSupply;
    //    }

    struct Pair {
        address pairAddress;
        address token0Address;
        bytes token0Name;
        bytes token0Symbol;
        bytes token0Decimals;
        bytes token0TotalSupply;
        address token1Address;
        bytes token1Name;
        bytes token1Symbol;
        bytes token1Decimals;
        bytes token1TotalSupply;
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
            if (token0Address.code.length > 0 && token1Address.code.length > 0) {
                (bool success01, bytes memory token0NameBytes) = address(token0Address).staticcall(abi.encodeWithSignature("name()"));
                (bool success02, bytes memory token0SymbolBytes) = address(token0Address).staticcall(abi.encodeWithSignature("symbol()"));
                (bool success03, bytes memory token0DecimalsBytes) = address(token0Address).staticcall(abi.encodeWithSignature("decimals()"));
                (bool success04, bytes memory token0TotalSupplyBytes) = address(token0Address).staticcall(abi.encodeWithSignature("totalSupply()"));

                (bool success11, bytes memory token1NameBytes) = address(token1Address).staticcall(abi.encodeWithSignature("name()"));
                (bool success12, bytes memory token1SymbolBytes) = address(token1Address).staticcall(abi.encodeWithSignature("symbol()"));
                (bool success13, bytes memory token1DecimalsBytes) = address(token1Address).staticcall(abi.encodeWithSignature("decimals()"));
                (bool success14, bytes memory token1TotalSupplyBytes) = address(token1Address).staticcall(abi.encodeWithSignature("totalSupply()"));

                if (success01 && success02 && success03 && success04 && success11 && success12 && success13 && success14) {
                    pairs[i] = Pair(
                        address(_uniswapPair),
                        token0Address,
                        token0NameBytes,
                        token0SymbolBytes,
                        token0DecimalsBytes,
                        token0TotalSupplyBytes,
                        token1Address,
                        token1NameBytes,
                        token1SymbolBytes,
                        token1DecimalsBytes,
                        token1TotalSupplyBytes
                    );
                    //                    string memory token0Symbol = abi.decode(token0SymbolBytes, (string));
                    //                    uint8 token0Decimals = abi.decode(token0DecimalsBytes, (uint8));
                    //                    uint256 token0TotalSupply = abi.decode(token0TotalSupplyBytes, (uint256));
                    //
                    //                    string memory token1Name = abi.decode(token1NameBytes, (string));
                    //                    string memory token1Symbol = abi.decode(token1SymbolBytes, (string));
                    //                    uint8 token1Decimals = abi.decode(token1DecimalsBytes, (uint8));
                    //                    uint256 token1TotalSupply = abi.decode(token1TotalSupplyBytes, (uint256));

                    //                    pairs[i] = Pair(
                    //                        address(_uniswapPair),
                    //                        token0Address,
                    //                        token0Name,
                    //                        token0Symbol,
                    //                        token0Decimals,
                    //                        token0TotalSupply,
                    //                        token1Address,
                    //                        token1Name,
                    //                        token1Symbol,
                    //                        token1Decimals,
                    //                        token0TotalSupply
                    //                    );
                } else {
                    errorGettingTokenInfo = true;
                }
            } else {
                errorGettingTokenInfo = true;
            }
            if (errorGettingTokenInfo) {
                pairs[i] = Pair(
                    address(_uniswapPair),
                    token0Address,
                    bytes("invalid"),
                    bytes("invalid"),
                    bytes("0"),
                    bytes("0"),
                    token1Address,
                    bytes("invalid"),
                    bytes("invalid"),
                    bytes("0"),
                    bytes("0")
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