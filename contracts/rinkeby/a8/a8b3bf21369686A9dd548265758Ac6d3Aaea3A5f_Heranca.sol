/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


/*contract HelloWorld {

    string public name;
    uint public numeroEscolhido; //uint não aceita numeros negativos (unsigned integer)

    function setName(string memory _qualquerNome) public {
        name = _qualquerNome;
    }

    function getName() public view returns(string memory){
        return name;
    } //no solidity quando declaramos uma variável como pública uma função como o
    // getName não é necessária, já que a própria linguagem já retorna a váriavel

    function setNumeroEscolhido(uint _numero) public {
        numeroEscolhido = _numero;
    }

}*/

/*contract Soma {

    uint private x;
    uint public y;

    function setXY(uint _x, uint _y) public {
        x = _x;
        y = _y;
    }

    function soma() public view returns (uint){
        return x+y;
    }

}*/

contract Heranca {

    mapping(string => uint) private valorAReceber; //o equivalente ao dicionário da linguagem solidity

    function escreveValor(string memory _nome, uint valor) public {
        valorAReceber[_nome] = valor;
    }


    //visibilidade: public, private, external, internal (sendo que public e private 
    //podem ser acessadas externamente ao contrato, e a external e internal só podem 
    //ser acessadas de dentro do contrato)
    function pegaValor(string memory _nome) public view returns (uint) {

        return valorAReceber[_nome];

    }

}