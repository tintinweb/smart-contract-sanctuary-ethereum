//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint public nombreFavori;

    function changerNombre(uint _nombre) public {
        nombreFavori = _nombre;
    }

    function lireNombre() public view returns (uint) {
        return nombreFavori;
    }
}