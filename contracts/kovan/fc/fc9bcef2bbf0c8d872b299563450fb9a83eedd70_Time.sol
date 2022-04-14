/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract Time{

    function getTime(uint256 time) public view returns(uint256){
            if(time<=block.timestamp){
               return 0;
            }
            else{
                return time+4830;
            }
    }
    
}