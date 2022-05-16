//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

//Contrato para chamar outros contratos: 0x9D3AD8ad4f9454D676a8C333eB9Ae64D3B2c9D82

interface IChamado {
    function serChamada() external returns(string memory teste);
}


contract Greeter {
    
    constructor () {
    }

    uint256 public x;
    string public teste;
    address public immutable chamado = 0xB1D70C5A64f682c5F7ed2259c42295b0977Ffdc8;

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

    function chamarContrato() external {
        IChamado(chamado).serChamada();
    }

    function retornarString() public returns(string memory) {
        teste = "okokfuncionou";
        return teste;
    }

    function retornarStringEx() external returns(string memory) {
        teste = "funcionouokok";
        return teste;
    }

    function retornarString3() public view returns(string memory) {
        return teste;
    }
}