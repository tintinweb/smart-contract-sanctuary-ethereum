/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TestFund {

    address public owner;
    Student[] public ListStudents;

    struct Student {
        address _diachi;
        uint _money;
        string _message;
    }

    constructor(){
        owner = msg.sender;
    }
    function getAllStudents () public view returns(Student[] memory){
        return ListStudents;
    }
    
    event SMVuaNhanDuocTien(address _diachi, uint _soTien, string loiChuc);
    function Deposit(string memory _message) public payable{
        require(msg.value >= 10**15, 'min value must be 0.01BNB');
        ListStudents.push(Student(msg.sender, msg.value, _message));
        emit SMVuaNhanDuocTien(msg.sender, msg.value, _message);
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "not owner");
        _;
    }

    function Withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function Counter() public view returns(uint){
        return ListStudents.length;
    }
    function getDetail(uint _ordering) public view returns(address, uint, string memory){
        if(_ordering < ListStudents.length){
            return (ListStudents[_ordering]._diachi, 
            ListStudents[_ordering]._money,
            ListStudents[_ordering]._message) ;
        } else {
            return (0x000000000000000000000000000000000000dEaD, 0, "");
        }
    }

}