// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract sa {
    uint public a;
    uint public b;
    function set(uint _a)public virtual{
        a=_a;
    }
}

contract sam is sa{
    function set(uint _a)public override{
        b=_a;
    }
}