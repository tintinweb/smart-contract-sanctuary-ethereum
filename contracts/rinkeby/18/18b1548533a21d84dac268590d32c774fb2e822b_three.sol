/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;


contract three{
    
   
    uint public constant duration= 100;

    struct user{
        uint end;
        bool isClicked;
        uint256 depositedbalance;
    }
    mapping(address=>user) Users;

    function deposit() external payable{

        Users[msg.sender] = user(0,false,Users[msg.sender].depositedbalance + msg.value);

    }

    function balanceOfContract() external view returns(uint){
        return address(this).balance;
    }

    function balanceOfCurrentUser() external view returns(uint256){
        return Users[msg.sender].depositedbalance;
    }

    function withdraw(uint256 _withdrawAmount) external{
        if( Users[msg.sender].isClicked==false){
            Users[msg.sender].end = block.timestamp + duration;
            Users[msg.sender].isClicked=true;
            return;
            }
        require(block.timestamp>=Users[msg.sender].end, "Locked! wait for the time duration to end");
        require(Users[msg.sender].depositedbalance >= _withdrawAmount,"Insufficient Balance");
        payable(msg.sender).transfer(_withdrawAmount);
        Users[msg.sender].depositedbalance -= _withdrawAmount;
        
    }
}