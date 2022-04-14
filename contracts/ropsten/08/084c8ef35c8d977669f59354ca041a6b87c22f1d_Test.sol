/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}
contract Test {
    function isPair(address account) public view returns(bool) {
        IUniswapV2Pair pair = IUniswapV2Pair(account);
        try pair.token0()
        {
            return true;
        }
        catch {
            return false;
        }
    }
}