// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SAEReimburse {

    address saeOwner;
    uint256 public constant amount = 0.011 ether;

    constructor(address _saeOwner){
        saeOwner = _saeOwner;
    }

    function reimburse(address[] calldata _addresses, uint8[] calldata _totals) external payable {
      require(msg.sender == saeOwner, "Method can only be called by SAE Owner");
      require(_addresses.length == _totals.length, "Length of arrays do not match");

      for(uint16 i = 0; i < _addresses.length; i++) {
        (bool success, ) = payable(_addresses[i]).call{value: _totals[i] * amount}("");
        require(success, "Failed to send Ether");
      }
    }

}