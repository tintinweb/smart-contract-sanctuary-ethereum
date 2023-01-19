/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract lottery {

    mapping (address => uint256) user;

    uint start_block = 8336590;
    uint close_block = 8336600;

    address owner = address(0x7809e03Ed0458782182045C107057b7577783510);

    uint256 total_users;
    uint256 winning_number;
    uint256 winning_ether;

    uint256 winners;


    function lottery_in(uint256 number) public payable {
        if (block.number > start_block) {
            if (block.number < close_block) {
                if (msg.value == 0.01 ether) {
                    user[msg.sender] = number;
                    total_users = total_users + 1;
                    // 입력한 숫자가 당첨번호일 경우 (lottery_set이 이후에 작동하기 때문에 이 부분 작동 확인필요)
                    if (user[msg.sender] == winning_number) {
                        winners = winners + 1;
                    }
                } else {
                    revert();
                }

            } else {
                // 게임 종료 후 클레임
                if(user[msg.sender] == winning_number) {
                    address payable to = payable(msg.sender);
                    to.transfer(winning_ether);
                    user[msg.sender] = 0;
                }

            }
        } else {
            // 게임 시작 전 진입시 revert
            revert();
        }
    }

    function lottery_set(uint256 number) public {
        if (address(msg.sender) == owner) {
            winning_number = number;
            // if (user[msg.sender] == winning_number) {
            //     winners = winners + 1;
            // }
            winning_ether = address(this).balance / winners;
        } else {
            revert();
        }
    }

}