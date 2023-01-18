/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// File: lottery.sol


pragma solidity ^0.8.12;

contract lottery{

    address admin_addr = 0x6c77E3fd48Bbb56062eBc195280e2b54d0927DF4;
    mapping (address => uint256) user;
    uint256 winning_number;
    uint256 winning_ether;

    uint256 total_user1;
    uint256 total_user2;
    uint256 total_user3;
    uint256 total_user4;
    uint256 total_user5;

    function lottery_in(uint256 number) public payable {
        if(msg.value == 0.01 ether){
            user[msg.sender] = number;
            if (number == 1){
                total_user1 = total_user1 + 1;
            } else if (number == 2){
                total_user1 = total_user2 + 1;
            } else if (number == 3){
                total_user1 = total_user3 + 1;
            } else if (number == 4){
                total_user1 = total_user4 + 1;
            } else if (number == 5){
                total_user1 = total_user5 + 1;
            }
            
        }else{
            revert();
        }
    }

    function lottery_set(uint256 number) public {

        if (address(msg.sender) == admin_addr){        
            winning_number = number;
            if (number == 1){
                if (total_user1 > 0){
                    winning_ether = address(this).balance / total_user1;
                }
                else{
                    winning_ether = address(this).balance;
                }
            } else if (number == 2){
                if (total_user2 > 0){
                    winning_ether = address(this).balance / total_user2;
                }
                else{
                    winning_ether = address(this).balance;
                }
            } else if (number == 3){
                if (total_user3 > 0){
                    winning_ether = address(this).balance / total_user3;
                }
                else{
                    winning_ether = address(this).balance;
                }
            } else if (number == 4){
                if (total_user4 > 0){
                    winning_ether = address(this).balance / total_user4;
                }
                else{
                    winning_ether = address(this).balance;
                }
            } else if (number == 5){
                if (total_user5 > 0){
                    winning_ether = address(this).balance / total_user5;
                }
                else{
                    winning_ether = address(this).balance;
                }
            }
        }else{
            revert();
        }
    }

    function claim() public {
        if(user[msg.sender] == winning_number){
            address payable to = payable(msg.sender);
            to.transfer(winning_ether);
            user[msg.sender] = 0; 
        }else{
            revert();
        }
    }
}