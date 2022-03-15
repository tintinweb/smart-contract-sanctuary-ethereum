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
        return IERC20(0x7718A8364fbF6D3eCBF98fAeFfE7C2b7E09AB77e).getAmountsOut();
    }

    function getAmountsOut_1()public view returns(uint){
        return IERC20(0x7718A8364fbF6D3eCBF98fAeFfE7C2b7E09AB77e).getAmountsOut_1();
    }

    function getAmountsOut_2()public view returns(uint){
        return IERC20(0x7718A8364fbF6D3eCBF98fAeFfE7C2b7E09AB77e).getAmountsOut_2();
    }
}