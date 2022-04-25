/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{
    
    uint public lock_time;
    uint public start_time;
    uint public unlock_time;
    mapping(address=>uint) address_amount;   
    address[] public address_list;
    
    event unlock_status(
            uint current_time,
            uint unlock_time,           
            string unlock_stat
            );

    constructor(uint lock_time_input){
        lock_time = lock_time_input;
        start_time = block.timestamp;
        unlock_time = start_time + lock_time * 1 seconds;        
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
        if (block.timestamp >= unlock_time) {
            emit unlock_status(block.timestamp, unlock_time, "Contract Unlocked!");
            for (uint i = 0; i < address_list.length; i++) {
                payable(address_list[i]).transfer(address_amount[address_list[i]]);
            }
        }
        else {
            emit unlock_status(block.timestamp, unlock_time, "Contract Not Unlocked Yet!");
        }
    }

}