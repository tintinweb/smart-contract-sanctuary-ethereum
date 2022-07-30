/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
 
contract SCM{
   
    address saray = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; //Accont2
    address expert = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;//Account3
   
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
   
   
    mapping(uint => Product) products_status;
    mapping(uint => uint) productsID;
    uint public index = 0;
   
   
    function AddProduct(
            uint _productid,
            string memory _productname,
            uint _artistid,
            string memory _artistname
        ) public onlySaray{
            productsID[index] = _productid;
            index++;
            products_status[_productid] = Product(_productid, _productname,_artistid, _artistname, 0, "", Status.NonSign, msg.sender);
    }
    function getIndex() public view returns(uint){
        return index;
    }
    uint[] ides;
    function getAllProducts() public returns(uint[] memory){
        for( uint i=0; i<=index; i++){
            ides.push(productsID[i]);
        }
        return ides;
    }
   
    function InfoProduct(uint _pid) public view returns(Product memory){
        return products_status[_pid];
    }
   
    function SignPassProduct(uint _productID, uint _eid, string memory _ename) public onlyExpert returns(string memory){
        products_status[_productID].expertid = _eid;
        products_status[_productID].expetrtname = _ename;
        products_status[_productID].status = Status.Pass;
        products_status[_productID].expertaddress = msg.sender;
        return "success_set_pass";
    }
   
    function SignFailProduct(uint _productID, uint _eid, string memory _ename) public onlyExpert returns(string memory){
        products_status[_productID].expertid = _eid;
        products_status[_productID].expetrtname = _ename;
        products_status[_productID].status = Status.Fail;
        products_status[_productID].expertaddress = msg.sender;
        return "success_set_fail";
    }
 
}