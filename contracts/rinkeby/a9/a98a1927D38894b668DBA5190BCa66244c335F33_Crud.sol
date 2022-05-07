// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Crud{

    struct Pessoa{
        string nome;
        uint256 id;
        uint256 idade;
    }
    address public Owner = msg.sender;

    mapping(address => Pessoa) public MapArrayPessoas;

    function Add(string memory _nome,uint256 _id,uint256 _idade)public {
        MapArrayPessoas[msg.sender]= (Pessoa({nome : _nome, id: _id,idade: _idade}));
    }
    function Remove()public {
       delete MapArrayPessoas[msg.sender];
    }
    function Update_Nome(string memory _nome)public {
        MapArrayPessoas[msg.sender].nome = _nome;
    }
    function Update_id(uint256 _id)public {
        MapArrayPessoas[msg.sender].id = _id;
    }
    function Update_idade(uint256 _idade)public {
        MapArrayPessoas[msg.sender].idade = _idade;
    }
    function Get(address chamador)public view returns(string memory,uint256,uint256){
        return(MapArrayPessoas[chamador].nome,MapArrayPessoas[chamador].id,MapArrayPessoas[chamador].idade);
    }

    constructor(){
        MapArrayPessoas[msg.sender].nome = "gui";
        MapArrayPessoas[msg.sender].id = 4;
        MapArrayPessoas[msg.sender].idade = 25;
    }

}