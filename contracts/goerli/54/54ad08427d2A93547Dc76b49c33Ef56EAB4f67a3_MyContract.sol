/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
contract MyContract{ 
    uint256 num;

    function getNum() public view returns(uint256){
        return num;
    }

    function setNum(uint256 _newnum) public {
        num=_newnum;
    }
    
}