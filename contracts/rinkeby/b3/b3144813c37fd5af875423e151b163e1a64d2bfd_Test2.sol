/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    contract Test2 {
     function callsetnum (int newnum) public returns(int) {
           Test t =  Test (0xf8e81D47203A594245E36C48e151709F0C19fBe8);
          return t.setnum ( newnum );
        }
    }

    contract Test {
        int public num ;
        function setnum(int newnum) public returns (int){
            num = newnum;
            return newnum;
        }
    }