/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract SCM{
   
    address saray = 0x640E3De84b8dEE2480731F0596d2f9894704BC23; //Accont2
    address expert = 0xbDB0cCCA872dED5BAb94C9D5bEf7ae50591e152E;//Account3
    
    modifier onlySaray{
        require(msg.sender == saray); _;
    }
    modifier onlyExpert{
        require(msg.sender == expert); _;
    }
    
    enum Status {Pass, Fail, NonSign}
    
    struct Product{
        uint productid;
        string productname;
        uint artistid;
        string artistname;
        uint expertid;
        string expetrtname;
        Status status;
        address expertaddress;
    }
    
    //uint[] products;
    
    mapping(uint => Product) products_status;

    
    
    function AddProduct(
            uint _productid, 
            string memory _productname,
            uint _artistid,
            string memory _artistname,
            uint _expertid,
            string memory _expetrtname
        ) public onlySaray{
        products_status[_productid] = Product(_productid, _productname,_artistid, _artistname, _expertid, _expetrtname, Status.NonSign, msg.sender);
    }
    
    function InfoProduct(uint _pid) public view returns(Product memory){

        return products_status[_pid];
    }
    
    function SignPassProduct(uint _productID) public onlyExpert returns(string memory){
        products_status[_productID].status = Status.Pass;
        products_status[_productID].expertaddress = msg.sender;
        return "success_set_pass";
    }
    
    function SignFailProduct(uint _productID) public onlyExpert returns(string memory){
        products_status[_productID].status = Status.Fail;
        products_status[_productID].expertaddress = msg.sender;
        return "success_set_fail";
    }

    

    int public number = 10;
    function getNum() public view returns(int){
        return number;
    }
    function setNumber(int _number) public{
        number = _number;
    }
}