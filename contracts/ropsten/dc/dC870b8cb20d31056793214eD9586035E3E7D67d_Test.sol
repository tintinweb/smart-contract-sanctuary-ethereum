/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract Test
{
    string private _msg;

    constructor()
    {
        _msg = "Hello";
    }

    function getMessage() external view returns (string memory)
    {
        return _msg;
    }

    function setMessage(string memory _msg_) external
    {
        _msg = _msg_;
    }
}