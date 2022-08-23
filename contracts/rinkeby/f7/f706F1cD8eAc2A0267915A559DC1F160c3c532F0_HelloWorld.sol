/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// File: contracts/hello.sol


// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.13;




contract HelloWorld {
    uint256 a;
    string  greet = "Hello World!";

function store(uint256 _a) public {
    a= _a;

}
  function retrive() public view returns(uint256)
  {
      return a;
  }
}