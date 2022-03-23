/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract GoldKu {
    address own;
    receive() external payable {}
    constructor()  {
        own = msg.sender;
    }

    function withdraw() public payable{
        payable(msg.sender).transfer(address(this).balance);
    }

    function ETH_balance() public view returns(uint){
        return address(this).balance;
    }
    
}