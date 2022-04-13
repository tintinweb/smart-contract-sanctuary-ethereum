// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Test{
    uint internal value=0;

    function setvalue(uint _v) external {
        value=_v;
    }
    function getValue() external view returns(uint){
        return value;
    }
   

    
}