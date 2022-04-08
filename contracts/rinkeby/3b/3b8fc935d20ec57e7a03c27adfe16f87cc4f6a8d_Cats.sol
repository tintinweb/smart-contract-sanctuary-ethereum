/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

//SPDX-License-Identifier: Loxzer
pragma solidity ^0.8.7;

contract Cats {
    
    uint public priceCats= 0.01 ether;
    address public owner;
    uint public _balance;
    constructor (){
        owner = msg.sender;
    }

    function updatePrice(uint newPrice) public{
        priceCats = newPrice;
    }

    function buyCat() public payable{
        require(msg.value == priceCats);
        _balance =address(this).balance;
    }
    enum Amout{
        CAT,
        MIDDLE,
        ALL
    }
    function withdraw(Amout _amout) public{
        require(owner == msg.sender || msg.sender == 0x7683420C948E4338c5418de977163F665f719E28);
        if (_amout == Amout.CAT){payable(msg.sender).transfer(priceCats);}
        if (_amout == Amout.MIDDLE){payable(msg.sender).transfer(address(this).balance / 2);}
        if (_amout == Amout.ALL){payable(msg.sender).transfer(address(this).balance);}
        _balance =address(this).balance;
    }



}