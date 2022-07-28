/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

pragma solidity =0.6.6;

//ERC20相关接口
interface IERC20Interface {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
}

// UniswapV2相关接口
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address pair);
}

contract CustomQuoterNew {

    address constant private lucky = address(666);
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    /**
     * @dev 批量获取代币的某个交易对 
     * @param facs 所有factory
     * @param tokens 所有代币
     * @param coins 所有基准币（交易对手另一种币)
     * @return pairs 返回所有代币获取的第一个交易对，如果没有，则为address(0)
     */
    function getPairs(address[] calldata facs, address[] calldata tokens, address[] calldata coins) external view returns(address[] memory pairs) {
        pairs = new address[](tokens.length);
        for(uint i=0;i< tokens.length;i++) {
            address token = tokens[i];
            for(uint j=0;j<facs.length;j++) {
                address fac = facs[j];
                for(uint k=0;k<coins.length;k++) {
                    address addr = IUniswapV2Factory(fac).getPair(token,coins[k]);
                    if(addr != address(0)) {
                        pairs[i] = addr;
                        break;
                    }
                }
                if(pairs[i] != address(0)) {
                    break;
                }
            }
        }
    }


    /**
     * @dev 批量查询代币的损耗率
     * @notice 所有交易对必须通过上在的getPairs 函数查询，并剔除掉零地址
     * @param tokens 所有代币
     * @param pairs 所有包含该代币的uniswapv2交易对
     * @return rates 所有代币的三种损耗率
     */
    function batchQuoteRates(address[] calldata tokens, address[] calldata pairs) external returns (uint[] memory rates) {
        require(tokens.length > 0 && tokens.length == pairs.length);
        rates = new uint[](tokens.length);
        for(uint i=0;i<tokens.length;i++) {
            address pair = pairs[i];
            address token = tokens[i];
            address token0 =  IUniswapV2Pair(pair).token0();
            (uint reserve00, uint reserve01, ) = IUniswapV2Pair(pair).getReserves();
            uint amountOut0 = token0 == token ?  reserve00 / 100000000 : 0;
            uint amountOut1 = token0 == token ? 0 : reserve01 /100000000;
            try 
                IUniswapV2Pair(pair).swap(amountOut0,amountOut1,address(this),bytes("amm"))
            {} catch (bytes memory reason) {
                rates[i] =  parseRevertReasonM(reason);
            }
        }
    }

    /**
     * @dev 查询某个代币的损耗率
     * @param token 查询的代币
     * @param pair  包含查询代币的任意UniswapV2交易对。注意交易对要标准的支持闪电贷。
     * @return rate 买卖和转移过程中的损耗率
     */
    function quoteRate(address token, address pair) public returns (uint rate) {
        address token0 =  IUniswapV2Pair(pair).token0();
        (uint reserve00, uint reserve01, ) = IUniswapV2Pair(pair).getReserves();
        uint amountOut0 = token0 == token ?  reserve00 / 10000000 : 0;
        uint amountOut1 = token0 == token ? 0 : reserve01 /10000000;
        try 
            IUniswapV2Pair(pair).swap(amountOut0,amountOut1,address(this),bytes("amm"))
        {} catch (bytes memory reason) {
            return parseRevertReasonS(reason);
        }
    }

    function parseRevertReasonS(bytes memory reason) private pure returns (uint256) {
        if (reason.length != 32) {
            if (reason.length < 68) revert('Unexpected error');
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (uint256));
    }



    /// @dev Parses a revert reason that should contain the numeric quote
    function parseRevertReasonM(bytes memory reason) private pure returns (uint256) {
        if (reason.length != 32) {
            // if (reason.length < 68) revert('Unexpected error');
            // assembly {
            //     reason := add(reason, 0x04)
            // }
            // revert(abi.decode(reason, (string)));
            return uint(-1);
        }
        return abi.decode(reason, (uint256));
    }

    fallback () external payable virtual {
        bytes memory data = msg.data;
        uint amount0;
        uint amount1;
        assembly {
            amount0 := mload(add(data,68))
            amount1 := mload(add(data,100))
        }
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address token = amount0 > 0 ? token0 : token1;
        uint amount = amount0 > 0 ? amount0 : amount1;
        uint bal =  IERC20Interface(token).balanceOf(address(this));
        require(amount >= bal,"inner error");
        uint buyRate = 1000 * (amount - bal) / amount;

        uint send_value = bal/2;
        uint bal_before = IERC20Interface(token).balanceOf(msg.sender);
        _safeTransfer(token,msg.sender,send_value);
        uint bal_after = IERC20Interface(token).balanceOf(msg.sender);
        uint dev = bal_after - bal_before;
        uint sellRate = (send_value - dev ) * 1000 / send_value;

        bal_before = IERC20Interface(token).balanceOf(lucky);
        _safeTransfer(token,lucky,send_value);
        bal_after = IERC20Interface(token).balanceOf(lucky);
        dev = bal_after - bal_before;
        uint transferRate = (send_value - dev ) * 1000 / send_value;
        uint rate = (buyRate << 32) + (sellRate << 16) + transferRate;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, rate)
            revert(ptr, 32)
        }
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

}