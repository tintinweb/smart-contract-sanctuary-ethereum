/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;
contract Lotto{

    address Owner;constructor(){
        Owner=msg.sender;
    }

    function donate() public payable{

    }

    function onlinelotto_transaction(uint number1, uint number2, uint number3) public payable {
        require(number1 >= 1 && number1 <= 20, "Number1 invalid.");
        require(number2 >= 1 && number2 <= 20, "Number2 invalid.");
        require(number3 >= 1 && number3 <= 20, "Number3 invalid.");
        require(msg.value >= 500000000000000000, "Pay at least 0.5 rEth.");


        if(number1 == randomLottoNumber()) {
            payable(tx.origin).transfer(balance() / 1000);
        }
        if(number2 == randomLottoNumber()) {
            payable(tx.origin).transfer(balance() / 1000);
        }
        if(number3 == randomLottoNumber()) {
            payable(tx.origin).transfer(balance() / 1000);
        }
        
        if(number1 == randomLottoNumber() && number2 == randomLottoNumber()) {
            payable(tx.origin).transfer(balance() / 100);
        }
        if(number1 == randomLottoNumber() && number3 == randomLottoNumber()) {
            payable(tx.origin).transfer(balance() / 100);
        }
        if(number2 == randomLottoNumber() && number3 == randomLottoNumber()) {
            payable(tx.origin).transfer(balance() / 100);
        }


        if(number1 == randomLottoNumber() && number2 == randomLottoNumber() && number3 == randomLottoNumber()) {
            payable(tx.origin).transfer(balance() / 2);
        }
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }

    function randomLottoNumber() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % 20 + 1;
    }

    function paybacktoowner(uint amount)public {require (Owner==msg.sender);
        payable(tx.origin).transfer(amount);

    }
}