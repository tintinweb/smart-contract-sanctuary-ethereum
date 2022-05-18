/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity 0.8.13;

contract Password {

  string public password;

  constructor(string memory _password) public {
    password = _password;
  }

  function isPassword(string memory _password) external view returns (bool) {
    return (keccak256(abi.encodePacked((password))) == keccak256(abi.encodePacked((_password))));
  }

}