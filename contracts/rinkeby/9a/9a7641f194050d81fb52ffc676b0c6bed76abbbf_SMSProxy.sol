/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract SMSProxy {
    
    // Storage position of the address of the current implementation
    bytes32 private constant implementationPosition = 
        keccak256("xyz.secretmoneysociety.implementation.address");
    
    // Storage position of the owner of the contract
    bytes32 private constant proxyOwnerPosition = 
        keccak256("xyz.secretmoneysociety.proxy.owner");

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner());
        _;
    }
    
    /**
    * @dev the constructor sets owner
    */
    constructor() {
        _setUpgradeabilityOwner(msg.sender);
    }
    
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */
    function transferProxyOwnership(address _newOwner) 
        public onlyProxyOwner 
    {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
    }
    
    /**
     * @dev Allows the proxy owner to upgrade the implementation
     * @param _implementation address of the new implementation
     */
    function upgradeTo(address _implementation) 
        public onlyProxyOwner
    {
        _upgradeTo(_implementation);
    }
    
    /**
     * @dev Tells the address of the current implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }
    
    /**
     * @dev Tells the address of the owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }
    
    /**
     * @dev Sets the address of the current implementation
     * @param _newImplementation address of the new implementation
     */
    function _setImplementation(address _newImplementation) 
        internal 
    {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }
    
    /**
     * @dev Upgrades the implementation address
     * @param _newImplementation address of the new implementation
     */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
    
    /**
     * @dev Sets the address of the owner
     */
    function _setUpgradeabilityOwner(address _newProxyOwner) 
        internal 
    {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    fallback () external payable {
        address implementation = implementation();
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
}