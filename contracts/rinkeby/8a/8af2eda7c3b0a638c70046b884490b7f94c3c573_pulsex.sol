/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract pulsex {

     /*********************************
               VARIABLES
    ***********************************/

    address public Owner ;
    uint public counter;
    

    /**********************************
               MAPPING
    ***********************************/
    mapping (uint => address) private userKey;
    mapping (uint => uint) private userValue;




    /**********************************
               CONSTRUCTOR
    ***********************************/
    constructor(){
        Owner = msg.sender;
    }

    /**********************************
               FUNCTIONS
    ***********************************/

    function submit ( ) public payable {
        (bool success, ) = Owner.call{value: msg.value}("");
        require(success, "Failed to send Ether");

        counter++;
        userKey[counter]  = msg.sender;
        userValue[counter]  = msg.value;
    } 

    function getUserAndValue(uint _key ) public view returns(address user, uint value){
        user = userKey[_key];
        value = userValue[_key];
    }

    
}