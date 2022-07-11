// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Base1{
    event Log1(string fync, string msg);
    function foo() virtual public {
        emit Log1("Base1->foo","I am here!");
    }
}

contract Base2 {
    event Log2(string fync, string msg);
    function foo() virtual public{
        emit Log2("Base2->foo","I am here!");
    }
}

contract Inherited is Base1, Base2 {
    event Log3(string fync, string msg);
    function foo() public override(Base1, Base2){
        emit Log3("Inherited->foo","I am here!");
    }
}