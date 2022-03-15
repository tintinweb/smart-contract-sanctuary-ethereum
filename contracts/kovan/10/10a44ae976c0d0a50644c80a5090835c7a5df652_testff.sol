/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function getAmountsOut() external view returns (uint256);
    function getAmountsOut_1() external view returns (uint256);
    function getAmountsOut_2() external view returns (uint256);
}

contract testff{

    function getAmountsOut()public view returns(uint){
        return IERC20(0x50eD82CEBdfB779cb21a2fBfD724f6cAB50d2459).getAmountsOut();
    }

    function getAmountsOut_1()public view returns(uint){
        return IERC20(0x50eD82CEBdfB779cb21a2fBfD724f6cAB50d2459).getAmountsOut_1();
    }

    function getAmountsOut_2()public view returns(uint){
        return IERC20(0x50eD82CEBdfB779cb21a2fBfD724f6cAB50d2459).getAmountsOut_2();
    }
}