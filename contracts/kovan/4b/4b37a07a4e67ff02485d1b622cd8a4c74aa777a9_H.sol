/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract E {

    event Log(string nessage);

    function foo() public virtual{
            emit Log("E,foo");
          
    }

    function bar() public virtual{
            emit Log("E,bar");
           
    }
}

contract F is E{

    function foo() public virtual override{
            emit Log("F,foo");
              E.foo();
    }

    function bar() public virtual override{
            emit Log("F,bar");
             super.bar();
    }
}

contract G is E{

    function foo() public virtual override{
            emit Log("G,foo");
            E.foo();
    }

    function bar() public virtual override{
            emit Log("G,bar");
             super.bar();
    }
}


contract H is F,G{

    function foo() public override (F,G){
            emit Log("G,foo");
            E.foo();
    }

    function bar() public override(F,G){
            emit Log("G,bar");
             super.bar();
    }
}