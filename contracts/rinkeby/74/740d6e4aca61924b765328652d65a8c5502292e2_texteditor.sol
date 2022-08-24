/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

contract texteditor {
     uint256 public id=0;

struct book {
    string block;
    string coordinates;
}

mapping(uint256=>mapping(uint256 => book)) bookStore;
mapping(uint256=>uint256) bookBlockIndex;

function save(uint256 bookId,string calldata _block, string calldata _coordinates) public{
    book memory temp_book =  book(_block,_coordinates);
    bookStore[bookId][bookBlockIndex[bookId]]=temp_book;
    bookBlockIndex[bookId]++;
}

function read_book(uint256 bookid,uint256 bookBlockid)view public returns (string memory,string memory){
    return (bookStore[bookid][bookBlockid].block,bookStore[bookid][bookBlockid].coordinates);
}

function remove_book(uint bookid,uint256 bookBlockid) public {
    delete bookStore[bookid][bookBlockid];
}

}