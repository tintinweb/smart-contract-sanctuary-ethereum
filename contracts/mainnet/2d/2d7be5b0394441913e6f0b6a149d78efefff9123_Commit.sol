/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

pragma solidity ^0.6.2;

contract Commit {
  event LogCommitment(bytes32 commitment);

  function commit(bytes32 commitment) public {
      emit LogCommitment(commitment);
  }
}