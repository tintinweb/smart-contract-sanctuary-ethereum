// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccessControlRegistry {
    
    function name() external view returns (string memory);    
    
    function initializeWithData(address sender, bytes memory initData) external;

    function updateWithData(bytes memory updateData) external;
    
    function getAccessLevel(address, address) external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import {IAccessControlRegistry} from "../../../../lib/onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";
import {IAccessControlRegistry} from "./IAccessControlRegistry.sol";

contract RoleAccess is IAccessControlRegistry {

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////    
    
    enum Roles {
        NO_ROLE,
        MANAGER,
        ADMIN
    }       

    struct RoleDetails {
        address account;
        Roles role;
    } 

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    error RequiresAdmin();
    error RequiresHigherRole();
    error RoleDoesntExist();    

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    event RoleGranted(
        address targetPress,
        address sender,
        address account,
        Roles role 
    );    

    event RoleRevoked(
        address targetPress,
        address sender,
        address account,
        Roles role 
    );            

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    string public constant name = "RoleAccess";

    // Curation contract to account to role
    mapping(address => mapping(address => Roles)) roleInfo;

    //////////////////////////////////////////////////
    // ADMIN
    //////////////////////////////////////////////////    

    /// @notice isAdmin getter for a target index
    /// @param targetPress target Press
    /// @param account account to check
    function _isAdmin(address targetPress, address account)
        internal
        view
        returns (bool)
    {
        // Return true/false depending on whether account is an admin
        return roleInfo[targetPress][account] != Roles.ADMIN ? false : true;
    }

    /// @notice isAdmin getter for a target index
    /// @param targetPress target Press
    /// @param account account to check
    function _isAdminOrManager(address targetPress, address account)
        internal
        view
        returns (bool)
    {
        // Return true/false depending on whether account is an admin or manager
        return roleInfo[targetPress][account] != Roles.NO_ROLE ? true : false;
    }       

    /// @notice Only allowed for contract admin
    /// @param targetPress target Press 
    /// @dev only allows approved admin of target Press (from msg.sender)
    modifier onlyAdmin(address targetPress) {
        if (!_isAdmin(targetPress, msg.sender)) {
            revert RequiresAdmin();
        }

        _;
    }

    /// @notice Only allowed for contract admin
    /// @param targetPress target Press 
    /// @dev only allows approved managers or admins of platform index (from msg.sender)
    modifier onlyAdminOrManager(address targetPress) {
        if (!_isAdminOrManager(targetPress, msg.sender)) {
            revert RequiresHigherRole();
        }

        _;
    }        

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice initializes mapping of access control
    /// @dev contract initializing access control => admin address
    /// @dev called by other contracts initiating access control
    /// @dev data format: admin
    function initializeWithData(address targetPress, bytes memory data) external {

        // abi.decode initial role information set on access control initialization
        (RoleDetails[] memory initialRoles) = abi.decode(data, (RoleDetails[]));

        // call internal grant roles function
        _grantRoles(targetPress, initialRoles);
    }

    /// @notice updates strategy of already initialized access control mapping
    /// @dev will always revert since this access control scheme cannot be updated
    function updateWithData(bytes memory data) external {}

    // /// @notice Grants new roles for given press
    // /// @param targetPress target Press index
    // /// @param roleDetails array of roleDetails structs
    // function grantRoles(address targetPress, RoleDetails[] memory roleDetails) 
    //     onlyAdmin(targetPress) 
    //     external
    // {
    //     _grantRoles(targetPress, roleDetails);
    // }

    /// @notice Grants new roles for given press
    /// @param targetPress target Press index
    /// @param roleDetails array of roleDetails structs
    function _grantRoles(address targetPress, RoleDetails[] memory roleDetails) internal {
        // grant roles to each [account, role] provided
        for (uint256 i; i < roleDetails.length; ++i) {
            // check that role being granted is a valid role
            if (roleDetails[i].role > Roles.ADMIN) {
                revert RoleDoesntExist();
            }
            // give role to account
            roleInfo[targetPress][roleDetails[i].account] = roleDetails[i].role;

            emit RoleGranted({
                targetPress: targetPress,
                sender: msg.sender,
                account: roleDetails[i].account,
                role: roleDetails[i].role
            });
        }    
    }    

    /// @notice Revokes roles for given Press 
    /// @param targetPress target Press
    /// @param accounts array of addresses to revoke roles from
    function revokeRoles(address targetPress, address[] memory accounts) 
        onlyAdmin(targetPress) 
        external
    {
        // revoke roles from each account provided
        for (uint256 i; i < accounts.length; ++i) {
            // revoke role from account
            roleInfo[targetPress][accounts[i]] = Roles.NO_ROLE;

            emit RoleRevoked({
                targetPress: targetPress,
                sender: msg.sender,
                account: accounts[i],
                role: Roles.NO_ROLE
            });
        }    
    }     

    //////////////////////////////////////////////////
    // VIEW FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
    function getAccessLevel(address accessMappingTarget, address addressToGetAccessFor)
        external
        view
        returns (uint256)
    {
        return uint256(roleInfo[accessMappingTarget][addressToGetAccessFor]);
    }
}