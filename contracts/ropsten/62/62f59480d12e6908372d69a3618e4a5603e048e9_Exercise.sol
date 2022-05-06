/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract Exercise {
    
    string public date = "2022-05-06";
    bool hora1;
    bool hora2;
    bool hora3;
    bool hora4;

//  bool public hora1 = true;
//  bool public hora2 = true;
//  bool public hora3 = true;
//  bool public hora4 = true;

    struct oFormando {
        string nome;
        bool hora1;
        bool hora2;
        bool hora3;
        bool hora4;
    }

    struct oFormador {
        string nome;
        bool hora1;
        bool hora2;
        bool hora3;
        bool hora4;
    }


    oFormando[] public formando;
    oFormador[] public formador;

    function Formando(string memory _nome, bool _hora1, bool _hora2, bool _hora3, bool _hora4) public{
        formando.push(oFormando(_nome, _hora1, _hora2, _hora3, _hora4));
    }

    function Formador(string memory _nome, bool _hora1, bool _hora2, bool _hora3, bool _hora4) public{
        formador.push(oFormador(_nome, _hora1, _hora2, _hora3, _hora4));
    }
}