/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

contract Aula {

    string public timeDoCoracao;

    constructor() {
        timeDoCoracao = "SPFC";
    }

    function mudarTime(string memory _novoTimeDoCoracao) public returns (bool, uint8) {
        timeDoCoracao = _novoTimeDoCoracao;
        return (true, 1);
    }
}