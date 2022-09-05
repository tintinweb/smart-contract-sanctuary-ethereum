// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract HolaMundo {
    string hola = "Hola";
    string mundo = "Mundo!!";

    function saludar() external view returns (string memory) {
        return string(abi.encodePacked(hola, " ", mundo));
    }

    function saludarConNombre(string calldata nombre)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("Hola ", nombre));
    }
}