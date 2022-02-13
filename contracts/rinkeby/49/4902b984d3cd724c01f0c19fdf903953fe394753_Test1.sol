/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;
contract Test1 
{    
     uint age;
     uint limitMoney=1 ether;

     constructor(uint _age) payable{
         age=_age;
     }

     event FA(uint x);
     event FB(uint x);
     
     function setAge(uint _age) public{
         age=_age;
         emit FA(age);
     }
    
    function getAge() public  returns(uint) {
        emit FB(age);
        return age;
        
    }

    // 后备函数
    receive() external payable {}
    fallback() external payable {}
     
}