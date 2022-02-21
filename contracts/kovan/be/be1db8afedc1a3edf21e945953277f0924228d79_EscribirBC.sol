/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity >= 0.7.0 < 0.8.0;

contract EscribirBC {
    string texto;
    function Escribir(string calldata _texto) public {
        texto = _texto;
    }
    function Leer() public view returns(string memory) {
        return texto;
    } 
}