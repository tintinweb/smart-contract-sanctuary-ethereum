/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library Lib{
    function init(uint256[] storage data, uint256 length)public returns(address){
        for(uint256 i = 0; i < length; i++){
            data.push(i + 1);
        }
        return address(this);
    }
}