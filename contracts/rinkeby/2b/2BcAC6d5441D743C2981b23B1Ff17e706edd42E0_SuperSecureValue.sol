// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SuperSecureValue  {
    
    string internal secureValue;
    
    constructor() {
      secureValue = "";
    }

    function readValue() external view returns (string memory) {
      return secureValue;
    }

    function storeValue(string calldata newValue) external {
      secureValue = newValue;
    }
    
}