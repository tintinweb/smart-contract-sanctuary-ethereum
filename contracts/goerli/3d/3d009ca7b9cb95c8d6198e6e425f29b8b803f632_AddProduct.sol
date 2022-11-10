/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract AvarageOf10people{

        uint256 average;
        uint256 public avarageNumber ;
        uint256 first;  uint256 second; uint256 third; uint256 fourth; uint256 fifth; uint256 sixth;  uint256 seventh; 
        uint256 eighth; uint256 ninth; uint256 tenth;

                
        function setTenPerson(uint256 _first, uint256 _second, uint256 _third, uint256 _fourth, uint256 _fifth,
            uint256 _sixth, uint256 _seventh, uint256 _eight, uint256 _ninth, uint256 _tenth) public{

             first = _first;
             second = _second;
             third = _third;
             fourth = _fourth;
             fifth = _fifth;
             sixth = _sixth;
             seventh = _seventh;
             eighth = _eight;
             ninth = _ninth;
             tenth = _tenth;  

             average = first + second + _third + _fourth + _fifth + _sixth + _seventh + _eight + _ninth + _tenth;                 

            avarageNumber = average / 10;
                 
             



        }

}





contract GradeNum{


    uint256 marks;
    string public result;

    function setMarks(uint256 _marks)public {
        marks = _marks;
        if(_marks < 0){
           result =  "please give a valid number";
        }else if(_marks < 60){
            result = "You are fail";
        }else if(_marks < 70){
            result = "You got Grad D";
        }else if(_marks < 80){
            result = "You got Grad C";
        }else if(_marks < 90){
            result = "You got Grad B";
        }else if(_marks < 100){
            result = "You got Grad A";
        }else {
            result = "please give valid marks";
        }

    }

}



contract Leapyear{

    uint256 year;

    string public result;

    function checkLeapYear(uint256 _year) public {
        year = _year;
        if (_year % 400 == 0){
        result = "This is leap year";
        }else if(_year % 100 == 0){
        result = "This is not leap year";
    }   else if(_year % 4 == 0){
        result = "This is leap year";

    }   else{
        result = "This is not leap year";
    }


    }

}




contract AddProduct{
    struct Product{
        string title;
        string desc;
        address payable seller;
        uint productId;
        uint price;
        address buyer;
       
    }

    uint counter = 1;
    Product[] public products;

    event registered(string title, uint productId, address seller);
    event bought(uint productId, address buyer);
    event delivered(uint productId);

    function registerProduct(string memory _title, string memory _desc, uint _price) public {
        require(_price>0, "price should be greater than 0");
       
       Product memory temProduct;

       temProduct.title = _title;
       temProduct.desc = _desc;
       temProduct.price = _price * 10**8;
       temProduct.seller = payable(msg.sender);
       temProduct.productId = counter;
       products.push(temProduct);
       counter++;
       emit registered(_title, temProduct.productId, msg.sender);


    }

    function buy(uint _productId) payable public{
        require(products[_productId-1].price==msg.value, "please pay the exact price");
        require(products[_productId-1].seller!=msg.sender, "seller can't be the buyer");
        products[_productId-1].buyer =msg.sender;
        emit bought(_productId, msg.sender);
    }

    
}