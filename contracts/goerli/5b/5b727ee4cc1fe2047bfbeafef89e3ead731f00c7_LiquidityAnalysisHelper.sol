/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
}

interface IERC20Broken {
    function symbol() external view returns (bytes32);
}

contract LiquidityAnalysisHelper {
    struct V2Response {
        string  symbol0;
        address address0;
        uint256 decimals0;

        string  symbol1;
        address address1;
        uint256 decimals1;

        address pair;
        uint256 reserve0;
        uint256 reserve1;
    }

    struct V3Response {
        string  symbol0;
        address address0;
        uint256 decimals0;

        string  symbol1;
        address address1;
        uint256 decimals1;

        address pair;
        uint24 fee;
        uint256 reserve0;
        uint256 reserve1;
    }

    function getV2Info(address token_, address[] calldata factories_, address[] calldata candidates_) public view returns (V2Response[] memory) { 
        V2Response[] memory results = new V2Response[](candidates_.length * factories_.length);
        uint256 saveIndex;
        for (uint256 j; j < factories_.length; j++) {
            for (uint256 i; i < candidates_.length; i++) {
                if (token_ == candidates_[i]) continue;
                
                address pair = IUniswapV2Factory(factories_[j]).getPair(token_, candidates_[i]);
                if (pair == address(0)) continue;

                address address0 = IUniswapV2Pair(pair).token0();
                address address1 = IUniswapV2Pair(pair).token1();
                (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();

                string memory symbol0 = IERC20(address0).symbol();
                uint256 decimals0 = IERC20(address0).decimals();

                string memory symbol1 = IERC20(address1).symbol();
                uint256 decimals1 = IERC20(address1).decimals();

                results[saveIndex] = V2Response({
                    address0: address0,
                    symbol0: symbol0,
                    decimals0: decimals0,

                    address1: address1,
                    symbol1: symbol1,
                    decimals1: decimals1,

                    pair: pair,
                    reserve0: reserve0,
                    reserve1: reserve1
                });
                saveIndex++;
            }

        }

        return results;
    }

    function getV3Info(address factory_, address token_, address[] calldata candidates_) public view returns (V3Response[] memory) { 
        V3Response[] memory results = new V3Response[](candidates_.length * 3);
        uint256 saveIndex;

        uint24 lFee = 500;
        uint24 mFee = 3000;
        uint24 hFee = 10000;

        for (uint256 i; i < candidates_.length; i++) {
            if (token_ == candidates_[i]) continue;
            
            address lPair = IUniswapV3Factory(factory_).getPool(token_, candidates_[i], lFee);
            address mPair = IUniswapV3Factory(factory_).getPool(token_, candidates_[i], mFee);
            address hPair = IUniswapV3Factory(factory_).getPool(token_, candidates_[i], hFee);

            if (lPair != address(0)) {
                results[saveIndex] = processV3Pool(lPair, lFee);
                saveIndex++;
            }
            
            if (mPair != address(0)) {
                results[saveIndex] = processV3Pool(mPair, mFee);
                saveIndex++;       
            }        
            
            if (hPair != address(0)) {
                results[saveIndex] = processV3Pool(hPair, hFee);
                saveIndex++;  
            }
        }

        return results;
    }

    function processV3Pool(address pair_, uint24 fee_) internal view returns (V3Response memory) { 
        address address0 = IUniswapV3Pool(pair_).token0();
        address address1 = IUniswapV3Pool(pair_).token1();

        string memory symbol0 = IERC20(address0).symbol();
        uint256 decimals0 = IERC20(address0).decimals();
        uint256 reserve0 = IERC20(address0).balanceOf(pair_);

        string memory symbol1 = IERC20(address1).symbol();
        uint256 decimals1 = IERC20(address1).decimals();
        uint256 reserve1 = IERC20(address1).balanceOf(pair_);

        return V3Response({
            address0: address0,
            symbol0: symbol0,
            decimals0: decimals0,

            address1: address1,
            symbol1: symbol1,
            decimals1: decimals1,

            pair: pair_,
            fee: fee_,
            reserve0: reserve0,
            reserve1: reserve1
        });
    }

    function getSymbol(address token_) public view returns (string memory) { 
        (bool success, bytes memory data) = token_.staticcall(abi.encodeWithSelector(IERC20.symbol.selector));

        if (success) {
            return string(abi.encodePacked(data));
        }
         
        return "";
    }
}