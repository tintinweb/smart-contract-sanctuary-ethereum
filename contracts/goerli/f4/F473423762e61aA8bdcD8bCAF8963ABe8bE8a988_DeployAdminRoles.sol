// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../MarketplaceFacet/AdminRolesFaucet.sol";

contract DeployAdminRoles {
    function deployAdminRolesContract(
        string memory _marketplaceName, 
        address _PSAdmin, 
        address _MPSAdmin
    ) external returns(address) {
        AdminRolesFaucet adminRolesContract = new AdminRolesFaucet(
            _marketplaceName,
            _PSAdmin,
            _MPSAdmin
        );

        return address(adminRolesContract);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibAdminRoles } from "../../libraries/LibAdminRolesFacetStorage.sol";

contract AdminRolesFaucet {
    constructor(string memory _marketplaceName, address _PSAdmin, address _MPSAdmin) {
        LibAdminRoles.AdminRolesFacetStorage storage ds = LibAdminRoles.adminRolesFacetStorage();
        ds.MarketPlace = _marketplaceName;
        ds.PSAdmin = _PSAdmin;
        ds.MPSAdmin = _MPSAdmin;

        ds.isPSuperAdmin[_PSAdmin] = true;
        ds.isMPSuperAdmin[_MPSAdmin] = true;
    }
    
    // We need addresses of both SuperAdmin & compliance-admin as both should approve it!
    function addMPCompilenceAdmin(address[] memory _owners, uint _numConfirmationsRequired) external {
        LibAdminRoles.addMPCompilenceAdmin(_owners, _numConfirmationsRequired);
    }

    // We need addresses of both SuperAdmin & token-admin as either can approve it!
    function addMPTokenAdmin(address[] memory _MPTokenAdmin) external {
        LibAdminRoles.addMPTokenAdmin(_MPTokenAdmin);
    }

    function GetNumConfirmationsRequired() external view returns(uint) {
        LibAdminRoles.AdminRolesFacetStorage storage ds = LibAdminRoles.adminRolesFacetStorage();
        return ds.numConfirmationsRequired;
    }

    function only_super_and_CompilanceAdmin(address admin) external view returns(bool) {
        LibAdminRoles.AdminRolesFacetStorage storage ds = LibAdminRoles.adminRolesFacetStorage();
        return ds.isMPCompilanceAdmin[admin];
    }

    function only_super_or_MPTokenAdmin(address admin) external view returns(bool) {
        LibAdminRoles.AdminRolesFacetStorage storage ds = LibAdminRoles.adminRolesFacetStorage();
        return ds.isMPTokenAdmin[admin];
    }

    function only_MPSuperAdmin(address admin) external view returns(bool) {
        LibAdminRoles.AdminRolesFacetStorage storage ds = LibAdminRoles.adminRolesFacetStorage();
        return ds.isMPSuperAdmin[admin];
    }

    function only_PSuperAdmin(address admin) external view returns(bool) {
        LibAdminRoles.AdminRolesFacetStorage storage ds = LibAdminRoles.adminRolesFacetStorage();
        return ds.isPSuperAdmin[admin];
    }

    function admin_Addresses() external view returns(address PSuperAdmin, address MPSuperAdmin) {
        LibAdminRoles.AdminRolesFacetStorage storage ds = LibAdminRoles.adminRolesFacetStorage();
        return (ds.PSAdmin, ds.MPSAdmin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Errors
error not_super_admin();
error compilance_Admin_Needed();
error invalid_number_of_required_confirmations();
error invalid_compliance();
error Admin_should_be_unique();
error invalid_MPTokenAdmin();

library LibAdminRoles {
    bytes32 constant STORAGE_POSITION = keccak256("car.storage.marketplace.adminRoles.facet");

    struct AdminRolesFacetStorage {
        string MarketPlace;
        address PSAdmin;
        address MPSAdmin;
        address[] MPCompilanceAdmin;
        address[] MPTokenAdmins;
        mapping(address => bool) isPSuperAdmin;
        mapping(address => bool) isMPSuperAdmin;
        mapping(address => bool) isMPCompilanceAdmin;
        mapping(address => bool) isMPTokenAdmin;
        uint numConfirmationsRequired; // Mostly 2 Marketplace Compliance Admin and MPSAdmin
    }

    // Creates and returns the storage pointer to the struct.
    function adminRolesFacetStorage() internal pure returns (AdminRolesFacetStorage storage ds) {
		bytes32 storagePosition = STORAGE_POSITION;
		
		assembly {
			ds.slot := storagePosition
		}
	}

    function addMPCompilenceAdmin(
        address[] memory _owners, 
        uint _numConfirmationsRequired
    ) internal {
        AdminRolesFacetStorage storage ds = adminRolesFacetStorage();

        if(ds.isMPSuperAdmin[msg.sender]) {    
            if (_owners.length <= 0) {
                revert compilance_Admin_Needed();
            }

            if(_numConfirmationsRequired < 0 && _numConfirmationsRequired > _owners.length) {
                revert invalid_number_of_required_confirmations();
            }

            // Adding Owner's addresses on an array - MPSAdmin, MPCAdmin
            for (uint i = 0; i < _owners.length; i++) {
                address owner = _owners[i];

                if(owner == address(0)) {
                    revert invalid_compliance();
                }

                if(ds.isMPCompilanceAdmin[owner]) {
                    revert Admin_should_be_unique();
                }

                ds.isMPCompilanceAdmin[owner] = true;
                ds.MPCompilanceAdmin.push(owner);
            }

            ds.numConfirmationsRequired = _numConfirmationsRequired;
        } else {
            revert not_super_admin();
        }
    }

    function addMPTokenAdmin(address[] memory _MPTokenAdmin) internal {
        AdminRolesFacetStorage storage ds = adminRolesFacetStorage();
        
        if(ds.isMPSuperAdmin[msg.sender]) {
            for (uint i = 0; i < _MPTokenAdmin.length; i++) {
                address MPTokenAdmin = _MPTokenAdmin[i];

                if(MPTokenAdmin == address(0)) {
                    revert invalid_MPTokenAdmin();
                }

                if(ds.isMPTokenAdmin[MPTokenAdmin]) {
                    revert Admin_should_be_unique();
                }

                ds.isMPTokenAdmin[MPTokenAdmin] = true;
                ds.MPTokenAdmins.push(MPTokenAdmin);
            }
        } else {
            revert not_super_admin();
        }
    }
}