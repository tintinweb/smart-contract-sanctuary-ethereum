/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// new stuff SPDX-License-Identifier: GPL-3.0

//pragma solidity >=0.7.0 <0.9.0;

pragma solidity ^0.8.13;

contract test {
//    address public owner;
 //   string [2] public;// AAAAAAAAAAAAAAAAAAAAAAAAAA = "David";
        string private firs4name = "David" ;
        string private las4name = "Jones" ;

    string public retS1 = "kelly";
    string public retS2 = "jason";
    //string MiddleName = "Doris";

    constructor () {
  //      myfunc(FirstName,    Surname);
//        string [2] public;// AAAAAAAAAAAAAAAAAAAAAAAAAA = "David";
//        myfunc("firstname", "lastname");
    }

    function myfunc(string memory s1, string memory s2) public {
        
        retS1 = firs4name ;
        retS2 = las4name ;
    }

}