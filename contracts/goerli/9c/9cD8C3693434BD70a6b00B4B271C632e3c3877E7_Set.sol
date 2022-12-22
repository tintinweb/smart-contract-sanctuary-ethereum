/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

pragma solidity ^0.4.16;

library Set {
    struct Data { mapping(uint => bool) flags; }

    function insert(Data storage self, uint value)
    public
    returns (bool)
    {
        if (self.flags[value])
            return false; // 已存在
        self.flags[value] = true;
        return true;
    }

    function remove(Data storage self, uint value)
    public
    returns (bool)
    {
        if (!self.flags[value])
            return false;
        self.flags[value] = false;
        return true;
    }

    function contains(Data storage self, uint value)
    public
    view
    returns (bool)
    {
        return self.flags[value];
    }
}