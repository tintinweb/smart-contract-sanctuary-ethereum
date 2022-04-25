/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract myToken {

string private tokenName;
string private tokenSymbol;
uint8 private tokenDecimals;
uint256 private tokenSupply;

constructor(string memory _name, string memory _symbol, uint8 _decimal, uint256 _supply) {
    tokenName = _name;
    tokenSymbol = _symbol;
    tokenDecimals = _decimal;
    tokenSupply = _supply;
}



event Transfer(address indexed _from, address indexed _to, uint256 _value);

event Approval(address indexed _owner, address indexed _spender, uint256 _value);


function name() public view returns (string memory) {
    return tokenName;
}

function getKYCStatus(bool value) public pure returns (bool) {
    return !value;
}



function symbol() public view returns (string memory) {
    return tokenSymbol;
}

function decimals() public view returns (uint8) {
    return tokenDecimals;
}

function totalSupply() public view returns (uint256) {
    return tokenSupply;
}

}