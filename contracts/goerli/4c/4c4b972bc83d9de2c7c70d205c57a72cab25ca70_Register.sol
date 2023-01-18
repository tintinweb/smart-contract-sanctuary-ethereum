/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
 
contract Register {
        string private info;
         // Essa variavel pode ser acessado apenas em modo privado dentro do smarcontract
   
        function getInfo() public view returns (string memory) {
            return info;
            // Essa função mostra a informação que salvei 
        }
 
        function setInfo(string memory _info) public {
            info = _info;

            // com essa função consigo monitorar as transações cada vez que utilizo setInfo
        }
}