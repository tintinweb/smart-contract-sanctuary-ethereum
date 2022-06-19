/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract HelloWeb3{
    string public _string_0 = "My first step!";
    string public _string_1 = "Goal, creat an shit nft in the next bull! ";
    uint public _number = 5;
    uint public number_1 = _number + 1 ;
    uint public number_12 = 2**3;
    uint public number_3 =7%3;
    bool public number_4 = number_12>=number_3;
    
    enum f {x1, x2, y1, y2 }
    f number_5 = f.y1;
    function change() external view returns(uint){
        return uint(number_5);
    }
    function Paytome() external payable returns(address sender, uint256 balance,uint256 gas){
        balance=address(this).balance;
        address  sender_address=msg.sender;
        uint gas_limit=block.gaslimit;
 
        return (sender_address, balance,gas_limit);
    }
    function backtoyou() external payable returns(uint256){
        address payable sender_address=payable(msg.sender);
        sender_address.transfer(address(this).balance-block.gaslimit);
        return(address(this).balance);

    }

    }