/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// File: lottery.sol


pragma solidity ^0.8.12;

contract lottery{

    mapping (address => uint256) user;
    uint256 total_users;
    uint256 winning_number;   
    uint256 winning_ether; 

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
        winning_ether = address(this).balance / total_users;
    }

    function claim() public {
        if(user[msg.sender] == winning_number){
            address payable to = payable(msg.sender);
            //to.transfer(address(this).balance);
            to.transfer(winning_ether);
            user[msg.sender] = 0;
        }else{
            revert();
        }
    }
}