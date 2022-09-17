// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contratto estremamente semplice: permette di immagazzinare e restituire un valore
// quando viene aggiornato il valore viene emesso un evento
contract Box
{
    uint256 private value;

    event ValueChanged(uint256 newValue);

    // Usiamo la funzione store come initializer function, ovvero quella funzione NON COSTRUTTORE
    // che chiamiamo non appena deployamo il contratto.
    function store(uint256 newValue) public 
    {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256)
    {
        return value;
    }
}