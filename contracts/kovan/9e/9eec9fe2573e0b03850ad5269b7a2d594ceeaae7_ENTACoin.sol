/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
pragma abicoder v2;

contract ENTACoin {

    address public owner = msg.sender;

    string public tokenName;
    string public tokenTag;

    mapping (address => uint256) public balanceOf;

    address ENTA = 0x7799e5710B5210A45CF5e87F405D644d2A2A46C1;

    function AreaDirecaoENTA(uint256 initialBalance, string memory _tokenName, string memory _tokenTag) public{
        require(ENTA== msg.sender, unicode"Apenas o criador é bem-vindo!");

        balanceOf[owner] = initialBalance;      // Funcionalidade:
        tokenName= _tokenName;                  // Inserir o montante inicial que o "criador" vai receber
        tokenTag = _tokenTag;                   // Inserir o nome e a tag do token
    }

    // Função para fazer transferências:
    function EnviarTOKENs(address _to, uint256 _amount) public returns (bool success){
        
        require (balanceOf[msg.sender] >= _amount);                 // Vai verificar se o "sender" tem tokens suficientes
        require (balanceOf[_to] + _amount >= balanceOf[_to]);       

        balanceOf[msg.sender] -= _amount;        // Vai subtrair da conta do "sender" o valor que foi transferido
        balanceOf[_to] += _amount;               // Vai adicionar ao "destinatário" o valor que foi subtraido do "sender"

        return true;
    }

    // Depois de o TOKEN estar criado
    // Ir à MetaMask -> "import token" -> o endereço do token é o enderço do contrato -> inserir o simbolo do token -> Decimal: 0

}