/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract E
{
    event Log(string message);

    function print() public virtual
    {
        emit Log("E.print()");
    }
}

contract F is E
{
    function print() public virtual override
    {
        emit Log("F.print()");
        // E.print();
        super.print();
    }
}

contract G is E
{
    function print() public virtual override
    {
        emit Log("G.print()");
        // E.print();
        super.print();
    }
}

contract H is F, G
{
    function print() public virtual override(F, G)
    {
        emit Log("H.print()");
        // F.print();
        // G.print();
        super.print();
    }
}