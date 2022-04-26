/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

contract Structs {
    
   struct Book { 
      string title;
      string author;
      uint book_id;
   }
   
   Book book1;
   Book book2;

   function setBook() public {
      book1 = Book('Learn Java', 'TP', 1);
      book2 = Book('Learn Solidity', 'Ram', 2);
   }
   
   function getBookId1() public view returns (uint) {
      return book1.book_id;
   }
   
   function getAuthor1() public view returns (string memory) {
      return book1.author;
   }
   
   function getTitle1() public view returns (string memory) {
      return book1.title;
   }
   
   
   
   function getBookId2() public view returns (uint) {
      return book2.book_id;
   }
   
   function getAuthor2() public view returns (string memory) {
      return book2.author;
   }
   
   function getTitle2() public view returns (string memory) {
      return book2.title;
   }
}