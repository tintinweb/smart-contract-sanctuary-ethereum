/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// File: lottery.sol


pragma solidity ^0.8.12;

contract lottery{

    mapping (address => uint256) user;
    uint256 total_users;
    uint256 winning_number;    

    function lottery_in(uint256 number) public payable {
        if(msg.value == 0.01 ether){
            user[msg.sender] = number;
            total_users = total_users + 1;
        }else{
            revert();
        }
    }

    function lottery_set(uint256 number) public {
        winning_number = number;
    }

}