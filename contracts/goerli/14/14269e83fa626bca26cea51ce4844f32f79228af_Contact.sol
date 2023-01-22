/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Contact{

    address owner;

    constructor(){
        owner=msg.sender;
    }

    struct ContactDetails{
        string name;
        uint product_id;
        string concern;
    }

    ContactDetails[] public p;

    modifier onlyOwner(){
        require(msg.sender==owner,"Only the owner can send this message.");
        _;
    }

    function sendConcern(string memory _name,uint _id,string memory _concern)public{
     p.push(
         ContactDetails({
             name:_name,
             product_id:_id,
             concern:_concern
         })
     );
    }


    function getConcerns()public view onlyOwner returns(ContactDetails[] memory){
        return p;
    }
}