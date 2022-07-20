/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity ^0.5.0;

contract People {

    uint maxAge = 1000;

}

contract father is People{

    uint public fatherAge = 30;

}

contract mother is People{

    uint public motherAge = 20;

}

contract son is People, father,mother{//儿子继承父亲，母亲的属性

    uint public age=10;

}