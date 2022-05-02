/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

contract EscribirEnLaBlockchain2 {
    string texto;
    address currentAdress;

    function Escribir(string calldata _texto) public {
        texto = _texto;
        currentAdress = msg.sender;
    }

    function Leer() public view returns(string memory) {
        return texto;
    }

    function LeerSender() public view returns(address) {
        return currentAdress;
    }
}