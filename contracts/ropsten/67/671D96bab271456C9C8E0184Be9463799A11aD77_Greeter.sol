//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Greeter {
    
    constructor () {
    }

    uint256 x;
    string teste;

    function testFunction() external pure returns(string memory) {
        return "Hey, funcionou!";
    }

    function useFunction(bytes4 _selector, address _to) external returns(bytes memory retorno) {
        (bool success, bytes memory retorno) = _to.call(abi.encode(_selector));
    }

    function retornarSelector() external view returns(bytes4) {
        return bytes4(keccak256(bytes("testFunction()")));
    }
    
    function serChamada() external returns(string memory teste) {
        teste = "Consegui editar com selector";
    }

    function retornarBytes4SerChamada() public view returns(bytes4){
        return bytes4(keccak256(bytes("serChamada()")));
    }

}