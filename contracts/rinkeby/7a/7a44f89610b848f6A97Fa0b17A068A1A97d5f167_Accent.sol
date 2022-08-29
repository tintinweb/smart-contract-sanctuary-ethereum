//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Accent
{
   uint256 transaction;

   mapping(string => uint256) public nameToTransaction;

    struct People 
    {
        uint256 str;
        string name;
    }

    People[] public people;


    function buy(uint256 transactionPay) public virtual 
    {
        transaction += transactionPay;
    }
     
    function retrieve() public view returns(uint256)
    {
        return transaction;
    }

   

    function addPerson(string memory _name, uint256 _str) public
    {
        people.push(People(_str, _name));
        nameToTransaction[_name] = _str;
    }
}