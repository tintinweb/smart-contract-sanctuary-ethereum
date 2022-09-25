/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.12;

contract ControlePonto {
    address internal owner;
    mapping(address => string[]) internal registroPonto;
    string[] internal pontoArray;
    string internal nome;
    string internal empresa;
    string internal cpf;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function setNome(string memory _nome) public onlyOwner{
        nome = _nome;
    }

    function setEmpresa(string memory _empresa) public onlyOwner{
        empresa = _empresa;
    }

    function setDocumento(string memory _cpf) public onlyOwner{
        cpf = _cpf;
    }

    function registrarPonto(string memory hora) public onlyOwner{
        pontoArray.push(hora);
        registroPonto[owner] = pontoArray;
    }

    function getPonto() public view returns(string[] memory) {
        return pontoArray;
    }

    function getProprietario() public  view returns(string memory) {
        string memory dados;

        dados = string.concat(dados, nome);
        dados = string.concat(dados, ",");
        dados = string.concat(dados, empresa);
        dados = string.concat(dados, ",");
        dados = string.concat(dados, cpf);

        return dados;
    }

    function getEnderecoProprietario() public view returns(address) {
        return owner;
    }
}