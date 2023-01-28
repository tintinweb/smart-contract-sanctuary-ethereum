/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: GPL-3.0
/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// ProxyGroupWallet adapted and applied for GroupWallet by pepihasenfuss.eth
pragma solidity ^0.8.16 <0.8.18;

abstract contract AbstractGWF_ReverseRegistrar {
  function claim(address owner) external virtual returns (bytes32);
  function claimWithResolver(address owner, address resolver) external virtual returns (bytes32);
  function setName(string memory name) external virtual returns (bytes32);
  function node(address addr) external virtual pure returns (bytes32);
}

abstract contract AbstractGWPC {
  function getMasterCopy() external view virtual returns (address);
}

contract ProxyGroupWallet {
    address internal masterCopy;

    mapping(uint256 => uint256) private tArr;
    address[]                   private owners;
    
    address internal GWF;                                                       // GWF - GroupWalletFactory contract
    mapping(uint256 => bytes)   private structures;
  
    // *************************************************************************
    event Deposit(address dep_from, uint256 dep_value);
    
    constructor(address _masterCopy, string memory _domain, AbstractGWF_ReverseRegistrar _reverse) payable
    { 
      masterCopy = _masterCopy;
      _reverse.setName(_domain);
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
      require(AbstractGWPC(masterCopy).getMasterCopy()==AbstractGWPC(master).getMasterCopy()," gwp gwpc owner!");
      masterCopy = master;
    }
    
    receive() external payable { emit Deposit(msg.sender, msg.value); }         // *** GWP can sell common shares to TokenProxy, thus reveiving payment ***
}