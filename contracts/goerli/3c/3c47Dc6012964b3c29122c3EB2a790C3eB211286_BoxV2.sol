// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contratto estremamente semplice: permette di immagazzinare e restituire un valore
// quando viene aggiornato il valore viene emesso un evento
// Nella versione 2 aggiungiamo solamente la funzione increment
contract BoxV2
{
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public 
    {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256)
    {
        return value;
    }

    function increment() public
    {
        value = value + 1;
        emit ValueChanged(value);
    }
}