/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// File: lottery.sol


pragma solidity ^0.8.12;

contract lottery{


    mapping (address => uint256) user;
    uint256[5] participants = [0,0,0,0,0];
    uint256 total_users;
    uint256 winning_number;
    uint256 winning_ether;

    function lottery_in(uint256 number) public payable {
        if(msg.value >= 0.01 ether){
            user[msg.sender] = number;
            participants[number-1] = participants[number-1] + 1;
        }
        else{
            revert(); //transaction fail을 때리는 함수
        }
    }
    function count_view() public view returns(uint){
        return participants[3];
    } 


    function lottery_set(uint256 number) public {
        if(msg.sender == 0x110F383CFD62330F501773650BD327F33a880225){      //관리자인지 주소 체크
            winning_number = number;
            winning_ether = address(this).balance / participants[number-1];
        }
        else{
            revert();
        }

    }

    function claim() public {
        if (user[msg.sender]==winning_number){
            address payable to = payable(msg.sender);
            //to.transfer(address(this).balance);
            to.transfer(winning_ether);
            user[msg.sender] = 0; //solidity에 -1은 없기 때문에 넣어줄 수 없음
        }
        else{
            revert();
        }
    }
}