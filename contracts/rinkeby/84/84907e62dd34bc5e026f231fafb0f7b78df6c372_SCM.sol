/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract SCM{
   
    address saray = 0xbDB0cCCA872dED5BAb94C9D5bEf7ae50591e152E; //Accont2
    address expert = 0xC3505768117da1f5B3EE5c06A7B7dD6a99d52001;//Account3
    
    modifier onlySaray{
        require(msg.sender == saray); _;
    }
    modifier onlyExpert{
        require(msg.sender == expert); _;
    }
    
    enum Status {Pass, Fail, NonSign}
    
    struct Product{
        uint id;
        string name;
        Status status;
        address expert;
    }
    
    //uint[] products;
    
    mapping(uint => Product) products_status;

    uint num = 121;
    function example() public view returns(uint){
        return num;
    }
    
    function AddProduct(uint _id, string memory _name) public onlySaray{
        //products.push(_id);
        products_status[_id] = Product(_id, _name, Status.NonSign, msg.sender);
    }
    
    function InfoProduct(uint _pid) public view returns(string memory){
        return products_status[_pid].name;
    }
    
    function SignPassProduct(uint _productID) public onlyExpert returns(string memory){
        products_status[_productID].status = Status.Pass;
        products_status[_productID].expert = msg.sender;
        return 'success_set_pass';
    }
    
    function SignFailProduct(uint _productID) public returns(string memory){
        products_status[_productID].status = Status.Fail;
        products_status[_productID].expert = msg.sender;
        return 'success_set_fail';
    }

    function ret() public pure returns(string memory){
        return '121';
    }

}