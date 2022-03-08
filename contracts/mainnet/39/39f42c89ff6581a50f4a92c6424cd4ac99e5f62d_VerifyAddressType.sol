/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

pragma solidity >=0.7.0 <0.9.0;

contract VerifyAddressType {
    function isContractByOpenzeppelin(address account) external view returns (bool) {
      return Address.isContract(account);
    }
  
    function isContract(address addr) external view returns (bool) {

      uint size;

      assembly { size := extcodesize(addr) }

      return size > 0;

    }
}