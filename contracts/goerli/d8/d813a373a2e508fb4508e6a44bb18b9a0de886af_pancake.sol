/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract pancake {

    uint256 round;
    uint256 price = 0.01 ether;
    uint256 winning_price = 0.01 ether;

    mapping (uint256 => mapping (address => uint256[])) my_numbers;
    mapping (uint256 => uint256[]) winning_numbers;

    function lottery_in(uint256[] memory numbers) public payable {

        if(msg.value == price){
            my_numbers[round][msg.sender] = numbers;
        } else {
            revert("Not enough ETH");
        }
    }

    function lottery_set(uint256[] memory numbers) public {
        winning_numbers[round] = numbers;
        round += 1;
    }

    function check_round_nuber() public view returns(uint256) {
        return round;
    }

    function claim(uint256 this_round) public {
        uint256 point = 0; 

        uint256 win1 =  winning_numbers[this_round][0];
        uint256 win2 =  winning_numbers[this_round][1];
        uint256 win3 =  winning_numbers[this_round][2];

        uint256 num1 =  my_numbers[this_round][msg.sender][0];
        uint256 num2 =  my_numbers[this_round][msg.sender][1];
        uint256 num3 =  my_numbers[this_round][msg.sender][2];

        if(win1 == num1) {
            point = point + 1;        
        }

        if(win2 == num2) {
            point = point + 1;
        }

        if(win3 == num3) {
            point = point + 1;
        }
 

        if(point > 0) {
            address payable to = payable(msg.sender);
            to.transfer(point * winning_price);
        }else {
            revert("NOt a Winner");
        }

    }

}