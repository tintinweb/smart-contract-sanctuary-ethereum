/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () virtual payable external {
    _fallback();
  }
  
  receive () virtual payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() virtual internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() virtual internal {
      
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    //if(OpenZeppelinUpgradesAddress.isContract(msg.sender) && msg.data.length == 0 && gasleft() <= 2300)         // for receive ETH only from other contract
    if(OpenZeppelinUpgradesAddress.isContract(msg.sender) && msg.data.length == 0)         // for receive ETH only from other contract
        return;
    _willFallback();
    _delegate(_implementation());
  }
}

library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

interface IBeacon {
    function governor() external view returns (address);
    function __admin__() external view returns (address);
    function implementation() external view returns (address);
    function implementations(bytes32 shard) external view returns (address);
}

contract Constants {
    address internal constant _NPics_           = 0xA2f78200746F73662ea8b5b721fDA86CB0880F15;
    bytes32 internal constant _SHARD_NEO_       = 0;
    bytes32 internal constant _SHARD_NBP_       = bytes32(uint(1));
}

contract BeaconProxyNEO is Proxy, Constants {
    function _implementation() virtual override internal view returns (address) {
        return IBeacon(_NPics_).implementations(_SHARD_NEO_);
  }
}