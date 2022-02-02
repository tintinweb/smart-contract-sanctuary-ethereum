//SPDX-License-Identifier:MIT

import "./Simple.sol";

pragma solidity ^0.8.0;

contract Test{ 

  function test()public pure returns(string memory){
    Simple simple = Simple(0x3ecB71cd448204bdDA929772Cf30Ea790eEFC24B);
    return simple.foo();
  }
}