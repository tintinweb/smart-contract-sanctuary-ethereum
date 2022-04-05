/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

 contract first {

 string public name;
 string public lastname;

 function enterdata(string memory _name,string memory _lastname)public  {


name = _name;
lastname = _lastname;

 }

function show ()public view returns (string memory)       {

return name;



}

 }