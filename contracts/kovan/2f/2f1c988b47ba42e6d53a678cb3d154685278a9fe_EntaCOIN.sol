/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.20;

contract EntaCOIN {


    address public owner = msg.sender;
    string public NomeToken;
    string public TagToken;

    mapping (address => uint256) public NumeroDeMoedas;

    function DarMoeda(uint256 initialSupply, string _NomeToken, string _TagToken) public {
        NumeroDeMoedas[owner] = initialSupply;
        NomeToken = _NomeToken;
        TagToken = _TagToken;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(NumeroDeMoedas[msg.sender] >= _value);
        require(NumeroDeMoedas[_to] + _value >= NumeroDeMoedas[_to]);
        NumeroDeMoedas[msg.sender] -= _value;
        NumeroDeMoedas[_to] += _value;
        return true;
    }
}