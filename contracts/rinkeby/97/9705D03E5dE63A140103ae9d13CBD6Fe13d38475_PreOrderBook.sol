/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PreOrderBook{
    struct PreOrder{

        string name;
        string bookName;
        string email;
        string addresspm;
        string phone;
        string price;
        string date;
    }


    mapping(uint => PreOrder) public bookMapping;

    uint BookCount;

    function bookBill(string memory _name,string memory _bookName,string memory _email,string memory _addresspm,string memory _phone,string memory _price,string memory _date) public{
        bookMapping[BookCount].name = _name;
        bookMapping[BookCount].bookName = _bookName;
        bookMapping[BookCount].email = _email;
        bookMapping[BookCount].addresspm = _addresspm;
        bookMapping[BookCount].phone = _phone;
        bookMapping[BookCount].price = _price;
        bookMapping[BookCount].date = _date;
        BookCount++;

    }

    function retrievePreOrder() public view returns (string[] memory, string[] memory, string[] memory, string[] memory, string[] memory, string[] memory, string[] memory){
        string[] memory _name = new string[](BookCount);
        string[] memory _bookName = new string[](BookCount);
        string[] memory _email = new string[](BookCount);
        string[] memory _addresspm = new string[](BookCount);
        string[] memory _phone = new string[](BookCount);
        string[] memory _price = new string[](BookCount);
        string[] memory _date = new string[](BookCount);

        for(uint loop = 0; loop < BookCount; loop++){
            _name[loop] = bookMapping[loop].name;
            _bookName[loop] = bookMapping[loop].bookName;
            _email[loop] = bookMapping[loop].email;
            _addresspm[loop] = bookMapping[loop].addresspm;
            _phone[loop] = bookMapping[loop].phone;
            _price[loop] = bookMapping[loop].price;
            _date[loop] = bookMapping[loop].date;
        }
        return ( _name,_bookName,_email,_addresspm,_phone,_price,_date);
    }
}