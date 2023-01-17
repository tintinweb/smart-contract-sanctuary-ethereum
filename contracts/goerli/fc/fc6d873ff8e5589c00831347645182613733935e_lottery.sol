/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// File: lottery.sol


pragma solidity ^0.8.12;


contract lottery {

    //당첨자끼리 N빵
    mapping (address => uint256) user;
    
    // total_users[0]은 사용하지 않고, total_users[1] ~ total_users[5] 만 사용
    uint256[6] public total_users;

    uint256 winning_number;
    uint256 winning_ether;

    //payable : 해당 함수 호출 시, 이더 전송 받음. (돈 내야 함)
    //입력될 수 있는 number는 1~5까지 숫자
    function lottery_in(uint256 number) public payable {
        if(msg.value == 0.01 ether) {
            user[msg.sender] = number;
            total_users[number] = total_users[number] + 1;
        } else {
            revert();
        }
    }

    //당첨 숫자를 설정하고, 그에 따른 당첨금 계산
    function lottery_set(uint256 number) public {
        //admin address (테스트 지갑 주소) : 0x050026c9258B7B7792aecfBbb929398B7a71543E        
        if(msg.sender == 0x050026c9258B7B7792aecfBbb929398B7a71543E) {
            winning_number = number;
            winning_ether = address(this).balance / total_users[number];
        } else {
            revert();
        }
    }

    //당첨금을 클레임
    function claim() public {
        if(user[msg.sender] == winning_number) {
            address payable to = payable(msg.sender);
            to.transfer(winning_ether);
            user[msg.sender] = 0;
        } else {
            revert();
        }
    }
}