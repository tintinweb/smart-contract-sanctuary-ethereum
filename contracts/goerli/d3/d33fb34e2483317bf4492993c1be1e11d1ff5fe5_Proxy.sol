/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity ^0.4.18;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {

    // 最后一次添加的合约地址
    address internal rootToken=0xfDb61FB43e2e3B5A19B26Ff17eabd1c3D2110360;
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address){
      return rootToken;
  }

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable public {
    address _impl = rootToken;
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}