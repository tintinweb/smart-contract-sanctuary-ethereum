//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
   address owner;
    bool flag;
    uint256 price;
    uint firstscore;
    address firstaddress;
    constructor(){
        owner = msg.sender;
        flag = false;
    }

    function addPlayer(uint score) public  payable{
        if(!flag){
            price = msg.value;
            firstaddress = msg.sender;
            firstscore = score;
            flag = !flag;
            return;
        }
        if(flag){
            require(msg.value>=price);

            if(score > firstscore){
                address payable to = payable(msg.sender);
                to.transfer(address(this).balance * 95/100);
                withdrawMoney();
            }
            if(score < firstscore){
                address payable to = payable(firstaddress);
                to.transfer(address(this).balance * 95/100);
                withdrawMoney();
            }
            flag = !flag;
        }
        
    }

    function withdrawMoney() public {
        address payable to = payable(owner);
        to.transfer(address(this).balance);
    }

    function getprice() public view returns(uint256){
        return price;
    }

    function getscore() public view returns(uint256){
        return firstscore;
    }

    function getstate() public view returns(bool){
        return flag;
    }
}