/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// É necessário especificar a versão do compilador solidity

contract Voting {
    
  /* O campo mapping abaixo é equivalente a uma matriz associativa ou hash.
   A chave do mapping é o nome do candidato armazenado como tipo bytes32 e o valor é
   um inteiro sem sinal para armazenar a contagem de votos
  */
  mapping (bytes32 => uint256) public totalVotes;
  
  /* Importante: O Solidity não permite que você passe uma série de strings no construtor (ainda).
   Usaremos uma matriz de bytes32 em vez de armazenar a lista de candidatos
  */
  bytes32[] public candidates;

  /* Este é o método construtor que será chamado uma vez quando for
   implantar o contrato no blockchain. Quando o contrato é implantado,
   uma série de candidatos que irão disputar a eleição será aprovada.
   
   Segue a lista de candidatos exemplo (basta copiar e colar no campo de deploy ao lado): 
   ["0x4361737369616e6f000000000000000000000000000000000000000000000000","0x4361726c6f730000000000000000000000000000000000000000000000000000","0x4a6f616f00000000000000000000000000000000000000000000000000000000"]
   Obs: Os nomes estão convertidos para bytes32 e representam os seguintes nomes ["Cassiano", "Carlos", "Joao"]
  */
  constructor(bytes32[] memory names) {
    candidates = names;
  }

  // Retorna a quantidade de votos recebidos por um candidato
  function totalVotesFor(bytes32 candidate) view public returns (uint256) {
    require(isValid(candidate));
    return totalVotes[candidate];
  }

  // Esta função incrementa a quantidade de votos recebidas por um candidato
  function insertVote(bytes32 candidate) public {
    require(isValid(candidate));
    totalVotes[candidate] += 1;
  }

  function isValid(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidates.length; i++) {
      if (candidates[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}