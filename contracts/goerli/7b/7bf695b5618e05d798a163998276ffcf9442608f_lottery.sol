/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract lottery {

    mapping (address => uint256) user;
    mapping (uint256 => uint256) winners;

    uint start_block = 8336730;
    uint close_block = 8336735;

    address owner = address(0x7809e03Ed0458782182045C107057b7577783510);

    uint256 total_users;
    uint256 winning_number;
    uint256 winning_ether;


    function lottery_in(uint256 number) public payable {
        if (block.number < close_block) {
            if (block.number > start_block) {
                if (msg.value == 0.01 ether) {
                    user[msg.sender] = number;
                    winners[number] = winners[number] + 1;
                    total_users = total_users + 1;
                } else {
                    // 0.01 ether 없으면 revert
                    revert();
                }
            } else {
                // 게임시작 전 진입시 revert
                revert();
            }
        } else {
            // 게임종료 후 진입시 revert
            revert();
        }
    }

    function claim() public {
        if(user[msg.sender] == winning_number) {
            address payable to = payable(msg.sender);
            to.transfer(winning_ether);
            user[msg.sender] = 0;
        }

    }

    function lottery_set(uint256 number) public {
        if (address(msg.sender) == owner) {
            winning_number = number;
            winning_ether = address(this).balance / winners[number];
        } else {
            revert();
        }
    }

}