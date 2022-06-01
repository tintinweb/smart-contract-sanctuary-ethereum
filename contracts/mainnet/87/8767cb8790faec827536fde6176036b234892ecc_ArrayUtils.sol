/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
// StarBlock DAO Contracts

pragma solidity ^0.8.0;

library ArrayUtils {
    function hasDuplicate(uint256[] memory self) external pure returns(bool) {
        uint256 ivalue;
        uint256 jvalue;
        for(uint256 i = 0; i < self.length - 1; i ++){
            ivalue = self[i];
            for(uint256 j = i + 1; j < self.length; j ++){
                jvalue = self[j];
                if(ivalue == jvalue){
                    return true;
                }
            }
        }
        return false;
    }
}