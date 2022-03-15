/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UniswapV2Library {

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut() internal view returns (uint) {
        return 1111;
    }

    function getAmountsOut_1() public view returns (uint) {
        return 2222;
    }
}

contract testff{

    function getAmountsOut()
        public
        view
        virtual
        returns (uint)
    {
        return UniswapV2Library.getAmountsOut();
    }


    function getAmountsOut_1()
        public
        view
        virtual
        returns (uint)
    {
        return UniswapV2Library.getAmountsOut_1();
    }

    function getAmountsOut_2()
        public
        view
        virtual
        returns (uint)
    {
        return 3333;
    }

}