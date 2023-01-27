// SPDX-License-Identifier: MIT

// El comentari anterior és per treure el warning que mostra al posar la següent comanda

pragma solidity >= 0.7.3;

contract AdoptaGossos{
    address[16] public perrosAdoptados;
    uint public balanceWei = 0;

    function adoptar(uint perroIndex) payable public returns (bool){

        require (perroIndex >= 0 && perroIndex <= 15, "Fora de rang");

        require (msg.value == 0.1 ether, "Quantitat insuficient per adoptar");

        balanceWei = balanceWei + msg.value;

        bool adoptarConExito = true;

        if (perrosAdoptados[perroIndex] == address(0)){
            perrosAdoptados[perroIndex] = msg.sender;
        } else {
            adoptarConExito = false;
        }

        return adoptarConExito;
    }

    function getPerrosAdoptados() public view returns (address[16] memory){
        return perrosAdoptados;
    }
}