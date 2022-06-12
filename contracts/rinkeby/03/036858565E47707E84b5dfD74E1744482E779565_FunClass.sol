/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract FunClass{

    Student[] public ArrayStudent;
    address public Owner;
    uint public countArray;

    struct Student {
        address Account;
        uint Amount;
        string content;

    }
    constructor(){
        Owner=msg.sender;
    }

    modifier CheckOwner(){
        require(msg.sender==Owner,"You are not the owner");
        _;
    }
    function SendDonate(string memory content)public payable {
        require(msg.value>= 10**15," Minimun is 0.001 BNB");
        ArrayStudent.push(Student(msg.sender,msg.value, content));
        countArray +=1;
    }

    function Get_1_Student(uint index)public view returns (address, uint,  string memory){
        require(index< ArrayStudent.length," number is invalid");
        return (ArrayStudent[index].Account, ArrayStudent[index].Amount, ArrayStudent[index].content);      
    }
    function GetBalane() public view returns(uint){
        return address(this).balance;
    }
    function Withdraw() public CheckOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}
//Contract Address BSC: 0x2920826a14cDfa9dfbfb3E70c45ce58d51FA06fe