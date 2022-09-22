/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
contract bookInfo{
 
     struct book{
    
        string name;
     }
        

    uint public price;
    book public Book;
    function bookData(string memory _name) public{
        Book.name = _name;
        if(keccak256(abi.encodePacked(_name))== keccak256(abi.encodePacked("C++"))){
                price = 30000;
                    
        }
        else if(keccak256(abi.encodePacked(_name))== keccak256(abi.encodePacked("bioinformatics"))){
                price = 2000;
                    
        }
    }
}