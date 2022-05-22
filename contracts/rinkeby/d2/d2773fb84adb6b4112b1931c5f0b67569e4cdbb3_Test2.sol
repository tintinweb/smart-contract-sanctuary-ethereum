/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    contract Test2 {
     function callsetnum (int newnum) public returns(int) {
           Test t =  Test (0xd9145CCE52D386f254917e481eB44e9943F39138);
          return t.setnum (newnum);
        }
    }

    contract Test {
        int public num ;
        function setnum(int newnum) public returns (int){
            num = newnum;
            return newnum;
        }
    }