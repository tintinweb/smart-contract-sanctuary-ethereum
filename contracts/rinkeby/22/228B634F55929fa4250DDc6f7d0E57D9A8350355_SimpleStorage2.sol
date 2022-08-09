/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

pragma solidity ^0.5.0;

contract SimpleStorage2 {
  string public data;

  function set(string memory _data) public {
    data = _data;
  }

  function get() view public returns(string memory) {
    return data;
  }
}