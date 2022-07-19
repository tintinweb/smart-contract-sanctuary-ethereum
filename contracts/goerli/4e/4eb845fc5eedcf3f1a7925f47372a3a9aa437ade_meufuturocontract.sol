// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.9.0;

contract meufuturocontract{
//estrutura das mensagens
struct seufuturo{
string oqueserameufuturo;
}
//armazenando as mensagens dos endereços na estrutura
//podemos consultar as msgs pelo mapping público
mapping(address => seufuturo) public msgsmeufuturo; 

//parametro inserido na construção do contrato 
constructor(string memory _oqueserameufuturo){
//salvando na estrutura a mensagem referente ao seu endereço
msgsmeufuturo[msg.sender].oqueserameufuturo = _oqueserameufuturo;
}
//sua msg de retorno 
function meufuturo() public view returns(string memory ,string memory){
return("Meu futuro sera",msgsmeufuturo[msg.sender].oqueserameufuturo);
}

//função de interação 
function inserirMeufuturo(string memory _meufuturo) public {
msgsmeufuturo[msg.sender].oqueserameufuturo = _meufuturo;
}

}