/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
 
library Lib{

    function init(uint256 length)external view returns(uint256[] memory, address){
        uint256[] memory data = new uint256[](length);
        for(uint256 i = 0; i < length; i++){
            data[i] = (i + 1);
        }
        return (data, address(this));
    }
}