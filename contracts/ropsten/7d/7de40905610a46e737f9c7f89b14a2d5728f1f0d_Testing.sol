/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity ^0.8.12;

contract Testing {

    string private _name;
    string private _symbol;

    constructor(string memory name_,string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }
}