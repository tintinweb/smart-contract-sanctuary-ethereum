pragma solidity ^0.8.0;

contract MerkleProof {
  struct userData{
        address _wallet;
        bytes32 password;
    }
   bytes32 public root = 0xdc90733af3aca9491b12c7331f402fcf4125ca049f929184284e0bbdde42bc6e;
   mapping(bytes32 => userData) public data;

   //DUMMY DATA ADD USER
   //ADDRESS: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
   //USER: 0x00000000000000000000000000000000000000000000616268697368656b7368
   //PASSWORD: 0xdc90733af3aca9491b12c7331f402fcf4125ca049f929184284e0bbdde42bc6e
   
  function addUser(address _wallet, bytes32 _user, bytes32 password) public {
    require(data[_user]._wallet == address(0), "THIS USER ALREADY EXIST.");
    data[_user] = userData(_wallet,password);
  }

  //DUMMY DATA VERIFY PROOF
  //PROOF: ["0x0638d297af6d64984635a8a3ef8f9846d80e329bbc4257d664450ad460e05b67","0x4dc98316390ed7bafbf7169a7fe567a3f601f8b790edcd0824a5869dd6716e0e","0x0f1348c16197b9ff851906d70a3bfe5abf4a4c3cac3c31918a9593838d85a26a"]
  //LEAF: 0xa75fc2c892c5f6169d4898ec344e04fefa775bec94ce9789162a33ba8190feaa

  function verifyProof(bytes32 _user, bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
  require(data[_user]._wallet != address(0), "THIS USER DOES NOT EXIST.");
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];
      //computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else { 
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }
    // Check if the computed hash (root) is equal to the provided root
    return computedHash == data[_user].password;
  }
}