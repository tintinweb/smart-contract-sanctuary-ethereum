/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FunctionModifier {

    address private owner;
    string public _DevIsBased = "Yes, Tomas is fucking Based";

    constructor() {
        // Guardamos la información del dueño del contrato para validar al mismo
        owner = msg.sender;
    }

    uint256 public _marketingTax = 2;
    uint256 public _devFee = 1;


    // Modificador para validar que la llamada la realiza el dueño del contrato
    modifier onlyOwner() {
        require(msg.sender == owner, "No eres el owner");
        _;
    }

    
    function modifyTotalFee(uint256 _newMarketingTax, uint256 _newDevFee) public onlyOwner{
        _marketingTax = _newMarketingTax;
        _devFee = _newDevFee;
    }

    // Solo el dueño del proyecto puede cambiar al mismo
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}