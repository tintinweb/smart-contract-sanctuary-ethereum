/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
contract test{
struct Book { 
      string title;
      string author;
      uint _book_id;
   }
   Book[] public book;


   function setBook() public  {
      Book memory details1 = Book('Learn Java', 'TP', 1);
      Book memory details2  = Book('_solidity', 'pp', 2);
      Book memory details3  = Book('_solidity advance', 'ahmad', 3);
      book.push(details1);
      book.push(details2);
      book.push(details3);

   }
   function getBooktitel(uint _bookid) public view returns (string memory) {
      return book[_bookid].title ;
   }
}