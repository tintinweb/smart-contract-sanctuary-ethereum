/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.5.0;

interface father{
    function addnum(uint a) external returns (uint);
}

contract son{
address public t=0x383C4F4222Bc2eB6Dbd6698944FB07FA48222469 ;

father aaa;
function addre(address a) public {
    aaa=father(a);
    
} 

    function push(uint b) public returns (uint){
        aaa.addnum(b);
        return b;
    }
    function PUSH_imm(uint b) public {
            father(t).addnum(b);
    }
    
   

}