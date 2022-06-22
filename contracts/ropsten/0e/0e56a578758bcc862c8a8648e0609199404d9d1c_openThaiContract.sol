/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract openThaiContract{

    struct Contract{
        address user;
        string created_at;
        string hashed;
        string detail;
    }

    mapping(address => Contract[]) public Contracts;

 
    function store(string memory _created_at, string memory _hashed, string memory _detail) public {
        Contracts[msg.sender].push(Contract(msg.sender,_created_at,_hashed,_detail));
    }

    function numContract() public view returns(uint){
        return Contracts[msg.sender].length;
    }
    function retrieve(uint index) public view returns (Contract memory){
        require(index<Contracts[msg.sender].length,"out of bound");
        return Contracts[msg.sender][index];
    }

    function retrieveAll() public view returns (Contract[] memory){
        return Contracts[msg.sender];
    }



    function wave() public pure returns (string memory){
        string memory message= "hi";
        return message;
    }
}