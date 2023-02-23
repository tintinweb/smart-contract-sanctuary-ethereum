/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface ISecurityManager  {
    
    /**
     * Returns `true` if `account` has been granted `role`.
     * 
     * @param role The role to query. 
     * @param account Does this account have the specified role?
     */
    function hasRole(bytes32 role, address account) external returns (bool); 
}

abstract contract ManagedSecurity is Context {
    ISecurityManager public securityManager; 
    
    //security roles 
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GENERAL_MANAGER_ROLE = keccak256("GENERAL_MANAGER_ROLE");
    bytes32 public constant LIFECYCLE_MANAGER_ROLE = keccak256("LIFECYCLE_MANAGER_ROLE");
    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");
    bytes32 public constant DEPOSIT_MANAGER_ROLE = keccak256("DEPOSIT_MANAGER_ROLE");
    
    //thrown when the onlyRole modifier reverts 
    error UnauthorizedAccess(bytes32 roleId, address addr); 
    
    //thrown if zero-address argument passed for securityManager
    error ZeroAddressArgument(); 
    
    //Restricts function calls to callers that have a specified security role only 
    modifier onlyRole(bytes32 role) {
        if (!securityManager.hasRole(role, _msgSender())) {
            revert UnauthorizedAccess(role, _msgSender());
        }
        _;
    }
    
    /**
     * Allows an authorized caller to set the securityManager address. 
     * 
     * Reverts: 
     * - {UnauthorizedAccess}: if caller is not authorized 
     * - {ZeroAddressArgument}: if the address passed is 0x0
     * - 'Address: low-level delegate call failed' (if `_securityManager` is not legit)
     * 
     * @param _securityManager Address of an ISecurityManager. 
     */
    function setSecurityManager(ISecurityManager _securityManager) external onlyRole(ADMIN_ROLE) {
        _setSecurityManager(_securityManager); 
    }
    
    /**
     * This call helps to check that a given address is a legitimate SecurityManager contract, by 
     * attempting to call one of its read-only methods. If it fails, this function will revert. 
     * 
     * @param _securityManager The address to check & verify 
     */
    function _setSecurityManager(ISecurityManager _securityManager) internal {
        
        //address can't be zero
        if (address(_securityManager) == address(0)) 
            revert ZeroAddressArgument(); 
            
        //this line will fail if security manager is invalid address
        _securityManager.hasRole(ADMIN_ROLE, address(this)); 
        
        //set the security manager
        securityManager = _securityManager;
    }
    
    //future-proof, as this is inherited by upgradeable contracts
    uint256[50] private __gap;
}

interface IWhitelist  {
    
    /**
     * Indicates whether or not the given address is in the contained. 
     * 
     * @param addr The address to query. 
     * @return True if the given address is on the whitelist, otherwise false.
     */
    function isWhitelisted(address addr) external returns (bool); 
}

contract Whitelist is IWhitelist, ManagedSecurity {
    mapping(address => bool) private whitelisted;   //stores the whitelist 
    bool public whitelistOn = true;                 //enables/disables whitelist 
    
    //events 
    event WhitelistOnOffChanged(address indexed caller, bool value); 
    event WhitelistAddedRemoved(address indexed caller, address indexed addr, bool value); 
    
    /**
     * Creates an instance of the Whitelist contract. 
     * 
     * @param _securityManager Contract which will manage secure access for this contract. 
     */
    constructor(ISecurityManager _securityManager) {
        _setSecurityManager(_securityManager); 
    }
    
    /**
     * Indicates whether or not the given address is in the whitelist. 
     * 
     * @param addr The address to query. 
     * @return bool True if the given address is in the whitelist.
     */
    function isWhitelisted(address addr) external view returns (bool) {
        if (whitelistOn) {
            return whitelisted[addr]; 
        }
        return true;
    }
    
    /**
     * Adds or removes an address to/from the whitelist. 
     * 
     * Emits: 
     * - {WhitelistAddedRemoved} event if any change has been made to the whitelist. 
     * 
     * Reverts: 
     * - {UnauthorizedAccess} if caller does not have the appropriate security role
     * - {ZeroAddressArgument} if address passed is 0x0
     * 
     * @param addr The address to add or remove. 
     * @param addRemove If true, adds; otherwise removes the address.
     */
    function addRemoveWhitelist(address addr, bool addRemove) external onlyRole(WHITELIST_MANAGER_ROLE) {  
        if (addr == address(0)) 
            revert ZeroAddressArgument(); 
        
        _addRemoveWhitelist(addr, addRemove); 
    }
    
    /**
     * Adds or removes multiple addresses to/from the whitelist. 
     * @dev Addresses that are equal to 0x0 will not be added, but the function will not revert if one 
     * is included in the array. 0x0 addresses in this function will just be ignored. 
     * 
     * Emits: 
     * - {WhitelistAddedRemoved} event if any change has been made to the whitelist, for each address. 
     * 
     * Reverts: 
     * - {UnauthorizedAccess} if caller does not have the appropriate security role
     * 
     * @param addresses Array of addresses to add or remove. 
     * @param addRemove If true, adds; otherwise removes the address.
     */
    function addRemoveWhitelistBulk(address[] calldata addresses, bool addRemove) external onlyRole(WHITELIST_MANAGER_ROLE)  {
        for (uint n = 0; n < addresses.length; n++) {
            if (addresses[n] != address(0)) {
                _addRemoveWhitelist(addresses[n], addRemove); 
            }
        }
    }
    
    /**
     * Enables or disables whitelisting. 
     * 
     * Emits: 
     * - {WhitelistOnOffChanged} event if any change has been made to {whitelistOn} flag. 
     * 
     * Reverts: 
     * - {UnauthorizedAccess} if caller does not have the appropriate security role
     * 
     * @param onOff If true, enables; otherwise disables whitelisting.
     */
    function setWhitelistOnOff(bool onOff) external onlyRole(WHITELIST_MANAGER_ROLE) { 
        if (whitelistOn != onOff) {
            whitelistOn = onOff;
            emit WhitelistOnOffChanged(_msgSender(), onOff);
        }
    }
    
    /**
     * Adds or removes the given address to/from the whitelist. 
     * 
     * Emits: 
     * - {WhitelistAddedRemoved} if any change has been made to the whitelist (e.g. address
     *      actually added or removed)
     * 
     * @param addr The address to add or remove. 
     * @param addRemove If true, adds; otherwise removes the address.
     */
    function _addRemoveWhitelist(address addr, bool addRemove) internal {
        if (whitelisted[addr] != addRemove) {
            whitelisted[addr] = addRemove;
            emit WhitelistAddedRemoved(_msgSender(), addr, addRemove); 
        }
    }
}