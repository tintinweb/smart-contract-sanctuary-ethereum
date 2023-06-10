/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Ejercicio1RenzoRenato {

    string private gretting = "Hello Ethereum";
    address private owner;
    address private direccionNoValida;

    constructor (){
        owner = msg.sender;
    }


    function getGretting() view public returns(string memory) {
        return gretting;
    }

    modifier ValidarOwner() {
        require(owner == msg.sender, "No eres el owner del contrato");
        _;
    }

    modifier ValidarAddress() {
        require(msg.sender>direccionNoValida, "Direccion no valida");
        _;
    }

    function setGretting(string memory _gretting) public ValidarOwner ValidarAddress{
        emit grettingChanged(msg.sender, gretting, _gretting);
        gretting = _gretting;
    }

    function changeOwner(address _newOwner) public ValidarOwner {
        emit ownerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    event grettingChanged(address direccion, string oldGretting, string newGreeting);
    event ownerChanged(address oldOwner, address newOwner);
}