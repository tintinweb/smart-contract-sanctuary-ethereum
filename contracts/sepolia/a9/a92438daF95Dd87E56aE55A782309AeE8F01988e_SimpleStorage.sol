/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    // Storage
    uint256 public storedValue; // Slot 0

    // Functions
    // getsStoredValue funcion de solo lectura (Consulta de estado)
    //function getStoredValue() public view returns (uint256) {
        //return storedValue;
    //}
    // setStoredValue funcion de escritura del estado (Transaccion)
    function setStoredValue(uint256 newStoredValue) public {
        // Poner el valor de newStoredValue en storedValue
        storedValue = newStoredValue;
    }
}