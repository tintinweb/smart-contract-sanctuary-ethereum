/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

contract EscribirEnLaBlockchain {
    string texto;

    function Escribir(string calldata _texto) public {
        texto = _texto;
    }

    function Leer() public view returns(string memory) {
        return texto;
    }
}