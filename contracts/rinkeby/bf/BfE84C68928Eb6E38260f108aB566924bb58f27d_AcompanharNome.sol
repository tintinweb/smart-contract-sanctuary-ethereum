/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

pragma solidity ^0.8.7;

contract AcompanharNome {

    string public nome;

    function mudarNome(string memory _nome) public {
        nome = _nome;
    }

}