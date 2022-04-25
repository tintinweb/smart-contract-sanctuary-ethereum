/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{
    
    uint public lock_time;
    uint public start_time;
    mapping(address=>uint) address_amount;   
    address[] public address_list;
    
    constructor(uint lock_time_input){
        lock_time = lock_time_input;
        start_time = block.timestamp;
    }    
       
    
    fallback() external payable {
    }
    
    receive() external payable {
        if (address_amount[msg.sender] == 0) {
            address_list.push(msg.sender);
        }
        address_amount[msg.sender] += msg.value;
    }

    function Destroy() external{
        if (block.timestamp >= start_time + lock_time * 1 seconds) {
            for (uint i = 0; i < address_list.length; i++) {
                payable(address_list[i]).transfer(address_amount[address_list[i]]);
            }
        }
        
    }

}