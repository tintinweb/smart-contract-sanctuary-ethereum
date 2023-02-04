/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract METATATU {

    mapping (address => uint) public balances;
    string public name = "METATU";
    string public symbol = "TATU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000 * (10 ** uint256(decimals));

    constructor() public {
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value, "Not enough balance");
        require(_to != address(0), "Invalid address");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
}