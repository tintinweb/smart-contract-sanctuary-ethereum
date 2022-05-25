/**
 * SPDX-License-Identifier: MIT
**/

import './Testdemo.sol';

pragma solidity =0.7.6;


contract TestCaller {

     Test c;

    function test () public {
       c = Test(0xf819fDbCbcF62A8A7ca5EB7db612CFB2C0315351);
       c.test();
        
    }

}