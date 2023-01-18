/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// File: lotto.sol


pragma solidity ^0.8.12;

contract Lottery {
    mapping (address => uint256) users;
    mapping (uint256 => uint256) select_numbers;
    uint256 total_users;
    uint256 winning_number;
    uint256 winning_ether;

    function lottery_in(uint256 number) public payable {
        if(msg.value == 0.01 ether){
            users[msg.sender] = number;
            select_numbers[number]++;
            total_users++;
        }else{
            revert();
        }
    }

    function lottery_set(uint256 number) public {
        if(msg.sender == 0xbb857B18AFA38B20628af770369664FD4972B307){
            winning_number = number;
            winning_ether = address(this).balance / select_numbers[number];
        }else{
            revert();
        }
    }

    function lottery_claim() public {
        if(users[msg.sender] == winning_number){
            address payable to = payable(msg.sender);
            to.transfer(winning_ether);
            users[msg.sender] = 987654321;
        }else{
            revert();
        }
    }
}