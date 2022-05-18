/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Heranca {
    mapping(string => uint) private dest;
    address public owner = msg.sender;

    function escreveValor(string memory _nome, uint valor) public {
        require(msg.sender == owner);
        dest[_nome] = valor;
    }

    function getDest(string memory _nome) public view returns (uint) {
        return dest[_nome];
    }
}