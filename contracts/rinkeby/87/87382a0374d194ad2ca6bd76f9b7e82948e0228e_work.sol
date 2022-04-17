/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract work {


event success (uint indexed , string indexed  );

string name ;

    function eventtt ( string memory _name )  public payable{
        name = _name; 
        emit success( (msg.sender).balance, "name is assigned" );
    }
}