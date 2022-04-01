/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 <0.9.0;

contract Projects{

    address private project1 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address payable private wallet1 = payable(address(project1));
    string private name1 = "andres";
    uint private totalAmount1 = 10000000000000000000;
    uint private collected1 = 0;
    bool private isFull1 = false;

    address private project2 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address payable private wallet2 = payable(address(project2));
    string private name2 = "Beto";
    uint private totalAmount2 = 20000000000000000000;
    uint private collected2 = 0;
    bool private isFull2 = false;

    address private project3 = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    address payable private wallet3 = payable(address(project3));
    string private name3 = "Carlos";
    uint private totalAmount3 = 30000000000000000000;
    uint private collected3 = 0;
    bool private isFull3 = false;
  

    function fundProject(uint  _number) public payable returns(string memory stateTx, uint valor, uint collected){

       if(_number>=1 && _number<=3)
       {
       valor= msg.value;

       if(_number==1 && !isFull1){
        collected1 += msg.value; //+ at the counter
        wallet1.transfer(msg.value); //send money
        stateTx = "success";
        collected = collected1;

        if(collected1>=totalAmount1){
            changeProjectState(1);
        }

       }

        if(_number==2 && !isFull2){
        collected2 += msg.value; //+ at the counter
        wallet2.transfer(msg.value); //send money
        stateTx = "success";
        collected = collected2;

        if(collected2>=totalAmount2){changeProjectState(2);}

       }

        if(_number==3 && !isFull3){
        collected3 += msg.value; //+ at the counter
        wallet3.transfer(msg.value); //send money
        stateTx = "success";
        collected = collected3;

        if(collected3>=totalAmount3){changeProjectState(3);}

       }

       }
       else{
           stateTx = "failed";
       }   
    }

    function changeProjectState(uint _option) private{

        if(_option>=1 && _option<=3){
        if(_option==1){isFull1=true;}
        if(_option==2){isFull2=true;}
        if(_option==3){isFull3=true;}
      }
    }

    function getBalances(uint _number) public view returns(uint balance){
        if(_number>=1 && _number<=3){
            if(_number==1){balance=collected1;}
            if(_number==2){balance=collected2;}
            if(_number==3){balance=collected3;}
        }
    }

}