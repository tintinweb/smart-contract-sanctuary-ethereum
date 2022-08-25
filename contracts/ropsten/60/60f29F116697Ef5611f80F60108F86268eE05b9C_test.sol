/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test {
   struct Book { 
      string title;
      string author;
      uint book_id;
      uint totalpages;
   }
   Book book;

   function setBook() public {
      book = Book('Learn Java', 'TP', 1,100);
   }
   function getBookId() public view returns (uint) {
      return book.book_id;
   }

   function getbooktitle()public view returns(string memory) {
       return book.title;
   }

   function getbookauthor() public view returns (string memory){
       return book.author;
   } 
   function gettotalpages() public view returns(uint){
       return book.totalpages;
   }
}