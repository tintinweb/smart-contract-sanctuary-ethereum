/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// File: lottery.sol


pragma solidity ^0.8.12;

// 컨트랙 이름
contract lottery {

    // 0x1234 => 1
    // 0x234242332423 => 9
    mapping (address => uint256) user;
    mapping (uint256 => uint256) countNumber;
    uint256 total_users;
    uint256 total_winning_ether;
    uint256 received_winning_ether = 0;
    uint256 winning_number;
    uint256 winning_ether;
    bool isSetLottery = false;
    address manager = 0xC10800B05bf2E6b768A12F946476db647a3E8F7B;

    // 추첨번호 넣기
    function lottery_in(uint256 number) public payable {
        if(isSetLottery) {
            revert();
        }

        if(msg.value == 0.001 ether) {
            user[msg.sender] = number;
            total_users = total_users + 1;
            countNumber[number] = countNumber[number] + 1;
        } else {
            revert();
        }
    }

    // 추첨번호 셋
    function lottery_set(uint256 number) public {
        if(msg.sender == manager) {
            winning_number = number;
            total_winning_ether = (0.001 * 10**18) * total_users * 80 / 100;
            winning_ether = ((0.001 * 10**18) * total_users * 80 / 100) / countNumber[number];
            isSetLottery = true;
        }
    }

    function lettery_reset() public {
        if(msg.sender == manager) {
            isSetLottery = false;
        }
    }

    // 추첨번호랑 맞으면 가져가라
    function claim() public {
        if(user[msg.sender] == winning_number) {
            address payable to = payable(msg.sender);
            received_winning_ether = received_winning_ether + (((0.001 * 10**18) * total_users * 80 / 100) / countNumber[winning_number]);
            to.transfer(winning_ether);
        } else {
            revert();
        }
    }
}