/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity >=0.4.22 <0.7.0;

contract Sorteo {

    uint256 numeroSecreto;
    uint256 posibilidades;
    bool activo;
    address ganador;


    event Resultado(bool ganador, uint256 premio, uint256 bote);

    constructor() public{
        activo=false;
        ganador = address(0);
    }

    function random() private view returns(uint){
        return uint256(keccak256(abi.encodePacked(block.difficulty, now)));
    }

    function participar(uint256 numero) public payable{
        require(activo);
        require(numero>0 && numero <= posibilidades);
        require(msg.value == 0.0001 ether);
        if (numero == numeroSecreto){
            uint256 premio = address(this).balance;
            msg.sender.transfer(premio);
            emit Resultado(true, premio, 0);
            ganador = msg.sender;
            activo = false;
        }
        else{
            emit Resultado(false, 0, address(this).balance);
        }
    }

    function bote() public view returns (uint256){
        return address(this).balance;
    }

    function estaActivo() public view returns (bool){
        return activo;
    }

    function quienHaGanado() public view returns (address){
        return ganador;
    }

    function cuantasPosibilidades() public view returns (uint256){
        return posibilidades;
    }

    function cargar(uint256 numeros) public payable{
        require(!activo);
        posibilidades = numeros;
        numeroSecreto = (random() % numeros)+1;
        ganador = address(0);
        activo = true;
    }
}