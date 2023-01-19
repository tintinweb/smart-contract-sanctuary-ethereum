/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract lottery{

    mapping(address => uint256) user;
    mapping(uint256 => uint256) count_users;
    uint256 winning_number;
    uint256 winning_ether;


    function lottery_in(uint256 number) public payable{
        if(msg.value == 0.01 ether){
            user[msg.sender] = number;
            count_users[number] = count_users[number] + 1;

        }
        else{
            revert();
        }
    }

    function lottery_set(uint256 number) public{
        if(msg.sender == 0xF482E000DcAFccc8970b2b5578f9cb0fFA8933F8){
        winning_number = number;
        winning_ether = address(this).balance / count_users[number];
        }
        else{
            revert();
        }
    }

    function claim() public{
        if(user[msg.sender] == winning_number){
            address payable to = payable(msg.sender);
            to.transfer(winning_ether);
            user[msg.sender] = 0;
        }
        else{
            revert();
        }
    }

}