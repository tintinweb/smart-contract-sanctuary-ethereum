/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.4;
contract opration{
    address public sender;
    uint public value;
    
    int public pro =1;
    function op(int n) public payable{
        
        for(int i = 1; i < n;i++){
            pro = pro  + 1;
        }
        sender = msg.sender;
        value = msg.value;
    }

    
}