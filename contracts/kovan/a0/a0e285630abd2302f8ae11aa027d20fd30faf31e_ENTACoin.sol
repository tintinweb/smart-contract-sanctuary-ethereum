/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract ENTACoin {

    address public owner = msg.sender;

    string public NomeMoeda;
    string public Tag;

    mapping (address => uint256) public NumeroDeMoedas;

    address ENTA = 0x11cf464aB69fF79f6cb1023604FD86dC652D2C78;

    function DarMoedas(uint256 initialBalance, string memory _NomeMoeda, string memory _Tag) public{
        require(ENTA== msg.sender, unicode"You are not the owner of the coin.");

        NumeroDeMoedas[owner] = initialBalance;
        NomeMoeda= _NomeMoeda;
        Tag = _Tag;   
    }

    // Função para fazer transferências:
    function TransferirMoedas(address _to, uint256 _amount) public returns (bool success){
        
        require (NumeroDeMoedas[msg.sender] >= _amount);                
        require (NumeroDeMoedas[_to] + _amount >= NumeroDeMoedas[_to]);       

        NumeroDeMoedas[msg.sender] -= _amount;   
 
        NumeroDeMoedas[_to] += _amount;
        return true;
    }


}