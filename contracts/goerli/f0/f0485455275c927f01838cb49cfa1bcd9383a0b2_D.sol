/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract BaseContract
{
    event Log(string message);

    function print() public virtual
    {
        emit Log("BaseContract.print()");
    }
}

contract A is BaseContract
{
    function print() public virtual override
    {
        emit Log("A.print()");
        // BaseContract.print();
        super.print();
    }
}

contract B is BaseContract
{
    function print() public virtual override
    {
        emit Log("B.print()");
        // BaseContract.print();
        super.print();
    }
}

contract C
{
    event CLog(string message);
    function gogogo() public
    {
        emit CLog("C.gogogo()");
    }
}

contract D is A, B, C
{
    function print() public virtual override(A, B)
    {
        emit Log("D.print()");
        // A.print();
        // B.print();
        super.print();
    }
}