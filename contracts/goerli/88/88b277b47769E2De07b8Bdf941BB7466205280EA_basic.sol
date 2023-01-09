// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract basic{

    uint public num = 5;

    function setter(uint num1) public {
        num=num1;
    }
    function receive_money() public payable{
        
    }
    function send_money(uint money) public {
        payable(msg.sender).transfer(money);
    }
    
    function get_balance() view public returns(uint bal) {
        return address(this).balance;
    }
}