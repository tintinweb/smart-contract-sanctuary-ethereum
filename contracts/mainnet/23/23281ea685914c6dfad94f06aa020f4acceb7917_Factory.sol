/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: OSL-3.0

pragma solidity 0.8.11;

contract Factory {

  mapping(uint256 => bool) private _usedSalts;

  event Deployed(address indexed contractAddress, uint256 indexed salt);

  constructor() {}

  function deploy(bytes memory code, uint256 salt) public {
    require(!_usedSalts[salt], "salt already used");
    address addr;
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }
    emit Deployed(addr, salt);
    _usedSalts[salt] = true;
  }

}