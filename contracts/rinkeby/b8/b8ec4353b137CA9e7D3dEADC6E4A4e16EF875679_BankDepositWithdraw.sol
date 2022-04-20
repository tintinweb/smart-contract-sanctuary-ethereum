/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.8.0; //SPDX-License-Identifier: UNLICENSED

contract BankDepositWithdraw {
    mapping(address => uint256) public balanceOf; 
    uint256 public deadline;

     function deposit() external payable {
        balanceOf[msg.sender] += msg.value;   
        deadline = block.timestamp + 25;  
    }

    function windraw() external CheckAddress() CheckTime(){
         payable(msg.sender).transfer(balanceOf[msg.sender]);
    
    }

    function currentBlockTime() external view returns(uint){
        return block.timestamp;
    }

    modifier CheckAddress(){
        require(balanceOf[msg.sender] > 0, 'not an valid addresss');

        _;
    }
    modifier CheckTime(){
        require(block.timestamp >= deadline, 'wait ');

        _;
    }


}