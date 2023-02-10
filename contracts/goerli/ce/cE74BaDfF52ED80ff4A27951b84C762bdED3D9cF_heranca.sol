/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.18;

    contract heranca{

        mapping (string => uint)valorAReceber;
        address public owner = msg.sender;

        function EscreveHeranca(string memory _nome, uint _valor) public{

            require(msg.sender == owner);
            valorAReceber[_nome] = _valor;

        }

        function consultaHeranca(string memory _nome) public view returns(uint){
            return valorAReceber[_nome];
        }



}