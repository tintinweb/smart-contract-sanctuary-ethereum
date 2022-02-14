/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {

    address public author=msg.sender;
    mapping(address => uint) public joined;
    bool public closed=false;
    uint public price=0.02 ether;
    uint constant Target = 10 ether;
    uint public endTime=block.timestamp+30 days;
    uint256 public jisuanResult;

    function updatePrice() internal{
        price=address(this).balance/1*0.02 ether+0.02 ether;
    }


    function deposit() external payable {
        require(joined[msg.sender] == 0, "you have join fund");
        require(!closed,"fund have closed");
        require(msg.value>price,"price too low");
        joined[msg.sender]=msg.value;
        updatePrice();
    }

    function authorWithdrawFund() external{
        require(msg.sender==author,"you are not author");
        require(address(this).balance>Target);
        closed=true;
        // msg.sender.transfer(address(this).balance);
        // msg.sender.transfer(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);

        
    }

    function withdraw() external{
        require(!closed,"fund have closed,fund have withdraw");
        // require(joined[address]!=0,"您未参加众筹");
        require(address(this).balance<Target,"you can't withdraw money");
        payable(msg.sender).transfer(joined[msg.sender]);
    }


    

    function jisuan(uint a) external {
        uint256 temp =1 ether;
        jisuanResult=temp+a;
        price=address(this).balance/1*0.02 ether+0.02 ether;
    }

    

}