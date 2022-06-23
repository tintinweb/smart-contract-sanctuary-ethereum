/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract openThaiContract{

    struct Contract{
        address owner;
        string created_at;
        string hashed;
        string detail;
    }

    mapping(address => Contract[]) public Contracts;

 
    function store(string memory _created_at, string memory _hashed, string memory _detail) public {
        Contracts[msg.sender].push(Contract(msg.sender,_created_at,_hashed,_detail));
    }

    function numberOfContract() public view returns(uint){
        return Contracts[msg.sender].length;
    }


    function retrieveAll() public view returns (Contract[] memory){
        return Contracts[msg.sender];
    }

    function deleteAll() public{
        delete Contracts[msg.sender];
    }

    //test function
    function wave() public pure returns (string memory){
        string memory message= "hi";
        return message;
    }
}