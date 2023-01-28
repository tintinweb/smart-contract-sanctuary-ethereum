/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: GPL-3.0

abstract contract AbstractGWF_ReverseRegistrar {
  function claim(address owner) external virtual returns (bytes32);
  function claimWithResolver(address owner, address resolver) external virtual returns (bytes32);
  function setName(string memory name) external virtual returns (bytes32);
  function node(address addr) external virtual pure returns (bytes32);
}

abstract contract AbstractTM {
  function owner() external view virtual returns (address ow);
}

abstract contract AbstractGWPC {
  function getMasterCopy() external view virtual returns (address);
}


/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// ProxyToken adapted and applied for shares and token by pepihasenfuss.eth
pragma solidity ^0.8.16 <0.8.18;

contract ProxyToken {
    address internal masterCopy;

    bytes32 internal name32;
    uint256 private ownerPrices;

    mapping (address => uint256) private balances;
    mapping (address => mapping  (address => uint256)) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);
    event Deployment(address owner, address theContract);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor(address _masterCopy) payable
    {
      masterCopy = _masterCopy;
    }
    
    fallback () external payable
    {   
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let master := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, master)
                return(0, 0x20)
            }

            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let success := delegatecall(gas(), master, ptr, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { 
              if eq(returndatasize(),0) { revert(0, 0x204) }
              revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
    
    function upgrade(address master) external payable {
      require(AbstractTM(masterCopy).owner()==AbstractTM(master).owner()," owner masterCopy!");
      masterCopy = master;
    }
    
    receive() external payable { emit Deposit(msg.sender, msg.value); }         // *** PTC may receive payments ***
}