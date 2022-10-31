/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyContract {
    string private _name;
    string private _symbol;

    constructor(string memory _name_c, string memory _symbol_c) public {
        _name = _name_c;
        _symbol = _symbol_c;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function test(uint256 a) public returns(uint256) {
        return a;
    }
}